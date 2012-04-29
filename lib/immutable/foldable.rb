module Immutable
  module Foldable
    # Reduces +self+ using +block+ from left to right. +e+ is used as the
    # starting value. A class including +Immutable::Foldable+ must implement
    # this method.
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldl(e, &block)
      raise NotImplementedError
    end

    # Returns the number of elements in +self+. May be zero.
    #
    # @return [Integer] the number of elements in +self+.
    def length
      foldl(0) { |x, y| x + 1 }
    end

    # Returns the number of elements in +self+. May be zero.
    #
    # @return [Integer] the number of elements in +self+.
    alias size length

    # Computes the sum of the numbers in +self+.
    #
    # @return [#+] the sum of the numbers.
    def sum
      foldl(0, &:+)
    end

    # Computes the product of the numbers in +self+.
    #
    # @return [#*] the product of the numbers.
    def product
      foldl(1, &:*)
    end
  end
end
