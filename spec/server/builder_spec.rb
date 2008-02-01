require File.dirname(__FILE__) + '/../spec_helper'

describe Server, 'app builder' do
  it "should build app from constructor" do
    server = Server.new('0.0.0.0', 3000, :works)
    
    server.app.should == :works
  end
  
  it "should build app from builder block" do
    server = Server.new '0.0.0.0', 3000 do
      run(proc { |env| :works })
    end
    
    server.app.call({}).should == :works
  end
  
  it "should use middlewares in builder block" do
    server = Server.new '0.0.0.0', 3000 do
      use Rack::ShowExceptions
      run(proc { |env| :works })
    end
    
    server.app.class.should == Rack::ShowExceptions
    server.app.call({}).should == :works
  end
  
  it "should work with Rack url mapper" do
    server = Server.new '0.0.0.0', 3000 do
      map '/test' do
        run(proc { |env| :works })
      end
    end
    
    server.app.call({})[0].should == 404
    server.app.call({'PATH_INFO' => '/test'}).should == :works
  end
end
