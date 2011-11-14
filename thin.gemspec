# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "thin/version"

Gem::Specification.new do |s|
  s.name        = "thin"
  s.version     = Thin::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Marc-Andre Cournoyer"]
  s.email       = ["thin@macournoyer.com"]
  s.homepage    = "http://code.macournoyer.com/thin"
  s.summary     = %q{A thin and fast web server}
  s.description = %q{Thin is a Rack based, high performance web server}

  s.rubyforge_project = "thin"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "eventmachine", "~> 1.0.0"
  s.add_dependency "http_parser.rb", "~> 0.5.3"
  s.add_dependency "preforker", "~> 0.1.1"
  s.add_dependency "kgio", "~> 2.6.0"
end
