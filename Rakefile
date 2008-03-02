RUBY_1_9 = RUBY_VERSION =~ /^1\.9/
WIN      = (RUBY_PLATFORM =~ /mswin|cygwin/)
SUDO     = (WIN ? "" : "sudo")

require 'rake'
require 'rake/clean'
require 'lib/thin'

Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => :spec

ext_task :thin_parser