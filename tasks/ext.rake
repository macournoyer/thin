EXT_DIR    = 'ext/thin_parser'
EXT_BUNDLE = "#{EXT_DIR}/thin_parser.#{Config::CONFIG['DLEXT']}"

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir EXT_DIR do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
end

task :package => :compile

def move_extensions
  Dir["#{EXT_DIR}/*.#{Config::CONFIG['DLEXT']}"].each { |file| mv file, "lib/" }
end
case RUBY_PLATFORM
when /mswin/
  FILENAME = "lib/thin_parser.so"
  file FILENAME do
    Dir.chdir("ext/thin_parser") do
      ruby "extconf.rb"
      system('nmake')
    end
    move_extensions
  end
  desc "compile C extension"
  task :compile => [FILENAME]
end
