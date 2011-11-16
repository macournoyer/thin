$:.unshift File.expand_path("../../lib", __FILE__)
require "thin"
require "test/unit"
require "mocha"
require "net/http"
require "timeout"

class Test::Unit::TestCase
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
end

class IntegrationTestCase < Test::Unit::TestCase
  PORT = 8181
  
  def thin(options={})
    options[:workers] ||= 1
    root = File.expand_path('../..', __FILE__)
    options_output = options.map { |k, v| "--#{k}=#{v}" }.join(" ")
    command = "ruby -I#{root}/lib #{root}/bin/thin -p#{PORT} #{options_output} #{root}/test/integration/config.ru"
    silence_stream(STDOUT) do
      @pid = spawn command
    end
    
    tries = 0
    until (get("/") rescue nil)
      sleep 0.1
      tries += 1
      raise "Failed to start server" if tries > 20
    end
  end
  
  def teardown
    if @pid
      Process.kill "TERM", @pid
      Process.wait @pid rescue Errno::ECHILD
      @pid = nil
    end
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
end