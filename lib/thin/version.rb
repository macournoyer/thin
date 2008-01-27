module Thin
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
  
  class PlatformNotSupported < RuntimeError; end
end
