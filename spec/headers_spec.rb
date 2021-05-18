require 'spec_helper'

describe Headers do
  before do
    @headers = Headers.new
  end
  
  it 'should allow duplicate on some fields' do
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    expect(@headers.to_s).to eq("Set-Cookie: twice\r\nSet-Cookie: is cooler the once\r\n")
  end
  
  it 'should overwrite value on non duplicate fields' do
    @headers['Host'] = 'this is unique'
    @headers['Host'] = 'so is this'

    expect(@headers.to_s).to eq("Host: this is unique\r\n")
  end
  
  it 'should output to string' do
    @headers['Host'] = 'localhost:3000'
    @headers['Set-Cookie'] = 'twice'
    @headers['Set-Cookie'] = 'is cooler the once'
    
    expect(@headers.to_s).to eq("Host: localhost:3000\r\nSet-Cookie: twice\r\nSet-Cookie: is cooler the once\r\n")
  end

  it 'should ignore nil values' do
    @headers['Something'] = nil
    expect(@headers.to_s).not_to include('Something: ')
  end

  it 'should format Time values correctly' do
    time = Time.now
    @headers['Modified-At'] = time
    expect(@headers.to_s).to include("Modified-At: #{time.httpdate}")
  end

  it 'should format Integer values correctly' do
    @headers['X-Number'] = 32
    expect(@headers.to_s).to include("X-Number: 32")
  end

  it 'should not allow CRLF' do
    expect { @headers['Bad'] = "a\r\nSet-Cookie: injected=value" }.to raise_error(InvalidHeader)
  end

  it 'should not allow CR' do
    expect { @headers['Bad'] = "a\rSet-Cookie: injected=value" }.to raise_error(InvalidHeader)
  end

  it 'should not allow LF' do
    expect { @headers['Bad'] = "a\nSet-Cookie: injected=value" }.to raise_error(InvalidHeader)
  end
end