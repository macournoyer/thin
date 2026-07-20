# frozen_string_literal: true

# Try the old rack/handler (Rack 1 & 2), fall back to rackup/handler (Rack 3)
begin
  require 'rack/handler'
rescue LoadError
  require 'rackup/handler'
end

# Load Thin and its Logging module before we subclass
require 'thin'
require 'thin/logging'
require_relative '../../thin/rackup/handler'

module Rack
  module Handler
    class Thin < ::Thin::Rackup::Handler
    end

    register :thin, Thin.to_s
  end
end
