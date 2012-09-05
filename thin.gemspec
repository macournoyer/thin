$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "thin/version"

# Describe your gem and declare its dependencies:
Thin::GemSpec = Gem::Specification.new do |s|
  s.name                  = "friendlyfashion-" + Thin::NAME
  s.version               = Thin::VERSION::STRING
  s.platform              = Thin.win? ? Gem::Platform::CURRENT : Gem::Platform::RUBY
  s.summary               = 
  s.description           = "A thin and fast web server"
  s.authors               = ["Laurynas Butkus", "Tomas Didziokas", "Justas Janauskas", "Edvinas Bartkus"]
  s.email                 = ["laurynas.butkus@gmail.com", "tomas.did@gmail.com", "jjanauskas@gmail.com", "edvinas.bartkus@gmail.com"]
  s.homepage              = 'https://github.com/friendlyfashion/thin'
  s.rubyforge_project     = 'thin'
  s.license               = 'Ruby'
  s.executables           = %w( thin )

  s.required_ruby_version = '>= 1.8.5'
  
  s.add_dependency        'rack',         '>= 1.0.0'
  s.add_dependency        'eventmachine', '>= 0.12.6'
  s.add_dependency        'daemons',      '>= 1.0.9'  unless Thin.win?

  s.files                 = %w(CHANGELOG README.md Rakefile) +
                            Dir["{bin,doc,example,lib}/**/*"] - Dir["lib/thin_parser.*"] + 
                            Dir["ext/**/*.{h,c,rb,rl}"]
  
  if Thin.win?
    s.files              += Dir["lib/*/thin_parser.*"]
  else
    s.extensions          = Dir["ext/**/extconf.rb"]
  end
  
  s.require_path          = "lib"
  s.bindir                = "bin"
end
