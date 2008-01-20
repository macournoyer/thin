RUBY_1_9 = RUBY_VERSION =~ /^1\.9/
WIN      = (PLATFORM =~ /mswin|cygwin/)
SUDO     = (WIN ? "" : "sudo")

require 'rake'
require 'rake/clean'
require 'lib/thin'

Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => :spec
