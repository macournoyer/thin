require 'spec_helper'

describe Request, 'persistent' do
  before do
    @request = Request.new
  end
  
  it "should not assume that a persistent connection is maintained for HTTP version 1.0" do
    @request.env['HTTP_VERSION'] = 'HTTP/1.0'
    expect(@request).not_to be_persistent
  end

  it "should assume that a persistent connection is maintained for HTTP version 1.0 when specified" do
    @request.env['HTTP_VERSION'] = 'HTTP/1.0'
    @request.env['HTTP_CONNECTION'] = 'Keep-Alive'
    expect(@request).to be_persistent
  end
  
  it "should maintain a persistent connection for HTTP/1.1 client" do
    @request.env['HTTP_VERSION'] = 'HTTP/1.1'
    @request.env['HTTP_CONNECTION'] = 'Keep-Alive'
    expect(@request).to be_persistent
  end

  it "should maintain a persistent connection for HTTP/1.1 client by default" do
    @request.env['HTTP_VERSION'] = 'HTTP/1.1'
    expect(@request).to be_persistent
  end

  it "should not maintain a persistent connection for HTTP/1.1 client when Connection header include close" do
    @request.env['HTTP_VERSION'] = 'HTTP/1.1'
    @request.env['HTTP_CONNECTION'] = 'close'
    expect(@request).not_to be_persistent
  end
end