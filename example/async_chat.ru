#!/usr/bin/env rackup -s thin
# 
#  async_chat.ru
#  raggi/thin
#  
#  Created by James Tucker on 2008-06-19.
#  Copyright 2008 James Tucker <raggi@rubyforge.org>.

# Uncomment if appropriate for you..
EM.epoll
# EM.kqueue # bug on OS X in 0.12?

class DeferrableBody
  include EventMachine::Deferrable
  
  def initialize
    @queue = []
  end
  
  def schedule_dequeue
    return unless @body_callback
    EventMachine::next_tick do
      next unless body = @queue.shift
      body.each do |chunk|
        @body_callback.call(chunk)
      end
      schedule_dequeue unless @queue.empty?
    end
  end 

  def call(body)
    @queue << body
    schedule_dequeue
  end

  def each &blk
    @body_callback = blk
    schedule_dequeue
  end

end

class Chat
  
  def initialize
    @users = {}
  end
  
  Page = [] << <<-EOPAGE
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html>
    <head>
      <style>
        body {
          font-family: sans-serif;
          margin: 0; 
          padding: 0;
          margin-top: 4em;
          margin-bottom: 1em;
        }
        #header {
          background: silver;
          height: 4em;
          width: 100%;
          position: fixed;
          top: 0px;
          border-bottom: 1px solid black;
          padding-left: 0.5em;
        }
        #messages {
          width: 100%;
          height: 100%;
        }
        .message {
          margin-left: 1em;
        }
        #send_form {
          position: fixed;
          bottom: 0px;
          height: 1em;
          width: 100%;
        }
        #message_box {
          background: silver;
          width: 100%;
          border: 0px;
          border-top: 1px solid black;
        }
      </style>
      <script type="text/javascript" src="http://ra66i.org/tmp/jquery-1.2.6.min.js"></script>
      <script type="text/javascript">
        XHR = function() {
          var request = false;
          try { request = new ActiveXObject('Msxml2.XMLHTTP');    } catch(e) {
            try { request = new ActiveXObject('Microsoft.XMLHTTP'); } catch(e1) {
      		    try {	request = new XMLHttpRequest();                 	}	catch(e2) { 
      		      return false; 
    		      }
  		      }
  	      }
          return request;
        }
        scroll = function() {
        	window.scrollBy(0,50);
        	setTimeout('scroll()',100);
        }
        send_message = function(message_box) {
          xhr = XHR();
          xhr.open("POST", "/", true); 
      		xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
      		xhr.setRequestHeader("X_REQUESTED_WITH", "XMLHttpRequest");
      		xhr.send("message="+escape(message_box.value));
          scroll();
          message_box.value = '';
          message_box.focus();
          return false;
        }
        new_message = function(username, message) {
          // TODO html escape message
          formatted_message = "<div class='message'>" + username + ": " + message + "</div>";
          messages_div = $('#messages');
          $(formatted_message).appendTo(messages_div);
          scroll();
          return true;
        }
      </script>
      <title>Async Chat</title>
    </head>
    <body>
      <div id="header">
        <h1>Async Chat</h1>
      </div>
      <div id="messages"></div>
      <form id="send_form" onSubmit="return send_message(this.message)">
        <input type="text" id="message_box" name="message"></input>
      </form>
      <script type="text/javascript">$('#message_box').focus();</script>
    </body>
  </html>
  EOPAGE
  
  def register_user(request)
    user_id = request.env['REMOTE_ADDR']
    renderer = request.env['async.callback']
    
    schedule_render user_id, renderer
  end
  
  def new_message(message)
    EventMachine::next_tick do
      @users.each { |id, body| body.call [js_message(id, message)] }
    end
  end
  
  private
  
  def schedule_render(user_id, renderer)
    EventMachine::next_tick do
      body = create_user(user_id)
      body.call Page
      renderer.call [200, {'Content-Type' => 'text/html'}, body]
      body.errback { delete_user user_id }
      body.callback { delete_user user_id }
    end
  end
  
  def delete_user(id)
    puts "User: #{id} disconnected"
    @users.delete id
  end
  
  JsHead = %!<script type="text/javascript">new_message("!
  JsMid  = %!","!
  JsTail = %!");</script>!
  
  def js_message(username, message)
    [JsHead, username, JsMid, message, JsTail].join
  end
  
  def create_user(id)
    puts "User: #{id} signed on"
    body = DeferrableBody.new
    @users[id] = body
  end
  
end

class AsyncChat
  
  AsyncResponse = [100, {}, []].freeze
  AjaxResponse = [200, {}, []].freeze
  
  def initialize
    @chat = Chat.new
  end
  
  def call(env)  
    request = Rack::Request.new(env)
    if request.xhr?
      @chat.new_message(request['message'])
      AjaxResponse
    else
      @chat.register_user(request)
      AsyncResponse
    end
  end
  
end

run AsyncChat.new
