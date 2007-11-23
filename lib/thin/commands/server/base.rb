module Thin::Commands::Server
  class Base < Thin::Commands::Command
    def cwd
      args.first || '.'
    end
  end
end