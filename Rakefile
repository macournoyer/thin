require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/thin'

CLEAN.include %w(doc/rdoc pkg tmp log)

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
end
task :default => :test

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += ['--quiet', '--title', "Thin",
             	     "--opname", "index.html",
            	     "--line-numbers",
            	     "--main", "README",
            	     "--inline-source"]
  rdoc.template = "site/rdoc.rb"
  rdoc.main = "README"
  rdoc.title = "Thin"
  rdoc.rdoc_files.add ['README', 'lib/thin/*.rb', 'bin/*']
end

spec = Gem::Specification.new do |s|
  s.name                  = Thin::NAME
  s.version               = Thin::VERSION
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Thin and fast web server"
  s.description           = s.summary
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'
  s.executables           = %w(thin)

  s.required_ruby_version = '>= 1.8.2'

  s.files                 = %w(COPYING README Rakefile) + Dir.glob("{bin,doc,test,lib}/**/*")
  
  s.require_path          = "lib"
  s.bindir                = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
end

def upload(file, to)
  sh %{scp -rq #{file} macournoyer@macournoyer.com:code.macournoyer.com/#{to}}
end

namespace :gem do
  desc 'Upload gem to code.macournoyer.com'
  task :upload do
    upload "pkg/#{spec.full_name}.gem", 'gems'
    sh 'ssh macournoyer@macournoyer.com "cd code.macournoyer.com && index_gem_repository.rb"'
  end
end

desc 'Show some stats about the code'
task :stats do
  line_counter = proc { |path| Dir["#{path}/**/*.rb"].collect {|f| File.open(f).readlines.size }.inject(0){|sum,n| sum += n} }
  %w(lib test).each do |dir|
    puts "#{line_counter[dir].to_s.rjust(6)} LOC in #{dir}"
  end
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
  
  task :upload => 'site:build' do
    upload 'tmp/site', 'thin'
  end
end