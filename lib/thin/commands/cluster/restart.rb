module Thin::Commands::Cluster
  class Restart < Base
    def run
      load_from_config
      
      cluster = Thin::Cluster.new(cwd, address, port, servers)

      cluster.log_file = log_file
      cluster.pid_file = pid_file
      cluster.trace    = trace
      cluster.user     = user
      cluster.group    = group
      
      cluster.restart
    end

    def self.help
      "Restart servers"
    end

    def self.detailed_help
      <<-EOF
usage: thin_cluster restart [options]

  Restart the servers one at the time.
  Prevent downtime by making sure only one is stopped at the time.
  
  For example, first server is stopped, then started. When the first
  server is fully started the second one is stopped ...
  
  See http://blog.carlmercier.com/2007/09/07/a-better-approach-to-restarting-a-mongrel-cluster/
EOF
    end
  end
end