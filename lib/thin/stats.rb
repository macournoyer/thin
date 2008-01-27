require 'erb'

module Thin
  # Rack adapter to log stats to a Rack application
  module Stats
    class Adapter
      include ERB::Util
      
      def initialize(app, path='/stats')
        @app  = app
        @path = path

        @template = ERB.new(TEMPLATE)
        
        @requests          = 0
        @requests_finished = 0
        @start_time        = Time.now
        @last_env          = {}
      end
      
      def call(env)
        if env['PATH_INFO'].index(@path) == 0
          serve(env)
        else
          log(env) { @app.call(env) }
        end
      end
      
      def log(env)
        @requests += 1
        @last_env = env
        request_started_at = Time.now
        
        response = yield
        
        @requests_finished += 1
        @last_request_time = Time.now - request_started_at
        
        response
      end
      
      def serve(env)
        body = @template.result(binding)
        
        [
          200,
          {
            'Content-Type' => 'text/html',
            'Content-Length' => body.size.to_s
          },
          [body]
        ]
      end

# Taken from Rack::ShowException
# adapted from Django <djangoproject.com>
# Copyright (c) 2005, the Lawrence Journal-World
# Used under the modified BSD license:
# http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5
TEMPLATE = <<'HTML'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <meta name="robots" content="NONE,NOARCHIVE" />
  <title>Thin Stats</title>
  <style type="text/css">
    html * { padding:0; margin:0; }
    body * { padding:10px 20px; }
    body * * { padding:0; }
    body { font:small sans-serif; }
    body>div { border-bottom:1px solid #ddd; }
    h1 { font-weight:normal; }
    h2 { margin-bottom:.8em; }
    h2 span { font-size:80%; color:#666; font-weight:normal; }
    h3 { margin:1em 0 .5em 0; }
    h4 { margin:0 0 .5em 0; font-weight: normal; }
    table {
        border:1px solid #ccc; border-collapse: collapse; background:white; }
    tbody td, tbody th { vertical-align:top; padding:2px 3px; }
    thead th {
        padding:1px 6px 1px 3px; background:#fefefe; text-align:left;
        font-weight:normal; font-size:11px; border:1px solid #ddd; }
    tbody th { text-align:right; color:#666; padding-right:.5em; }
    table.vars { margin:5px 0 2px 40px; }
    table.vars td, table.req td { font-family:monospace; }
    table td.code { width:100%;}
    table td.code div { overflow:hidden; }
    table.source th { color:#666; }
    table.source td {
        font-family:monospace; white-space:pre; border-bottom:1px solid #eee; }
    ul.traceback { list-style-type:none; }
    ul.traceback li.frame { margin-bottom:1em; }
    div.context { margin: 10px 0; }
    div.context ol {
        padding-left:30px; margin:0 10px; list-style-position: inside; }
    div.context ol li {
        font-family:monospace; white-space:pre; color:#666; cursor:pointer; }
    div.context ol.context-line li { color:black; background-color:#ccc; }
    div.context ol.context-line li span { float: right; }
    div.commands { margin-left: 40px; }
    div.commands a { color:black; text-decoration:none; }
    #summary { background: #ffc; }
    #summary h2 { font-weight: normal; color: #666; }
    #summary ul#quicklinks { list-style-type: none; margin-bottom: 2em; }
    #summary ul#quicklinks li { float: left; padding: 0 1em; }
    #summary ul#quicklinks>li+li { border-left: 1px #666 solid; }
    #explanation { background:#eee; }
    #template, #template-not-exist { background:#f6f6f6; }
    #template-not-exist ul { margin: 0 0 0 20px; }
    #traceback { background:#eee; }
    #summary table { border:none; background:transparent; }
    #requests { background:#f6f6f6; padding-left:120px; }
    #requests h2, #requests h3 { position:relative; margin-left:-100px; }
    #requests h3 { margin-bottom:-1em; }
    .error { background: #ffc; }
    .specific { color:#cc3300; font-weight:bold; }
  </style>
</head>
<body>

<div id="summary">
  <h1>Server stats</h1>
  <h2><%= Thin::SERVER %></h2>
  <div id="uptime">
    <%= Time.now - @start_time %> uptime
  </div>
</div>

<div id="requests">
  <h2>Requests</h2>
  <h3>Stats</h3>
  <table class="req">
    <tr>
      <td>Requests</td>
      <td><%= @requests %></td>
    </tr>
    <tr>
      <td>Finished</td>
      <td><%= @requests_finished %></td>
    </tr>
    <tr>
      <td>Errors</td>
      <td><%= @requests - @requests_finished %></td>
    </tr>
    <tr>
      <td>Last request</td>
      <td><%= @last_request_time %> sec</td>
    </tr>
  </table>
  <% if @last_env %>
    <h3>Last request</h3>
    <table class="req">
      <tr>
        <th>Variable</th>
        <th>Value</th>
      </tr>
      <tr>
      <% @last_env.sort_by { |k, v| k.to_s }.each do |key, val| %>
        <tr>
          <td><%=h key %></td>
          <td class="code"><div><%=h val.inspect %></div></td>
        </tr>
      <% end %>
      </tr>
    </table>
  <% end %>
</div>

<div id="explanation">
  <p>
    You're seeing this error because you use <code>Thin::Stats</code>.
  </p>
</div>

</body>
</html>
HTML
    end
  end
end