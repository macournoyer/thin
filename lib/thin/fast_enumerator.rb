require 'fiber' if defined?(Fiber)

module Thin
  # Turns out Enumerator#next is pretty slow and rolling our own w/ Fibers is a lot faster.
  # Still not as fast as Enumerable#each but eh...
  class FastEnumerator
    if defined?(Fiber)
      
      def initialize(array)
        @fiber = Fiber.new do
          array.each do |i|
            Fiber.yield i
          end
        end
      end

      def next
        return nil unless @fiber.alive?
        @fiber.resume
      end

    else

      # Slow Enumerator based version for Rubies w/ no fibers.

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