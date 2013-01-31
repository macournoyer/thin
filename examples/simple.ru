class Simple
  def call(env)
    [200, {'Content-Type' => 'text/plain', 'Content-Length' => '2'}, ['ok']]
  end
end

run Simple.new