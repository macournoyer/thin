require File.dirname(__FILE__) + '/spec_helper'

describe Command do
  before do
    @command = Command.new(:start, :port => 3000, :daemonize => true, :log => 'hi.log', :pid => nil)
    @command.silent = true
  end
  
  it 'should shellify command' do
    out = @command.shellify
    out.should include('--port=3000', '--daemonize', '--log="hi.log"', 'thin start --')
    out.should_not include('--pid=')
  end
end