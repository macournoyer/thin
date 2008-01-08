RUBY_1_9 = RUBY_VERSION =~ /^1\.9/

require 'rake'
require 'rake/clean'
require 'lib/thin'
Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => [:compile, :spec]

task :install => :compile do
  sh %{rake package}
  sh %{sudo #{gem} install pkg/#{Thin::NAME}-#{Thin::VERSION::STRING}}
end

task :uninstall => :clean do
  sh %{sudo #{gem} uninstall #{Thin::NAME}}
end
