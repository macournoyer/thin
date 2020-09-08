require 'spec_helper'

describe Server, 'on TCP socket' do
  before do
    start_server do |env|
      body = env.inspect + env['rack.input'].read
      [200, { 'Content-Type' => 'text/html' }, body]
    end
  end
  
  it 'should GET from Net::HTTP' do
    expect(get('/?cthis')).to include('cthis')
  end
  
  it 'should GET from TCPSocket' do
    status, headers, body = parse_response(send_data("GET /?this HTTP/1.0\r\nConnection: close\r\n\r\n"))
    expect(status).to eq(200)
    expect(headers['Content-Type']).to eq('text/html')
    expect(headers['Connection']).to eq('close')
    expect(body).to include('this')
  end
  
  it 'should return empty string on incomplete headers' do
    expect(send_data("GET /?this HTTP/1.1\r\nHost:")).to be_empty
  end
  
  it 'should return empty string on incorrect Content-Length' do
    expect(send_data("POST / HTTP/1.1\r\nContent-Length: 300\r\nConnection: close\r\n\r\naye")).to be_empty
  end
  
  it 'should POST from Net::HTTP' do
    expect(post('/', :arg => 'pirate')).to include('arg=pirate')
  end
  
  it 'should handle big POST' do
    big = 'X' * (20 * 1024)
    expect(post('/', :big => big)).to include(big)
  end
  
  it "should retreive remote address" do
    expect(get('/')).to include('"REMOTE_ADDR"=>"127.0.0.1"')
  end
  
  after do
    stop_server
  end
end
