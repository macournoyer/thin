require 'rake/gempackagetask'
require 'yaml'

WIN_SUFFIX = ENV['WIN_SUFFIX'] || 'i386-mswin32'

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
  s.rubyforge_project     = 'thin'
  s.has_rdoc              = true
  s.executables           = %w(thin)

  s.required_ruby_version = '>= 1.8.5'
  
  s.add_dependency        'rack',         '>= 0.3.0'
  s.add_dependency        'eventmachine', '>= 0.12.0'
  unless WIN
    s.add_dependency      'daemons',      '>= 1.0.9'
  end

  s.files                 = %w(COPYING CHANGELOG COMMITTERS README Rakefile) +
                            Dir.glob("{benchmark,bin,doc,example,lib,spec,tasks}/**/*") + 
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
  desc "Update the gemspec for GitHub's gem server"
  task :github do
    File.open("thin.gemspec", 'w') { |f| f << YAML.dump(spec) }
  end
  
  desc 'Upload gem to code.macournoyer.com'
  task :upload => :gem do
    upload "pkg/#{spec.full_name}.gem", 'gems'
    system 'ssh macournoyer@code.macournoyer.com "cd code.macournoyer.com && gem generate_index"'
  end
  
  namespace :upload do
    desc 'Upload the precompiled win32 gem to code.macournoyer.com'
    task :win do
      upload "pkg/#{spec.full_name}-#{WIN_SUFFIX}.gem", 'gems'
      system 'ssh macournoyer@code.macournoyer.com "cd code.macournoyer.com && gem generate_index"'
    end    

    desc 'Upload gems (ruby & win32) to rubyforge.org'
    task :rubyforge => :gem do
      sh 'rubyforge login'
      sh "rubyforge add_release thin thin #{Thin::VERSION::STRING} pkg/#{spec.full_name}.gem"
      sh "rubyforge add_file thin thin #{Thin::VERSION::STRING} pkg/#{spec.full_name}.gem"
      sh "rubyforge add_file thin thin #{Thin::VERSION::STRING} pkg/#{spec.full_name}-#{WIN_SUFFIX}.gem"
    end
  end
  
  desc 'Download the Windows gem from Kevin repo'
  task 'download:win' => 'pkg' do
    cd 'pkg' do
      `wget http://rubygems.bantamtech.com/ruby18/gems/#{spec.full_name}-#{WIN_SUFFIX}.gem`
    end
  end
end

task :install => [:clobber, :compile, :package] do
  sh "#{SUDO} #{gem} install pkg/#{spec.full_name}.gem"
end

task :uninstall => :clean do
  sh "#{SUDO} #{gem} uninstall -v #{Thin::VERSION::STRING} -x #{Thin::NAME}"
end


def gem
  RUBY_1_9 ? 'gem19' : 'gem'
end