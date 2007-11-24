# == Set of Capistrano 2 recipes
# To use, add on top of your Capfile file:
#  load 'config/deploy'
#  # ...
#  require 'thin'
#  require 'thin/recipes'
#
# === Configurable parameters
# You can configure some parameters but it should work out of the box.
# Path to the thin_cluster script, don't need to change this if
# you installed thin as a gem on the server.
#  set :thin_cluster, "thin_cluster"
# Location of the config file:
#  set :thin_config, "#{release_path}/config/thin.yml"

Capistrano::Configuration.instance.load do
  set :thin_cluster, "thin_cluster"
  set :thin_config, "#{release_path}/config/thin.yml"

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
end