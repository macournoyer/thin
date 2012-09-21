class RackApp
  def call(env)
    body = env.inspect
    # Response
    [
      200, # status code
      { 'Content-Type' => 'text/plain', 'Content-Length' => body.size.to_s }, # headers
      [body] # body
    ]
  end
end

run RackApp.new