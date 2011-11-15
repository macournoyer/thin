module Thin
  module VERSION
    MAJOR    = 2
    MINOR    = 0
    TINY     = 0

    STRING   = [MAJOR, MINOR, TINY].join('.')

    CODENAME = "The Wire Burner".freeze

    RACK     = [1, 1].freeze # Rack protocol version
  end
  
  NAME    = 'thin'.freeze
  SERVER  = "#{NAME} #{VERSION::STRING} codename #{VERSION::CODENAME}".freeze
end
