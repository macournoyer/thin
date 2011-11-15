module Thin
  module System
    def self.win?
      RUBY_PLATFORM =~ /mswin|mingw/
    end

    def self.linux?
      RUBY_PLATFORM =~ /linux/
    end

    def self.ruby_18?
      RUBY_VERSION =~ /^1\.8/
    end
    
    # Source: https://github.com/grosser/parallel/blob/master/lib/parallel.rb#L65-84
    def self.processor_count
      architecture = RbConfig::CONFIG['host_os']
      case architecture = RbConfig::CONFIG['host_os']
      when /darwin9/
        `hwprefs cpu_count`.to_i
      when /darwin/
        (`which hwprefs` != '' ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      when /linux/
        `grep -c processor /proc/cpuinfo`.to_i
      when /freebsd/
        `sysctl -n hw.ncpu`.to_i
      when /mswin|mingw/
        require 'win32ole'
        wmi = WIN32OLE.connect("winmgmts://")
        cpu = wmi.ExecQuery("select NumberOfLogicalProcessors from Win32_Processor")
        cpu.to_enum.first.NumberOfLogicalProcessors
      else
        warn "Unknown architecture ( #{architecture} ) assuming one processor."
        1
      end
    end
  end
end