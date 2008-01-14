require 'lib/thin'
require 'echoe'

# sudo flag
windows             = (PLATFORM =~ /mswin|cygwin/)
SUDO                = windows ? "" : "sudo"

# ruby version
RUBY_1_9            = RUBY_VERSION =~ /^1\.9/
def gem
  RUBY_1_9 ? 'gem19' : 'gem'
end

# ragel
RAGEL_BASE          = 'parser'
RAGEL_TARGET        = "#{RAGEL_BASE}.c"
RAGEL_FILE          = "#{RAGEL_BASE}.rl"

# ext
EXT_BASE            = 'thin_parser'
EXT_DIR             = "ext/#{EXT_BASE}"
EXT_BUNDLE          = "#{EXT_DIR}/#{EXT_BASE}.#{Config::CONFIG['DLEXT']}"
SO_FILE             = "#{EXT_BASE}.so"

Echoe.new(Thin::NAME) do |p|
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
  p.rdoc_pattern = ['README', 'LICENSE', 'changes.txt', 'lib/**/*.rb', 'doc/**/*.rdoc']
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
#      self.platform = Gem::Platform::CURRENT
      add_dependency('eventmachine', '>= 0.8.1')
    else
#      self.platform = Gem::Platform::RUBY
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

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir EXT_DIR do
    File.unlink RAGEL_TARGET if File.exist? RAGEL_TARGET
    sh "ragel #{RAGEL_FILE} | rlgen-cd -G2 -o #{RAGEL_TARGET}"
    raise "Failed to compile Ragel state machine" unless File.exist? RAGEL_TARGET
  end
end

case RUBY_PLATFORM
when /mswin/
  FILENAME = "lib/#{SO_FILE}"
  file FILENAME do
    Dir.chdir EXT_DIR do
      ruby "extconf.rb"
      system('nmake')
    end
    cp EXT_BUNDLE, 'lib/'
  end
  desc "compile mswin32 extension"
  task :compile => [FILENAME]
end

# :compile defined by echoe
task :package => :compile

namespace :deploy do
  task :site => %w(site:upload rdoc:upload)
  
  desc 'Deploy on code.macournoyer.com'
  task :alpha => %w(gem:upload deploy:site)
  
  desc 'Deploy on rubyforge'
  task :public => %w(gem:upload_rubyforge deploy:site)  
end
desc 'Deploy on all servers'
task :deploy => %w(deploy:alpha deploy:public)

def upload(file, to, options={})
  sh %{ssh macournoyer@macournoyer.com "rm -rf code.macournoyer.com/#{to}"} if options[:replace]
  sh %{scp -rq #{file} macournoyer@macournoyer.com:code.macournoyer.com/#{to}}
end

namespace :site do
  task :build do
    mkdir_p 'tmp/site/images'
    cd 'tmp/site' do
      sh "SITE_ROOT='/thin' ruby ../../site/thin.rb --dump"
    end
    cp 'site/style.css', 'tmp/site'
    cp_r Dir['site/images/*'], 'tmp/site/images'
  end
  
  desc 'Upload website to code.macournoyer.com'
  task :upload => 'site:build' do
    upload 'tmp/site/*', 'thin'
  end
end

if RUBY_1_9
  task :spec do
    warn 'RSpec not yet supporting Ruby 1.9, so cannot run the specs :('
  end
else
  # RSpec not yet working w/ Ruby 1.9
  require 'spec/rake/spectask'
  
  desc "Run all examples"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
end

task :default => [:compile, :spec]

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

desc "install the gem"
task :thin_install => [:clean,:package] do
  sh %{#{SUDO} #{gem} install pkg/#{Thin::NAME}-#{Thin::VERSION::STRING}*.gem --no-update-sources}
end

desc "uninstall the gem"
task :thin_uninstall => :clean do
  sh %{#{SUDO} #{gem} uninstall #{Thin::NAME}}
end
