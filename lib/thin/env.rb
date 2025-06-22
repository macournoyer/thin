
module Thin
  module Env
    def self.with_defaults(env)
      if ::Rack.release >= "3"
        rack_env_class = Rack3
      else
        rack_env_class = Rack2
      end

      rack_env_class.env.merge(env)
    end
  end

  private

  class Rack2
    RACK_VERSION = [1, 0].freeze

    def self.env
      {
        ::Thin::Request::RACK_VERSION      => RACK_VERSION,
        ::Thin::Request::RACK_MULTITHREAD  => false,
        ::Thin::Request::RACK_MULTIPROCESS => false,
        ::Thin::Request::RACK_RUN_ONCE     => false
      }
    end
  end

  class Rack3
    def self.env
      {}
    end
  end
end
