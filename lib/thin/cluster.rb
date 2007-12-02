module Thin
  # Control a set of servers. Generate start and stop commands and run then.
  class Cluster
    include Logging
    
    attr_accessor :log_file, :pid_file, :user, :group, :timeout
    attr_reader   :address, :first_port, :size
    
    # Create a new cluster of servers bound to +host+
    # on ports +first_port+ to <tt>first_port + size - 1</tt>.
    def initialize(dir, address, first_port, size)
      @address    = address
      @first_port = first_port
      @size       = size
      
      @log_file  = 'thin.log'
      @pid_file  = 'thin.pid'
      
      @cmd_timeout = 5 # sec
      
      thin # Cache the path to the thin command before changing the current dir
      Dir.chdir dir if dir
    end
    
    # Start the servers
    def start
      with_each_instance do |port|
        start_on_port port
      end
    end
    
    # Start the server on a single port
    def start_on_port(port)
      logc "Starting #{address}:#{port} ... "
      
      run :start, :port      => port,
                  :address   => @address,
                  :daemonize => true,
                  :pid_file  => pid_file_for(port),
                  :log_file  => log_file_for(port),
                  :user      => @user,
                  :group     => @group,
                  :timeout   => @timeout,
                  :trace     => @trace
      
      if wait_until_pid(:exist, port)
        log "started in #{pid_for(port)}" if $?.success?
      else
        log 'failed to start'
      end
    end
  
    # Stop the servers
    def stop
      with_each_instance do |port|
        stop_on_port port
      end
    end
    
    # Stop the server running on +port+
    def stop_on_port(port)
      logc "Stopping #{address}:#{port} ... "
      
      run :stop, :pid_file => pid_file_for(port),
                 :timeout  => @timeout
      
      if wait_until_pid(!:exist, port)
        log 'stopped' if $?.success?
      else
        log 'failed to stop'
      end
    end
    
    # Restart the servers one at the time.
    # Prevent downtime by making sure only one is stopped at the time.
    # See http://blog.carlmercier.com/2007/09/07/a-better-approach-to-restarting-a-mongrel-cluster/
    def restart
      with_each_instance do |port|
        stop_on_port port
        sleep 0.1 # Let the OS do his thang
        start_on_port port
      end
    end
    
    def log_file_for(port)
      include_port_number @log_file, port
    end
    
    def pid_file_for(port)
      include_port_number @pid_file, port
    end
    
    def pid_for(port)
      File.read(pid_file_for(port)).chomp.to_i
    end
    
    private
      # Send the command to the +thin+ script
      def run(cmd, options={})
        shell_cmd = shellify(cmd, options)
        trace shell_cmd
        `#{shell_cmd}`
      end
      
      # Turn into a runnable shell command
      def shellify(cmd, options={})
        shellified_options = options.inject([]) do |args, (name, value)|
          args << case value
          when NilClass
          when TrueClass then "--#{name}"
          else                "--#{name.to_s.tr('_', '-')}=#{value.inspect}"
          end
        end
        "#{thin} #{cmd} #{shellified_options.compact.join(' ')}"
      end
      
      # Return the path to the +thin+ script
      def thin
        @thin_cmd ||= File.expand_path(File.dirname(__FILE__) + '/../../bin/thin')
      end
      
      # Wait for the pid file to be created (exist=true) of deleted (exist=false)
      def wait_until_pid(exist, port)
        Timeout.timeout(1) do
          sleep 0.1 until File.exist?(pid_file_for(port)) == !!exist
        end
        true
      rescue Timeout::Error
        false
      end
    
      def with_each_instance
        @size.times do |n|
          port = @first_port + n
          yield port
        end
      end
      
      # Add the port numbers in the filename
      # so each instance get its own file
      def include_port_number(path, port)
        raise ArgumentError, "filename '#{path}' must include an extension" unless path =~ /\./
        path.gsub(/\.(.+)$/) { ".#{port}.#{$1}" }
      end
  end
end