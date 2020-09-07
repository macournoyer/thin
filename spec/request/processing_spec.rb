require 'spec_helper'

describe Request, 'processing' do
  it 'should parse in chunks' do
    request = Request.new
    expect(request.parse("POST / HTTP/1.1\r\n")).to be_falsey
    expect(request.parse("Host: localhost\r\n")).to be_falsey
    expect(request.parse("Content-Length: 9\r\n")).to be_falsey
    expect(request.parse("\r\nvery ")).to be_falsey
    expect(request.parse("cool")).to be_truthy

    expect(request.env['CONTENT_LENGTH']).to eq('9')
    expect(request.body.read).to eq('very cool')
    expect(request).to validate_with_lint
  end

  it "should move body to tempfile when too big" do
    len = Request::MAX_BODY + 2
    request = Request.new
    request.parse("POST /postit HTTP/1.1\r\nContent-Length: #{len}\r\n\r\n#{'X' * (len/2)}")
    request.parse('X' * (len/2))

    expect(request.body.size).to eq(len)
    expect(request).to be_finished
    expect(request.body.class).to eq(Tempfile)
  end

  it "should delete body tempfile when closing" do
    body = 'X' * (Request::MAX_BODY + 1)

    request = Request.new
    request.parse("POST /postit HTTP/1.1\r\n")
    request.parse("Content-Length: #{body.size}\r\n\r\n")
    request.parse(body)

    expect(request.body.path).not_to be_nil
    request.close
    expect(request.body.path).to be_nil
  end

  it "should close body tempfile when closing" do
    body = 'X' * (Request::MAX_BODY + 1)

    request = Request.new
    request.parse("POST /postit HTTP/1.1\r\n")
    request.parse("Content-Length: #{body.size}\r\n\r\n")
    request.parse(body)

    expect(request.body.closed?).to be_falsey
    request.close
    expect(request.body.closed?).to be_truthy
  end

  it "should raise error when header is too big" do
    big_headers = "X-Test: X\r\n" * (1024 * (80 + 32))
    expect { R("GET / HTTP/1.1\r\n#{big_headers}\r\n") }.to raise_error(InvalidRequest)
  end

  it "should set body external encoding to ASCII_8BIT" do
    pending("Ruby 1.9 compatible implementations only") unless StringIO.instance_methods.include? :external_encoding
    expect(Request.new.body.external_encoding).to eq(Encoding::ASCII_8BIT)
  end
end
