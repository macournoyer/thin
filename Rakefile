RUBY_1_9 = RUBY_VERSION =~ /^1\.9/

require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'  unless RUBY_1_9 # RSpec not yet working w/ Ruby 1.9

require File.dirname(__FILE__) + '/lib/thin'


EXT_DIR    = 'ext/thin_parser'
EXT_BUNDLE = "#{EXT_DIR}/thin_parser.#{Config::CONFIG['DLEXT']}"
EXT_FILES  = FileList[
  "#{EXT_DIR}/*.c",
  "#{EXT_DIR}/*.h",
  "#{EXT_DIR}/*.rl",
  "#{EXT_DIR}/extconf.rb",
  "#{EXT_DIR}/Makefile",
  "lib"
]
CLEAN.include %w(doc/rdoc pkg coverage tmp log *.gem **/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile ext/*/conftest.dSYM)

if RUBY_1_9
  task :default => [:compile]
else
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*.rb']
  end
  task :default => [:compile, :spec]
end

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
  rdoc.rdoc_files.add %w(README) +
                      FileList['lib/**/*.rb'] +
                      FileList['bin/*']
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

task :ragel do
  Dir.chdir EXT_DIR do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
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
    sh(RUBY_PLATFORM =~ /win32/ ? 'nmake' : 'make')
  end
  cp EXT_BUNDLE, 'lib/'
end

desc 'Show some stats about the code'
task :stats do
  line_count = proc do |path|
    Dir[path].collect { |f| File.open(f).readlines.reject { |l| l =~ /(^\s*(\#|\/\*))|^\s*$/ }.size }.inject(0){ |sum,n| sum += n }
  end
  lib = line_count['lib/**/*.rb']
  ext = line_count['ext/**/*.{c,h}'] 
  spec = line_count['spec/**/*.rb']
  ratio = '%1.2f' % (spec.to_f / lib.to_f)
  
  puts "#{lib.to_s.rjust(6)} LOC of lib"
  puts "#{ext.to_s.rjust(6)} LOC of ext"
  puts "#{spec.to_s.rjust(6)} LOC of spec"
  puts "#{ratio.to_s.rjust(6)} ratio lib/spec"
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

task :install => :compile do
  sh %{rake package}
  sh %{sudo #{gem} install pkg/#{Thin::NAME}-#{Thin::VERSION::STRING}}
end

task :uninstall => :clean do
  sh %{sudo #{gem} uninstall #{Thin::NAME}}
end

# == Utilities

def upload(file, to, options={})
  sh %{ssh macournoyer@macournoyer.com "rm -rf code.macournoyer.com/#{to}"} if options[:replace]
  sh %{scp -rq #{file} macournoyer@macournoyer.com:code.macournoyer.com/#{to}}
end

def gem
  RUBY_1_9 ? 'gem19' : 'gem'
end