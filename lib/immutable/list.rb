require "immutable/consable"

module Immutable
  # +Immutable::List+ represents an immutable list.
  #
  # +Immutable::List+ is an abstract class and
  # {Immutable::List.[]} should be used instead of
  # {Immutable::List.new}. For example:
  #
  #   include Immutable
  #   p List[]      #=> List[]
  #   p List[1, 2]  #=> List[1, 2]
  #
  # +Immutable::Nil+ represents an empty list, and
  # +Immutable::Cons+ represents a cons cell, which is a node in
  # a list. For example:
  #
  #   p Nil                    #=> List[]
  #   p Cons[1, Cons[2, Nil]]  #=> List[1, 2]
  class List
    include Consable

    # Returns an empty list.
    #
    # @return [list] the empty list.
    def self.empty
      Nil
    end

    # Creates a new list populated with the given objects.
    #
    # @param [Array<Object>] elements the elements of the list.
    # @return [List] the new list.
    def self.[](*elements)
      from_array(elements)
    end

    # Converts the given array to a list.
    #
    # @param [Array, #reverse_each] ary the array to convert.
    # @return [List] the list converted from +ary+.
    def self.from_array(ary)
      ary.reverse_each.inject(Nil) { |x, y|
        Cons.new(y, x)
      }
    end

    # Converts the given Enumerable object to a list.
    #
    # @param [#inject] enum the Enumerable object to convert.
    # @return [List] the list converted from +enum+.
    def self.from_enum(enum)
      enum.inject(Nil) { |x, y|
        Cons.new(y, x)
      }.reverse
    end

    # Adds a new element at the head of +self+.
    #
    # @param [Object] x the element to add.
    # @return [List] a new list.
    def cons(x)
      Cons[x, self]
    end

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      # this method should be overriden
    end

    # Returns the last element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the last element of +self+.
    def last
      # this method should be overriden
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [List] the elements after the head of +self+.
    def tail
      # this method should be overriden
    end

    # Returns all the elements of +self+ except the last one.
    # If +self+ is empty, +Immutable::EmptyError+ is
    # raised.
    #
    # @return [List] the elements of +self+ except the last one.
    def init
      # this method should be overriden
    end

    # Same as {#init}.
    #
    # @return [List] the elements of +self+ except the last one.
    def pop
      init
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      # this method should be overriden
    end

    # Transposes the rows and columns of +self+. For example:
    # 
    #   p List[List[1, 2, 3], List[4, 5, 6]].transpose
    #   #=> List[List[1, 4], List[2, 5], List[3, 6]]
    #
    # @return [List] the transposed list.
    def transpose
      # this method should be overriden
    end

    # Returns the list of all subsequences of +self+.
    #
    # @return [List<List>] the list of subsequences.
    def subsequences
      Cons[List[], nonempty_subsequences]
    end

    # Concatenates a list of lists.
    #
    # @return [List] the concatenated list.
    def flatten
      foldr(Nil) { |x, xs| x + xs }
    end

    alias concat flatten

    # Returns the list obtained by concatenating the results of the given
    # block for each element in +self+.
    #
    # @return [List] the obtained list.
    def flat_map
      foldr(Nil) { |x, xs| yield(x) + xs }
    end

    alias concat_map flat_map
    alias bind flat_map

    # Builds a list from the seed value +e+ and the given block. The block
    # takes a seed value and returns +nil+ if the seed should
    # unfold to the empty list, or returns +[a, b]+, where
    # +a+ is the head of the list and +b+ is the next
    # seed from which to unfold the tail.  For example:
    #
    #   xs = List.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
    #   p xs #=> List[3, 2, 1]
    #
    # +unfoldr+ is the dual of +foldr+.
    #
    # @param [Object] e the seed value.
    # @return [List] the list built from the seed value and the block.
    def self.unfoldr(e, &block)
      x = yield(e)
      if x.nil?
        Nil
      else
        y, z = x
        Cons[y, unfoldr(z, &block)]
      end
    end

    # Returns the first +n+ elements of +self+, or all the elements of
    # +self+ if +n > self.length+.
    #
    # @param [Integer] n the number of elements to take.
    # @return [List] the first +n+ elements of +self+.
    def take(n)
      # this method should be overriden
    end

    # Returns the suffix of +self+ after the first +n+ elements, or
    # +List[]+ if +n > self.length+.
    #
    # @param [Integer] n the number of elements to drop.
    # @return [List] the suffix of +self+ after the first +n+ elements.
    def drop(n)
      # this method should be overriden
    end

    # Returns the longest prefix of the elements of +self+ for which +block+
    # evaluates to true.
    #
    # @return [List] the prefix of the elements of +self+.
    def take_while(&block)
      # this method should be overriden
    end

    # Returns the suffix remaining after
    # +self.take_while(&block)+.
    #
    # @return [List] the suffix of the elements of +self+.
    def drop_while(&block)
      # this method should be overriden
    end

    # Returns +self+.
    #
    # @return [List] +self+.
    def to_list
      self
    end

    # Returns the elements in +self+ for which the given block evaluates to
    # true.
    #
    # @return [List] the elements that satisfies the condition.
    def filter
      foldr(Nil) { |x, xs|
        if yield(x)
          Cons[x, xs]
        else
          xs
        end
      }
    end

    # Takes zero or more lists and returns a new list in which each element
    # is an array of the corresponding elements of +self+ and the input
    # lists.
    #
    # @param [Array<List>] xss the input lists.
    # @return [List] the new list.
    def zip(*xss)
      # this method should be overriden
    end

    # Takes zero or more lists and returns the list obtained by applying the
    # given block to an array of the corresponding elements of +self+ and
    # the input lists.
    # +xs.zip_with(*yss, &block)+ is equivalent to
    # +xs.zip(*yss).map(&block)+.
    #
    # @param [Array<List>] xss the input lists.
    # @return [List] the new list.
    def zip_with(*xss, &block)
      # this method should be overriden
    end

    private

    def class_name
      "List"
    end
  end

  # +Immutable::Nil+ represents an empty list.
  Nil = List.new

  # +Immutable::Cons+ represents a cons cell.
  class Cons < List
    # Creates a new list obtained by prepending +head+ to the list +tail+.
    #
    # @return [Cons] the new list.
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

    def Nil.transpose
      Nil
    end

    def transpose
      if @head == Nil
        @tail.transpose
      else
        tail = @tail.filter { |x| !x.empty? }
        Cons[Cons[@head.head, tail.map(&:head)],
          Cons[@head.tail, tail.map(&:tail)].transpose]
      end
    end

    def Nil.nonempty_subsequences
      List[]
    end

    def nonempty_subsequences
      yss = @tail.nonempty_subsequences.foldr(List[]) { |xs, xss|
        Cons[xs, Cons[Cons[@head, xs], xss]]
      }
      Cons[List[@head], yss]
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

    def Nil.zip(*xss)
      Nil
    end

    def zip(*xss)
      heads = xss.map { |xs| xs.null? ? nil : xs.head }
      tails = xss.map { |xs| xs.null? ? Nil : xs.tail }
      Cons[[head, *heads], tail.zip(*tails)]
    end

    def Nil.zip_with(*xss, &block)
      Nil
    end

    def zip_with(*xss, &block)
      heads = xss.map { |xs| xs.null? ? nil : xs.head }
      tails = xss.map { |xs| xs.null? ? Nil : xs.tail }
      Cons[yield(head, *heads), tail.zip_with(*tails, &block)]
    end
  end
end
