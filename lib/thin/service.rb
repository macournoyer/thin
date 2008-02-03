require 'erb'

module Thin
  # System service controller to launch all servers which
  # config files are in a directory.
  class Service < Controller
    NAME        = 'thin'
    CONFIG_PATH = "/etc/#{NAME}"
    # INITD_PATH  = "/etc/init.d/#{NAME}"
    INITD_PATH  = "init.d/#{NAME}"
    TEMPLATE    = File.dirname(__FILE__) + '/service.sh.erb'
    
    def initialize(options)
      @options = options
      
      raise PlatformNotSupported, 'Running as a service only supported on Linux' unless Thin.linux?
    end
    
    def start
      run :start
    end
    
    def stop
      run :stop
    end
    
    def restart
      run :restart
    end
    
    def install
      config = @options[:config]
      raise OptionRequired, :config unless config
      
      unless File.exist?(INITD_PATH)
        log ">> Installing thin service in #{INITD_PATH} ..."
        log "writing #{INITD_PATH}"
        File.open(INITD_PATH, 'w') do |f|
          f << ERB.new(File.read(TEMPLATE)).result(binding)
        end
        FileUtils.chmod 0755, INITD_PATH, :verbose => true # Make executable
        
        log "To configure thin to start at system boot:"
        log "on RedHat like systems:"
        log "  sudo /sbin/chkconfig --level 345 #{NAME} on"
        log "on Debian like systems (Ubuntu):"
        log "  sudo /usr/sbin/update-rc.d -f #{NAME} defaults"
      end
      
      symlink = CONFIG_PATH + '/' + File.basename(config)
      log ">> Creating symlink #{config} => #{symlink} ..."
      FileUtils.mkdir_p CONFIG_PATH
      File.symlink File.expand_path(config), symlink
    end
    
    private
      def run(command)
        Dir[CONFIG_PATH + '/*'].each do |config|
          log "[#{command}] #{config} ..."
          Command.run(command, :config => config, :daemonize => true)          
        end
      end
  end
end