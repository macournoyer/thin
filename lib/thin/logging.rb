module Thin
  # To be included into classes to allow some basic logging
  # that can be silented (+silent+) or made more verbose ($DEBUG=true).
  module Logging
    # Don't output any message if +true+.
    attr_accessor :silent
    
    protected
      # Log a message to the console
      def log(msg)
        puts msg unless @silent
      end
      
      # Log a message to the console if tracing is activated
      def trace(msg=nil)
        puts msg || yield if $DEBUG && !@silent
      end
      
      def log_error(e)
        trace { "#{e}\n\t" + e.backtrace.join("\n\t") }
      end
  end
end