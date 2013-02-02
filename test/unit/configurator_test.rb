require 'test_helper'
require "thin/configurator"

class ConfiguratorTest < Test::Unit::TestCase
  class MockMiddleware
    def initialize(app, response)
      @app = app
      @response = response
    end

    def call(env)
      Rack::Response.new(@response).finish
    end
  end
  
  class MockApp
    def initialize(response)
      @response = response
    end

    def call(env)
      Rack::Response.new(@response).finish
    end
  end

  def setup
    @config = Thin::Configurator.new
  end

  def test_worker_processes
    @config.worker_processes 5
    assert_equal 5, @config.options[:worker_processes]
    assert_raise(ArgumentError) { @config.worker_processes "5" }
  end

  def test_use_epoll
    @config.use_epoll true
    @config.use_epoll false
    assert_raise(ArgumentError) { @config.use_epoll 1 }
  end

  def test_listen
    @config.listen 3000
    @config.listen "0.0.0.0:3000"
    assert_raise(ArgumentError) { @config.listen false }
    assert_equal 2, @config.options[:listeners].size
  end

  def test_before_fork
    @config.before_fork { :ok }
    assert_equal :ok, @config.options[:before_fork].call(:server)
  end

  def test_use
    @config.use MockMiddleware, "ok"
    @config.builder.run(MockApp.new("app"))
    assert_equal "ok", Rack::MockRequest.new(@config.builder).get("/").body
  end

  def test_map
    @config.map '/ok' do
      use MockMiddleware, "ok"
    end
    @config.builder.run(MockApp.new("app"))
    request = Rack::MockRequest.new(@config.builder)

    assert_equal "app", request.get("/").body
    assert_equal "ok", request.get("/ok").body
  end

  def test_load_from_file
    Thin::Configurator.load(File.expand_path("../../fixtures/thin.conf.rb", __FILE__))
  end

  def test_apply_options
    server = Thin::Server.new {}
    @config.worker_processes 10000
    @config.apply_options(server)
    assert_equal 10000, server.worker_processes
  end
end
