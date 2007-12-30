require 'rubygems'
require File.dirname(__FILE__) + '/../lib/thin'
require 'spec'
require 'benchmark'
require 'timeout'

include Thin

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

module Matchers
  class BeFasterThen
    def initialize(max_time)
      @max_time = max_time
    end

    def matches?(target)
      @target = target
      @time = Benchmark.measure { @target.call }.real * 1000
      @time <= @max_time
    end
    
    def message(less_more=:less)
      "took #{@time} ms, should take #{less_more} then #{@max_time} ms"
    end

    def failure_message
      message :less
    end

    def negative_failure_message
      message :more
    end

    def to_string(value)
      value.to_s
    end
  end
  
  class ValidateWithLint
    def matches?(request)
      @request = request
      Rack::Lint.new(proc{[200, {'Content-Type' => 'text/html'}, []]}).call(@request.env)
      true
    rescue Rack::Lint::LintError => e
      @message = e.message
      false
    end
    
    def failure_message(negation=nil)
      "should#{negation} validate with Rack Lint"
    end

    def negative_failure_message
      failure_message ' not'
    end

    def to_string(value)
      value.to_s
    end
  end

  # Actual matchers that are exposed.

  def be_faster_then(time)
    BeFasterThen.new(time)
  end
  
  def validate_with_lint
    ValidateWithLint.new
  end
end

module Helpers
  def timeout(sec)
    Timeout.timeout(sec) { yield }
  rescue Timeout::Error
    violated "Timeout after #{sec} sec"
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

Spec::Runner.configure do |config|
  config.include Matchers
  config.include Helpers
end