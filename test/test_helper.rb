require 'rubygems'
require File.dirname(__FILE__) + '/../lib/thin'
require 'test/unit'
require 'mocha'
require 'benchmark'

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

class TestHandler < Thin::Handler
  def process(request, response)
    response.body << request.body.read
    response.body << request.params['QUERY_STRING']
    true
  end
end

class Test::Unit::TestCase
  protected
    def assert_faster_then(max_time, verbose=false)
      time = Benchmark.measure { yield }.real * 1000
      puts "Took #{time} ms, should take less then #{max_time} ms" if verbose
      assert time <= max_time, "Too slow : took #{time} ms, should take less then #{max_time} ms"
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
