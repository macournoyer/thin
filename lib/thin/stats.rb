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
        @last_request = Rack::Request.new(env)
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
      
      # Taken from Rails
      def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
        from_time = from_time.to_time if from_time.respond_to?(:to_time)
        to_time = to_time.to_time if to_time.respond_to?(:to_time)
        distance_in_minutes = (((to_time - from_time).abs)/60).round
        distance_in_seconds = ((to_time - from_time).abs).round

        case distance_in_minutes
          when 0..1
            return (distance_in_minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
            case distance_in_seconds
              when 0..4   then 'less than 5 seconds'
              when 5..9   then 'less than 10 seconds'
              when 10..19 then 'less than 20 seconds'
              when 20..39 then 'half a minute'
              when 40..59 then 'less than a minute'
              else             '1 minute'
            end

          when 2..44           then "#{distance_in_minutes} minutes"
          when 45..89          then 'about 1 hour'
          when 90..1439        then "about #{(distance_in_minutes.to_f / 60.0).round} hours"
          when 1440..2879      then '1 day'
          when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
          when 43200..86399    then 'about 1 month'
          when 86400..525599   then "#{(distance_in_minutes / 43200).round} months"
          when 525600..1051199 then 'about 1 year'
          else                      "over #{(distance_in_minutes / 525600).round} years"
        end
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
  <table>
    <tr>
      <th>Uptime</th>
      <td><%= distance_of_time_in_words(@start_time, Time.now) %> (<%= Time.now - @start_time %> sec)</td>
    </tr>
    <tr>
      <th>PID</th>
      <td><%=h Process.pid %></td>
    </tr>
  </table>
  
  <% if @last_request %>
    <h3>Jump to:</h3>
    <ul id="quicklinks">
      <li><a href="#get-info">GET</a></li>
      <li><a href="#post-info">POST</a></li>
      <li><a href="#cookie-info">Cookies</a></li>
      <li><a href="#env-info">ENV</a></li>
    </ul>
  <% end %>
</div>

<div id="stats">
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
</div>

<% if @last_request %>
  <div id="requestinfo">
    <h2>Last Request information</h2>

    <h3 id="get-info">GET</h3>
    <% unless @last_request.GET.empty? %>
      <table class="req">
        <thead>
          <tr>
            <th>Variable</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
            <% @last_request.GET.sort_by { |k, v| k.to_s }.each { |key, val| %>
            <tr>
              <td><%=h key %></td>
              <td class="code"><div><%=h val.inspect %></div></td>
            </tr>
            <% } %>
        </tbody>
      </table>
    <% else %>
      <p>No GET data.</p>
    <% end %>

    <h3 id="post-info">POST</h3>
    <% unless @last_request.POST.empty? %>
      <table class="req">
        <thead>
          <tr>
            <th>Variable</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
            <% @last_request.POST.sort_by { |k, v| k.to_s }.each { |key, val| %>
            <tr>
              <td><%=h key %></td>
              <td class="code"><div><%=h val.inspect %></div></td>
            </tr>
            <% } %>
        </tbody>
      </table>
    <% else %>
      <p>No POST data.</p>
    <% end %>


    <h3 id="cookie-info">COOKIES</h3>
    <% unless @last_request.cookies.empty? %>
      <table class="req">
        <thead>
          <tr>
            <th>Variable</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          <% @last_request.cookies.each { |key, val| %>
            <tr>
              <td><%=h key %></td>
              <td class="code"><div><%=h val.inspect %></div></td>
            </tr>
          <% } %>
        </tbody>
      </table>
    <% else %>
      <p>No cookie data.</p>
    <% end %>

    <h3 id="env-info">Rack ENV</h3>
      <table class="req">
        <thead>
          <tr>
            <th>Variable</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
            <% @last_request.env.sort_by { |k, v| k.to_s }.each { |key, val| %>
            <tr>
              <td><%=h key %></td>
              <td class="code"><div><%=h val %></div></td>
            </tr>
            <% } %>
        </tbody>
      </table>

  </div>
<% end %>

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