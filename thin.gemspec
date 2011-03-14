# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = "thin"
  s.version = '1.2.8'
  s.platform = Gem::Platform::RUBY
  s.summary = "A thin and fast web server."
  s.email = "macournoyer@gmail.com"
  s.homepage = "http://code.macournoyer.com/thin/"
  s.description = "A thin and fast web server."
  s.authors = ['Marc-Andre Cournoyer']

  s.date = %q{2010-10-25 12:35:00}

  s.rubyforge_project = "thin"

  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extensions << 'ext/thin_parser/extconf.rb'

  s.has_rdoc = true

  s.add_dependency("rack", ">= 1.0.0")
  s.add_dependency("eventmachine", ">= 0.12.6")
  s.add_dependency("daemons", ">= 1.0.9")
end