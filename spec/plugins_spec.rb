require File.dirname(__FILE__) + '/spec_helper'

describe Plugins do
  before do
    Gem::SourceIndex.should_receive(:from_installed_gems).and_return([
      ['rails-10.6.0',    stub('rails-gemspec',       :name => 'rails')],
      ['thin-1.0',        stub('thin-gemspec',        :name => 'thin')],
      ['thin-plugin-1.0', stub('thin-plugin-gemspec', :name => 'thin-plugin')],
      ['thin-plugin-0.5', stub('thin-plugin-gemspec', :name => 'thin-plugin')],
      ['thin_plugin-0.5', stub('thin_plugin-gemspec', :name => 'thin_plugin')]
    ])
  end
  
  it 'should return all gems that start with thin- or thin_' do
    Plugins.gems.should == ['thin-plugin', 'thin_plugin']
  end
  
  it "should load all gems" do
    Plugins.should_receive(:require).with('thin-plugin')
    Plugins.should_receive(:require).with('thin_plugin')
    Plugins.load
  end
end