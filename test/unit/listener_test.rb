require 'test_helper'

class ListenerTest < Test::Unit::TestCase
  def test_parse_integer_port_addresses
    listener = Thin::Listener.parse(3000)
    assert_nil listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_star_port_addresses
    listener = Thin::Listener.parse("*:3000")
    assert_nil listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_host_and_port
    listener = Thin::Listener.parse("127.0.0.1:3000")
    assert_equal "127.0.0.1", listener.host
    assert_equal 3000, listener.port
  end

  def test_socket
    listener = Thin::Listener.parse(3000)
    assert_kind_of Socket, listener.socket
  ensure
    listener.close
  end

  def test_set_socket_option
    listener = Thin::Listener.parse(3000)
    listener.tcp_no_delay = true
    assert listener.socket.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY)
  ensure
    listener.close
  end
end
