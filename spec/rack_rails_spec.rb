require File.dirname(__FILE__) + '/spec_helper'
require 'rack/mock'

begin
  gem 'rails', '= 2.0.2' # We could freeze Rails in the rails_app dir to remove this

  context Rack::Adapter::Rails do
    before do
      rails_app_path = File.dirname(__FILE__) + '/rails_app'
      @request = Rack::MockRequest.new(Rack::Adapter::Rails.new(:root => rails_app_path))
    end
  
    it "should handle simple GET request" do
      res = @request.get("/simple", :lint => true)

      res.should be_ok
      res["Content-Type"].should include("text/html")

      res.body.should include('Simple#index')
    end

    it "should handle POST parameters" do
      data = "foo=bar"
      res = @request.post("/simple/post_form", :input => data, 'CONTENT_LENGTH' => data.size)

      res.should be_ok
      res["Content-Type"].should include("text/html")
      res["Content-Length"].should_not be_nil
    
      res.body.should include('foo: bar')
    end
  
    it "should serve static files" do
      res = @request.get("/index.html")

      res.should be_ok
      res["Content-Type"].should include("text/html")
    end
    
    it "handles multiple cookies" do
      res = @request.get('/simple/set_cookie?name=a&value=1')
    
      res.should be_ok
    
      res.headers['Set-Cookie'].should include("a=1; path=/\n")
      res.headers['Set-Cookie'].last.should match(/^_rails_app_session=.*; path=\/$/)
    end
  end

rescue Gem::LoadError
  warn 'Rails 2.0.2 is required to run the Rails adapter specs'
end
