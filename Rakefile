require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/thin'

REVISION   = `svn info`.match('Revision: (\d+)')[1]
EXT_DIR    = 'ext/http11'
EXT_BUNDLE = "#{EXT_DIR}/http11.bundle"
EXT_FILES  = FileList[
  "#{EXT_DIR}/*.c",
  "#{EXT_DIR}/*.h",
  "#{EXT_DIR}/*.rl",
  "#{EXT_DIR}/extconf.rb",
  "#{EXT_DIR}/Makefile",
  "lib"
]
CLEAN.include %w(doc/rdoc pkg tmp log *.gem **/*.{bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile)

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
end
task :default => [:compile, :test]

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
  rdoc.rdoc_files.add %w(README lib/thin/*.rb')
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
  s.summary               = 
  s.description           = "A thin and fast web server"
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'

  s.required_ruby_version = '>= 1.8.6'
  
  s.add_dependency        'eventmachine', '>= 0.9.0'
  s.add_dependency        'rack',         '>= 0.2.0'

  s.files                 = %w(README COPYING Rakefile) + Dir.glob("{doc,lib,test,example}/**/*")
  s.extensions            = FileList["ext/**/extconf.rb"].to_a
  
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

task :ragel do
  Dir.chdir "ext/http11" do
    target = "http11_parser.c"
    File.unlink target if File.exist? target
    sh "ragel http11_parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to build C source" unless File.exist? target
  end
end
  
desc "Compile the extensions"
task :compile => ["#{EXT_DIR}/Makefile", EXT_BUNDLE]

task :package => :compile

file "#{EXT_DIR}/Makefile" => ["#{EXT_DIR}/extconf.rb"] do
  cd(EXT_DIR) { ruby "extconf.rb" }
end

file EXT_BUNDLE => EXT_FILES do
  cd EXT_DIR do
    sh(PLATFORM =~ /win32/ ? 'nmake' : 'make')
  end
  cp EXT_BUNDLE, 'lib/'
end

desc 'Show some stats about the code'
task :stats do
  line_count = proc do |path|
    Dir[path].collect { |f| File.open(f).readlines.reject { |l| l =~ /(^\s*\#)|^\s*$/ }.size }.inject(0){ |sum,n| sum += n }
  end
  lib = line_count['lib/**/*.rb']
  test = line_count['test/**/*.rb']
  ratio = '%1.2f' % (test.to_f / lib.to_f)
  
  puts "#{lib.to_s.rjust(6)} LOC of lib"
  puts "#{test.to_s.rjust(6)} LOC of test"
  puts "#{ratio.to_s.rjust(6)} ratio"
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