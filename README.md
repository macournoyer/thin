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

Installation
============
For the latest stable version:

`gem install thin`

Or from source:

```
git clone git://github.com/macournoyer/thin.git
cd thin
rake install
```


Usage
=====
A +thin+ script offers an easy way to start your Rack application:

```
cd to/your/app
thin start
```

But Thin is also usable with a Rack config file.
You need to setup a config.ru file and pass it to the thin script:

```ruby
#cat config.ru
app = proc do |env|
 [
   200,
   {
     'Content-Type' => 'text/html',
     'Content-Length' => '2'
   },
   ['hi']
 ]
end

run app
```

` thin start -R config.ru `

See example directory for more samples and run 'thin -h' for usage.

License
=======
Ruby License, http://www.ruby-lang.org/en/LICENSE.txt.

Credits
=======
The parser was stolen from Mongrel http://mongrel.rubyforge.org by Zed Shaw.
Mongrel Web Server (Mongrel) is copyrighted free software by Zed A. Shaw
<zedshaw at zedshaw dot com> You can redistribute it and/or modify it under
either the terms of the GPL.

Thin is copyright Marc-Andre Cournoyer <macournoyer@gmail.com>

Get help at http://groups.google.com/group/thin-ruby/
Report bugs at https://github.com/macournoyer/thin/issues
and major security issues directly to me macournoyer@gmail.com.
