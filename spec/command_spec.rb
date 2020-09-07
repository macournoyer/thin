require 'spec_helper'

describe Command do
  before do
    Command.script = 'thin'
    @command = Command.new(:start, :port => 3000, :daemonize => true, :log => 'hi.log',
                           :require => %w(rubygems thin), :no_epoll => true)
  end
  
  it 'should shellify command' do
    out = @command.shellify
    expect(out).to include('--port=3000', '--daemonize', '--log="hi.log"', 'thin start --')
    expect(out).not_to include('--pid')
  end
  
  it 'should shellify Array argument to multiple parameters' do
    out = @command.shellify
    expect(out).to include('--require="rubygems"', '--require="thin"')
  end

  it 'should convert _ to - in option name' do
    out = @command.shellify
    expect(out).to include('--no-epoll')
  end
end