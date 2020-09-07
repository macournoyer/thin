CLEAN.include %w(coverage tmp log)

require 'rspec/core/rake_task'

PERF_SPECS = FileList['spec/perf/*_spec.rb']
WIN_SPECS  = %w(
  spec/backends/unix_server_spec.rb
  spec/controllers/service_spec.rb
  spec/daemonizing_spec.rb
  spec/server/unix_socket_spec.rb
  spec/server/swiftiply_spec.rb
)
# HACK Event machine causes some problems when running multiple
# tests in the same VM so we split the specs in groups before I find
# a better solution...
SPEC_GROUPS = [
  %w(spec/server/threaded_spec.rb spec/server/tcp_spec.rb),
  %w(spec/daemonizing_spec.rb),
  %w(spec/server/stopping_spec.rb),
]
SPECS = FileList['spec/**/*_spec.rb'] - PERF_SPECS - SPEC_GROUPS.flatten

def spec_task(name, specs)
  RSpec::Core::RakeTask.new(name) do |t|
    t.rspec_opts = ["-c", "-f progress"]
    t.pattern = specs
  end
end

desc "Run all main specs"
spec_task "spec:main", SPECS
task :spec => [:compile, "spec:main"]

SPEC_GROUPS.each_with_index do |files, i|
  task_name = "spec:group:#{i}"
  desc "Run specs sub-group ##{i}"
  spec_task task_name, files
  task :spec => task_name
end

desc "Run all performance examples"
spec_task 'spec:perf', PERF_SPECS

task :check_benchmark_unit_gem do
  begin
    require 'benchmark_unit'
  rescue LoadError
    abort "To run specs, install benchmark_unit gem"
  end
end

task 'spec:perf' => :check_benchmark_unit_gem
