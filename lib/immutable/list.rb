# -*- tailcall-optimization: true; trace-instruction: false -*-

require "immutable/maybe"

module Immutable
  # Immutable::List represents an immutable list.
  class List
    class EmptyError < StandardError
      def initialize(msg = "list is empty")
        super(msg)
      end
    end

    # Returns a new list populated with the given objects.
    def self.[](*args)
      from_array(args)
    end

    # Converts the given array +ary+ to a list.
    def self.from_array(ary)
      ary.reverse_each.inject(Nil) { |x, y|
        Cons.new(y, x)
      }
    end

    # Converts +enum+ to a list. +enum+ should respond to <code>each</code>.
    def self.from_enum(enum)
      enum.inject(Nil) { |x, y|
        Cons.new(y, x)
      }.reverse
    end

    # Returns the first element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    def head
      raise ScriptError, "this method should be overriden"
    end

    # Returns the first element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    def first
      head
    end

    # Returns the last element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    def last
      raise ScriptError, "this method should be overriden"
    end

    # Returns the element after the head of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    def tail
      raise ScriptError, "this method should be overriden"
    end

    # Returns all the element of +self+ except the last one.
    # If +self+ is empty, <code>Immutable::List::EmptyError</code> is
    # raised.
    def init
      raise ScriptError, "this method should be overriden"
    end

    # Returns <code>true</code> if +self+ is empty.
    def empty?
      raise ScriptError, "this method should be overriden"
    end

    # Returns <code>true</code> if +self+ is empty.
    def null?
      empty?
    end

    # Returns the number of elements in +self+. May be zero.
    def length
      foldl(0) { |x, y| x + 1 }
    end

    alias size length

    # Appends two lists +self+ and +xs+.
    def +(xs)
      foldr(xs) { |y, ys| Cons[y, ys] }
    end

    # Concatenates a list of lists.
    def flatten
      foldr(Nil) { |x, xs| x + xs }
    end

    alias concat flatten

    # Returns the list obtained by applying the given block to each element
    # in +self+.
    def map
      foldr(Nil) { |x, xs| Cons[yield(x), xs] }
    end

    # Returns the list obtained by concatenating the results of the given
    # block for each element in +self+.
    def flat_map
      foldr(Nil) { |x, xs| yield(x) + xs }
    end

    alias concat_map flat_map
    alias bind flat_map

    # Returns the elements in +self+ for which the given block evaluates to
    # true.
    def filter
      foldr(Nil) { |x, xs|
        if yield(x)
          Cons[x, xs]
        else
          xs
        end
      }
    end

    # Returns the elements of +self+ in reverse order.
    def reverse
      foldl(Nil) { |x, y| Cons[y, x] }
    end

    # Inserts +xs+ in between the lists in +self+ and concatenates the
    # result.
    # <code>xss.intercalate(xs)</code> is equivalent to
    # <code>xss.intersperse(xs).flatten</code>.
    def intercalate(xs)
      intersperse(xs).flatten
    end

    # Computes the sum of the numbers in +self+.
    def sum
      foldl(0, &:+)
    end

    # Computes the product of the numbers in +self+.
    def product
      foldl(1, &:*)
    end

    # Builds a list from the seed value +e+ and the given block. The block
    # takes a seed value and returns Nothing if the seed should unfold to
    # the empty list, or returns Just[a, b], where a is the head of the list
    # and b is the next seed from which to unfold the tail.  For example:
    #
    #   xs = List.unfoldr(3) { |x| x == 0 ? Nothing : Just[x, x - 1] }
    #   p xs #=> List[3, 2, 1]
    #
    # <code>unfoldr</code> is the dual of <code>foldr</code>.
    def self.unfoldr(e, &block)
      x = yield(e)
      if x.nothing?
        Nil
      else
        y, z = *x.values
        Cons[y, unfoldr(z, &block)]
      end
    end
  end

  Nil = List.new

  class Cons < List
    # Creates a list obtained by prepending +head+ to the list +tail+.
    def self.[](head, tail = Nil)
      self.new(head, tail)
    end

    # Creates a list obtained by prepending +head+ to the list +tail+.
    def initialize(head, tail = Nil)
      @head = head
      @tail = tail
    end

    def Nil.head
      raise EmptyError
    end

    attr_reader :head

    def Nil.last
      raise EmptyError
    end

    def last
      if @tail.empty?
        @head
      else
        @tail.last
      end
    end

    def Nil.tail
      raise EmptyError
    end

    attr_reader :tail

    def Nil.init
      raise EmptyError
    end

    def init
      if @tail.empty?
        Nil
      else
        Cons[@head, @tail.init]
      end
    end

    def Nil.empty?
      true
    end

    def empty?
      false
    end

    def Nil.foldr(e)
      e
    end

    def foldr(e, &block)
      yield(@head, @tail.foldr(e, &block))
    end

    def Nil.foldr1
      raise EmptyError
    end

    def foldr1(&block)
      if @tail.empty?
        @head
      else
        yield(@head, @tail.foldr1(&block))
      end
    end

    def Nil.foldl(e)
      e
    end

    def foldl(e, &block)
      @tail.foldl(yield(e, @head), &block)
    end

    def Nil.foldl1
      raise EmptyError
    end

    def foldl1(&block)
      @tail.foldl(@head, &block)
    end

    def ==(xs)
      if xs.empty?
        false
      else
        @head == xs.head && @tail == xs.tail
      end
    end

    def Nil.inspect
      "List[]"
    end

    def inspect
      "List[" + @head.inspect +
        @tail.foldl("") {|x, y| x + ", " + y.inspect } + "]"
    end

    def Nil.find
      Nothing
    end

    def find(&block)
      if yield(@head)
        Just[@head]
      else
        @tail.find(&block)
      end
    end

    def Nil.intersperse(sep)
      Nil
    end

    def intersperse(sep)
      Cons[@head, @tail.prepend_to_all(sep)]
    end

    def Nil.prepend_to_all(sep)
      Nil
    end

    def prepend_to_all(sep)
      Cons[sep, Cons[@head, @tail.prepend_to_all(sep)]]
    end

    def Nil.take(n)
      Nil
    end

    def take(n)
      if n <= 0
        Nil
      else
        Cons[@head, @tail.take(n - 1)]
      end
    end

    def Nil.take_while
      Nil
    end

    def take_while(&block)
      if yield(@head)
        Cons[@head, @tail.take_while(&block)]
      else
        Nil
      end
    end

    def Nil.drop(n)
      Nil
    end

    def drop(n)
      if n > 0
        @tail.drop(n - 1)
      else
        self
      end
    end

    def Nil.drop_while
      Nil
    end

    def drop_while(&block)
      if yield(@head)
        @tail.drop_while(&block)
      else
        self
      end
    end
  end
end
