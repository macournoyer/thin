module Thin
  # Raised when a feature is not supported on the
  # current platform.
  class PlatformNotSupported < RuntimeError; end
  
  VERSION = "2.0.1"
  CODENAME = "Thinception".freeze
  
  NAME    = 'thin'.freeze
  SERVER  = "#{NAME} #{VERSION} codename #{CODENAME}".freeze
  
  def self.win?
    RUBY_PLATFORM =~ /mswin|mingw/
  end
  
  def self.linux?
    RUBY_PLATFORM =~ /linux/
  end
end
