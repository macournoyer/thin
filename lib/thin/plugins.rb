module Thin
  # Very basic plugin mechanism.
  # Loads all Gems which name starts with <tt>thin-</tt> or <tt>thin_</tt>.
  # Just reopen classes or define all you want in your gem.
  # No need for more really!
  class Plugins
    extend Logging
    
    GEM_PREFIX = "thin(-|_)"
    
    def self.gems
      sdir = File.join(Gem.dir, "specifications")
      Gem::SourceIndex.from_installed_gems(sdir).inject([]) do |plugins, (path, gem)|
        plugins << gem.name if gem.name =~ /^#{GEM_PREFIX}/
        plugins
      end.uniq
    end
    
    def self.load
      gems.each do |gem|
        log ">> Loading #{gem} gem"
        require gem
      end
    end    
  end
end