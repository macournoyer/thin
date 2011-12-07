require 'test_helper'

class EnvTest < IntegrationTestCase
  def test_get
    thin

    get '/env?hi=there'

    assert_status 200
    assert_response_includes "REMOTE_ADDR: 127.0.0.1"
    assert_response_includes "SERVER_SOFTWARE: thin"
    assert_response_includes "HTTP_HOST: localhost:8181"
    assert_response_includes "SERVER_PORT: 8181"
    assert_response_includes "SERVER_NAME: localhost"
    assert_response_includes "REQUEST_METHOD: GET"
    assert_response_includes "PATH_INFO: /env"
    assert_response_includes "QUERY_STRING: hi=there"
    assert_response_includes "rack.url_scheme: http"
    assert_response_includes "rack.multithread: false"
    assert_response_includes "rack.multiprocess: true"
    assert_response_includes "rack.run_once: false"
  end

  def test_post
    thin

    post '/env', :hi => "there"

    assert_status 200
    assert_response_includes "REMOTE_ADDR: 127.0.0.1"
    assert_response_includes "SERVER_SOFTWARE: thin"
    assert_response_includes "HTTP_HOST: localhost:8181"
    assert_response_includes "SERVER_PORT: 8181"
    assert_response_includes "SERVER_NAME: localhost"
    assert_response_includes "REQUEST_METHOD: POST"
    assert_response_includes "PATH_INFO: /env"
    assert_response_includes "QUERY_STRING: \n"
    assert_response_includes "rack.url_scheme: http"
    assert_response_includes "rack.multithread: false"
    assert_response_includes "rack.multiprocess: true"
    assert_response_includes "rack.run_once: false"
    assert_response_includes "\n\nhi=there"
  end
end
