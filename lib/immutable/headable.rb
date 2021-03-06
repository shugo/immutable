require_relative "foldable"

module Immutable
  class EmptyError < StandardError
    def initialize(msg = "collection is empty")
      super(msg)
    end
  end

  module Headable
    include Enumerable
    include Foldable

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised. A class including
    # +Immutable::Headable+ must implement this method.
    #
    # @return [Object] the first element of +self+.
    def head
      raise NotImplementedError
    end

    # Same as {#head}. This method just calls {#head}.
    #
    # @return [Object] the first element of +self+.
    def first
      head
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised. A class including
    # +Immutable::Headable+ must implement this method.
    #
    # @return [Headable] the elements after the head of +self+.
    def tail
      raise NotImplementedError
    end

    # Same as {#tail}. This method just calls {#tail}.
    #
    # @return [Headable] the elements after the head of +self+.
    def shift
      tail
    end

    # Returns whether +self+ is empty. A class including
    # +Immutable::Headable+ must implement this method.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      raise NotImplementedError
    end

    # Same as {#empty?}. This method just calls {#empty?}.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def null?
      empty?
    end

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

    alias to_s inspect

    # Returns whether +self+ equals to +x+.
    #
    # @param [Object] x the object to compare.
    # @return [true, false] +true+ if +self+ equals to +x+; otherwise,
    #   +false+.
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

    def eql?(x)
      if !x.is_a?(self.class)
        false
      else
        if empty?
          x.empty?
        else
          !x.empty? && head.eql?(x.head) && tail.eql?(x.tail)
        end
      end
    end
    
    # @return [Integer]
    def hash
      to_a.hash
    end

    # Calls +block+ once for each element in +self+.
    # @yield [element]
    # @yieldreturn [self]
    # @return [Enumerator]
    def each(&block)
      return to_enum unless block_given?
  
      unless empty?
        yield(head)
        tail.each(&block)
      end
      
      self
    end

    # Calls +block+ once for each index in +self+.
    # @yield [index]
    # @yieldparam [Integer] index
    # @yieldreturn [self]
    # @return [Enumerator]
    def each_index
      return to_enum(__callee__) unless block_given?
  
      each_with_index{ |_, idx| yield(idx) }
    end

    # Reduces +self+ using +block+ from right to left. +e+ is used as the
    # starting value. For example:
    #
    #   List[1, 2, 3].foldr(9) { |x, y| x - y } #=> 1 - (2 - (3 - 9)) = -7
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
    #   List[1, 2, 3].foldl(9) { |x, y| x - y } #=> ((9 - 1) - 2) - 3 = 3
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
    # @param [#call, nil] ifnone
    # @yield [element]
    # @yieldreturn [Object] the found element.
    # @return [Enumerator]
    def find(ifnone=nil, &block)
      return to_enum(__callee__, ifnone) unless block_given?

      if empty?
        if ifnone.nil?
          nil
        else
          ifnone.call
        end
      else
        if yield(head)
          head
        else
          tail.find(ifnone, &block)
        end
      end
    end
    
    alias detect find

    # Returns the +n+th element of +self+. If +n+ is out of range, +nil+ is
    # returned.
    #
    # @param [Integer, #to_int] n
    # @return [Object] the +n+th element.
    def [](n)
      raise TypeError unless n.respond_to?(:to_int)
      int = n.to_int

      if int < 0 || empty?
        nil
      elsif int == 0
        head
      else
        tail[int - 1]
      end
    end

    alias at []

    # Returns the +n+th element of +self+. If +n+ is out of range, +IndexError+
    # returned.
    #
    # @overload fetch(n)
    #   @param [Integer, #to_int] n
    #   @return [Object] the +n+th element.
    #   @raise [IndexError] if n is out of rage
    # @overload fetch(n, ifnone)
    #   @param [Integer, #to_int] n
    #   @return ifnone
    # @overload fetch(n) {|n|}
    #   @param [Integer, #to_int] n
    #   @yield [n]
    #   @yieldparam [Integer, #to_int] n
    def fetch(*args)
      alen = args.length
      n, ifnone = *args
      
      unless (1..2).cover?(alen)
        raise ArgumentError, "wrong number of arguments (#{alen} for 1..2)"
      end

      raise TypeError unless n.respond_to?(:to_int)
      int = n.to_int

      return at(int) if int >= 0 && int < length

      if block_given?
        if alen == 2
          warn "#{__LINE__}:warning: block supersedes default value argument"
        end

        yield n
      else
        if alen == 2
          ifnone
        else
          raise IndexError, "index #{int} outside of list bounds"
        end
      end
    end

    # @overload index(val)
    #   @return [Integer, nil] index
    # @overload index
    #   @return [Enumerator]
    # @overload index {}
    #   @yieldreturn [Integer, nil] index
    def index(*args)
      alen = args.length
      val = args.first

      raise ArgumentError unless (0..1).cover?(alen)
      return to_enum(__callee__) if !block_given? && alen == 0

      if alen == 1
        if block_given?
          warn "#{__LINE__}:warning: given block not used"
        end

        each_with_index { |e, idx|
          return idx if e == val
        }
      else
        if block_given?
          each_with_index { |e, idx|
            return idx if yield(e)
          }
        end
      end

      nil
    end

    # @overload rindex(val)
    #   @return [Integer, nil] index
    # @overload rindex
    #   @return [Enumerator]
    # @overload rindex {}
    #   @yieldreturn [Integer, nil] index
    def rindex(*args)
      alen = args.length
      val = args.first

      raise ArgumentError unless (0..1).cover?(alen)
      return to_enum(__callee__) if !block_given? && alen == 0

      if alen == 1
        if block_given?
          warn "#{__LINE__}:warning: given block not used"
        end

        reverse_each.with_index { |e, idx|
          return length - (idx + 1) if e == val
        }
      else
        if block_given?
          reverse_each.with_index { |e, idx|
            return length - (idx + 1) if yield(e)
          }
        end
      end

      nil
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
