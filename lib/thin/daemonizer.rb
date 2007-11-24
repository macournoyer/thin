require 'etc'

module Thin
  # Creator of external processes to run the server in the background.
  class Daemonizer
    def initialize(pid_file)
      raise ArgumentError, 'PID file required' unless pid_file
      @pid_file = pid_file
    end
    
    # Kill the process which PID is stored in +pid_file+.
    def kill
      if File.exist?(@pid_file) && pid = open(@pid_file).read
        print "Sending INT signal to process #{pid} ... "
        Process.kill('INT', pid.to_i)
        Timeout.timeout(5) do
          sleep 0.5 until !File.exist?(@pid_file)
        end
        puts "stopped!"
      else
        STDERR.puts "Can't stop process, no PID found in #{@pid_file}"
      end
    rescue Object => e
      STDERR.puts "error : #{e}"
    end
    
    # Starts the server in a seperate process
    # returning the control right away.
    def daemonize(title=nil)
      print "Starting #{title} ... "
      pid = fork do
        write_pid_file
        at_exit { remove_pid_file }
        yield
        exit
      end
      puts "started in process #{pid}"

      # Make sure we do not create zombies
      Process.detach(pid)
    end
    
    # Change privileges of the process to specified user and group.
    def change_privilege(user, group)
      uid, gid = Process.euid, Process.egid
      target_uid = Etc.getpwnam(user).uid if user
      target_gid = Etc.getgrnam(group).gid if group

      if uid != target_uid || gid != target_gid
        Process.initgroups(user, target_gid)
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
    rescue Errno::EPERM => e
      STDERR.puts "Couldn't change user and group to #{user}:#{group}: #{e}."
    end
    
    private
      def remove_pid_file
        File.delete(@pid_file) if @pid_file && File.exists?(@pid_file)
      end

      def write_pid_file
        FileUtils.mkdir_p File.dirname(@pid_file)
        open(@pid_file,"w") { |f| f.write(Process.pid) }
      end
  end
end