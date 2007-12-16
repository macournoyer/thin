require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/thin'

REVISION = `svn info`.match('Revision: (\d+)')[1]
CLEAN.include %w(doc/rdoc pkg tmp log)

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
end
task :default => :test

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += ['--quiet', '--title', Thin::NAME,
             	     "--opname", "index.html",
            	     "--line-numbers",
            	     "--main", "README",
            	     "--inline-source"]
  rdoc.template = "site/rdoc.rb"
  rdoc.main = "README"
  rdoc.title = Thin::NAME
  rdoc.rdoc_files.add ['README', 'lib/thin/*.rb', 'bin/*']
end

namespace :rdoc do
  desc 'Upload rdoc to code.macournoyer.com'
  task :upload => :rdoc do
    upload "doc/rdoc", 'thin/doc', :replace => true
  end
end

spec = Gem::Specification.new do |s|
  s.name                  = Thin::NAME
  s.version               = Thin::VERSION::STRING
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Thin and fast web server"
  s.description           = s.summary
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'

  s.required_ruby_version = '>= 1.8.6' # To be sure the multipart eof fix is in there

  s.files                 = %w(README COPYING Rakefile) + Dir.glob("{doc,lib,test,example}/**/*")
  
  s.require_path          = "lib"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end

namespace :gem do
  desc 'Upload gem to code.macournoyer.com'
  task :upload => :gem do
    upload "pkg/#{spec.full_name}.gem", 'gems'
    sh 'ssh macournoyer@macournoyer.com "cd code.macournoyer.com && index_gem_repository.rb"'
  end
  
  desc 'Upload gem to rubyforge.org'
  task :upload_rubyforge => :gem do
    sh 'rubyforge login'
    sh "rubyforge add_release thin thin #{Thin::VERSION::STRING} pkg/thin-#{Thin::VERSION::STRING}.gem"
    sh "rubyforge add_file thin thin #{Thin::VERSION::STRING} pkg/thin-#{Thin::VERSION::STRING}.gem"
  end
end

desc 'Show some stats about the code'
task :stats do
  line_count = proc do |path|
    Dir[path].collect { |f| File.open(f).readlines.reject { |l| l =~ /(^\s*\#)|^\s*$/ }.size }.inject(0){ |sum,n| sum += n }
  end
  puts "#{line_count['lib/**/*.rb'].to_s.rjust(6)} LOC of lib"
  puts "#{line_count['lib/thin/{server,request,response,cgi,rails,handler,headers}.rb'].to_s.rjust(6)} LOC of web serving stuff"
  puts "#{line_count['test/**/*.rb'].to_s.rjust(6)} LOC of test"
end

namespace :site do
  task :build do
    mkdir_p 'tmp/site/images'
    cd 'tmp/site' do
      ruby '../../site/thin.rb', '--dump'
    end
    cp 'site/style.css', 'tmp/site'
    cp_r Dir['site/images/*'], 'tmp/site/images'
  end
  
  desc 'Upload website to code.macournoyer.com'
  task :upload => 'site:build' do
    upload 'tmp/site/*', 'thin'
  end
end

namespace :deploy do
  task :site => %w(site:upload rdoc:upload)
  
  desc 'Deploy on code.macournoyer.com'
  task :alpha => %w(gem:upload deploy:site)
  
  desc 'Deploy on rubyforge'
  task :public => %w(gem:upload_rubyforge deploy:site)  
end
desc 'Deploy on all servers'
task :deploy => %w(deploy:alpha deploy:public)

task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{Thin::NAME}-#{Thin::VERSION::STRING}}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{Thin::NAME}}
end

task :tag do
  sh %Q{svn cp . http://code.macournoyer.com/svn/thin/tags/#{Thin::VERSION::STRING} -m "Tagging version #{Thin::VERSION::STRING}"}
end

# == Utilities

def upload(file, to, options={})
  sh %{ssh macournoyer@macournoyer.com "rm -rf code.macournoyer.com/#{to}"} if options[:replace]
  sh %{scp -rq #{file} macournoyer@macournoyer.com:code.macournoyer.com/#{to}}
end