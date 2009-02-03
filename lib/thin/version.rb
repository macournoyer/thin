module Thin  
  # Raised when a feature is not supported on the
  # current platform.
  class PlatformNotSupported < RuntimeError; end
  
  module VERSION #:nodoc:
    MAJOR    = 1
    MINOR    = 1
    TINY     = 0
    
    STRING   = [MAJOR, MINOR, TINY].join('.')
    
    CODENAME = "Super Disco Power".freeze
    
    RACK     = [0, 1].freeze # Rack protocol version that was tested
  end
  
  NAME    = 'thin'.freeze
  SERVER  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze  
  
  def self.win?
    RUBY_PLATFORM =~ /mswin/
  end
  
  def self.linux?
    RUBY_PLATFORM =~ /linux/
  end
  
  def self.ruby_18?
    RUBY_VERSION =~ /^1\.8/
  end
end
