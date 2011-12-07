class Echo < EventMachine::Connection
  def receive_data(data)
    send_data data
    close_connection_after_writing
  end
end
