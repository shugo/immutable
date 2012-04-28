require "immutable/stream"

module Immutable
  # +Immutable::Deque+ is an implementation of real-time deques described in
  # "Purely Functional Data Structures" by Chris Okasaki.
  class Deque
    include Headable

    # +Deque.new+ is for internal use only. Use {Deque.empty} or {Deque.[]}
    # instead.
    def initialize(front, front_len, front_schedule,
                   rear, rear_len, rear_schedule)
      @front = front
      @front_len = front_len
      @front_schedule = front_schedule
      @rear = rear
      @rear_len = rear_len
      @rear_schedule = rear_schedule
      @c = 3  # @c should be 2 or 3
    end

    # Returns an empty deque.
    #
    # @return [Deque] the empty deque.
    def self.empty
      Deque.new(Stream.null, 0, Stream.null,
                Stream.null, 0, Stream.null)
    end

    # Creates a new deque populated with the given objects.
    #
    # @param [Array<Object>] elements the elements of the deque.
    # @return [Deque] the new deque.
    def self.[](*elements)
      elements.inject(empty, &:snoc)
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      length == 0
    end

    alias null? empty?

    # Returns the number of elements in +self+. May be zero.
    #
    # @return [Integer] the number of elements in +self+.
    def length
      @front_len + @rear_len
    end

    # Adds a new element at the head of +self+.
    #
    # @param [Object] x the element to add.
    # @return [Deque] a new deque.
    def cons(x)
      queue(Stream.cons(->{x}, ->{@front}), @front_len + 1,
            exec1(@front_schedule),
            @rear, @rear_len, exec1(@rear_schedule))
    end

    alias unshift cons
    alias prepend cons

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      if @front.null?
        if @rear.null?
          raise EmptyError
        else
          @rear.head
        end
      else
        @front.head
      end
    end

    alias first head

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Deque] the elements after the head of +self+.
    def tail
      if @front.null?
        if @rear.null?
          raise EmptyError
        else
          self.class.empty
        end
      else
        queue(@front.tail, @front_len - 1, exec2(@front_schedule),
              @rear, @rear_len, exec2(@rear_schedule))
      end
    end

    alias shift tail

    # Adds a new element at the end of +self+.
    #
    # @param [Object] x the element to add.
    # @return [Deque] a new queue.
    def snoc(x)
      queue(@front, @front_len, exec1(@front_schedule),
            Stream.cons(->{x}, ->{@rear}), @rear_len + 1,
            exec1(@rear_schedule))
    end

    alias push snoc

    # Returns the last element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the last element of +self+.
    def last
      if @rear.null?
        if @front.null?
          raise EmptyError
        else
          @front.head
        end
      else
        @rear.head
      end
    end

    # Returns all the elements of +self+ except the last one.
    # If +self+ is empty, +Immutable::EmptyError+ is
    # raised.
    #
    # @return [Deque] the elements of +self+ except the last one.
    def init
      if @rear.null?
        if @front.null?
          raise EmptyError
        else
          self.class.empty
        end
      else
        queue(@front, @front_len, exec2(@front_schedule),
              @rear.tail, @rear_len - 1, exec2(@rear_schedule))
      end
    end

    alias pop init

    private

    def exec1(s)
      if s.null?
        s
      else
        s.tail
      end
    end

    def exec2(s)
      exec1(exec1(s))
    end

    def rotate_rev(r, f, a)
      if r.null?
        f.reverse + a
      else
        Stream.cons(->{r.head},
                    ->{rotate_rev(r.tail, f.drop(@c),
                                  f.take(@c).reverse + a)})
      end
    end

    def rotate_drop(r, i, f)
      if i < @c
        rotate_rev(r, f.drop(i), Stream.null)
      else
        x = r.head
        r2 = r.tail
        Stream.cons(->{x}, ->{rotate_drop(r2, i - @c, f.drop(@c))})
      end
    end

    def queue(f, f_len, f_schedule, r, r_len, r_schedule)
      if f_len > @c * r_len + 1
        i = (f_len + r_len) / 2
        j = (f_len + r_len) - i
        f2 = f.take(i)
        r2 = rotate_drop(r, i, f)
        self.class.new(f2, i, f2, r2, j, r2)
      elsif r_len > @c * f_len + 1
        j = (f_len + r_len) / 2
        i = (f_len + r_len) - j
        f2 = rotate_drop(f, j, r)
        r2 = r.take(j)
        self.class.new(f2, i, f2, r2, j, r2)
      else
        self.class.new(f, f_len, f_schedule, r, r_len, r_schedule)
      end
    end
  end
end
