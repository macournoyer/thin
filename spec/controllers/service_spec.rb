require 'spec_helper'
include Controllers

describe Service do
  before(:all) do
    silence_warnings do
      Service::INITD_PATH          = 'tmp/sandbox' + Service::INITD_PATH
      Service::DEFAULT_CONFIG_PATH = 'tmp/sandbox' + Service::DEFAULT_CONFIG_PATH
    end
  end

  before do
    allow(Thin).to receive(:linux?) { true }
    FileUtils.mkdir_p 'tmp/sandbox'

    @service = Service.new(:all => 'spec/configs')
  end

  it "should call command for each config file" do
    expect(Command).to receive(:run).with(:start, :config => 'spec/configs/cluster.yml', :daemonize => true)
    expect(Command).to receive(:run).with(:start, :config => 'spec/configs/single.yml', :daemonize => true)
    expect(Command).to receive(:run).with(:start, :config => 'spec/configs/with_erb.yml', :daemonize => true)

    @service.start
  end

  it "should create /etc/init.d/thin file when calling install" do
    @service.install

    expect(File.exist?(Service::INITD_PATH)).to be_truthy
    script_name = File.directory?('/etc/rc.d') ?
      '/etc/rc.d/thin' : '/etc/init.d/thin'
    expect(File.read(Service::INITD_PATH)).to include('CONFIG_PATH=tmp/sandbox/etc/thin',
                                                  'SCRIPT_NAME=tmp/sandbox' + script_name,
                                                  'DAEMON=' + Command.script)
  end

  it "should create /etc/thin dir when calling install" do
    @service.install

    expect(File.directory?(Service::DEFAULT_CONFIG_PATH)).to be_truthy
  end

  it "should include specified path in /etc/init.d/thin script" do
    @service.install('tmp/sandbox/usr/thin')

    expect(File.read(Service::INITD_PATH)).to include('CONFIG_PATH=tmp/sandbox/usr/thin')
  end

  after do
    FileUtils.rm_rf 'tmp/sandbox'
  end
end
