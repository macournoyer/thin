class Echo < EventMachine::Connection
  attr_accessor :server

  def receive_data(data)
    send_data data
    close_connection_after_writing
  end
end
