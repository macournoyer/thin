CLEAN.include %w(**/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile ext/*/conftest.dSYM)

def ext_task(name)
  ext_dir    = "ext/#{name}"
  ext_bundle = "#{ext_dir}/#{name}.#{Config::CONFIG['DLEXT']}"
  ext_files  = FileList[
    "#{ext_dir}/*.c",
    "#{ext_dir}/*.h",
    "#{ext_dir}/*.rl",
    "#{ext_dir}/extconf.rb",
    "#{ext_dir}/Makefile",
    "lib"
  ]
  
  task "compile:#{name}" => ["#{ext_dir}/Makefile", ext_bundle]
  task :compile => "compile:#{name}"
  
  file "#{ext_dir}/Makefile" => ["#{ext_dir}/extconf.rb"] do
    cd(ext_dir) { ruby "extconf.rb" }
  end

  file ext_bundle => ext_files do
    cd ext_dir do
      sh(WIN ? 'nmake' : 'make')
    end
    cp ext_bundle, 'lib/'
  end
end

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/thin_parser' do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl | rlgen-cd -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
end
  
desc "Compile the extensions"
task :compile
task :package => :compile
