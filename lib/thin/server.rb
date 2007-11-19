require 'socket'
require 'fileutils'
require 'logger'

module Thin
  class Server
    attr_accessor :port, :host, :handlers, :pid_file
    
    def initialize(host, port, *handlers)
      @host     = host
      @port     = port
      @handlers = handlers
      @stop     = true

      @socket   = TCPServer.new(host, port)
      
      self.logger = Logger.new(STDOUT)
    end
    
    def logger
      @logger
    end
    
    def logger=(logger)
      @logger = logger
      @handlers.each { |h| h.logger = logger }
    end
    
    def start
      @stop = false
      trap('INT') do
        logger.info '>> Caught INT signal, stopping ...'
        stop
      end
      
      logger.info ">> Thin web server (v#{VERSION})"

      logger.info ">> Starting handlers ..."
      @handlers.each { |h| h.start }
      
      logger.info ">> Listening on #{host}:#{port}, CTRL+C to stop"      
      until @stop
        client = @socket.accept rescue nil
        break if @socket.closed?
        process(client)
      end
    ensure
      @socket.close unless @socket.closed? rescue nil
    end
        
    def process(client)
      return if client.eof?
      data     = client.readpartial(CHUNK_SIZE)
      request  = Request.new(data)
      response = Response.new
      
      # Add client info to the request env
      request.params['REMOTE_ADDR'] = client.peeraddr.last
      
      # Add server info to the request env
      request.params['SERVER_SOFTWARE'] = SERVER
      request.params['SERVER_PORT']     = @port.to_s
      request.params['SERVER_PROTOCOL'] = 'HTTP/1.1'

      served = false
      @handlers.each do |handler|
        served = handler.process(request, response)
        break if served
      end
      
      if served
        response.write client
      else
        client.write ERROR_404_RESPONSE
      end

    rescue InvalidRequest => e
      logger.error "Invalid request : #{e.message}"
      client.write ERROR_404_RESPONSE rescue nil
    rescue Object => e
      logger.error "Unexpected error while processing request : #{e.message}"
    ensure
      request.close  if request            rescue nil
      response.close if response           rescue nil
      client.close   unless client.closed? rescue nil
    end
    
    def stop
      @stop = true
      @socket.close rescue nil
    end
    
    def self.kill(pid_file)
      if File.exist?(pid_file) && pid = open(pid_file).read.chomp
        puts "Sending INT signal to process #{pid}"
        Process.kill('INT', pid.to_i)
      else
        STDERR.puts "Can't stop server, no PID found in #{pid_file}"
      end
    end
    
    def daemonize
      pid = fork do
        write_pid_file
        at_exit { remove_pid_file }
        start
      end
      # Make sure we do not create zombies
      Process.detach(pid)
    end
    
    private
      def remove_pid_file
        File.delete(@pid_file) if @pid_file && File.exists?(@pid_file)
      end

      def write_pid_file
        logger.info "Writing PID file to #{@pid_file}"
        FileUtils.mkdir_p File.dirname(@pid_file)
        open(@pid_file,"w") { |f| f.write(Process.pid) }
      end
  end
end