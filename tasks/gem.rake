require 'rake/gempackagetask'

CLEAN.include %w(pkg *.gem)

spec = Gem::Specification.new do |s|
  s.name                  = Thin::NAME
  s.version               = Thin::VERSION::STRING
  s.platform              = Gem::Platform::RUBY
  s.summary               = 
  s.description           = "A thin and fast web server"
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'
  s.executables           = %w(thin)

  s.required_ruby_version = '>= 1.8.6'
  
  s.add_dependency        'eventmachine', '>= 0.8.1'
  s.add_dependency        'rack',         '>= 0.2.0'
  s.add_dependency        'daemons',      '>= 1.0.9'

  s.files                 = %w(COPYING README Rakefile) +
                            Dir.glob("{bin,doc,spec,lib,example}/**/*") + 
                            Dir.glob("ext/**/*.{h,c,rb,rl}") +
  s.extensions            = FileList["ext/**/extconf.rb"].to_a
  
  s.require_path          = "lib"
  s.bindir                = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end

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