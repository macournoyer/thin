require 'rake'
require 'rake/clean'
load 'thin.gemspec'

task :default => :spec

desc "Build gem packages"
task :build do
  sh "gem build thin.gemspec"
end

desc "Push gem packages"
task :push => :build do
  sh "gem push thin-*.gem"
end

task :install => :build do
  sh "gem install thin-*.gem"
end

desc "Release version #{Thin::VERSION}"
task :release => [:tag, :push]
