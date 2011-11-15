class App
  def call(env)
    request = Rack::Request.new(env)
    case request.path_info
    when "/"
      [200, {"Content-Type" => "text/plain", "Content-Length" => "2"}, ["ok"]]
    when "/crash"
      raise "ouch"
    when "/exit"
      exit!
    when "/sleep"
      sleep request["sec"].to_f
    else
      [404, {"Content-Type" => "text/plain"}, ["Not found"]]
    end
  end
end

run App.new