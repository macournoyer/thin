require 'spec_helper'

describe Server, 'app builder' do

  before :all do
    Logging.debug = false
  end

  it "should build app from constructor" do
    app = proc {}
    server = Server.new('0.0.0.0', 3000, app)
    
    expect(server.app).to eq(app)
  end
  
  it "should build app from builder block" do
    server = Server.new '0.0.0.0', 3000 do
      run(proc { |env| :works })
    end
    
    expect(server.app.call({})).to eq(:works)
  end
  
  it "should use middlewares in builder block" do
    server = Server.new '0.0.0.0', 3000 do
      use Rack::ShowExceptions
      run(proc { |env| :works })
    end
    
    expect(server.app.class).to eq(Rack::ShowExceptions)
    expect(server.app.call({})).to eq(:works)
  end
  
  it "should work with Rack url mapper" do
    server = Server.new '0.0.0.0', 3000 do
      map '/test' do
        run(proc { |env| [200, {}, 'Found /test'] })
      end
    end
    
    default_env = { 'SCRIPT_NAME' => '' }
    
    expect(server.app.call(default_env.update('PATH_INFO' => '/'))[0]).to eq(404)
    
    status, headers, body = server.app.call(default_env.update('PATH_INFO' => '/test'))
    expect(status).to eq(200)
    expect(body).to eq('Found /test')
  end
end
