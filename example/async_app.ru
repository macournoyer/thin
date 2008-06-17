#!/usr/bin/env rackup -s thin
# 
#  async_app.ru
#  raggi/thin
#   
#   A first demo app for async rack + thin app processing!
# 
#  Created by James Tucker on 2008-06-17.
#  Copyright 2008 James Tucker <raggi@rubyforge.org>.
#
#--
# Benchmark Results:
#
# raggi@mbk:~$ ab -c 100 -n 500 http://127.0.0.1:3000/
# This is ApacheBench, Version 2.0.40-dev <$Revision: 1.146 $> apache-2.0
# Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
# Copyright 2006 The Apache Software Foundation, http://www.apache.org/
# 
# Benchmarking 127.0.0.1 (be patient)
# Completed 100 requests
# Completed 200 requests
# Completed 300 requests
# Completed 400 requests
# Finished 500 requests
# 
# 
# Server Software:        thin
# Server Hostname:        127.0.0.1
# Server Port:            3000
# 
# Document Path:          /
# Document Length:        12 bytes
# 
# Concurrency Level:      100
# Time taken for tests:   5.251864 seconds
# Complete requests:      500
# Failed requests:        0
# Write errors:           0
# Total transferred:      47000 bytes
# HTML transferred:       6000 bytes
# Requests per second:    95.20 [#/sec] (mean)
# Time per request:       1050.373 [ms] (mean)
# Time per request:       10.504 [ms] (mean, across all concurrent requests)
# Transfer rate:          8.57 [Kbytes/sec] received
# 
# Connection Times (ms)
#               min  mean[+/-sd] median   max
# Connect:        0    3   2.1      3       8
# Processing:  1033 1044   4.7   1045    1052
# Waiting:     1031 1040   4.9   1040    1051
# Total:       1041 1047   3.3   1048    1054
# 
# Percentage of the requests served within a certain time (ms)
#   50%   1048
#   66%   1050
#   75%   1051
#   80%   1051
#   90%   1051
#   95%   1052
#   98%   1052
#   99%   1052
#  100%   1054 (longest request)
# 

class AsyncApp
  
  def call(env)
    @env = env
    :async
  end
  
  def callback(instance, method)
    process_async(instance, method)
  end
  
  def process_async(instance, method)
    EventMachine::add_timer(1) {
      instance.send(method, [200, {}, 'Woah, async!'])
    }
  end
  
end

use Rack::CommonLogger
use Rack::Reloader
run AsyncApp.new
