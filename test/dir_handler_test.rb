require File.dirname(__FILE__) + '/test_helper'

class DirHandlerTest < Test::Unit::TestCase
  def setup
    @handler = Fart::DirHandler.new(File.dirname(__FILE__) + '/site')
    @response = Fart::Response.new
  end
  
  def test_processing_unexisting_file_returns_false  
    assert_equal false, @handler.process(TestRequest.new('/do_not_exist'), @response)
  end

  def test_processing_existing_file_returns_true
    @handler.expects(:serve_file).once
    assert_equal true, @handler.process(TestRequest.new('/index.html'), @response)
  end
  
  def test_processing_existing_dir_returns_true
    @handler.expects(:serve_dir).once
    assert_equal true, @handler.process(TestRequest.new('/images'), @response)
  end
  
  def test_serve_html_with_correct_content_type
    @handler.process(TestRequest.new('/images/fun.jpg'), @response)
    assert_equal 'image/jpeg', @response.content_type
  end
  
  def test_serve_image_with_correct_content_type
    @handler.process(TestRequest.new('/images/fun.jpg'), @response)
    assert_equal 'image/jpeg', @response.content_type
  end
  
  def test_serve_image_with_correct_content_length
    @handler.process(TestRequest.new('/images/fun.jpg'), @response)
    @response.head
    assert_equal File.size(File.dirname(__FILE__) + '/site/images/fun.jpg'), @response.headers['Content-Length']
  end
  
  def test_serve_dir_outputs_dir_listing
    @handler.process(TestRequest.new('/'), @response)
    @response.body.rewind
    body = @response.body.read
    assert_match '<h1>Listing /</h1>', body
    assert_match %Q{<li><a href="/images">images</a></li>}, body
    assert_match %Q{<li><a href="/index.html">index.html</a></li>}, body
  end

  def test_serve_sub_dir_outputs_dir_listing    
    @handler.process(TestRequest.new('/images'), @response)
    @response.body.rewind
    body = @response.body.read
    assert_match '<h1>Listing /images</h1>', body
    assert_match %Q{<li><a href="/images/fun.jpg">fun.jpg</a></li>}, body
  end
end