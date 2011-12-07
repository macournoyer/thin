require "bundler/setup"
Bundler.require(:default, :test)

$:.unshift File.expand_path("../../lib", __FILE__)
require "thin"
require "test/unit"
require "mocha"
require "net/http"
require "timeout"

class Test::Unit::TestCase
  include Mocha::API # fix mocha API not being included in minitest

  # Silences any stream for the duration of the block.
  #
  #   silence_stream(STDOUT) do
  #     puts 'This will never be seen'
  #   end
  #
  #   puts 'But this will'
  #
  # (Taken from ActiveSupport)
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end

  def silence_streams
    silence_stream($stdout) { silence_stream($stderr) { yield } }
  end

  def capture_streams
    out = StringIO.new
    silence_streams do
      $stdout = out
      $stderr = out
      yield
      out.read
    end
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end
end

class ConfigWriter < BasicObject
  def initialize(&block)
    @lines = []
    instance_eval(&block) if block
  end

  def method_missing(name, *args)
    @lines << name.to_s + " " + args.map { |arg| arg.inspect }.join(", ")
  end

  def write(file)
    ::File.open(file, "w") do |f|
      f << "# Generated during tests by ConfigWriter in test_helper.rb\n"
      f << @lines.join("\n")
    end
  end
end

class IntegrationTestCase < Test::Unit::TestCase
  PORT = 8181
  UNIX_SOCKET = "/tmp/thin-test.sock"
  LOG_FILE = "test.log"
  PID_FILE = "test.pid"

  # Start a new thin server from the command line utility mimicing real world usage.
  # @param runner_options Options to pass to the command line utility.
  # @param configuration Block of configuration to pass to the configurator.
  def thin(runner_options={}, &configuration)
    raise "Server already started in process #" + File.read(PID_FILE) if File.exist?(PID_FILE)

    # Cleanup
    File.delete LOG_FILE if File.exist?(LOG_FILE)
    File.delete UNIX_SOCKET if File.exist?(UNIX_SOCKET)

    root = File.expand_path('../..', __FILE__)

    # Generate a config file from the configuration block
    config_file = "test.conf.rb"
    config = ConfigWriter.new do
      worker_processes 1
    end
    config.instance_eval(&configuration) if configuration
    config.write(config_file)

    # Command line options
    runner_options = { :config => config_file, :port => PORT, :log => LOG_FILE, :pid => PID_FILE }.merge(runner_options)

    # Launch the server from the shell
    command = "bundle exec ruby -I#{root}/lib " +
                "#{root}/bin/thin " +
                  runner_options.map { |k, v| "--#{k}" + (TrueClass === v ? "" : "=#{v}") }.join(" ") + " " +
                  File.expand_path("../integration/config.ru", __FILE__)
    launcher_pid = silence_stream($stdout) { spawn command }

    tries = 0
    wait = 5 #sec
    until running?
      sleep 0.1
      tries += 1
      raise "Failed to start server under #{wait} sec" if tries > wait/0.1
    end

    @pid = File.read(PID_FILE).to_i

    launcher_pid
  end

  def teardown
    if @pid
      Process.kill "INT", @pid
      begin
        Process.wait @pid
      rescue Errno::ECHILD
        # Process is not a child. We ping until process dies.
        sleep 0.1 while Process.kill 0, @pid rescue false
      end
      @pid = nil
    end
    raise "Didn't delete PID file." if File.exist?(PID_FILE)
    @response = nil
  end
  
  def running?
    return true if File.exist?(UNIX_SOCKET)
    get("/")
    true
  rescue Errno::ECONNREFUSED
    false
  rescue
    true
  end

  def get(path, host="localhost")
    @response = Timeout.timeout(3) { Net::HTTP.get_response(URI.parse("http://#{host}:#{PORT}" + path)) }
  end

  def post(path, params={})
    Timeout.timeout(3) do
      uri = URI.parse("http://localhost:#{PORT}" + path)
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)

      @response = http.request(request)
    end
  end

  def socket
    @response = nil
    socket = TCPSocket.new("localhost", PORT)
    yield socket
  ensure
    socket.close rescue nil
  end

  def unix_socket
    @response = nil
    socket = UNIXSocket.new(UNIX_SOCKET)
    yield socket
  ensure
    socket.close rescue nil
  end

  def assert_status(status)
    assert_equal status, @response.code.to_i
  end

  def assert_response_equals(string)
    assert_equal string, @response.body
  end

  def assert_response_includes(*strings)
    strings.each do |string|
      assert @response.body.include?(string), "expected response to include #{string}, but got: #{@response.body}"
    end
  end

  def assert_header(key, value)
    assert_equal value, @response[key]
  end

  def read_log
    File.read(LOG_FILE)
  end
end
