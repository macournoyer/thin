class Async
  def call(env)
    response = Thin::AsyncResponse.new(env)

    # Webkit requires some padding before displaying something.
    # response << " " * 1024
    
    response << "this is ... "
    # Will be sent to the browse 1 sec after.
    EM.add_timer(1) do
      response << "async stuff ... "
    end
    EM.add_timer(2) do
      response << "yeaaah!"
      response.done # close the connection
    end
    
    response.finish
  end
end

use Rack::Chunked

use Thin::Async do
  use Thin::Chunked
  use Rack::CommonLogger
end

run Async.new