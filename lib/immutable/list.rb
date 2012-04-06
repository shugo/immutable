# -*- tailcall-optimization: true; trace-instruction: false -*-

module Immutable
  class List
    class EmptyError < StandardError
    end

    NIL = List.new

    class Cons < List
      attr_reader :head, :tail

      def self.[](head, tail = nil)
        self.new(head, tail)
      end

      def initialize(head, tail = NIL)
        @head = head
        @tail = tail
      end

      def NIL.init
        raise EmptyError, "list is empty"
      end

      def init
        if @tail.empty?
          NIL
        else
          Cons[@head, @tail.init]
        end
      end

      def NIL.empty?
        true
      end

      def empty?
        false
      end

      def NIL.foldl(e)
        e
      end

      def foldl(e, &block)
        @tail.foldl(yield(e, @head), &block)
      end

      def NIL.foldl1
        raise EmptyError, "list is empty"
      end

      def foldl1(&block)
        @tail.foldl(@head, &block)
      end

      def NIL.foldr(e)
        e
      end

      def foldr(e, &block)
        yield(@head, @tail.foldr(e, &block))
      end

      def NIL.foldr1
        raise EmptyError, "list is empty"
      end

      def foldr1(&block)
        if @tail.empty?
          @head
        else
          yield(@head, @tail.foldr1(&block))
        end
      end

      def ==(xs)
        if xs.empty?
          false
        else
          @head == xs.head && @tail == xs.tail
        end
      end

      def NIL.inspect
        "List[]"
      end

      def inspect
        "List[" + @head.inspect +
          @tail.foldl("") {|x, y| x + ", " + y.inspect } + "]"
      end

      def NIL.intersperse(sep)
        NIL
      end

      def intersperse(sep)
        Cons[@head, @tail.prepend_to_all(sep)]
      end

      def NIL.prepend_to_all(sep)
        NIL
      end

      def prepend_to_all(sep)
        Cons[sep, Cons[@head, @tail.prepend_to_all(sep)]]
      end

      def NIL.take(n)
        NIL
      end

      def take(n)
        if n <= 0
          NIL
        else
          Cons[@head, @tail.take(n - 1)]
        end
      end

      def NIL.take_while
        NIL
      end

      def take_while(&block)
        if yield(@head)
          Cons[@head, @tail.take_while(&block)]
        else
          NIL
        end
      end

      def NIL.drop(n)
        NIL
      end

      def drop(n)
        if n > 0
          @tail.drop(n - 1)
        else
          self
        end
      end

      def NIL.drop_while
        NIL
      end

      def drop_while(&block)
        if yield(@head)
          @tail.drop_while(&block)
        else
          self
        end
      end
    end

    def self.[](*args)
      from_array(args)
    end

    def self.from_array(ary)
      ary.reverse_each.inject(NIL) { |x, y|
        Cons.new(y, x)
      }
    end

    def self.from_enum(enum)
      enum.inject(NIL) { |x, y|
        Cons.new(y, x)
      }.reverse
    end

    def null?
      empty?
    end

    def length
      foldl(0) { |x, y| x + 1 }
    end

    alias size length

    def +(xs)
      foldr(xs) { |y, ys| Cons[y, ys] }
    end

    def flatten
      foldr(NIL) { |x, xs| x + xs }
    end

    alias concat flatten

    def map
      foldr(NIL) { |x, xs| Cons[yield(x), xs] }
    end

    def flat_map
      foldr(NIL) { |x, xs| yield(x) + xs }
    end

    alias concat_map flat_map

    def filter
      foldr(NIL) { |x, xs|
        if yield(x)
          Cons[x, xs]
        else
          xs
        end
      }
    end

    def reverse
      foldl(NIL) { |x, y| Cons[y, x] }
    end

    def intercalate(xs)
      intersperse(xs).flatten
    end

    def sum
      foldl(0, &:+)
    end

    def product
      foldl(1, &:*)
    end

    def self.unfoldr(e, &block)
      x = yield(e)
      if x.nothing?
        NIL
      else
        y, z = *x.values
        Cons[y, unfoldr(z, &block)]
      end
    end
  end
end
