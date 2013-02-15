require "eventmachine-le"
require "rack"

module Thin
  module Backends
    autoload :Prefork, "thin/backends/prefork"
    autoload :SingleProcess, "thin/backends/single_process"
  end

  autoload :Configurator, "thin/configurator"
  autoload :Connection, "thin/connection"
  autoload :FastEnumerator, "thin/fast_enumerator"
  autoload :Listener, "thin/listener"
  autoload :Request, "thin/request"
  autoload :Response, "thin/response"
  autoload :Runner, "thin/runner"
  autoload :Server, "thin/server"
  autoload :System, "thin/system"
  autoload :Version, "thin/version"

  # Middlewares
  autoload :Async, "thin/middlewares/async"
  autoload :CatchAsync, "thin/middlewares/catch_async"
  autoload :Chunked, "thin/middlewares/chunked"
  autoload :StreamFile, "thin/middlewares/stream_file"
  autoload :Streamed, "thin/middlewares/streamed"
  autoload :Threaded, "thin/middlewares/threaded"
end