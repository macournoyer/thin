RUBY_1_9 = RUBY_VERSION =~ /^1\.9/
WIN      = (RUBY_PLATFORM =~ /mswin|cygwin/)
SUDO     = (WIN ? "" : "sudo")

require 'rake'
require 'rake/clean'
require 'rake/extensiontask' # from rake-compiler gem

$: << File.join(File.dirname(__FILE__), 'lib')
require 'thin'

# Load tasks in tasks/
Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => :spec

Rake::ExtensionTask.new('thin_parser', Thin::GemSpec)

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/thin_parser' do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
end
