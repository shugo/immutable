module Immutable
  # <code>Immutable::List</code> represents an immutable list.
  #
  # <code>Immutable::List</code> is an abstract class and
  # <code>Immutable::List.[]</code> should be used instead of
  # <code>Immutable::List.new</code>. For example:
  #
  #   include Immutable
  #   p List[]      #=> List[]
  #   p List[1, 2]  #=> List[1, 2]
  #
  # <code>Immutable::Nil</code> represents an empty list, and
  # <code>Immutable::Cons</code> represents a cons cell, which is a node in
  # a list. For example:
  #
  #   p Nil                    #=> List[]
  #   p Cons[1, Cons[2, Nil]]  #=> List[1, 2]
  class List
    class EmptyError < StandardError
      def initialize(msg = "list is empty")
        super(msg)
      end
    end

    # Creates a new list populated with the given objects.
    #
    # @return [List] the created list.
    def self.[](*args)
      from_array(args)
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

    # Appends two lists +self+ and +xs+.
    #
    # @param [List] xs the list to append.
    # @return [List] the new list.
    def +(xs)
      foldr(xs) { |y, ys| Cons[y, ys] }
    end

    # Returns the first element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      # this method should be overriden
    end

    # Returns the first element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the first element of +self+.
    def first
      head
    end

    # Returns the last element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the last element of +self+.
    def last
      # this method should be overriden
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [List] the elements after the head of +self+.
    def tail
      # this method should be overriden
    end

    # Returns all the element of +self+ except the last one.
    # If +self+ is empty, <code>Immutable::List::EmptyError</code> is
    # raised.
    #
    # @return [List] the elements of +self+ except the last one.
    def init
      # this method should be overriden
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      # this method should be overriden
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def null?
      empty?
    end

    # Returns the number of elements in +self+. May be zero.
    #
    # @return [Integer] the number of elements in +self+.
    def length
      foldl(0) { |x, y| x + 1 }
    end

    alias size length

    # Returns the list obtained by applying the given block to each element
    # in +self+.
    #
    # @return [List] the obtained list.
    def map
      foldr(Nil) { |x, xs| Cons[yield(x), xs] }
    end

    # Returns the elements of +self+ in reverse order.
    #
    # @return [List] the reversed list.
    def reverse
      foldl(Nil) { |x, y| Cons[y, x] }
    end

    # Inserts +sep+ in between the elements of +self+.
    #
    # @param [Object] sep the object to insert between elements.
    # @return [List] the created list.
    def intersperse(sep)
      # this method should be overriden
    end

    # Inserts +xs+ in between the lists in +self+ and concatenates the
    # result.
    # <code>xss.intercalate(xs)</code> is equivalent to
    # <code>xss.intersperse(xs).flatten</code>.
    #
    # @param [List] xs the list to insert between lists.
    # @return [List] the created list.
    def intercalate(xs)
      intersperse(xs).flatten
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

    # Reduces +self+ using +block+ from right to left. +e+ is used as the
    # starting value. For example:
    #
    #   List[1, 2, 3].foldr(9) { |x, y| x + y } #=> 1 - (2 - (3 - 9)) = -7
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldr(e, &block)
      # this method should be overriden
    end

    # Reduces +self+ using +block+ from right to left. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the reduced value.
    def foldr1(&block)
      # this method should be overriden
    end

    # Reduces +self+ using +block+ from left to right. +e+ is used as the
    # starting value. For example:
    #
    #   List[1, 2, 3].foldl(9) { |x, y| x + y } #=> ((9 - 1) - 2) - 3 = 3
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldl(e, &block)
      # this method should be overriden
    end

    # Reduces +self+ using +block+ from left to right. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the reduced value.
    def foldl1(&block)
      # this method should be overriden
    end

    # Concatenates a list of lists.
    #
    # @return [List] the concatenated list.
    def flatten
      foldr(Nil) { |x, xs| x + xs }
    end

    # An alias of <code>flatten</code>.
    alias concat flatten

    # Returns the list obtained by concatenating the results of the given
    # block for each element in +self+.
    #
    # @return [List] the obtained list.
    def flat_map
      foldr(Nil) { |x, xs| yield(x) + xs }
    end

    # An alias of <code>flat_map</code>.
    alias concat_map flat_map

    # An alias of <code>flat_map</code>.
    alias bind flat_map

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

    # Builds a list from the seed value +e+ and the given block. The block
    # takes a seed value and returns <code>nil</code> if the seed should
    # unfold to the empty list, or returns <code>[a, b]</code>, where
    # <code>a</code> is the head of the list and <code>b</code> is the next
    # seed from which to unfold the tail.  For example:
    #
    #   xs = List.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
    #   p xs #=> List[3, 2, 1]
    #
    # <code>unfoldr</code> is the dual of <code>foldr</code>.
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

    # Returns the first +n+ elements of +self+, or +self+ itself if
    # <code>n > self.length</code>.
    #
    # @param [Integer] n the number of elements to take.
    # @return [List] the first +n+ elements of +self+.
    def take(n)
      # this method should be overriden
    end


    # Returns the suffix of +self+ after the first +n+ elements, or
    # <code>List[]</code> if <code>n > self.length</code>.
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
    # <code>self.take_while(&block)</code>.
    #
    # @return [List] the suffix of the elements of +self+.
    def drop_while(&block)
      # this method should be overriden
    end

    # Returns the first element in +self+ for which the given block
    # evaluates to true.  If such an element is not found, it
    # returns <code>nil</code>.
    #
    # @return [Object] the found element.
    def find(&block)
      # this method should be overriden
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
  end

  Nil = List.new

  class Cons < List
    # Creates a list obtained by prepending +head+ to the list +tail+.
    #
    # @return [Cons] the created list.
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

    def Nil.find
      nil
    end

    def find(&block)
      if yield(@head)
        @head
      else
        @tail.find(&block)
      end
    end
  end
end
