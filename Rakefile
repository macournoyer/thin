require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
require "thin/version"

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/unit/**/*_test.rb'
  end
  
  Rake::TestTask.new(:integration) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/integration/**/*_test.rb'
  end
  
end
desc "Run all tests"
task :test => ["test:unit", "test:integration"]

task :default => :test

task :man do
  ENV['RONN_MANUAL']  = "Thin Manual"
  ENV['RONN_ORGANIZATION'] = "Thin #{Thin::VERSION::STRING}"
  sh "ronn -w -s toc -5 man/*.ronn"
  mv FileList["man/*.html"], "site/public/man"
end

task :rm_space do
  sh %{find . -name "*.rb" -print0 | xargs -0 sed -i '' -E "s/[[:space:]]*$//"}
end