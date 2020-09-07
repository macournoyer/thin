require 'spec_helper'

describe Rack::Adapter do
  before do
    @config_ru_path = File.dirname(__FILE__) + '/../../example'
    @rails_path = File.dirname(__FILE__) + '/../rails_app'
  end
  
  it "should load Rack app from config" do
    expect(Rack::Adapter.load(@config_ru_path + '/config.ru').class).to eq(Proc)
  end
  
  it "should guess Rack app from dir" do
    expect(Rack::Adapter.guess(@config_ru_path)).to eq(:rack)
  end
  
  it "should guess rails app from dir" do
    expect(Rack::Adapter.guess(@rails_path)).to eq(:rails)
  end
  
  it "should return nil when can't guess from dir" do
    expect { Rack::Adapter.guess('.') }.to raise_error(Rack::AdapterNotFound)
  end
  
  it "should load Rack adapter" do
    expect(Rack::Adapter.for(:rack, :chdir => @config_ru_path).class).to eq(Proc)
  end
  
  it "should load Rails adapter" do
    expect(Rack::Adapter::Rails).to receive(:new)
    Rack::Adapter.for(:rails, :chdir => @rails_path)
  end
  
  it "should load File adapter" do
    expect(Rack::File).to receive(:new)
    Rack::Adapter.for(:file)
  end
  
  it "should raise error when adapter can't be found" do
    expect { Rack::Adapter.for(:fart, {}) }.to raise_error(Rack::AdapterNotFound)
  end
end