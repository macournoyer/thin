require File.dirname(__FILE__) + '/test_helper'
require 'thin/cluster'

class ClusterTest < Test::Unit::TestCase
  def setup
    @cluster = Thin::Cluster.new('0.0.0.0', 3000, 3)
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
  
  def test_start
    @cluster.expects(:start_on_port).times(3)
    @cluster.start
  end
  
  def test_start_on_port
    server = mock('server')
    Thin::Server.expects(:new).with('0.0.0.0', 3001).returns(server)
    logger = mock('logger')
    Logger.expects(:new).with('thin.3001.log').returns(logger)
    server.expects(:logger=).with(logger)
    Thin::Daemonizer.any_instance.expects(:daemonize)
    
    @cluster.send(:start_on_port, 3001)
  end
  
  def test_stop
    @cluster.expects(:stop_on_port).times(3)
    @cluster.stop
  end
  
  def test_stop_on_port
    Thin::Daemonizer.any_instance.expects(:kill)
    
    @cluster.send(:stop_on_port, 3002)
  end
  
  def test_restart
    @cluster.expects(:stop_on_port).with(3000)
    @cluster.expects(:start_on_port).with(3000)
    
    @cluster.expects(:stop_on_port).with(3001)
    @cluster.expects(:start_on_port).with(3001)
    
    @cluster.expects(:stop_on_port).with(3002)
    @cluster.expects(:start_on_port).with(3002)
    
    @cluster.restart
  end
end