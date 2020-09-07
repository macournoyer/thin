require 'spec_helper'

##
# Dummy class, so that we can mix in the Logging module and test it.
#
class TestLogging
  include Logging
end

describe Logging do
  subject {TestLogging.new}

  after do
    Logging.silent = true
    Logging.debug = false
    Logging.trace = false
  end

  describe "when setting a custom logger" do

    it "should not accept a logger object that is not sane" do
      expect { Logging.logger = "" }.to raise_error(ArgumentError)
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
      subject.log_debug("hi")

      str = nil
      expect { str = @readpipe.read_nonblock(512) }.to_not raise_error
      expect(str).not_to be_nil
    end

    #
    #
    it "at log level NOT DEBUG should NOT output logs at debug level" do
      Logging.debug = false
      subject.log_debug("hiya")

      expect do
        @readpipe.read_nonblock(512)
      end.to raise_error(IO::EAGAINWaitReadable)
    end

    #
    #
    it "should be usable (at the module level) for logging" do
      expect(@custom_logger).to receive(:add)
      Logging.log_msg("hey")
    end

    # These should be the last test we run for the 'log' functionality
    #
    it "should not log messages if silenced via module method" do
      Logging.silent = true
      subject.log_info("hola")
      expect do
        @readpipe.read_nonblock(512)
      end.to raise_error(IO::EAGAINWaitReadable)
    end

    it "should not log anything if silenced via module methods" do
      Logging.silent = true
      Logging.log_msg("hi")
      expect do
        @readpipe.read_nonblock(512)
      end.to raise_error(IO::EAGAINWaitReadable)
    end

    it "should not log anything if silenced via instance methods" do
      subject.silent = true
      subject.log_info("hello")
      expect do
        @readpipe.read_nonblock(512)
      end.to raise_error(IO::EAGAINWaitReadable)
    end

  end # Logging tests (with custom logger)

  describe "logging routines (with NO custom logger)" do

    it "should log at debug level if debug logging is enabled " do
      Logging.debug = true
      out = with_redirected_stdout do
        subject.log_debug("Hey")
      end

      expect(out.include?("Hey")).to be_truthy
      expect(out.include?("DEBUG")).to be_truthy
    end

    it "should be usable (at the module level) for logging" do
      out = with_redirected_stdout do
        Logging.log_msg("Hey")
      end

      expect(out.include?("Hey")).to be_truthy
    end

  end

  describe "trace routines (with custom trace logger)" do

    before :each do
      @custom_tracer = Logger.new(STDERR)
      Logging.trace_logger = @custom_tracer
    end

    it "should NOT emit trace messages if tracing is disabled" do
      Logging.trace = false
      expect(@custom_tracer).not_to receive(:info)
      subject.trace("howdy")
    end

    it "should emit trace messages when tracing is enabled" do
      Logging.trace = true
      expect(@custom_tracer).to receive(:info)

      subject.trace("aloha")
    end

  end # Tracer tests (with custom tracer)

  describe "tracing routines (with NO custom logger)" do

    it "should emit trace messages if tracing is enabled " do
      Logging.trace = true
      out = with_redirected_stdout do
        subject.trace("Hey")
      end

      expect(out.include?("Hey")).to be_truthy
    end

    it "should be usable (at the module level) for logging" do
      Logging.trace = true
      out = with_redirected_stdout do
        Logging.trace_msg("hey")
      end

      expect(out.include?("hey")).to be_truthy
    end

  end # tracer tests (no custom logger)

end
