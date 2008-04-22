module Rack
  class AdapterNotFound < RuntimeError; end

  # Hash used to guess which adapter to use in <tt>Adapter.for</tt>.
  # Framework name => file unique to this framework.
  # +nil+ for value to never guess.
  ADAPTERS = {
    :rails   => "config/environment.rb",
    :ramaze  => "start.rb",
    :merb    => "config/init.rb",
    :halcyon => 'runner.ru',
    :mack    => 'config/app_config/default.yml',
    :file    => nil
  }
    
  module Adapter    
    # Guess which adapter to use based on the directory structure
    # or file content.
    # Returns a symbol representing the name of the adapter to use
    # to load the application under <tt>dir/</tt>.
    def self.guess(dir)
      ADAPTERS.each_pair do |adapter, file|
        return adapter if file && ::File.exist?(::File.join(dir, file))
      end
      raise AdapterNotFound, "No adapter found for #{dir}"
    end
    
    # Loads an adapter identified by +name+ using +options+ hash.
    def self.for(name, options={})
      case name.to_sym
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
      
      when :halcyon
        require 'halcyon'
        
        $:.unshift(Halcyon.root/'lib')
        Halcyon::Runner.load_config Halcyon.root/'config'/'config.yml'
        
        return Halcyon::Runner.new
      
      when :mack
        ENV["MACK_ENV"] = options[:environment]
        load(::File.join(options[:chdir], "Rakefile"))
        require 'mack'
        return Mack::Utils::Server.build_app
      when :file
        return Rack::File.new(options[:chdir])
      
      else
        raise AdapterNotFound, "Adapter not found: #{name}"
        
      end
    end
  end
end