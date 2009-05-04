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

def jruby_ext_task(name)
  ext_dir   = "ext/#{name}"
  build_dir = "ext/#{name}/classes"
  jar_file  = "lib/#{name}.jar"
  
  # Avoid JRuby in-process launching problem
  require 'jruby'
  JRuby.runtime.instance_config.run_ruby_in_process = false
  classpath = Java::java.lang.System.getProperty('java.class.path')
  
  file jar_file do
    mkdir_p build_dir
    sources = FileList["ext/#{name}/**/*.java"].join(' ')
    sh "javac -target 1.4 -source 1.4 -d #{build_dir} -cp #{classpath} #{sources}"
    sh "jar cf #{jar_file} -C #{build_dir} ."
  end
  task :compile => [jar_file]
end

desc "Compile the extensions"
task :compile
task :package => :compile
