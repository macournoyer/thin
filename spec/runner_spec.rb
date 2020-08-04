require 'spec_helper'

describe Runner do
  it "should parse options" do
    runner = Runner.new(%w(start --pid test.pid --port 5000 -o 3000))

    expect(runner.options[:pid]).to eq('test.pid')
    expect(runner.options[:port]).to eq(5000)
    expect(runner.options[:only]).to eq(3000)
  end

  it "should parse specified command" do
    expect(Runner.new(%w(start)).command).to eq('start')
    expect(Runner.new(%w(stop)).command).to eq('stop')
    expect(Runner.new(%w(restart)).command).to eq('restart')
  end

  it "should abort on unknow command" do
    runner = Runner.new(%w(poop))

    expect(runner).to receive(:abort)
    runner.run!
  end

  it "should exit on empty command" do
    runner = Runner.new([])

    expect(runner).to receive(:exit).with(1)

    silence_stream(STDOUT) do
      runner.run!
    end
  end

  it "should use Controller when controlling a single server" do
    runner = Runner.new(%w(start))

    controller = double('controller')
    expect(controller).to receive(:start)
    expect(Controllers::Controller).to receive(:new).and_return(controller)

    runner.run!
  end

  it "should use Cluster controller when controlling multiple servers" do
    runner = Runner.new(%w(start --servers 3))

    controller = double('cluster')
    expect(controller).to receive(:start)
    expect(Controllers::Cluster).to receive(:new).and_return(controller)

    runner.run!
  end

  it "should default to single server controller" do
    expect(Runner.new(%w(start))).not_to be_a_cluster
  end

  it "should consider as a cluster with :servers option" do
    expect(Runner.new(%w(start --servers 3))).to be_a_cluster
  end

  it "should consider as a cluster with :only option" do
    expect(Runner.new(%w(start --only 3000))).to be_a_cluster
  end

  it "should warn when require a rack config file" do
    runner = Runner.new(%w(start -r config.ru))

    expect(runner).to receive(:warn).with(/WARNING:/)

    runner.run! rescue nil

    expect(runner.options[:rackup]).to eq('config.ru')
  end

  it "should require file" do
    runner = Runner.new(%w(start -r unexisting))
    expect { runner.run! }.to raise_error(LoadError)
  end

  it "should remember requires" do
    runner = Runner.new(%w(start -r rubygems -r thin))
    expect(runner.options[:require]).to eq(%w(rubygems thin))
  end

  it "should remember debug options" do
    runner = Runner.new(%w(start -D -q -V))
    expect(runner.options[:debug]).to be_truthy
    expect(runner.options[:quiet]).to be_truthy
    expect(runner.options[:trace]).to be_truthy
  end

  it "should default debug, silent and trace to false" do
    runner = Runner.new(%w(start))
    expect(runner.options[:debug]).not_to be_truthy
    expect(runner.options[:quiet]).not_to be_truthy
    expect(runner.options[:trace]).not_to be_truthy
  end
end

describe Runner, 'with config file' do
  before :each do
    @runner = Runner.new(%w(start --config spec/configs/cluster.yml))
  end

  it "should load options from file with :config option" do
    @runner.send :load_options_from_config_file!

    expect(@runner.options[:environment]).to eq('production')
    expect(@runner.options[:chdir]).to eq('spec/rails_app')
    expect(@runner.options[:port]).to eq(5000)
    expect(@runner.options[:servers]).to eq(3)
  end

  it "should load options from file using an ERB template" do
    @runner = Runner.new(%w(start --config spec/configs/with_erb.yml))
    @runner.send :load_options_from_config_file!

    expect(@runner.options[:timeout]).to eq(30)
    expect(@runner.options[:port]).to eq(4000)
    expect(@runner.options[:environment]).to eq('production')
  end

  it "should change directory after loading config" do
    @orig_dir = Dir.pwd

    controller = double('controller')
    expect(controller).to receive(:respond_to?).with('start').and_return(true)
    expect(controller).to receive(:start)
    expect(Controllers::Cluster).to receive(:new).and_return(controller)
    expected_dir = File.expand_path('spec/rails_app')

    begin
      silence_stream(STDERR) do
        @runner.run!
      end

      expect(Dir.pwd).to eq(expected_dir)

    ensure
      # any other spec using relative paths should work as expected
      Dir.chdir(@orig_dir)
    end
  end
end

describe Runner, "service" do
  before do
    allow(Thin).to receive(:linux?) { true }

    @controller = double('service')
    allow(Controllers::Service).to receive(:new) { @controller }
  end

  it "should use Service controller when controlling all servers" do
    runner = Runner.new(%w(start --all))

    expect(@controller).to receive(:start)

    runner.run!
  end

  it "should call install with arguments" do
    runner = Runner.new(%w(install /etc/cool))

    expect(@controller).to receive(:install).with('/etc/cool')

    runner.run!
  end

  it "should call install without arguments" do
    runner = Runner.new(%w(install))

    expect(@controller).to receive(:install).with(no_args)

    runner.run!
  end
end
