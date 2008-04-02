module Rack
  class AdapterNotFound < RuntimeError; end
  
  module Adapter
    # Guess which adapter to use based on the directory structure
    # or file content.
    # Returns a symbol representing the name of the adapter to use
    # to load the application under <tt>dir/</tt>.
    def self.guess(dir)
      case
      when ::File.exist?("#{dir}/config/environment.rb") then :rails
      when ::File.exist?("#{dir}/start.rb")              then :ramaze
      when ::File.exist?("#{dir}/config/init.rb")        then :merb
      when ::File.exist?("#{dir}/runner.ru")             then :halcyon
      else
        raise AdapterNotFound, "No adapter found for #{dir}"
      end
    end
    
    # Loads an adapter identified by +name+ using +options+ hash.
    def self.for(name, options={})
      case name.to_sym
      when :rails
        Rails.new(options.merge(:root => options[:chdir]))
      
      when :ramaze
        require "#{options[:chdir]}/start"

        Ramaze.trait[:essentials].delete Ramaze::Adapter
        Ramaze.start :force => true

        Ramaze::Adapter::Base

      # FIXME not working, halp! halp!
      # when :merb
      #   require 'merb'
      #   require "#{options[:chdir]}/config/init.rb"
      #   Merb::BootLoader.run
      #   Merb::Rack::Application.new
      
      when :halcyon
        require 'halcyon'
        $:.unshift(Halcyon.root/'lib')
        Halcyon::Runner.load_config Halcyon.root/'config'/'config.yml'
        Halcyon::Runner.new
      
      else
        raise AdapterNotFound, "Adapter not found: #{name}"
        
      end
    end
  end
end