module Rack
  class AdapterNotFound < RuntimeError; end
  
  # Mapping used to guess which adapter to use in <tt>Adapter.for</tt>.
  # Framework <name> => <file unique to this framework> in order they will
  # be tested.
  # +nil+ for value to never guess.
  # NOTE: If a framework has a file that is not unique, make sure to place
  # it at the end.
  ADAPTERS = [
    [:rack,    'config.ru'],
    [:rails,   'config/environment.rb'],
    [:ramaze,  'start.rb'],
    [:merb,    'config/init.rb'],
    [:file,    nil]
  ]
  
  module Adapter
    # Guess which adapter to use based on the directory structure
    # or file content.
    # Returns a symbol representing the name of the adapter to use
    # to load the application under <tt>dir/</tt>.
    def self.guess(dir)
      ADAPTERS.each do |adapter, file|
        return adapter if file && ::File.exist?(::File.join(dir, file))
      end
      raise AdapterNotFound, "No adapter found for #{dir}"
    end
    
    # Load a Rack application from a Rack config file (.ru).
    def self.load(config)
      rackup_code = ::File.read(config)
      eval("Rack::Builder.new {( #{rackup_code}\n )}.to_app", TOPLEVEL_BINDING, config)
    end
    
    # Loads an adapter identified by +name+ using +options+ hash.
    def self.for(name, options={})
      ENV['RACK_ENV'] = options[:environment]
      
      case name.to_sym
      when :rack
        return load(::File.join(options[:chdir], "config.ru"))
        
      when :rails
        return Rails.new(options.merge(:root => options[:chdir]))
      
      when :ramaze
        require "#{options[:chdir]}/start"
        
        Ramaze.trait[:essentials].delete Ramaze::Adapter
        Ramaze.start :force => true
        
        return Ramaze::Adapter::Base
        
      when :merb
        require 'merb-core'
        
        Merb::Config.setup(:merb_root   => options[:chdir],
                           :environment => options[:environment])
        Merb.environment = Merb::Config[:environment]
        Merb.root = Merb::Config[:merb_root]
        Merb::BootLoader.run
        
        return Merb::Rack::Application.new
        
      when :file
        return Rack::File.new(options[:chdir])

      when :site
        return Rack::Builder.new do
          use Index, :root=>options[:chdir]
          run Rack::Directory.new(options[:chdir])  
        end

      else
        raise AdapterNotFound, "Adapter not found: #{name}"
        
      end
    end
  end

  # Rack middleware to serve an index file by default (e.g. `index.html`).
  class Index
    def initialize(app, options={})
      @app   = app
      @root  = options[:root]  || Dir.pwd
      @index = options[:index] || 'index.html'
    end

    def call(env)
      path = Rack::Utils.unescape(env['PATH_INFO'])
      index_file = ::File.join(@root, path, @index)
      if ::File.exists?(index_file)
        [200, {'Content-Type' => 'text/html'}, ::File.new(index_file)]
      else
        @app.call(env)
      end
    end
  end
end
