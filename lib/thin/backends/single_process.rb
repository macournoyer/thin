module Thin
  module Backends
    class SingleProcess
      def initialize(server)
        @server = server
      end

      def start(daemonize)
        raise NotImplementedError, "Daemonization not supported in single process mode" if daemonize

        @pid_manager = Preforker::PidManager.new(@server.pid_path)

        $0 = @server.to_s

        # Install signals
        trap("INT", "EXIT")

        EM.run do
          yield
        end
      end

      def stop
        @pid_manager.unlink
        EM.stop_event_loop
      end
    end
  end
end
