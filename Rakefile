RUBY_1_9 = RUBY_VERSION =~ /^1\.9/

windows = (PLATFORM =~ /mswin|cygwin/)

SUDO = windows ? "" : "sudo"

require 'lib/thin'

Dir['tasks/**/*.rake'].each { |rake| load rake }

task :default => [:compile, :spec]

desc "install the gem"
task :thin_install => [:clean,:package] do
  sh %{#{SUDO} #{gem} install pkg/#{Thin::NAME}-#{Thin::VERSION::STRING}*.gem --no-update-sources}
end

desc "uninstall the gem"
task :thin_uninstall => :clean do
  sh %{#{SUDO} #{gem} uninstall #{Thin::NAME}}
end
