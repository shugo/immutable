require "immutable/stream"

module Immutable
  # +Immutable::Queue+ is an implementation of real-time queues described in
  # "Purely Functional Data Structures" by Chris Okasaki.
  class Queue
    include Enumerable

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
      new(Stream.null, Nil, Stream.null)
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
      @front.null?
    end

    def rotate(front, rear, accumulator)
      Stream.lazy {
        if front.null?
          Stream.cons(->{rear.head}, ->{accumulator})
        else
          Stream.cons(->{front.head}, ->{
            rotate(front.tail, rear.tail,
                   Stream.cons(->{rear.head}, ->{accumulator}))
          })
        end
      }
    end
    private :rotate

    def queue(front, rear, schedule)
      if schedule.null?
        f = rotate(front, rear, Stream.null)
        self.class.new(f, Nil, f)
      else
        self.class.new(front, rear, schedule.tail)
      end
    end
    private :queue

    # Adds a new element at the end of +self+.
    #
    # @param [Object] x the element to add.
    # @return [Queue] a new queue.
    def snoc(x)
      queue(@front, Cons[x, @rear], @schedule)
    end
    alias push snoc

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::List::EmptyError+ is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      @front.head
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::List::EmptyError+ is raised.
    #
    # @return [Queue] the elements after the head of +self+.
    def tail
      if @front.null?
        raise List::EmptyError
      else
        queue(@front.tail, @rear, @schedule)
      end
    end

    # Calls +block+ once for each element in +self+.
    def each(&block)
      unless @front.null?
        yield(head)
        tail.each(&block)
      end
    end
  end
end
