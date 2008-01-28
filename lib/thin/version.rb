module Thin
  class PlatformNotSupported < RuntimeError; end
  
  module VERSION #:nodoc:
    MAJOR    = 0
    MINOR    = 7
    TINY     = 0
    
    STRING   = [MAJOR, MINOR, TINY].join('.')
    
    CODENAME = 'Bionic Pickle'
  end
  
  def self.win?
    RUBY_PLATFORM =~ /mswin/
  end
  
  def self.ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end
end
