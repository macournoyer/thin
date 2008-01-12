require 'erb'

MSG_TEMPLATE = File.dirname(__FILE__) + '/email.erb'
SEND_TO      = %w(thin-ruby@googlegroups.com eventmachine-talk@rubyforge.org Rubymtl@lists.artengine.ca ruby-talk@ruby-lang.org)

desc 'Generate a template for the new version annoucement'
task :ann do
  msg = ERB.new(File.read(MSG_TEMPLATE)).result(binding)
    
  body = <<END_OF_MESSAGE
To: #{SEND_TO}
Subject: [ANN] Thin #{Thin::VERSION::STRING} #{Thin::VERSION::CODENAME} released

#{msg}
END_OF_MESSAGE

  puts body
end