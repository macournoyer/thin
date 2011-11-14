require "thin/connection"

module Thin
  class Acceptor < EM::Connection
    attr_accessor :server
    
    def post_init
      self.notify_readable = true
    end
    
    def notify_readable
      io = @io.kgio_tryaccept or return
      EM.attach(io, Connection) { |c| c.server = @server }
    end
  end
end