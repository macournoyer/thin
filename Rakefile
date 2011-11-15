require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/unit/*_test.rb'
  end
  
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/integration/*_test.rb'
  end
  
end
desc "Run all tests"
task :test => ["test:unit", "test:integration"]

task :default => :test