module Thin
  module Logging
    # Output extra info about the request, response, errors and stuff like that.
    attr_writer :trace
    
    # Don't output any message if +true+.
    attr_accessor :silent
    
    protected
      def log(msg)
        puts msg unless @silent
      end
      
      def logc(msg)
        unless @silent
          print msg
          STDOUT.flush # Make sure the msg is shown right away
        end
      end
  
      def trace(msg=nil)
        puts msg || yield if @trace && !@silent
      end
  end
end