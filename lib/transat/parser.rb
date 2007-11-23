# Original copy of this file taken from Piston
# Copyright (c) 2006 Francois Beausoleil <francois@teksol.info>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require "optparse"

module Transat
  class VersionNeeded < StandardError; end

  class HelpNeeded < StandardError
    attr_reader :command

    def initialize(command)
      @command = command
    end
  end

  class NoCommandGiven < StandardError
    def message
      "No command given"
    end
  end

  class UnknownOptions < StandardError
    attr_reader :command

    def initialize(command, unrecognized_options)
      @command, @unrecognized_options = command, unrecognized_options
    end

    def message
      "Command #{@command} does not accept options #{@unrecognized_options.join(", ")}"
    end
  end

  class UnknownCommand < StandardError
    def initialize(command, parser)
      @command, @parser = command, parser
    end

    def message
      "Unknown command: #{@command.inspect}"
    end
  end

  class BaseCommand
    attr_reader :non_options, :options
    def initialize(non_options, options)
      @non_options, @options = non_options, options
    end
  end

  class VersionCommand < BaseCommand
    def run
      raise VersionNeeded
    end
  end

  class HelpCommand < BaseCommand
    def run
      raise HelpNeeded.new(non_options.first)
    end
  end

  class Parser
    def initialize(&block)
      @valid_options, @received_options, @commands = [], {}, {}
      @option_parser = OptionParser.new

      command(:help, Transat::HelpCommand)
      command(:version, Transat::VersionCommand)
      instance_eval(&block) if block_given?
    end

    def option(name, options={})
      options[:long] = name.to_s.gsub("_", "-") unless options[:long]
      @valid_options << name
      @received_options[name] = nil

      opt_args = []
      opt_args << "-#{options[:short]}" if options.has_key?(:short)
      opt_args << "--#{options[:long] || name}"
      opt_args << "=#{options[:param_name]}" if options.has_key?(:param_name)
      opt_args << options[:message]
      case options[:type]
      when :int, :integer
        opt_args << Integer
      when :float
        opt_args << Float
      when nil
        # NOP
      else
        raise ArgumentError, "Option #{name} has a bad :type parameter: #{options[:type].inspect}"
      end

      if options.has_key?(:default)
        opt_args << "(default: #{options[:default]})"
        @received_options[name] = options[:default]
      end
      
      @option_parser.on(*opt_args.compact) do |value|
        @received_options[name] = value
      end
    end

    def command(name, klass, options={})
      @commands[name.to_s] = options.merge(:class => klass)
    end
    
    def help(message)
      @help = message
    end

    def parse_and_execute(args=ARGV)
      begin
        command, non_options = parse(args)
        execute(command, non_options)
      rescue HelpNeeded
        $stderr.puts usage($!.command)
        exit 1
      rescue VersionNeeded
        puts "#{program_name} #{version}"
        exit 0
      rescue NoCommandGiven, UnknownOptions, UnknownCommand
        $stderr.puts "ERROR: #{$!.message}"
        $stderr.puts usage($!.respond_to?(:command) ? $!.command : nil)
        exit 1
      end
    end

    def parse(args)
      non_options = @option_parser.parse(args)
      command = non_options.shift
      raise NoCommandGiven unless command
      return command, non_options
    end

    def execute(command, non_options)
      found = false
      @commands.each do |command_name, options|
        command_klass = options[:class]
        aliases = [command_name]
        aliases += command_klass.aliases if command_klass.respond_to?(:aliases)
        return command_klass.new(non_options, @received_options).run if aliases.include?(command)
      end

      raise UnknownCommand.new(command, self)
    end

    def usage(command=nil)
      message = []

      if command then
        command_klass = @commands[command][:class]
        help =
          if command_klass.respond_to?(:aliases) then
            "#{command} (#{command_klass.aliases.join(", ")})"
          else
            "#{command}"
          end
        help = "#{help}: #{command_klass.help}" if command_klass.respond_to?(:help)
        message << help
        message << command_klass.detailed_help if command_klass.respond_to?(:detailed_help)
        message << ""
        message << "Valid options:"
        @option_parser.summarize(message)
      else
        message << "usage: #{program_name.downcase} <command> [options] [args...]"
        message << "Type '#{program_name.downcase} help <command>' for help on a specific command."
        message << "Type '#{program_name.downcase} version' to get this program's version."
        message << ""
        message << "Available commands are:"
        @commands.sort.each do |command, options|
          command_klass = options[:class]
          if command_klass.respond_to?(:aliases) then
            message << "  #{command} (#{command_klass.aliases.join(", ")})"
          else
            message << "  #{command}"
          end
        end
        if @help
          message << ""
          message << @help
        end
      end

      message.map {|line| line.chomp}.join("\n")
    end

    def program_name(value=nil)
      value ? @program_name = value : @program_name
    end

    def version(value=nil)
      if value then
        @version = value.respond_to?(:join) ? value.join(".") : value
      else
        @version
      end
    end

    def self.parse_and_execute(args=ARGV, &block)
      self.new(&block).parse_and_execute(args)
    end
  end
end
