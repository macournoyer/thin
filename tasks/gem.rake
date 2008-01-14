require 'rubygems'
gem 'echoe', '>=2.7.5'
require 'echoe'

e = Echoe.new("thin") do |p|
  p.author = "Marc-Andre Cournoyer"
  p.email = "macournoyer@gmail.com"
  p.description = "Thin takes the http parser from Mongrel, the 
    connection engine from EventMachine and the web server interface
    from Rack, creating a highly flexible, small, fast, and sexy
    web app server for Ruby."
  p.summary = "A thin and fast web server"
  p.url = "http://code.macournoyer.com/thin/"
  p.docs_host = "macournoyer.com:~/code.macournoyer.com/thin/doc/"
  p.clean_pattern = ['ext/thin_parser/*.{bundle,so,o,obj,pdb,lib,def,exp}', 'lib/*.{bundle,so,o,obj,pdb,lib,def,exp}', 'ext/thin_parser/Makefile', 'pkg', 'lib/*.bundle', '*.gem', '*.gemspec', '.config', 'coverage']
  p.ignore_pattern = /^(.git|benchmark|site|tasks)|.gitignore/
  p.rdoc_pattern = ['README', 'LICENSE', 'CHANGELOG', 'changes.txt', 'lib/**/*.rb', 'doc/**/*.rdoc']
  p.ruby_version = '>= 1.8.6'
  p.dependencies = ['rack >= 0.2.0']
  p.extension_pattern = nil
  p.need_tar_gz = false
  
  if RUBY_PLATFORM !~ /mswin/
    p.extension_pattern = ["ext/**/extconf.rb"]
  end
  
  p.eval = proc do
    case RUBY_PLATFORM
    when /mswin/
      self.files += ['lib/thin_parser.so']
      self.platform = Gem::Platform::CURRENT
      add_dependency('eventmachine', '>= 0.8.1')
    else
      add_dependency('daemons', '>= 1.0.9')
      add_dependency('eventmachine')
    end
  end
end

task :clean => :clobber_package

task :tag_warn do
  puts "*" * 40
  puts "Don't forget to tag the release:"
  puts "  git tag -a v#{Thin::VERSION::STRING}"
  puts "*" * 40
end
task :gem => :tag_warn

namespace :gem do
  desc 'Upload gem to code.macournoyer.com'
  task :upload => :gem do
    upload "pkg/#{spec.full_name}.gem", 'gems'
    system 'ssh macournoyer@macournoyer.com "cd code.macournoyer.com && gem generate_index"'
  end
  
  desc 'Upload gem to rubyforge.org'
  task :upload_rubyforge => :gem do
    sh 'rubyforge login'
    sh "rubyforge add_release thin thin #{Thin::VERSION::STRING} pkg/thin-#{Thin::VERSION::STRING}.gem"
    sh "rubyforge add_file thin thin #{Thin::VERSION::STRING} pkg/thin-#{Thin::VERSION::STRING}.gem"    
  end
end

def gem
  RUBY_1_9 ? 'gem19' : 'gem'
end