module Thin
  # Control a set of servers. Generate start and stop commands and run them.
  class Cluster
    include Logging
    
    class << self
      # Script to run
      attr_accessor :thin_script
    end
    self.thin_script = 'thin'
    
    # Number of servers in the cluster.
    attr_accessor :size
    
    # Command line options passed to the thin script
    attr_accessor :options
    
    # Create a new cluster of servers launched using +options+.
    def initialize(options)
      @options = options.merge(:daemonize => true)
      @size    = @options.delete(:servers)
    end
    
    def first_port; @options[:port]     end
    def address;    @options[:address]  end    
    def pid_file;   File.expand_path File.join(@options[:chdir], @options[:pid]) end
    def log_file;   File.expand_path File.join(@options[:chdir], @options[:log]) end
    
    # Start the servers
    def start
      with_each_server { |port| start_on_port port }
    end
    
    # Start the server on a single port
    def start_on_port(port)
      log "Starting #{address}:#{port} ... "
      
      run :start, @options, port
    end
  
    # Stop the servers
    def stop
      with_each_server { |port| stop_on_port port }
    end
    
    # Stop the server running on +port+
    def stop_on_port(port)
      log "Stopping #{address}:#{port} ... "
      
      run :stop, @options, port
    end
    
    # Stop and start the servers.
    def restart
      stop
      sleep 0.1 # Let's breath a bit shall we ?
      start
    end
    
    def log_file_for(port)
      include_port_number log_file, port
    end
    
    def pid_file_for(port)
      include_port_number pid_file, port
    end
    
    def pid_for(port)
      File.read(pid_file_for(port)).chomp.to_i
    end
    
    private
      # Send the command to the +thin+ script
      def run(cmd, options, port)
        shell_cmd = shellify(cmd, options.merge(:pid => pid_file_for(port), :log => log_file_for(port)))
        trace shell_cmd
        log `#{shell_cmd}`
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
        "#{self.class.thin_script} #{cmd} #{shellified_options.compact.join(' ')}"
      end
      
      def with_each_server
        @size.times { |n| yield first_port + n }
      end
      
      # Add the port numbers in the filename
      # so each instance get its own file
      def include_port_number(path, port)
        raise ArgumentError, "filename '#{path}' must include an extension" unless path =~ /\./
        path.gsub(/\.(.+)$/) { ".#{port}.#{$1}" }
      end
  end
end