require File.dirname(__FILE__) + '/test_helper'
require 'thin/cluster'

class ClusterTest < Test::Unit::TestCase
  def setup
    FileUtils.mkdir_p File.dirname(__FILE__) + '/../log'
    
    @pwd = Dir.pwd
    
    Thin::Cluster.thin = File.expand_path(File.dirname(__FILE__) + '/../bin/thin')
    @cluster = Thin::Cluster.new(File.dirname(__FILE__) + '/rails_app', '0.0.0.0', 3000, 3)
    @cluster.silent = true
    @cluster.pid_file = File.expand_path(File.dirname(__FILE__) + '/cluster_test.pid')
    @cluster.log_file = File.expand_path(File.dirname(__FILE__) + '/../log/cluster_test.log')
  end
  
  def teardown
    3000.upto(3003) do |port|
      Process.kill 9, @cluster.pid_for(port) rescue nil
      File.delete @cluster.pid_file_for(port) rescue nil
    end
    
    Dir.chdir @pwd
  end
  
  def test_include_port_number
    assert_equal 'thin.3000.log', @cluster.send(:include_port_number, 'thin.log', 3000)
    assert_equal 'thin.3000.pid', @cluster.send(:include_port_number, 'thin.pid', 3000)
    assert_raise(ArgumentError) { @cluster.send(:include_port_number, 'thin', 3000) }
  end
  
  def test_with_each_instance
    calls = []
    @cluster.send(:with_each_instance) do |port|
      calls << port
    end
    assert_equal [3000, 3001, 3002], calls
  end
  
  def test_shellify
    out = @cluster.send(:shellify, :start, :port => 3000, :daemonize => true, :log_file => 'hi.log', :pid_file => nil)
    assert_match '--port=3000', out
    assert_match '--daemonize', out
    assert_match '--log-file="hi.log"', out
    assert_no_match %r'--pid-file=', out
    assert_match 'thin start --', out
  end
  
  def test_start_on_port
    @cluster.expects(:log).with { |t| t =~ /started in/ }
    
    @cluster.start_on_port 3000
    
    assert File.exist?(@cluster.pid_file_for(3000))
    assert File.exist?(@cluster.log_file_for(3000))
  end

  def test_stop_on_port
    @cluster.expects(:log)
    @cluster.expects(:log).with { |t| t =~ /stopped/ }
    
    @cluster.start_on_port 3000
    @cluster.stop_on_port 3000
    
    assert !File.exist?(@cluster.pid_file_for(3000))
  end
  
  def test_start_with_error
    @cluster.expects(:log).with { |t| t =~ /failed to start/ }

    Dir.chdir '../' # Switch to a non valid dir
    
    silence_stream STDERR do
      @cluster.start_on_port 3000
    end
  end
end