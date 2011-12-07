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

class IntegrationTestCase < Test::Unit::TestCase
  PORT = 8181
  LOG_FILE = "test.log"

  def thin(options={})
    root = File.expand_path('../..', __FILE__)
    pid_file = "test.pid"
    options = { :workers => 1, :port => PORT, :pid => pid_file, :log => LOG_FILE }.merge(options)

    raise "Server already started in process #" + File.read(pid_file) if File.exist?(pid_file)

    File.delete LOG_FILE if File.exist?(LOG_FILE)

    command = "bundle exec ruby -I#{root}/lib " +
                "#{root}/bin/thin " +
                  options.map { |k, v| "--#{k}" + (TrueClass === v ? "" : "=#{v}") }.join(" ") + " " +
                  "#{root}/test/integration/config.ru"
    launcher_pid = silence_stream($stdout) { spawn command }

    tries = 0
    until (get("/") rescue nil)
      sleep 0.1
      tries += 1
      raise "Failed to start server" if tries > 20
    end

    @pid = File.read(pid_file).to_i

    launcher_pid
  end

  def teardown
    if @pid
      Process.kill "TERM", @pid
      begin
        Process.wait @pid
      rescue Errno::ECHILD
        # Process is not a child. We ping until process dies.
        sleep 0.1 while Process.kill 0, @pid rescue false
      end
      @pid = nil
    end
    @response = nil
    File.delete LOG_FILE if File.exist?(LOG_FILE)
  end

  def get(path)
    @response = Timeout.timeout(3) { Net::HTTP.get_response(URI.parse("http://localhost:#{PORT}" + path)) }
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
