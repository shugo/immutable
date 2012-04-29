require "immutable/headable"

module Immutable
  module Consable
    include Headable

    module ClassMethods
      # Creates a new +Consable+ object populated with the given objects.
      #
      # @param [Array<Object>] elements the elements of the +Consable+
      #   object.
      # @return [Consable] the new +Consable+ object.
      def [](*elements)
        from_array(elements)
      end

      # Converts the given array to a +Consable+ object.
      #
      # @param [Array, #reverse_each] ary the array to convert.
      # @return [Consable] the +Consable+ object converted from +ary+.
      def from_array(ary)
        ary.reverse_each.inject(empty) { |x, y|
          Cons(y, x)
        }
      end

      # Converts the given Enumerable object to a +Consable+ object.
      #
      # @param [#inject] enum the Enumerable object to convert.
      # @return [Cons] the +Consable+ object converted from +enum+.
      def from_enum(enum)
        enum.inject(empty) { |x, y|
          Cons(y, x)
        }.reverse
      end

      # Builds a +Consable+ object from the seed value +e+ and the given
      # block. The block takes a seed value and returns +nil+ if the seed
      # should unfold to the empty +Consable+ object, or returns +[a, b]+,
      # where +a+ is the head of the +Consable+ object and +b+ is the next
      # seed from which to unfold the tail.  For example:
      #
      #   xs = List.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
      #   p xs #=> List[3, 2, 1]
      #
      # +unfoldr+ is the dual of +foldr+.
      #
      # @param [Object] e the seed value.
      # @return [Consable] the +Consable+ object built from the seed value
      # and the block.
      def unfoldr(e, &block)
        x = yield(e)
        if x.nil?
          empty
        else
          y, z = x
          Cons(y, unfoldr(z, &block))
        end
      end

      private

      def Cons(x, y)
        y.cons(x)
      end
    end

    def self.included(c)
      c.extend(ClassMethods)
    end

    # Adds a new element at the head of +self+. A class including
    # +Immutable::Consable+ must implement this method.
    #
    # @param [Object] x the element to add.
    # @return [Consable] a new +Consable+ object.
    def cons(x)
      raise NotImplementedError
    end

    # Same as {#cons}. This method just calls {#cons}.
    #
    # @param [Object] x the element to add.
    # @return [Consable] a new +Consable+ object.
    def unshift(x)
      cons(x)
    end

    # Same as {#cons}. This method just calls {#cons}.
    #
    # @param [Object] x the element to add.
    # @return [Consable] a new +Consable+ object.
    def prepend(x)
      cons(x)
    end

    # Appends two +Consable+ objects +self+ and +xs+.
    #
    # @param [Consable] xs the +Consable+ object to append.
    # @return [Consable] a new +Consable+ object.
    def +(xs)
      foldr(xs) { |y, ys| Cons(y, ys) }
    end

    # Returns the +Consable+ object obtained by applying the given block to
    # each element in +self+.
    #
    # @return [Consable] the obtained +Consable+ object.
    def map
      foldr(empty) { |x, xs| Cons(yield(x), xs) }
    end

    # Returns the elements of +self+ in reverse order.
    #
    # @return [Consable] the reversed +Consable+ object.
    def reverse
      foldl(empty) { |x, y| Cons(y, x) }
    end

    # Returns a new +Consable+ object obtained by inserting +sep+ in between
    # the elements of +self+.
    #
    # @param [Object] sep the object to insert between elements.
    # @return [Consable] the new +Consable+ object.
    def intersperse(sep)
      if empty?
        empty
      else
        Cons(head, tail.prepend_to_all(sep))
      end
    end

    # Returns a new +Consable+ object obtained by inserting +xs+ in between
    # the +Consable+ objects in +self+ and concatenates the result.
    # +xss.intercalate(xs)+ is equivalent to +xss.intersperse(xs).flatten+.
    #
    # @param [Consable] xs the +Consable+ object to insert between
    #   +Consable+ objects.
    # @return [Consable] the new +Consable+ object.
    def intercalate(xs)
      intersperse(xs).flatten
    end

    # Transposes the rows and columns of +self+. For example:
    # 
    #   p List[List[1, 2, 3], List[4, 5, 6]].transpose
    #   #=> List[List[1, 4], List[2, 5], List[3, 6]]
    #
    # @return [Consable] the transposed +Consable+ object.
    def transpose
      if empty?
        empty
      else
        if head.empty?
          tail.transpose
        else
          t = tail.filter { |x| !x.empty? }
          Cons(Cons(head.head, t.map(&:head)),
               Cons(head.tail, t.map(&:tail)).transpose)
        end
      end
    end

    # Returns the +Consable+ object of all subsequences of +self+.
    #
    # @return [Consable<Consable>] the subsequences of +self+.
    def subsequences
      Cons(empty, nonempty_subsequences)
    end

    # Concatenates a +Consable+ object of +Consable+ objects.
    #
    # @return [Consable] the concatenated +Consable+ object.
    def flatten
      foldr(empty) { |x, xs| x + xs }
    end

    alias concat flatten

    # Returns the +Consable+ object obtained by concatenating the results of
    # the given block for each element in +self+.
    #
    # @return [Consable] the obtained +Consable+ object.
    def flat_map
      foldr(empty) { |x, xs| yield(x) + xs }
    end

    alias concat_map flat_map
    alias bind flat_map

    # Returns the first +n+ elements of +self+, or all the elements of
    # +self+ if +n > self.length+.
    #
    # @param [Integer] n the number of elements to take.
    # @return [Consable] the first +n+ elements of +self+.
    def take(n)
      if empty?
        empty
      else
        if n <= 0
          empty
        else
          Cons(head, tail.take(n - 1))
        end
      end
    end

    # Returns the suffix of +self+ after the first +n+ elements, or
    # an empty +Consable+ object if +n > self.length+.
    #
    # @param [Integer] n the number of elements to drop.
    # @return [Consable] the suffix of +self+ after the first +n+ elements.
    def drop(n)
      if empty?
        empty
      else
        if n > 0
          tail.drop(n - 1)
        else
          self
        end
      end
    end

    # Returns the longest prefix of the elements of +self+ for which +block+
    # evaluates to true.
    #
    # @return [Consable] the prefix of the elements of +self+.
    def take_while(&block)
      if empty?
        empty
      else
        if yield(head)
          Cons(head, tail.take_while(&block))
        else
          empty
        end
      end
    end

    # Returns the suffix remaining after
    # +self.take_while(&block)+.
    #
    # @return [Consable] the suffix of the elements of +self+.
    def drop_while(&block)
      if empty?
        empty
      else
        if yield(head)
          tail.drop_while(&block)
        else
          self
        end
      end
    end

    # Returns the elements in +self+ for which the given block evaluates to
    # true.
    #
    # @return [Consable] the elements that satisfies the condition.
    def filter
      foldr(empty) { |x, xs|
        if yield(x)
          Cons(x, xs)
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
      if empty?
        empty
      else
        heads = xss.map { |xs| xs.empty? ? nil : xs.head }
        tails = xss.map { |xs| xs.empty? ? empty : xs.tail }
        Cons([head, *heads], tail.zip(*tails))
      end
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
      if empty?
        empty
      else
        heads = xss.map { |xs| xs.null? ? nil : xs.head }
        tails = xss.map { |xs| xs.null? ? empty : xs.tail }
        Cons(yield(head, *heads), tail.zip_with(*tails, &block))
      end
    end

    protected

    def prepend_to_all(sep)
      if empty?
        empty
      else
        Cons(sep, Cons(head, tail.prepend_to_all(sep)))
      end
    end

    def nonempty_subsequences
      if empty?
        empty
      else
        yss = tail.nonempty_subsequences.foldr(empty) { |xs, xss|
          Cons(xs, Cons(Cons(head, xs), xss))
        }
        Cons(Cons(head, empty), yss)
      end
    end
 
    private

    def empty
      self.class.empty
    end

    def Cons(x, y)
      y.cons(x)
    end
  end
end
