module Thin::Commands::Server
  class Base < Thin::Command
    def cwd
      args.first || '.'
    end
  end
end