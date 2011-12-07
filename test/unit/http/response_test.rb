require 'test_helper'
require 'thin/protocols/http'

class HttpResponseTest < Test::Unit::TestCase
  def setup
    @response = Thin::Protocols::Http::Response.new
    @response.headers['Content-Type'] = 'text/html'
    @response.headers['Content-Length'] = '0'
    @response.body = ''
    @response.finish
  end

  def test_initialize_with_values
    @response = Thin::Protocols::Http::Response.new(201, {"Content-Type" => "text/plain"}, ["hi"])
    assert_equal 201, @response.status
    assert_match "Content-Type: text/plain", @response.headers.to_s
    assert_equal ["hi"], @response.body
  end

  def test_output_headers
    assert_match "Content-Type: text/html", @response.headers.to_s
    assert_match "Content-Length: 0", @response.headers.to_s
    assert_match "Connection: close", @response.headers.to_s
  end

  def test_include_server_name_header
    assert_match "Server: thin", @response.headers.to_s
  end

  def test_output_head
    assert_match /^HTTP\/1.1 200 OK/, @response.head
    assert_match /\r\n\r\n$/, @response.head
  end

  def test_allow_duplicates_on_some_headers
    @response.headers['Set-Cookie'] = 'mium=7'
    @response.headers['Set-Cookie'] = 'hi=there'

    assert_match "Set-Cookie: mium=7", @response.head
    assert_match "Set-Cookie: hi=there", @response.head
  end

  def test_parse_simple_header_values
    @response.headers = {
      'Host' => 'localhost'
    }

    assert_match "Host: localhost", @response.head
  end

  def test_parse_multiline_header_values_in_several_headers
    @response.headers = {
      'Set-Cookie' => "mium=7\nhi=there"
    }

    assert_match "Set-Cookie: mium=7", @response.head
    assert_match "Set-Cookie: hi=there", @response.head
  end

  def test_ignore__nil_headers
    @response.headers = nil
    @response.headers = { 'Host' => 'localhost' }
    @response.headers = { 'Set-Cookie' => nil }
    assert_no_match /Set-Cookie/, @response.head
  end

  def test_body
    @response.body = ['<html>', '</html>']

    out = ''
    @response.each { |l| out << l }
    assert_match /\r\n\r\n<html><\/html>$/, out
  end

  def test_string_body
    @response.body = '<html></html>'

    out = ''
    @response.each { |l| out << l }
    assert_match /\r\n\r\n<html><\/html>$/, out
  end

  def test_close
    @response.close
  end
end
