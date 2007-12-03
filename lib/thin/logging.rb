module Thin
  # To be included into classes to allow some basic logging
  # that can be silented (+silent+) or made more verbose (+trace+).
  module Logging
    # Output extra info about the request, response, errors and stuff like that.
    attr_writer :trace
    
    # Don't output any message if +true+.
    attr_accessor :silent
    
    protected
      # Log a message to the console
      def log(msg)
        puts msg unless @silent
      end
      
      # Log a message to the console (no line feed)
      def logc(msg)
        unless @silent
          print msg
          STDOUT.flush # Make sure the msg is shown right away
        end
      end
  
      # Log a message to the console if tracing is activated
      def trace(msg=nil)
        puts msg || yield if @trace && !@silent
      end
  end
end