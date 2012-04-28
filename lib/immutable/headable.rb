require "immutable/foldable"

module Immutable
  class EmptyError < StandardError
    def initialize(msg = "collection is empty")
      super(msg)
    end
  end

  module Headable
    include Enumerable
    include Foldable

    # Returns a string containing a human-readable representation of +self+.
    # 
    # @return [String] a string representation of +self+.
    def inspect
      if empty?
        class_name + "[]"
      else
        class_name + "[" + head.inspect +
          tail.foldl("") {|x, y| x + ", " + y.inspect } + "]"
      end
    end

    # Returns whether +self+ equals to +xs+.
    #
    # @param [Object] x the object to compare.
    # @return [true, false] +true+ if +self+ equals to +xs+; otherwise,
    # +false+.
    def ==(x)
      if !x.is_a?(self.class)
        false
      else
        if empty?
          x.empty?
        else
          !x.empty? && head == x.head && tail == x.tail
        end
      end
    end

    # Calls +block+ once for each element in +self+.
    def each(&block)
      unless empty?
        yield(head)
        tail.each(&block)
      end
    end

    # Reduces +self+ using +block+ from right to left. +e+ is used as the
    # starting value. For example:
    #
    #   List[1, 2, 3].foldr(9) { |x, y| x + y } #=> 1 - (2 - (3 - 9)) = -7
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldr(e, &block)
      if empty?
        e
      else
        yield(head, tail.foldr(e, &block))
      end
    end

    # Reduces +self+ using +block+ from right to left. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the reduced value.
    def foldr1(&block)
      if empty?
        raise EmptyError
      else
        if tail.empty?
          head
        else
          yield(head, tail.foldr1(&block))
        end
      end
    end

    # Reduces +self+ using +block+ from left to right. +e+ is used as the
    # starting value. For example:
    #
    #   List[1, 2, 3].foldl(9) { |x, y| x + y } #=> ((9 - 1) - 2) - 3 = 3
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldl(e, &block)
      if empty?
        e
      else
        tail.foldl(yield(e, head), &block)
      end
    end

    # Reduces +self+ using +block+ from left to right. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the reduced value.
    def foldl1(&block)
      if empty?
        raise EmptyError
      else
        tail.foldl(head, &block)
      end
    end

    # Returns the first element in +self+ for which the given block
    # evaluates to true.  If such an element is not found, it
    # returns +nil+.
    #
    # @return [Object] the found element.
    def find(&block)
      if empty?
        nil
      else
        if yield(head)
          head
        else
          tail.find(&block)
        end
      end
    end

    # Returns the +n+th element of +self+. If +n+ is out of range, +nil+ is
    # returned.
    #
    # @return [Object] the +n+th element.
    def [](n)
      if n < 0 || empty?
        nil
      elsif n == 0
        head
      else
        tail[n - 1]
      end
    end

    # Converts +self+ to a list.
    #
    # @return [List] a list.
    def to_list
      foldr(List[]) { |x, xs| Cons[x, xs] }
    end
 
    private

    def class_name
      self.class.name.slice(/[^:]*\z/)
    end
  end
end
