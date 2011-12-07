require "preforker"

module Thin
  module Backends
    class Prefork
      def initialize(server)
        @server = server
      end

      def start(daemonize)
        @server.before_fork.call(@server) if @server.before_fork

        @prefork = Preforker.new(
                     :app_name => @server.to_s,
                     :workers => @server.worker_processes,
                     :timeout => @server.timeout,
                     :pid_path => @server.pid_path,
                     :stderr_path => @server.log_path,
                     :stdout_path => @server.log_path,
                     :logger => Logger.new(@server.log_path || $stdout)
                   ) do |master|

          EM.run do
            EM.add_periodic_timer(4) do
              EM.stop_event_loop unless master.wants_me_alive?
            end

            @server.after_fork.call(@server, master) if @server.after_fork

            yield
          end
        end

        if daemonize
          @prefork.start
        else
          @prefork.run
        end

        at_exit { @server.stop }
      end
    end
  end
end
