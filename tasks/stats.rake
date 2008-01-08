desc 'Show some stats about the code'
task :stats do
  line_count = proc do |path|
    Dir[path].collect { |f| File.open(f).readlines.reject { |l| l =~ /(^\s*(\#|\/\*))|^\s*$/ }.size }.inject(0){ |sum,n| sum += n }
  end
  lib = line_count['lib/**/*.rb']
  ext = line_count['ext/**/*.{c,h}'] 
  spec = line_count['spec/**/*.rb']
  ratio = '%1.2f' % (spec.to_f / lib.to_f)
  
  puts "#{lib.to_s.rjust(6)} LOC of lib"
  puts "#{ext.to_s.rjust(6)} LOC of ext"
  puts "#{spec.to_s.rjust(6)} LOC of spec"
  puts "#{ratio.to_s.rjust(6)} ratio lib/spec"
end
