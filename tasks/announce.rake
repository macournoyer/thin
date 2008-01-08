require 'time'
require 'erb'

MSG_TEMPLATE = File.dirname(__FILE__) + '/email.erb'
FROM         = 'macournoyer@gmail.com'
SEND_ANN_TO  = %w(thin-ruby@googlegroups.com eventmachine-talk@rubyforge.org Rubymtl@lists.artengine.ca ruby-talk@ruby-lang.org)

namespace :ann do
  task :email do
    abort 'Specify PW for GMail account' unless ENV['PW']
    
    (ENV['TEST'] ? %w(macournoyer@yahoo.ca) : SEND_ANN_TO).each do |to|
      msg = ERB.new(File.read(MSG_TEMPLATE)).result(binding)
    
      body = <<END_OF_MESSAGE
From: Marc-Andre Cournoyer <#{FROM}>
To: #{to}
Subject: [ANN] Thin #{Thin::VERSION::STRING} #{Thin::VERSION::CODENAME} released
Date: #{Time.now.httpdate}
Message-Id: <unique.message.id.string@example.com>

#{msg}
END_OF_MESSAGE
    
      Net::SMTP.start('smtp.gmail.com', 587, 'localhost.localdomain', 
                      'macournoyer', ENV['PW'], :plain) do |smtp|
        smtp.send_message body, FROM, to
      end
    end
  end
end

# Require some magic stuff for sending mails using Gmail
# Source: http://d.hatena.ne.jp/zorio/20060416
require 'openssl'
require 'net/smtp'

Net::SMTP.class_eval do
  private
  def do_start(helodomain, user, secret, authtype)
    raise IOError, 'SMTP session already started' if @started
    check_auth_args user, secret, authtype if user or secret

    sock = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
    @socket = Net::InternetMessageIO.new(sock)
    @socket.read_timeout = 60 #@read_timeout
    @socket.debug_output = STDERR #@debug_output

    check_response(critical { recv_response() })
    do_helo(helodomain)

    raise 'openssl library not installed' unless defined?(OpenSSL)
    starttls
    ssl = OpenSSL::SSL::SSLSocket.new(sock)
    ssl.sync_close = true
    ssl.connect
    @socket = Net::InternetMessageIO.new(ssl)
    @socket.read_timeout = 60 #@read_timeout
    @socket.debug_output = STDERR #@debug_output
    do_helo(helodomain)

    authenticate user, secret, authtype if user
    @started = true
  ensure
    unless @started
      # authentication failed, cancel connection.
        @socket.close if not @started and @socket and not @socket.closed?
      @socket = nil
    end
  end

  def do_helo(helodomain)
     begin
      if @esmtp
        ehlo helodomain
      else
        helo helodomain
      end
    rescue Net::ProtocolError
      if @esmtp
        @esmtp = false
        @error_occured = false
        retry
      end
      raise
    end
  end

  def starttls
    getok('STARTTLS')
  end
end