Thin
====

Tiny, fast & funny HTTP server

Thin is a Ruby web server that glues together 3 of the best Ruby libraries in web history:

  * The Mongrel parser: the root of Mongrel speed and security
  * Event Machine: a network I/O library with extremely high scalability, performance and stability
  * Rack: a minimal interface between webservers and Ruby frameworks

Which makes it, with all humility, the most secure, stable, fast and extensible Ruby web server
bundled in an easy to use gem for your own pleasure.

    Site:  http://code.macournoyer.com/thin/
    Group: http://groups.google.com/group/thin-ruby/topics
    Bugs:  http://github.com/macournoyer/thin/issues
    Code:  http://github.com/macournoyer/thin
    IRC:   #thin on freenode

## Installation

For the latest stable version:

`gem install thin`

Or from source:

```
git clone git://github.com/macournoyer/thin.git
cd thin
rake install
```

## Usage

A +thin+ script offers an easy way to start your Rack application:

```
cd to/your/app
thin start
```

When using with Rails and Bundler, make sure to add `gem 'thin'`
to your Gemfile.

See example directory for samples.

### Command Line Examples

Use a rackup file and bind to localhost port 8080:

```
thin -R config.ru -a 127.0.0.1 -p 8080 start
```

Store the server process ID, log to a file and daemonize:

```
thin -p 9292 -P tmp/pids/thin.pid -l logs/thin.log -d start
```

Thin is quite flexible in that many options can be specified at the command line (see below for usage).

### Configuration files

You can create configuration files in yaml format and feed them to thin using `thin -C config.yml`.  Here is an example config file:

```yaml
--- 
user: www-data
group: www-data
pid: tmp/pids/thin.pid
timeout: 30
wait: 30
log: log/thin.log
max_conns: 1024
require: []
environment: production
max_persistent_conns: 512
servers: 1
threaded: true
no-epoll: true
daemonize: true
socket: tmp/sockets/thin.sock
chdir: /path/to/your/apps/root
tag: a-name-to-show-up-in-ps aux
```

### Command Line Options

This is the usage for the thin command which can be obtained by running `thin -h` at the command line.

```sh
Usage: thin [options] start|stop|restart|config|install

Server options:
    -a, --address HOST               bind to HOST address (default: 0.0.0.0)
    -p, --port PORT                  use PORT (default: 3000)
    -S, --socket FILE                bind to unix domain socket
    -y, --swiftiply [KEY]            Run using swiftiply
    -A, --adapter NAME               Rack adapter to use (default: autodetect)
                                     (rack, rails, ramaze, merb, file)
    -R, --rackup FILE                Load a Rack config file instead of Rack adapter
    -c, --chdir DIR                  Change to dir before starting
        --stats PATH                 Mount the Stats adapter under PATH

SSL options:
        --ssl                        Enables SSL
        --ssl-key-file PATH          Path to private key
        --ssl-cert-file PATH         Path to certificate
        --ssl-disable-verify         Disables (optional) client cert requests

Adapter options:
    -e, --environment ENV            Framework environment (default: development)
        --prefix PATH                Mount the app under PATH (start with /)

Daemon options:
    -d, --daemonize                  Run daemonized in the background
    -l, --log FILE                   File to redirect output (default: /home/robert/log/thin.log)
    -P, --pid FILE                   File to store PID (default: tmp/pids/thin.pid)
    -u, --user NAME                  User to run daemon as (use with -g)
    -g, --group NAME                 Group to run daemon as (use with -u)
        --tag NAME                   Additional text to display in process listing

Cluster options:
    -s, --servers NUM                Number of servers to start
    -o, --only NUM                   Send command to only one server of the cluster
    -C, --config FILE                Load options from config file
        --all [DIR]                  Send command to each config files in DIR
    -O, --onebyone                   Restart the cluster one by one (only works with restart command)
    -w, --wait NUM                   Maximum wait time for server to be started in seconds (use with -O)

Tuning options:
    -b, --backend CLASS              Backend to use, full classname
    -t, --timeout SEC                Request or command timeout in sec (default: 30)
    -f, --force                      Force the execution of the command
        --max-conns NUM              Maximum number of open file descriptors (default: 1024)
                                     Might require sudo to set higher than 1024
        --max-persistent-conns NUM   Maximum number of persistent connections
                                     (default: 100)
        --threaded                   Call the Rack application in threads [experimental]
        --threadpool-size NUM        Sets the size of the EventMachine threadpool.
                                     (default: 20)
        --no-epoll                   Disable the use of epoll

Common options:
    -r, --require FILE               require the library
    -q, --quiet                      Silence all logging
    -D, --debug                      Enable debug logging
    -V, --trace                      Set tracing on (log raw request/response)
    -h, --help                       Show this message
    -v, --version                    Show version
```

## License

Ruby License, http://www.ruby-lang.org/en/LICENSE.txt.

## Credits

The parser was stolen from Mongrel http://mongrel.rubyforge.org by Zed Shaw.
Mongrel is copyright 2007 Zed A. Shaw and contributors. It is licensed under
the Ruby license and the GPL2.

Thin is copyright Marc-Andre Cournoyer <macournoyer@gmail.com>

Get help at http://groups.google.com/group/thin-ruby/
Report bugs at https://github.com/macournoyer/thin/issues
and major security issues directly to me macournoyer@gmail.com.
