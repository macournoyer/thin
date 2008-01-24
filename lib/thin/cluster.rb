module Thin
  # Control a set of servers.
  # * Generate start and stop commands and run them.
  # * Inject the port number in the pid and log filenames.
  # Servers are started throught the +thin+ commandline script.
  class Cluster
    include Logging
    
    # Path to the +thin+ script used to control the servers.
    # Leave this to default to use the one in the path.
    attr_accessor :script
    
    # Number of servers in the cluster.
    attr_accessor :size
    
    # Command line options passed to the thin script
    attr_accessor :options
    
    # Create a new cluster of servers launched using +options+.
    def initialize(options)
      @options = options.merge(:daemonize => true)
      @size    = @options.delete(:servers)
      @script  = File.join(File.dirname(__FILE__), '..', '..', 'bin', 'thin')
      
      if socket
        @options.delete(:address)
        @options.delete(:port)
      end
    end
    
    def first_port; @options[:port]     end
    def address;    @options[:address]  end
    def socket;     @options[:socket]   end
    def pid_file;   File.expand_path File.join(@options[:chdir], @options[:pid]) end
    def log_file;   File.expand_path File.join(@options[:chdir], @options[:log]) end
    
    # Start the servers
    def start
      with_each_server { |port| start_server port }
    end
    
    # Start a single server
    def start_server(number)
      log "Starting server on #{server_id(number)} ... "
      
      run :start, @options, number
    end
  
    # Stop the servers
    def stop
      with_each_server { |n| stop_server n }
    end
    
    # Stop a single server
    def stop_server(number)
      log "Stopping server on #{server_id(number)} ... "
      
      run :stop, @options, number
    end
    
    # Stop and start the servers.
    def restart
      stop
      sleep 0.1 # Let's breath a bit shall we ?
      start
    end
    
    def server_id(number)
      if socket
        socket_for(number)
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
      def run(cmd, options, number)
        cmd_options = options.dup
        cmd_options.merge!(:pid => pid_file_for(number), :log => log_file_for(number))
        if socket
          cmd_options.merge!(:socket => socket_for(number))
        else
          cmd_options.merge!(:port => number)
        end
        shell_cmd = shellify(cmd, cmd_options)
        trace shell_cmd
        ouput = `#{shell_cmd}`.chomp
        log "  " + ouput.gsub("\n", "  \n") unless ouput.empty?
      end
      
      # Turn into a runnable shell command
      def shellify(cmd, options)
        shellified_options = options.inject([]) do |args, (name, value)|
          args << case value
          when NilClass
          when TrueClass then "--#{name}"
          else                "--#{name.to_s.tr('_', '-')}=#{value.inspect}"
          end
        end
        "#{@script} #{cmd} #{shellified_options.compact.join(' ')}"
      end
      
      def with_each_server
        @size.times do |n|
          yield socket ? n : (first_port + n)
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