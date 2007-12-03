require 'transat/parser'

module Thin
  # Define a set of commands that can be parsed and executed.
  # see bin/thin for an example.
  def self.define_commands(&block)
    begin
      Transat::Parser.parse_and_execute(ARGV, &block)      
    rescue CommandError => e
      puts "Error: #{e}"
    end
  end
  
  # Raised when a command specific error happen.
  class CommandError < StandardError; end
  
  # A command that can be runned from a command line script.
  class Command
    attr_reader :args
  
    def initialize(non_options, options)
      @args = non_options

      options.each do |option, value|
        self.send("#{option}=", value)
      end
    end
    
    def self.command_name
      self.name.match(/::(\w+)$/)[1].downcase
    end
    
    def self.detailed_help
      <<-EOF
usage: #{File.basename($PROGRAM_NAME)} #{command_name}

#{help}
EOF
    end
    
    protected
      def error(message)
        raise CommandError, message
      end
  end
  
  module Commands; end
  Dir[File.dirname(__FILE__) + '/commands/**/*.rb'].each { |l| require l }
end