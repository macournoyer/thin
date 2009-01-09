--- !ruby/object:Gem::Specification 
name: thin
version: !ruby/object:Gem::Version 
  version: 1.0.1
platform: ruby
authors: 
- Marc-Andre Cournoyer
autorequire: 
bindir: bin
cert_chain: []

date: 2008-12-16 00:00:00 -05:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: rack
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 0.3.0
    version: 
- !ruby/object:Gem::Dependency 
  name: eventmachine
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 0.12.0
    version: 
- !ruby/object:Gem::Dependency 
  name: daemons
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 1.0.9
    version: 
description: A thin and fast web server
email: macournoyer@gmail.com
executables: 
- thin
extensions: 
- ext/thin_parser/extconf.rb
extra_rdoc_files: []

files: 
- COPYING
- CHANGELOG
- COMMITTERS
- README
- Rakefile
- benchmark/abc
- benchmark/benchmarker.rb
- benchmark/runner
- bin/thin
- doc/rdoc
- doc/rdoc/classes
- doc/rdoc/classes/Process.html
- doc/rdoc/classes/Rack
- doc/rdoc/classes/Rack/Adapter
- doc/rdoc/classes/Rack/Adapter/Rails
- doc/rdoc/classes/Rack/Adapter/Rails/CGIWrapper.html
- doc/rdoc/classes/Rack/Adapter/Rails.html
- doc/rdoc/classes/Rack/Adapter.html
- doc/rdoc/classes/Rack/AdapterNotFound.html
- doc/rdoc/classes/Rack/Handler
- doc/rdoc/classes/Rack/Handler/Thin.html
- doc/rdoc/classes/Rack/Handler.html
- doc/rdoc/classes/Rack.html
- doc/rdoc/classes/Thin
- doc/rdoc/classes/Thin/Backends
- doc/rdoc/classes/Thin/Backends/Base.html
- doc/rdoc/classes/Thin/Backends/SwiftiplyClient.html
- doc/rdoc/classes/Thin/Backends/TcpServer.html
- doc/rdoc/classes/Thin/Backends/UnixServer.html
- doc/rdoc/classes/Thin/Backends.html
- doc/rdoc/classes/Thin/Command.html
- doc/rdoc/classes/Thin/Connection.html
- doc/rdoc/classes/Thin/Controllers
- doc/rdoc/classes/Thin/Controllers/Cluster.html
- doc/rdoc/classes/Thin/Controllers/Controller.html
- doc/rdoc/classes/Thin/Controllers/Service.html
- doc/rdoc/classes/Thin/Controllers.html
- doc/rdoc/classes/Thin/Daemonizable
- doc/rdoc/classes/Thin/Daemonizable/ClassMethods.html
- doc/rdoc/classes/Thin/Daemonizable.html
- doc/rdoc/classes/Thin/Headers.html
- doc/rdoc/classes/Thin/InvalidOption.html
- doc/rdoc/classes/Thin/InvalidRequest.html
- doc/rdoc/classes/Thin/Logging.html
- doc/rdoc/classes/Thin/OptionRequired.html
- doc/rdoc/classes/Thin/PidFileExist.html
- doc/rdoc/classes/Thin/PlatformNotSupported.html
- doc/rdoc/classes/Thin/Request.html
- doc/rdoc/classes/Thin/Response.html
- doc/rdoc/classes/Thin/Runner.html
- doc/rdoc/classes/Thin/RunnerError.html
- doc/rdoc/classes/Thin/Server.html
- doc/rdoc/classes/Thin/Stats
- doc/rdoc/classes/Thin/Stats/Adapter.html
- doc/rdoc/classes/Thin/Stats.html
- doc/rdoc/classes/Thin/SwiftiplyConnection.html
- doc/rdoc/classes/Thin/UnixConnection.html
- doc/rdoc/classes/Thin.html
- doc/rdoc/created.rid
- doc/rdoc/files
- doc/rdoc/files/bin
- doc/rdoc/files/bin/thin.html
- doc/rdoc/files/lib
- doc/rdoc/files/lib/rack
- doc/rdoc/files/lib/rack/adapter
- doc/rdoc/files/lib/rack/adapter/loader_rb.html
- doc/rdoc/files/lib/rack/adapter/rails_rb.html
- doc/rdoc/files/lib/rack/handler
- doc/rdoc/files/lib/rack/handler/thin_rb.html
- doc/rdoc/files/lib/thin
- doc/rdoc/files/lib/thin/backends
- doc/rdoc/files/lib/thin/backends/base_rb.html
- doc/rdoc/files/lib/thin/backends/swiftiply_client_rb.html
- doc/rdoc/files/lib/thin/backends/tcp_server_rb.html
- doc/rdoc/files/lib/thin/backends/unix_server_rb.html
- doc/rdoc/files/lib/thin/command_rb.html
- doc/rdoc/files/lib/thin/connection_rb.html
- doc/rdoc/files/lib/thin/controllers
- doc/rdoc/files/lib/thin/controllers/cluster_rb.html
- doc/rdoc/files/lib/thin/controllers/controller_rb.html
- doc/rdoc/files/lib/thin/controllers/service_rb.html
- doc/rdoc/files/lib/thin/daemonizing_rb.html
- doc/rdoc/files/lib/thin/headers_rb.html
- doc/rdoc/files/lib/thin/logging_rb.html
- doc/rdoc/files/lib/thin/request_rb.html
- doc/rdoc/files/lib/thin/response_rb.html
- doc/rdoc/files/lib/thin/runner_rb.html
- doc/rdoc/files/lib/thin/server_rb.html
- doc/rdoc/files/lib/thin/stats_rb.html
- doc/rdoc/files/lib/thin/statuses_rb.html
- doc/rdoc/files/lib/thin/version_rb.html
- doc/rdoc/files/lib/thin_rb.html
- doc/rdoc/files/README.html
- doc/rdoc/index.html
- doc/rdoc/logo.gif
- doc/rdoc/rdoc-style.css
- example/adapter.rb
- example/config.ru
- example/monit_sockets
- example/monit_unixsock
- example/myapp.rb
- example/ramaze.ru
- example/thin.god
- example/thin_solaris_smf.erb
- example/thin_solaris_smf.readme.txt
- example/vlad.rake
- lib/rack
- lib/rack/adapter
- lib/rack/adapter/loader.rb
- lib/rack/adapter/rails.rb
- lib/rack/handler
- lib/rack/handler/thin.rb
- lib/thin
- lib/thin/backends
- lib/thin/backends/base.rb
- lib/thin/backends/swiftiply_client.rb
- lib/thin/backends/tcp_server.rb
- lib/thin/backends/unix_server.rb
- lib/thin/command.rb
- lib/thin/connection.rb
- lib/thin/controllers
- lib/thin/controllers/cluster.rb
- lib/thin/controllers/controller.rb
- lib/thin/controllers/service.rb
- lib/thin/controllers/service.sh.erb
- lib/thin/daemonizing.rb
- lib/thin/headers.rb
- lib/thin/logging.rb
- lib/thin/request.rb
- lib/thin/response.rb
- lib/thin/runner.rb
- lib/thin/server.rb
- lib/thin/stats.html.erb
- lib/thin/stats.rb
- lib/thin/statuses.rb
- lib/thin/version.rb
- lib/thin.rb
- lib/thin_parser.bundle
- spec/backends
- spec/backends/swiftiply_client_spec.rb
- spec/backends/tcp_server_spec.rb
- spec/backends/unix_server_spec.rb
- spec/command_spec.rb
- spec/configs
- spec/configs/cluster.yml
- spec/configs/single.yml
- spec/connection_spec.rb
- spec/controllers
- spec/controllers/cluster_spec.rb
- spec/controllers/controller_spec.rb
- spec/controllers/service_spec.rb
- spec/daemonizing_spec.rb
- spec/headers_spec.rb
- spec/logging_spec.rb
- spec/perf
- spec/perf/request_perf_spec.rb
- spec/perf/response_perf_spec.rb
- spec/perf/server_perf_spec.rb
- spec/rack
- spec/rack/loader_spec.rb
- spec/rack/rails_adapter_spec.rb
- spec/rails_app
- spec/rails_app/app
- spec/rails_app/app/controllers
- spec/rails_app/app/controllers/application.rb
- spec/rails_app/app/controllers/simple_controller.rb
- spec/rails_app/app/helpers
- spec/rails_app/app/helpers/application_helper.rb
- spec/rails_app/app/views
- spec/rails_app/app/views/simple
- spec/rails_app/app/views/simple/index.html.erb
- spec/rails_app/config
- spec/rails_app/config/boot.rb
- spec/rails_app/config/environment.rb
- spec/rails_app/config/environments
- spec/rails_app/config/environments/development.rb
- spec/rails_app/config/environments/production.rb
- spec/rails_app/config/environments/test.rb
- spec/rails_app/config/initializers
- spec/rails_app/config/initializers/inflections.rb
- spec/rails_app/config/initializers/mime_types.rb
- spec/rails_app/config/routes.rb
- spec/rails_app/log
- spec/rails_app/log/mongrel_debug
- spec/rails_app/public
- spec/rails_app/public/404.html
- spec/rails_app/public/422.html
- spec/rails_app/public/500.html
- spec/rails_app/public/dispatch.cgi
- spec/rails_app/public/dispatch.fcgi
- spec/rails_app/public/dispatch.rb
- spec/rails_app/public/favicon.ico
- spec/rails_app/public/images
- spec/rails_app/public/images/rails.png
- spec/rails_app/public/index.html
- spec/rails_app/public/javascripts
- spec/rails_app/public/javascripts/application.js
- spec/rails_app/public/javascripts/controls.js
- spec/rails_app/public/javascripts/dragdrop.js
- spec/rails_app/public/javascripts/effects.js
- spec/rails_app/public/javascripts/prototype.js
- spec/rails_app/public/robots.txt
- spec/rails_app/script
- spec/rails_app/script/about
- spec/rails_app/script/console
- spec/rails_app/script/destroy
- spec/rails_app/script/generate
- spec/rails_app/script/performance
- spec/rails_app/script/performance/benchmarker
- spec/rails_app/script/performance/profiler
- spec/rails_app/script/performance/request
- spec/rails_app/script/plugin
- spec/rails_app/script/process
- spec/rails_app/script/process/inspector
- spec/rails_app/script/process/reaper
- spec/rails_app/script/process/spawner
- spec/rails_app/script/runner
- spec/rails_app/script/server
- spec/rails_app/tmp
- spec/rails_app/tmp/pids
- spec/request
- spec/request/mongrel_spec.rb
- spec/request/parser_spec.rb
- spec/request/persistent_spec.rb
- spec/request/processing_spec.rb
- spec/response_spec.rb
- spec/runner_spec.rb
- spec/server
- spec/server/builder_spec.rb
- spec/server/pipelining_spec.rb
- spec/server/robustness_spec.rb
- spec/server/stopping_spec.rb
- spec/server/swiftiply.yml
- spec/server/swiftiply_spec.rb
- spec/server/tcp_spec.rb
- spec/server/threaded_spec.rb
- spec/server/unix_socket_spec.rb
- spec/server_spec.rb
- spec/spec_helper.rb
- tasks/announce.rake
- tasks/deploy.rake
- tasks/email.erb
- tasks/ext.rake
- tasks/gem.rake
- tasks/rdoc.rake
- tasks/site.rake
- tasks/spec.rake
- tasks/stats.rake
- ext/thin_parser/ext_help.h
- ext/thin_parser/parser.h
- ext/thin_parser/parser.c
- ext/thin_parser/thin.c
- ext/thin_parser/extconf.rb
- ext/thin_parser/common.rl
- ext/thin_parser/parser.rl
has_rdoc: true
homepage: http://code.macournoyer.com/thin/
post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: 1.8.5
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: thin
rubygems_version: 1.2.0
signing_key: 
specification_version: 2
summary: A thin and fast web server
test_files: []

