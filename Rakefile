RUBY_1_9 = RUBY_VERSION =~ /^1\.9/
JRUBY    = RUBY_PLATFORM =~ /java/
WIN      = (RUBY_PLATFORM =~ /mswin|cygwin/)
SUDO     = (WIN ? "" : "sudo")

require 'rake'
require 'rake/clean'
require 'lib/thin'

Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => :spec

if JRUBY
  jruby_ext_task :thin_parser_jruby, "lib/thin_parser.jar"
else
  ext_task :thin_parser
end

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/thin_parser' do
    # C ext
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel -G2 parser.c.rl -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
  Dir.chdir 'ext/thin_parser_jruby' do
    # JRuby
    target = "org/thin/HttpParser.java"
    mkdir_p File.dirname(target)
    File.unlink target if File.exist? target
    sh "ragel -J parser.java.rl -o #{target}"
    raise "Failed to build Java source" unless File.exist? target
  end
end
