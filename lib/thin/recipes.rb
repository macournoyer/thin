# Set of Capistrano 2 recipes
# To use, add:
#  load 'thin'
#  load 'thin/recipes'
# on top of your config/deploy.rb file.

# Configurable parameters
# Path to the thin_cluster script
#  set :thin_cluster, "thin_cluster"
set :thin_cluster, "thin_cluster" unless thin_cluster
# Location of the config file
#  set :thin_config, "#{release_path}/config/thin.yml"
set :thin_config, "#{release_path}/config/thin.yml" unless thin_config

namespace :deploy do  
  desc 'Start Thin processes on the app server.'
  task :start, :roles => :app do
    run "#{thin_cluster} start -C #{thin_config}"
  end
  
  desc 'Stop the Thin processes on the app server.'
  task :stop, :roles => :app do
    run "#{thin_cluster} stop -C #{thin_config}"
  end

  desc 'Restart the Thin processes on the app server by starting and stopping the cluster.'
  task :restart, :roles => :app do
    run "#{thin_cluster} restart -C #{thin_config}"
  end
end