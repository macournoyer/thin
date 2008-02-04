require File.dirname(__FILE__) + '/spec_helper'

describe Service do
  before do
    Thin.stub!(:linux?).and_return(true)
    # Service.silence = true
  end
  
  it "should call command with each config file"
  
  it "should create /etc/init.d/thin file when calling install"
  
  it "should include specified path in /etc/init.d/thin script"
  
  it "should output help message when calling install"
end