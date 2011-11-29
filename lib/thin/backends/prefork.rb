require "preforker"

module Thin
  # Raised when the pid file already exist starting as a daemon.
  class PidFileExist < RuntimeError; end
  
  module Backends
    class Prefork
      def initialize(server)
        @server = server
      end
      
      def start(daemonize)
        if File.file?(@server.pid_path)
          raise PidFileExist, "#{@server.pid_path} already exists. Thin is already running or the file is stale. " +
                              "Stop the process or delete #{@server.pid_path}."
        end
        
        @prefork = Preforker.new(
                     :app_name => @server.to_s,
                     :workers => @server.workers,
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

            yield
          end
        end
        
        if daemonize
          @prefork.start
        else
          @prefork.run
        end
      end
      
      def stop
        @prefork.quit if @prefork
      end
    end
  end
end