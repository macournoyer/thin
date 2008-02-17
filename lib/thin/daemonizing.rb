require 'etc'
require 'daemons' unless Thin.win?

module Process
  # Returns +true+ the process identied by +pid+ is running.
  def running?(pid)
    Process.getpgid(pid) != -1
  rescue Errno::ESRCH
    false
  end
  module_function :running?
end

module Thin
  # Raised when the pid file already exist starting as a daemon.
  class PidFileExist < RuntimeError; end
  
  # Module included in classes that can be turned into a daemon.
  # Handle stuff like:
  # * storing the PID in a file
  # * redirecting output to the log file
  # * changing processs privileges
  # * killing the process gracefully
  module Daemonizable
    attr_accessor :pid_file, :log_file
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    def pid
      File.exist?(pid_file) ? open(pid_file).read.to_i : nil
    end
    
    # Turns the current script into a daemon process that detaches from the console.
    def daemonize
      raise PlatformNotSupported, 'Daemonizing not supported on Windows'     if Thin.win?
      raise ArgumentError,        'You must specify a pid_file to daemonize' unless @pid_file
      raise PidFileExist,         "#{@pid_file} already exist, seems like it's already running. " +
                                  "Stop the process or delete #{@pid_file}." if File.exist?(@pid_file)
      
      pwd = Dir.pwd # Current directory is changed during daemonization, so store it
      
      Daemonize.daemonize(File.expand_path(@log_file), name)
      
      Dir.chdir(pwd)
      
      write_pid_file
      
      trap('HUP') { restart }
      at_exit do
        log ">> Exiting!"
        remove_pid_file
      end
    end
    
    # Change privileges of the process
    # to the specified user and group.
    def change_privilege(user, group=user)
      log ">> Changing process privilege to #{user}:#{group}"
      
      uid, gid = Process.euid, Process.egid
      target_uid = Etc.getpwnam(user).uid
      target_gid = Etc.getgrnam(group).gid

      if uid != target_uid || gid != target_gid
        # Change process ownership
        Process.initgroups(user, target_gid)
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
    rescue Errno::EPERM => e
      log "Couldn't change user and group to #{user}:#{group}: #{e}"
    end
    
    # Registerer a proc to be called to restart the server.
    def on_restart(&block)
      @on_restart = block
    end
    
    # Restart the server
    def restart
      raise ArgumentError, "Can't restart, no 'on_restart' proc specified" unless @on_restart
      log '>> Restarting ...'
      stop
      remove_pid_file
      @on_restart.call
      exit!
    end
    
    module ClassMethods
      # Send a INT signal the process which PID is stored in +pid_file+.
      # If the process is still running after +timeout+, KILL signal is
      # sent.
      def kill(pid_file, timeout=60)
        if pid = send_signal('INT', pid_file)
          begin
            Timeout.timeout(timeout) do
              sleep 0.1 while Process.running?(pid)
            end
          rescue Timeout::Error
            print "Timeout! "
            send_signal('KILL', pid_file)
          rescue Interrupt
            send_signal('KILL', pid_file)
          end
        end
        File.delete(pid_file) if File.exist?(pid_file)
      end
      
      # Restart the server by sending HUP signal
      def restart(pid_file)
        send_signal('HUP', pid_file)
      end
      
      # Send a +signal+ to the process which PID is stored in +pid_file+.
      def send_signal(signal, pid_file)
        if File.exist?(pid_file) && pid = open(pid_file).read
          pid = pid.to_i
          print "Sending #{signal} signal to process #{pid} ... "
          Process.kill(signal, pid)
          puts
          pid
        else
          puts "Can't stop process, no PID found in #{pid_file}"
          nil
        end
      rescue Errno::ESRCH # No such process
        puts "process not found!"
        nil
      end
    end
    
    protected
      def remove_pid_file
        File.delete(@pid_file) if @pid_file && File.exists?(@pid_file)
      end
    
      def write_pid_file
        log ">> Writing PID to #{@pid_file}"
        FileUtils.mkdir_p File.dirname(@pid_file)
        open(@pid_file,"w") { |f| f.write(Process.pid) }
        File.chmod(0644, @pid_file)
      end
  end
end
