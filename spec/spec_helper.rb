require 'rubygems'
require 'thin'
require 'benchmark'
require 'timeout'
require 'fileutils'
require 'net/http'
require 'socket'
require 'tempfile'

include Thin

FileUtils.mkdir_p File.dirname(__FILE__) + '/../log'
Command.script = File.dirname(__FILE__) + '/../bin/thin'
Logging.silent = true

unless Object.const_defined?(:SWIFTIPLY_PATH)
  SWIFTIPLY_PATH       = `which swiftiply`.chomp
  DEFAULT_TEST_ADDRESS = '0.0.0.0'
  DEFAULT_TEST_PORT    = 3333
end

module Matchers
  class BeFasterThen
    def initialize(max_time)
      @max_time = max_time
    end

    def supports_block_expectations?
      true
    end

    # Base on benchmark_unit/assertions#compare_benchmarks
    def matches?(proc)
      @time, multiplier = 0, 1
      
      while (@time < 0.01) do
        @time = Benchmark.realtime do
          multiplier.times &proc
        end
        multiplier *= 10
      end
      
      multiplier /= 10
      
      iterations = (@time * multiplier).to_i
      iterations = 1 if iterations < 1
      
      total = Benchmark.realtime do
        iterations.times &proc
      end
      
      @time = total / iterations
      
      @time < @max_time
    end
    
    def failure_message(less_more=:less)
      "took <#{@time.inspect}s>, should take #{less_more} than #{@max_time}s."
    end

    def failure_message_when_negated
      failure_message :more
    end
  end
  
  class ValidateWithLint
    def matches?(request)
      @request = request
      Rack::Lint.new(proc{[200, {'content-type' => 'text/html', 'content-length' => '0'}, []]}).call(@request.env)
      true
    rescue Rack::Lint::LintError => e
      @message = e.message
      false
    end
    
    def failure_message(negation=nil)
      "should#{negation} validate with Rack Lint: #{@message}"
    end

    def failure_message_when_negated
      failure_message ' not'
    end
  end

  class TakeLessThen
    def initialize(time)
      @time = time
    end
    
    def supports_block_expectations?
      true
    end
    
    def matches?(proc)
      Timeout.timeout(@time) { proc.call }
      true
    rescue Timeout::Error
      false 
    end
    
    def failure_message(negation=nil)
      "should#{negation} take less then #{@time} sec to run"
    end

    def failure_message_when_negated
      failure_message ' not'
    end
  end

  # Actual matchers that are exposed.

  def be_faster_then(time)
    BeFasterThen.new(time)
  end
  
  def validate_with_lint
    ValidateWithLint.new
  end

  def take_less_then(time)
    TakeLessThen.new(time)
  end  
end

module Helpers
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
  
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  # Yield to the provided block, redirecting its STDOUT
  # temporarily, and return its output to our caller
  #
  #   msgs = with_redirected_stdout do
  #     server.do_something_that_logs
  #   end
  #
  #   puts msgs
  #
  def with_redirected_stdout
    ret = nil
    t = Tempfile.new('thin-tests')
    begin
      old_stdout = STDOUT.dup
      STDOUT.reopen(t) ; STDOUT.sync = true
      yield
      t.rewind
      ret = t.read
    ensure
      STDOUT.reopen(old_stdout)
      t.close
    end
    ret
  end

  # Create and parse a request
  def R(raw, convert_line_feed=false)
    raw.gsub!("\n", "\r\n") if convert_line_feed
    request = Thin::Request.new
    request.parse(raw)
    request
  end
  
  def start_server(address=DEFAULT_TEST_ADDRESS, port=DEFAULT_TEST_PORT, options={}, &app)
    @server = Thin::Server.new(address, port, options, app)
    @server.ssl = options[:ssl]
    @server.threaded = options[:threaded]
    @server.timeout = 3
    Thin::Logging.silent = true
    
    @thread = Thread.new { @server.start }
    if options[:wait_for_socket]
      wait_for_socket(address, port)
    else
      # If we can't ping the address fallback to just wait for the server to run
      sleep 0.01 until @server.running?
    end
  end
  
  def stop_server
    @server.stop!
    @thread.kill
    
    1000.times do
      break unless EM.reactor_running?
      sleep 0.01
    end

    raise "Reactor still running, wtf?" if EventMachine.reactor_running?
  end
  
  def wait_for_socket(address=DEFAULT_TEST_ADDRESS, port=DEFAULT_TEST_PORT, timeout=5)
    Timeout.timeout(timeout) do
      loop do
        begin
          if address.include?('/')
            UNIXSocket.new(address).close
          else
            TCPSocket.new(address, port).close
          end
          return true
        rescue
        end
      end
    end
  end
    
  def send_data(data)
    if @server.backend.class == Backends::UnixServer
      socket = UNIXSocket.new(@server.socket)
    else
      socket = TCPSocket.new(@server.host, @server.port)
    end
    socket.write data
    out = socket.read
    socket.close
    out
  end
  
  def parse_response(response)
    raw_headers, body = response.split("\r\n\r\n", 2)
    raw_status, raw_headers = raw_headers.split("\r\n", 2)

    status  = raw_status.match(%r{\AHTTP/1.1\s+(\d+)\b}).captures.first.to_i
    headers = Hash[ *raw_headers.split("\r\n").map { |h| h.split(/:\s+/, 2) }.flatten ]

    [ status, headers, body ]
  end
  
  def get(url)
    if @server.backend.class == Backends::UnixServer
      send_data("GET #{url} HTTP/1.1\r\nConnection: close\r\n\r\n")
    else
      Net::HTTP.get(URI.parse("http://#{@server.host}:#{@server.port}" + url))
    end
  end
  
  def post(url, params={})
    Net::HTTP.post_form(URI.parse("http://#{@server.host}:#{@server.port}" + url), params).body
  end
end

RSpec.configure do |config|
  config.include Matchers
  config.include Helpers
end
