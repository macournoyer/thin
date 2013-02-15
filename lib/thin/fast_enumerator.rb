require 'fiber' if defined?(Fiber)

module Thin
  # Enumerator#next is pretty slow and rolling our own w/ Fibers is a lot faster.
  class FastEnumerator
    if defined?(Fiber)
      
      def initialize(array)
        @fiber = Fiber.new do
          array.each do |e|
            Fiber.yield e
          end
        end
      end

      def next
        return nil unless @fiber.alive?
        @fiber.resume
      end

    else

      # Slow Enumerator-based version for Rubies w/o Fibers.

      # Ruby 1.8
      unless defined?(Enumerator)
        Enumerator = Enumerable::Enumerator
      end

      def initialize(array)
        @enum = Enumerator.new(array)
      end

      def next
        begin
          @enum.next
        rescue StopIteration
          nil
        end
      end

    end
  end
end