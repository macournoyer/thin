require 'socket'

module Thin
  # An exception class to handle the event that server didn't start on time
  class RestartTimeout < RuntimeError; end
  
  module Controllers
    # Control a set of servers.
    # * Generate start and stop commands and run them.
    # * Inject the port or socket number in the pid and log filenames.
    # Servers are started throught the +thin+ command-line script.
    class Cluster < Controller
      # Cluster only options that should not be passed in the command sent
      # to the indiviual servers.
      CLUSTER_OPTIONS = [:servers, :only, :onebyone, :xbyx, :wait]
      
      # Maximum wait time for the server to be restarted
      DEFAULT_WAIT_TIME = 30    # seconds
      
      # Create a new cluster of servers launched using +options+.
      def initialize(options)
        super
        # Cluster can only contain daemonized servers
        @options.merge!(:daemonize => true)
      end
      
      def first_port; @options[:port]     end
      def address;    @options[:address]  end
      def socket;     @options[:socket]   end
      def pid_file;   @options[:pid]      end
      def log_file;   @options[:log]      end
      def size;       @options[:servers]  end
      def only;       @options[:only]     end
      def onebyone;   @options[:onebyone] end
      def xbyx;       @options[:xbyx]     end
      def wait;       @options[:wait]     end
      
      def swiftiply?
        @options.has_key?(:swiftiply)
      end
    
      # Start the servers
      def start
        with_each_server { |n| start_server n }
      end
    
      # Start a single server
      def start_server(number)
        log_info "Starting server on #{server_id(number)} ... "
      
        run :start, number
      end
  
      # Stop the servers
      def stop
        with_each_server { |n| stop_server n }
      end
    
      # Stop a single server
      def stop_server(number)
        log_info "Stopping server on #{server_id(number)} ... "
      
        run :stop, number
      end
    
      # Stop and start the servers.
      def restart
        if onebyone
          #Stop/Start each server, on by one
          with_each_server do |n| 
            stop_server(n)
            sleep 0.1 # Let's breath a bit shall we ?
            start_server(n)
            wait_until_server_started(n)
          end           
        elsif !xbyx.nil? and xbyx > 0
          #Stop up to xbyx servers at a time in the cluster, then start them.
          #Repeat until all servers have been restarted. Allows us to speed up large clusters while maintaining service
          q=[]
          #build total queue in reverse order so we can pop servers off the end
          with_each_server do |n|
            q=[n]+q
          end
          while q.length > 0
            bq=[]
            #build our batch queue to process
            while bq.length < xbyx and q.length > 0
               bq << q.pop
            end
            bq.each do |server|
              stop_server(server)
            end
            sleep 0.1 #if xbyx is small give just a moment for process to finish
            bq.each do |server|
              start_server(server)
            end
          end
        else
          # Let's do a normal restart by default
          stop
          sleep 0.1 # Let's breath a bit shall we ?
          start
        end
      end
      
      def test_socket(number)
        if socket
          UNIXSocket.new(socket_for(number))
        else
          TCPSocket.new(address, number)
        end
      rescue
        nil
      end
      
      # Make sure the server is running before moving on to the next one.
      def wait_until_server_started(number)
        log_info "Waiting for server to start ..."
        STDOUT.flush # Need this to make sure user got the message
        
        tries = 0
        loop do
          if test_socket = test_socket(number)
            test_socket.close
            break
          elsif tries < wait
            sleep 1
            tries += 1
          else
            raise RestartTimeout, "The server didn't start in time. Please look at server's log file " +
                                  "for more information, or set the value of 'wait' in your config " +
                                  "file to be higher (defaults: 30)."
          end
        end
      end
    
      def server_id(number)
        if socket
          socket_for(number)
        elsif swiftiply?
          [address, first_port, number].join(':')
        else
          [address, number].join(':')
        end
      end
    
      def log_file_for(number)
        include_server_number log_file, number
      end
    
      def pid_file_for(number)
        include_server_number pid_file, number
      end
    
      def socket_for(number)
        include_server_number socket, number
      end
    
      def pid_for(number)
        File.read(pid_file_for(number)).chomp.to_i
      end
      
      private
        # Send the command to the +thin+ script
        def run(cmd, number)
          cmd_options = @options.reject { |option, value| CLUSTER_OPTIONS.include?(option) }
          cmd_options.merge!(:pid => pid_file_for(number), :log => log_file_for(number))
          if socket
            cmd_options.merge!(:socket => socket_for(number))
          elsif swiftiply?
            cmd_options.merge!(:port => first_port)
          else
            cmd_options.merge!(:port => number)
          end
          Command.run(cmd, cmd_options)
        end
      
        def with_each_server
          if only
            if first_port && only < 80
              # interpret +only+ as a sequence number
              yield first_port + only
            else
              # interpret +only+ as an absolute port number
              yield only
            end
          elsif socket || swiftiply?
            size.times { |n| yield n }
          else
            size.times { |n| yield first_port + n }
          end
        end
      
        # Add the server port or number in the filename
        # so each instance get its own file
        def include_server_number(path, number)
          ext = File.extname(path)
          path.gsub(/#{ext}$/, ".#{number}#{ext}")
        end
    end
  end
end
