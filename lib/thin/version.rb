module Thin
  # Raised when a feature is not supported on the
  # current platform.
  class PlatformNotSupported < RuntimeError; end
  
  module VERSION #:nodoc:
    MAJOR    = 0
    MINOR    = 6
    TINY     = 2
    
    STRING   = [MAJOR, MINOR, TINY].join('.')
    
    CODENAME = 'Rambo'
  end
  
  def self.win?
    RUBY_PLATFORM =~ /mswin/
  end
  
  def self.ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end
end
