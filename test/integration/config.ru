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
      
    when "/crash"
      raise "ouch"
      
    when "/exit"
      exit!
      
    when "/sleep"
      sleep request["sec"].to_f
      
    else
      Rack::Response.new do |response|
        response.status = 404
        response.write "ok"
      end.finish
      
    end
  end
end

run App.new