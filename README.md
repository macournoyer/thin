---

# This is alpha software. Things might break, people will cry and it will be your fault.
### When reporting issues, make sure to mention you're using Thin v2.

---

# Thin
Tiny, fast & funny Ruby server

Thin is a high performance and customizable Ruby server. It is an evented prefork server much like Nginx. A master process listen to incoming requests and dispatch to its worker processes, each one running an EventMachine loop.

Which makes it, with all humility, the most secure, stable, fast and extensible Ruby web server bundled in an easy to use gem for your own pleasure.

**Site:**  http://code.macournoyer.com/thin/  
**Group:** http://groups.google.com/group/thin-ruby/topics  
**Bugs:**  http://github.com/macournoyer/thin/issues  
**Code:**  http://github.com/macournoyer/thin  

## Features

 * Prefork model with an EventMachine loop running in each worker.
 * Optional single process mode for non-UNIX systems and simpler deployments.
 * Optional threaded mode using a pool of threads.
 * Easy asynchronous streaming response support with chunked encoding.
 * Fast file serving with automatic streaming for large files.
 * Keep-alive support.
 * SSL support (upcoming).

## Installation
For this pre-release of version 2.0:

    $ gem install thin --pre

Or from source:

    $ git clone git://github.com/macournoyer/thin.git
    $ git checkout v2
    $ cd thin
    $ bundle install
    $ rake install

## Usage
The `thin` script offers an easy way to start your Rack based application and acts just like
the `rackup` script.:

    $ cd to/your/rack/app
    $ thin

To use with Rails, add thin to your Gemfile and use Rails server command:

    $ echo "gem 'thin'" >> Gemfile
    $ bundle install
    $ rails server thin

See examples/thin.conf.rb for a sample configuration file.

Run `thin -h` to list available options.

## License
Ruby License, http://www.ruby-lang.org/en/LICENSE.txt.

## Credits
Thin is copyright Marc-Andre Cournoyer <macournoyer@gmail.com>
