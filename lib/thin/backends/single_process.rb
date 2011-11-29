module Thin
  module Backends
    class SingleProcess
      def initialize(server)
        @server = server
      end
      
      def start(daemonize)
        raise NotImplementedError, "Daemonization not supported in single process mode" if daemonize
        
        $0 = @server.to_s
        
        # Install signals
        trap("INT", "EXIT")
        
        EM.run do
          yield
        end
      end
      
      def stop
        EM.stop_event_loop
      end
    end
  end
end