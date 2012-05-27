require File.expand_path('../lib/thin/version', __FILE__)
Gem::Specification.new do |s|
  s.name                  = Thin::NAME
  s.version               = Thin::VERSION::STRING
  s.summary               =
  s.description           = "A thin and fast web server"
  s.author                = "Marc-Andre Cournoyer"
  s.email                 = 'macournoyer@gmail.com'
  s.homepage              = 'http://code.macournoyer.com/thin/'
  s.rubyforge_project     = 'thin'
  s.executables           = %w(thin)

  s.required_ruby_version = '>= 1.8.5'

  s.add_dependency        'rack',           '>= 1.0.0'
  s.add_dependency        'eventmachine',   '>= 0.12.6'
  s.add_dependency        'http_parser.rb', '>= 0.5.3'
  s.add_dependency        'daemons',        '>= 1.0.9'

  s.files                 = %w(CHANGELOG README Rakefile) +
                            Dir.glob("{benchmark,bin,doc,example,lib,spec,tasks}/**/*")

  s.require_path          = "lib"
  s.bindir                = "bin"
end
