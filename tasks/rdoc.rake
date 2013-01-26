require 'rdoc/task'

CLEAN.include %w(doc/rdoc)

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += ['--quiet', '--title', Thin::NAME,
             	     "--opname", "index.html",
            	     "--line-numbers",
            	     "--main", "README.md",
            	     "--inline-source"]
  rdoc.template = "site/rdoc.rb"
  rdoc.main = "README.md"
  rdoc.title = Thin::NAME
  rdoc.rdoc_files.add %w(README.md) +
                      FileList['lib/**/*.rb'] +
                      FileList['bin/*']
end

namespace :rdoc do
  desc 'Upload rdoc to code.macournoyer.com'
  task :upload => :rdoc do
    upload "doc/rdoc", 'thin/doc', :replace => true
  end
end
