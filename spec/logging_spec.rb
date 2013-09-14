require 'spec_helper'

##
# Dummy class, so that we can mix in the Logging module and test it.
#
class TestLogging
  include Logging
end

describe Logging do

  before :all do
    @object = TestLogging.new
  end

  after(:all) do
    Logging.silent = true
    Logging.debug  = false
    Logging.trace  = false
  end

  describe "when setting a custom logger" do

    it "should not accept a logger object that is not sane" do
      expect { Logging.logger = "" }.to raise_error
    end

    it "should accept a legit custom logger object" do
      expect { Logging.logger = Logger.new(STDOUT) }.to_not raise_error
    end

  end

  describe "logging routines (with a custom logger)" do

    before :each do
      @readpipe, @writepipe = IO.pipe
      @custom_logger = Logger.new(@writepipe)
      Logging.logger = @custom_logger
      Logging.level  = Logger::INFO
    end

    after :each do
      [@readpipe, @writepipe].each do |pipe|
        pipe.close if pipe
      end
    end

    #
    #
    it "at log level DEBUG should output logs at debug level" do
      Logging.debug = true
      @object.log_debug("hi")

      str = nil
      expect { str = @readpipe.read_nonblock(512) }.to_not raise_error
      str.should_not be_nil
    end

    #
    #
    it "at log level NOT DEBUG should NOT output logs at debug level" do
      Logging.debug = false
      @object.log_debug("hiya")

      expect { @readpipe.read_nonblock(512) }.to raise_error
    end

    #
    #
    it "should be usable (at the module level) for logging" do
      @custom_logger.should_receive(:add)
      Logging.log_msg("hey")
    end

    # These should be the last test we run for the 'log' functionality
    #
    it "should not log messages if silenced via module method" do
      Logging.silent = true
      @object.log_info("hola")
      expect { @readpipe.read_nonblock(512) }.to raise_error()
    end

    it "should not log anything if silenced via module methods" do
      Logging.silent = true
      Logging.log_msg("hi")
      expect { @readpipe.read_nonblock(512) }.to raise_error()
    end

    it "should not log anything if silenced via instance methods" do
      @object.silent = true
      @object.log_info("hello")
      expect { @readpipe.read_nonblock(512) }.to raise_error()
    end

  end # Logging tests (with custom logger)

  describe "logging routines (with NO custom logger)" do

    it "should log at debug level if debug logging is enabled " do
      Logging.debug = true
      out = with_redirected_stdout do
        @object.log_debug("Hey")
      end

      out.include?("Hey").should be_true
      out.include?("DEBUG").should be_true
    end

    it "should be usable (at the module level) for logging" do
      out = with_redirected_stdout do
        Logging.log_msg("Hey")
      end

      out.include?("Hey").should be_true
    end

  end

  describe "trace routines (with custom trace logger)" do

    before :each do
      @custom_tracer = Logger.new(STDERR)
      Logging.trace_logger = @custom_tracer
    end

    it "should NOT emit trace messages if tracing is disabled" do
      Logging.trace = false
      @custom_tracer.should_not_receive(:info)
      @object.trace("howdy")
    end

    it "should emit trace messages when tracing is enabled" do
      Logging.trace = true
      @custom_tracer.should_receive(:info)

      @object.trace("aloha")
    end

  end # Tracer tests (with custom tracer)

  describe "tracing routines (with NO custom logger)" do

    it "should emit trace messages if tracing is enabled " do
      Logging.trace = true
      out = with_redirected_stdout do
        @object.trace("Hey")
      end

      out.include?("Hey").should be_true
    end

    it "should be usable (at the module level) for logging" do
      Logging.trace = true
      out = with_redirected_stdout do
        Logging.trace_msg("hey")
      end

      out.include?("hey").should be_true
    end

  end # tracer tests (no custom logger)

end
