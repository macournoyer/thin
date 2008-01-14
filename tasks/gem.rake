require 'rake/gempackagetask'

task :clean => :clobber_package

spec = Gem::Specification.new do |s|
  s.name                  = Thin::NAME
  s.version               = Thin::VERSION::STRING
  s.platform              = WIN ? Gem::Platform::CURRENT : Gem::Platform::RUBY
  s.summary               = 
  s.description           = "A thin and fast web server"
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'
  s.executables           = %w(thin)

  s.required_ruby_version = '>= 1.8.6' # Makes sure the CGI eof fix is there
  
  if WIN
    s.add_dependency      'eventmachine', '>= 0.8.1' # Latest precompiled version released
  else
    s.add_dependency      'eventmachine'
    s.add_dependency      'daemons',      '>= 1.0.9' # Daemonizing doesn't work on win
  end
  s.add_dependency        'rack',         '>= 0.2.0'

  s.files                 = %w(COPYING CHANGELOG README Rakefile) +
                            Dir.glob("{benchmark,bin,doc,example,lib,spec}/**/*") + 
                            Dir.glob("ext/**/*.{h,c,rb,rl}")
  
  if WIN
    s.files              += ["lib/thin_parser.#{Config::CONFIG['DLEXT']}"]
  else
    s.extensions          = FileList["ext/**/extconf.rb"].to_a
  end
  
  s.require_path          = "lib"
  s.bindir                = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end

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
