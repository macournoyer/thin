module Thin
  # Run a command though the +thin+ command-line script.
  class Command
    include Logging
    
    class << self
      # Path to the +thin+ script used to control the servers.
      # Leave this to default to use the one in the path.
      attr_accessor :script
    end
    
    def initialize(name, options={})
      @name    = name
      @options = options
    end
    
    def self.run(*args)
      new(*args).run
    end
    
    # Send the command to the +thin+ script
    def run
      shell_cmd = shellify
      trace shell_cmd
      ouput = `#{shell_cmd}`.chomp
      log "  " + ouput.gsub("\n", "  \n") unless ouput.empty?
    end
    
    # Turn into a runnable shell command
    def shellify
      shellified_options = @options.inject([]) do |args, (name, value)|
        args << case value
        when NilClass,
             TrueClass then "--#{name}"
        when FalseClass
        else                "--#{name.to_s.tr('_', '-')}=#{value.inspect}"
        end
      end
      
      raise ArgumentError, "Path to thin script can't be found, set Command.script" unless self.class.script
      
      "#{self.class.script} #{@name} #{shellified_options.compact.join(' ')}"
    end
  end
end