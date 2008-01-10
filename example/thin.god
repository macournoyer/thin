# WARNING: this config file has not been tested yet.
# If you know God better then I, feel free to tweak it and send it to me.
# Thanks!
# -- Marc

RAILS_ROOT = "/Users/marc/projects/refactormycode"

God.watch do |w|
  w.name = "thin-3000"
  w.group = 'thins'
  w.interval = 5.seconds # default
  w.start = "thin start -c #{RAILS_ROOT} -P #{RAILS_ROOT}/tmp/pids/thin.3000.pid -p 3000 -d"
  w.stop = "thin stop -P #{RAILS_ROOT}/tmp/pids/thin.3000.pid"
  w.restart = "thin restart -P #{RAILS_ROOT}/tmp/pids/thin.3000.pid -p 3000"
  w.pid_file = File.join(RAILS_ROOT, "tmp/pids/thin.3000.pid")
  
  # clean pid files before start if necessary
  w.behavior(:clean_pid_file)
  
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
  
  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
    
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end
  
  # restart if memory or cpu is too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.interval = 20
      c.above = 50.megabytes
      c.times = [3, 5]
    end
    
    on.condition(:cpu_usage) do |c|
      c.interval = 10
      c.above = 10.percent
      c.times = [3, 5]
    end
  end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end