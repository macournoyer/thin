#!/usr/bin/env rackup -s thin
# 
#  async_app.ru
#  raggi/thin
#   
#   A second demo app for async rack + thin app processing!
#   Now using http status code 100 instead.
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
# Time taken for tests:   5.263089 seconds
# Complete requests:      500
# Failed requests:        0
# Write errors:           0
# Total transferred:      47000 bytes
# HTML transferred:       6000 bytes
# Requests per second:    95.00 [#/sec] (mean)
# Time per request:       1052.618 [ms] (mean)
# Time per request:       10.526 [ms] (mean, across all concurrent requests)
# Transfer rate:          8.55 [Kbytes/sec] received
# 
# Connection Times (ms)
#               min  mean[+/-sd] median   max
# Connect:        0    3   2.2      3       8
# Processing:  1042 1046   3.1   1046    1053
# Waiting:     1037 1042   3.6   1041    1050
# Total:       1045 1049   3.1   1049    1057
# 
# Percentage of the requests served within a certain time (ms)
#   50%   1049
#   66%   1051
#   75%   1053
#   80%   1053
#   90%   1054
#   95%   1054
#   98%   1056
#   99%   1057
#  100%   1057 (longest request)

class AsyncApp
    
  def call(env)
    @env = env
    # Semi-emulate a long db request, instead of a timer, in reality we'd be 
    # waiting for the response data. Whilst this happens, other connections 
    # can be serviced.
    # This could be any callback based thing though, a deferrable waiting on 
    # IO data, a db request, an http request, an smtp send, whatever.
    EventMachine::add_timer(1) {      
      env['async.connection'].send(env['async.callback'], [200, {}, 'Woah, async!'])
    }
    throw :async
  end
  
end

# The additions to env for async.connection and async.callback absolutely 
# destroy the speed of the request if Lint is doing it's checks on env.
# It is also important to note that an async response will not pass through 
# any further middleware, as the async response notification has been passed 
# right up to the webserver, and the callback goes directly there too.
# Middleware could possibly catch :async, and also provide a different 
# async.connection and async.callback.

# use Rack::Lint
run AsyncApp.new
