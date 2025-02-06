# frozen_string_literal: true

require 'rackup/handler'
require_relative '../../thin/rackup/handler'

module Rackup
  module Handler
    class Thin < ::Thin::Rackup::Handler
    end

    register :thin, Thin
  end
end
