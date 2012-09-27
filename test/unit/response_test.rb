require 'test_helper'
require 'thin/response'

class ResponseTest < Test::Unit::TestCase
  def setup
    @response = Thin::Response.new
    @response.headers['Content-Type'] = 'text/html'
    @response.headers['Content-Length'] = '0'
    @response.headers['x-thin'] = '2'
    @response.body = ''
    @response.finish
  end

  def test_initialize_with_values
    @response = Thin::Response.new(201, {"Content-Type" => "text/plain"}, ["hi"])
    assert_equal 201, @response.status
    assert_match "Content-Type: text/plain", @response.head
    assert_equal ["hi"], @response.body
  end

  def test_output_headers
    assert_match "Content-Type: text/html", @response.head
    assert_match "Content-Length: 0", @response.head
    assert_match "Connection: close", @response.head
  end

  def test_include_server_name_header
    assert_match "Server: thin", @response.head
  end

  def test_output_head
    assert_match /^HTTP\/1.1 200 OK/, @response.head
    assert_match /\r\n\r\n$/, @response.head
  end

  def test_parse_simple_header_values
    @response.headers = {
      'Host' => 'localhost'
    }

    assert_match "Host: localhost", @response.head
  end

  def test_parse_multiline_header_values_in_several_headers
    @response.headers['Set-Cookie'] = "mium=7\nhi=there"

    assert_match "Set-Cookie: mium=7", @response.head
    assert_match "Set-Cookie: hi=there", @response.head
  end

  def test_ignore__nil_headers
    @response.headers = { 'Set-Cookie' => nil }
    assert_no_match /Set-Cookie/, @response.head
  end

  def test_body
    @response.body = ['<html>', '</html>']

    out = ''
    @response.each { |l| out << l }
    assert_match /\r\n\r\n<html><\/html>$/, out
  end

  def test_close
    @response.close
  end

  def test_async
    assert Thin::Response.new(*Thin::Response::ASYNC).async?
  end

  def test_no_duplicated_with_different_character_case
    size = @response.headers.size
    @response.headers['X-Thin'] = '2'
    assert_equal size, @response.headers.size
  end

  def test_header_name_character_case
    assert_match /x-thin: 2/i, @response.head
    @response.headers['X-Thin'] = '2.1'
    assert_match /x-thin: 2\.1/i, @response.head
  end
end
