require 'rubygems'
require File.dirname(__FILE__) + '/../lib/thin'
require 'test/unit'
require 'mocha'
require 'benchmark'
require 'timeout'

FileUtils.mkdir_p File.dirname(__FILE__) + '/../log'

class TestRequest < Thin::Request
  def initialize(path, verb='GET', params={})
    @path = path
    @verb = verb.to_s.upcase
    @params = {
      'HTTP_HOST'      => 'localhost:3000',
      'REQUEST_URI'    => @path,
      'REQUEST_PATH'   => @path,
      'REQUEST_METHOD' => @verb,
      'SCRIPT_NAME'    => @path
    }.merge(params)
    
    @body = "#{@verb} #{path} HTTP/1.1"
  end
end

class Test::Unit::TestCase
  protected
    def timeout(sec)
      Timeout.timeout(sec) { yield }
    rescue Timeout::Error
      flunk "Timeout after #{sec} sec"
    end
  
    def assert_faster_then(title, max_time, verbose=false)
      time = Benchmark.measure { yield }.real * 1000
      msg = "took #{time} ms, should take less then #{max_time} ms"
      puts msg if verbose
      warn "#{title} too slow : #{msg}" if time > max_time
    end
    
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
