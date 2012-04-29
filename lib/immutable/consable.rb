require "immutable/headable"

module Immutable
  module Consable
    include Headable

    module ClassMethods
      # Creates a new +Consable+ object populated with the given objects.
      #
      # @param [Array<Object>] elements the elements of the list.
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
    # the lists in +self+ and concatenates the result.
    # +xss.intercalate(xs)+ is equivalent to +xss.intersperse(xs).flatten+.
    #
    # @param [Consable] xs the list to insert between +Consable+ objects.
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
