require_relative "stream"

module Immutable
  # +Immutable::Queue+ is an implementation of real-time queues described in
  # "Purely Functional Data Structures" by Chris Okasaki.
  class Queue
    include Headable

    # +Queue.new+ is for internal use only. Use {Queue.empty} or {Queue.[]}
    # instead.
    def initialize(front, rear, schedule)
      @front = front
      @rear = rear
      @schedule = schedule
    end

    # Returns an empty queue.
    #
    # @return [Queue] the empty queue.
    def self.empty
      new(Stream.empty, Nil, Stream.empty)
    end

    # Creates a new queue populated with the given objects.
    #
    # @param [Array<Object>] elements the elements of the queue.
    # @return [Queue] the new queue.
    def self.[](*elements)
      elements.inject(empty, &:snoc)
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      @front.empty?
    end

    # Adds a new element at the end of +self+.
    #
    # @param [Object] x the element to add.
    # @return [Queue] a new queue.
    def snoc(x)
      queue(@front, Cons[x, @rear], @schedule)
    end

    alias push snoc

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      @front.head
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Queue] the elements after the head of +self+.
    def tail
      if @front.empty?
        raise EmptyError
      else
        queue(@front.tail, @rear, @schedule)
      end
    end

    private

    def rotate(front, rear, accumulator)
      Stream.lazy {
        if front.empty?
          Stream.cons(->{rear.head}, ->{accumulator})
        else
          Stream.cons(->{front.head}, ->{
            rotate(front.tail, rear.tail,
                   Stream.cons(->{rear.head}, ->{accumulator}))
          })
        end
      }
    end

    def queue(front, rear, schedule)
      if schedule.empty?
        f = rotate(front, rear, Stream.empty)
        self.class.new(f, Nil, f)
      else
        self.class.new(front, rear, schedule.tail)
      end
    end
  end
end
