CLEAN.include %w(**/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile ext/*/conftest.dSYM)

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

desc "Compile the Ragel state machines"
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
