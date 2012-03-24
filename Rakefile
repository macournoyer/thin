RUBY_1_9 = RUBY_VERSION =~ /^1\.9/
WIN      = (RUBY_PLATFORM =~ /mswin|cygwin/)
SUDO     = (WIN ? "" : "sudo")

require 'rake'
require 'rake/clean'

$: << File.join(File.dirname(__FILE__), 'lib')
require 'thin/version'

# Load tasks in tasks/
Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => :spec

CLEAN.include %w(**/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile ext/*/conftest.dSYM lib/1.{8,9}})

desc "Build gem packages"
task :gems do
  sh "rake clean gem && rake cross native gem RUBY_CC_VERSION=1.8.6:1.9.1"
end

desc "Release version #{Thin::VERSION::STRING} gems to rubyforge"
task :release => [:tag, "gem:push"]
