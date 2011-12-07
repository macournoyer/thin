require 'test_helper'

class ListenerTest < Test::Unit::TestCase
  def test_parse_integer_port_addresses
    listener = Thin::Listener.parse(3000)
    assert_equal "", listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_star_port_addresses
    listener = Thin::Listener.parse("*:3000")
    assert_equal "", listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_ipv4_and_port
    listener = Thin::Listener.parse("127.0.0.1:3000")
    assert_equal "127.0.0.1", listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_ipv6_and_port
    listener = Thin::Listener.parse("[::]:3000")
    assert_equal "::", listener.host
    assert_equal 3000, listener.port
  end

  def test_parse_unix_socket
    listener = Thin::Listener.parse("/file.sock")
    assert_nil listener.host
    assert_nil listener.port
    assert_equal "/file.sock", listener.socket_file
  end

  def test_parse_relative_unix_socket_with_prefix
    listener = Thin::Listener.parse("unix:file.sock")
    assert_nil listener.host
    assert_nil listener.port
    assert_equal "file.sock", listener.socket_file
  end

  def test_parse_invalid_address
    assert_raise(ArgumentError) { Thin::Listener.parse("file.sock") }
  end

  def test_ipv4_socket
    listener = Thin::Listener.parse(3000)
    assert_kind_of Socket, listener.socket
  ensure
    listener.close
  end

  def test_ipv6_socket
    listener = Thin::Listener.parse("[::]:3000")
    assert_kind_of Socket, listener.socket
  ensure
    listener.close
  end

  def test_unix_socket
    listener = Thin::Listener.parse("/tmp/thin-test.sock")
    assert_kind_of Socket, listener.socket
  ensure
    listener.close
    assert ! File.exist?("tmp/thin-test.sock")
  end

  def test_set_socket_option
    listener = Thin::Listener.parse(3000)
    listener.tcp_no_delay = true
    assert listener.socket.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY)
  ensure
    listener.close
  end
end
