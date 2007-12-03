module Thin
  # Handle a request and populate a response.
  class Handler
    # Start the handler.
    # Initialize resources, open files, that kinda thing.
    def start
    end
    
    # Process the incoming +request+ into the +response+
    # that will be sent to the client.
    # Return +true+ to send the request to the next handler
    # or +false+ to stop processing the request and send the
    # response to the client right away.
    def process(request, response)
      raise NotImplemented
    end
  end
  
  # Serve a directory from a URI.
  class DirHandler < Handler
    def initialize(pwd)
      @pwd = pwd.dup
    end
    
    def process(request, response)
      path = File.join(@pwd, request.path)
      if File.directory?(path)
        serve_dir request.path, path, response
        return true
      elsif File.file?(path)
        serve_file path, response
        return true
      end
      false
    end
    
    def serve_dir(base, path, response)
      response.content_type = 'text/html'
      response.body << '<html><head><title>Dir listing</title></head>'
      response.body << "<body><h1>Listing #{base}</h1><ul>"
      Dir.entries(path).each do |entry|
        next if entry == '.'
        response.body << %Q{<li><a href="#{File.join(base, entry)}">#{entry}</a></li>}
      end
      response.body << '</ul></body></html>'
    end
    
    def serve_file(path, response)
      response.content_type = MIME_TYPES[File.extname(path)] || "application/octet-stream".freeze
      File.open(path, "rb") { |f| response.body << f.read }
    end
    
    def to_s
      "dir #{@pwd}"
    end
  end
end