module Thin
  # To be included in classes to allow some basic logging
  # that can be silented (<tt>Logging.silent=</tt>) or made
  # more verbose.
  # <tt>Logging.debug=</tt>: log all error backtrace and messages
  #                          logged with +debug+.
  # <tt>Logging.trace=</tt>: log all raw request and response and
  #                          messages logged with +trace+.
  module Logging
    class << self
      attr_writer :trace, :debug, :silent
      
      def trace?;  !@silent && @trace  end
      def debug?;  !@silent && @debug  end
      def silent?;  @silent            end
    end
    
    # Deprecated silencer methods, those are now a module methods
    def silent
      warn "`#{self.class.name}\#silent` deprecated, use `Thin::Logging.silent?` instead"
      Logging.silent?
    end
    def silent=(value)
      warn "`#{self.class.name}\#silent=` deprecated, use `Thin::Logging.silent = #{value}` instead"
      Logging.silent = value
    end
    
    protected
      # Log a message to the console
      def log(msg)
        puts msg unless Logging.silent?
      end
      
      # Log a message to the console if tracing is activated
      def trace(msg=nil)
        log msg || yield if Logging.trace?
      end
      
      # Log a message to the console if debugging is activated
      def debug(msg=nil)
        log msg || yield if Logging.debug?
      end
      
      # Log an error backtrace if debugging is activated
      def log_error(e)
        debug "#{e}\n\t" + e.backtrace.join("\n\t")
      end
  end
end