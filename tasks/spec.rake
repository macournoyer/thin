CLEAN.include %w(coverage tmp log)

if RUBY_1_9 # RSpec not yet working w/ Ruby 1.9
  task :spec do
    warn 'RSpec not yet supporting Ruby 1.9, so cannot run the specs :('
  end
else
  require 'spec/rake/spectask'
  
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb'] - FileList['spec/perf/*_spec.rb']
    if WIN
      t.spec_files -= [
          'spec/backends/unix_server_spec.rb',
          'spec/controllers/service_spec.rb',
          'spec/daemonizing_spec.rb',
          'spec/server/unix_socket_spec.rb',
          'spec/server/swiftiply_spec.rb'
          ]
    end
  end
  task :spec => :compile
  
  desc "Run all performance examples"
  Spec::Rake::SpecTask.new('spec:perf') do |t|
    t.spec_files = FileList['spec/perf/*_spec.rb']
  end
  
  task :check_benchmark_unit_gem do
    begin
      require 'benchmark_unit'
    rescue LoadError
      abort "To run specs, install benchmark_unit gem"
    end
  end
  
  task 'spec:perf' => :check_benchmark_unit_gem
end