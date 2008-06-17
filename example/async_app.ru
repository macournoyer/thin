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
# Time taken for tests:   5.244146 seconds
# Complete requests:      500
# Failed requests:        0
# Write errors:           0
# Total transferred:      47000 bytes
# HTML transferred:       6000 bytes
# Requests per second:    95.34 [#/sec] (mean)
# Time per request:       1048.829 [ms] (mean)
# Time per request:       10.488 [ms] (mean, across all concurrent requests)
# Transfer rate:          8.58 [Kbytes/sec] received
# 
# Connection Times (ms)
#               min  mean[+/-sd] median   max
# Connect:        0    3   1.8      3       7
# Processing:  1034 1043   3.0   1044    1050
# Waiting:     1032 1039   3.8   1040    1049
# Total:       1041 1046   1.9   1047    1051
# 
# Percentage of the requests served within a certain time (ms)
#   50%   1047
#   66%   1048
#   75%   1048
#   80%   1048
#   90%   1048
#   95%   1049
#   98%   1049
#   99%   1049
#  100%   1051 (longest request)


class AsyncApp
  
  # Status code 100 means CONTINUE
  AsyncResponse = [100,{},'']
  
  def call(env)
    @env = env
    # If we have fibers / threads available, we could fire off the processing
    # here, but if we're trying to linearize, it's just as easy to wait until 
    # async is called.
    AsyncResponse
  end
  
  def async(instance, method)
    # Semi-emulate a long db request, instead of a timer, in reality we'd be 
    # waiting for the response data. Whilst this happens, other connections 
    # can be serviced.
    # This could be any callback based thing though, a deferrable waiting on 
    # IO data, a db request, an http request, an smtp send, whatever.
    EventMachine::add_timer(1) {      
      instance.send(method, [200, {}, 'Woah, async!'])
    }
  end
end

# use Rack::Lint
run AsyncApp.new
