class App
  def call(env)
    case env["PATH_INFO"]
    when "/"
      [200, {"Content-Type" => "text/plain", "Content-Length" => "2"}, ["ok"]]
    when "/crash"
      raise "ouch"
    when "/exit"
      exit!
    else
      [404, {"Content-Type" => "text/plain"}, ["Not found"]]
    end
  end
end

run App.new