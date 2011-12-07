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
        %w( INT TERM ).each { |signal| trap(signal, "EXIT") }
        at_exit do
          @server.stop
          @pid_manager.unlink
        end

        EM.run do
          yield
        end
      end
    end
  end
end
