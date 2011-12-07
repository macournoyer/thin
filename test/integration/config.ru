require "thin/async"

class App
  def call(env)
    request = Rack::Request.new(env)
    
    case request.path_info
    when "/"
      Rack::Response.new do |response|
        response.write "ok"
      end.finish
      
    when "/env"
      Rack::Response.new do |response|
        env.each_pair do |key, value|
          response.write "#{key}: #{value}\n"
        end
        response.write "\n" + request.body.read
      end.finish
      
    when "/eval"
      Rack::Response.new do |response|
        response.write eval(request["code"]).to_s
      end.finish
      
    when "/raise"
      raise "ouch"
      
    when "/exit"
      exit!
      
    when "/sleep"
      sleep request["sec"].to_f
      
    when "/async"
      Thin::AsyncResponse.new(env) do |response|
        response << "1\n"
        # Will be sent to the browse 1 sec after.
        EM.add_timer(0.1) do
          response << "2\n"
          response.done # close the connection
        end
      end.finish
      
    else
      Rack::Response.new do |response|
        response.status = 404
        response.write "ok"
      end.finish
      
    end
  end
end

run App.new