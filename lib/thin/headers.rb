module Thin
  # Acts like a Hash, but allows duplicated keys
  # Class largely based on Mongrel::CGIWrapper
  # http://mongrel.rubyforge.org/ by Zed Shaw
  class Headers
    def initialize
      @sent = {}
      @items = []
      @allowed_duplicates = %w(Set-Cookie Set-Cookie2 Warning WWW-Authenticate)
    end

    def []=(key, value)
      if ! @sent.has_key?(key) || @allowed_duplicates.include?(key)
        @sent[key] = true
        @items << [key, value]
      end
    end
    
    def [](key)
      if item = @items.assoc(key)
        item[1]
      end
    end
    
    def to_s
      @items.inject('') { |out, (name, value)| out << HEADER_FORMAT % [name, value] }
    end
  end
end