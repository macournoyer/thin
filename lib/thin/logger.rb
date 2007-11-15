require 'logger'

module Thin
  # Application wide logger
  def self.logger
    @@logger
  end
  
  def self.logger=(logger)
    @@logger = logger
  end
  
  # Default to outputing to the console
  self.logger = Logger.new(STDOUT)
end