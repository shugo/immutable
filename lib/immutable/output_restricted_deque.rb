require "immutable/queue"

module Immutable
  # +Immutable::OutputRestrictedDeque+ is an implementation of
  # output-restricted deques described in "Purely Functional Data
  # Structures" by Chris Okasaki.
  class OutputRestrictedDeque < Queue
    include Consable

    # Adds a new element at the head of +self+.
    #
    # @param [Object] x the element to add.
    # @return [Queue] a new queue.
    def cons(x)
      self.class.new(Stream.cons(->{x}, ->{@front}), @rear,
                     Stream.cons(->{x}, ->{@schedule}))
    end
    alias prepend cons
  end
end
