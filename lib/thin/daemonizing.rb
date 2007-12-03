require 'etc'

module Kernel
  unless respond_to? :daemonize # Already part of Ruby 1.9, yeah!
    # Turns the current script into a daemon process that detaches from the console.
    # It can be shut down with a TERM signal. Taken from ActiveSupport.
    def daemonize
      exit if fork                   # Parent exits, child continues.
      Process.setsid                 # Become session leader.
      exit if fork                   # Zap session leader. See [1].
      Dir.chdir "/"                  # Release old working directory.
      File.umask 0000                # Ensure sensible umask. Adjust as needed.
      STDIN.reopen "/dev/null"       # Free file descriptors and
      STDOUT.reopen "/dev/null", "a" # point them somewhere sensible.
      STDERR.reopen STDOUT           # STDOUT/ERR should better go to a logfile.
      trap("TERM") { exit }
    end
  end
end

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
    
    # Turns the current script into a daemon process that detaches from the console.
    def daemonize
      raise ArgumentError, 'You must specify a pid_file to deamonize' unless @pid_file
      
      pwd = Dir.pwd # Current directory is changed during daemonization, so store it
      super         # Calls Kernel#daemonize
      Dir.chdir pwd
      
      trap('HUP', 'IGNORE') # Don't die upon logout

      # Redirect output to the logfile
      [STDOUT, STDERR].each { |f| f.reopen @log_file, 'a' } if @log_file
      
      write_pid_file
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
    
    module ClassMethods
      # Kill the process which PID is stored in +pid_file+.
      def kill(pid_file, timeout=60)
        if File.exist?(pid_file) && pid = open(pid_file).read
          pid = pid.to_i
          print "Sending INT signal to process #{pid} ... "
          begin
            Process.kill('INT', pid)
            Timeout.timeout(timeout) do
              sleep 0.1 while Process.running?(pid)
            end
          rescue Timeout::Error
            print "timeout, Sending KILL signal ... "
            Process.kill('KILL', pid)
          end
          puts "stopped!"
        else
          puts "Can't stop process, no PID found in #{@pid_file}"
        end
      rescue Errno::ESRCH # No such process
        puts "process not found!"
      ensure
        File.delete(pid_file) rescue nil
      end
    end
    
    private
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
