require 'rake/gempackagetask'
require 'yaml'

task :clean => :clobber_package

spec_path = File.expand_path('../../thin.gemspec', __FILE__)
Thin::GemSpec = eval(File.read(spec_path), binding, spec_path, 0)

Rake::GemPackageTask.new(Thin::GemSpec) do |p|
  p.gem_spec = Thin::GemSpec
end

task :tag_warn do
  puts "*" * 40
  puts "Don't forget to tag the release:"
  puts
  puts "  git tag -m 'Tagging #{Thin::SERVER}' -a v#{Thin::VERSION::STRING}"
  puts
  puts "or run rake tag"
  puts "*" * 40
end
task :tag do
  sh "git tag -m 'Tagging #{Thin::SERVER}' -a v#{Thin::VERSION::STRING}"
end
task :gem => :tag_warn

namespace :gem do
  desc 'Upload gems to gemcutter.org'
  task :push do
    Dir["pkg/#{Thin::GemSpec.full_name}*.gem"].each do |file|
      sh "gem push #{file}"
    end
  end
end
