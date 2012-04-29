require "immutable/headable"

module Immutable
  module Consable
    include Headable

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

    protected

    def prepend_to_all(sep)
      if empty?
        empty
      else
        Cons(sep, Cons(head, tail.prepend_to_all(sep)))
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
