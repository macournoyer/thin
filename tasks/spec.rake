CLEAN.include %w(coverage tmp log)

if RUBY_1_9
  task :spec do
    warn 'RSpec not yet supporting Ruby 1.9, so cannot run the specs :('
  end
else
  # RSpec not yet working w/ Ruby 1.9
  require 'spec/rake/spectask'
  
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
end
