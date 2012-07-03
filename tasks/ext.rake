require 'rake/extensiontask' # from rake-compiler gem

Rake::ExtensionTask.new('thin_parser', Thin::GemSpec) do |ext|
  # enable cross compilation (requires cross compile toolchain)
  ext.cross_compile = true
  
  # forces the Windows platform instead of the default one
  # configure options only for cross compile
  ext.cross_platform = %w( i386-mswin32 x86-mingw32 )
end

CLEAN.include %w(**/*.{o,bundle,jar,so,obj,pdb,lib,def,exp,log} ext/*/Makefile ext/*/conftest.dSYM lib/1.{8,9}})

desc "Compile the Ragel state machines"
task :ragel do
  Dir.chdir 'ext/thin_parser' do
    target = "parser.c"
    File.unlink target if File.exist? target
    sh "ragel parser.rl -G2 -o #{target}"
    raise "Failed to compile Ragel state machine" unless File.exist? target
  end
end
