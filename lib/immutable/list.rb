# -*- tailcall-optimization: true; trace-instruction: false -*-

require "immutable/maybe"

module Immutable
  class List
    class EmptyError < StandardError
    end

    def self.[](*args)
      from_array(args)
    end

    def self.from_array(ary)
      ary.reverse_each.inject(Nil) { |x, y|
        Cons.new(y, x)
      }
    end

    def self.from_enum(enum)
      enum.inject(Nil) { |x, y|
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
      foldr(Nil) { |x, xs| x + xs }
    end

    alias concat flatten

    def map
      foldr(Nil) { |x, xs| Cons[yield(x), xs] }
    end

    def flat_map
      foldr(Nil) { |x, xs| yield(x) + xs }
    end

    alias concat_map flat_map
    alias bind flat_map

    def filter
      foldr(Nil) { |x, xs|
        if yield(x)
          Cons[x, xs]
        else
          xs
        end
      }
    end

    def reverse
      foldl(Nil) { |x, y| Cons[y, x] }
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
        Nil
      else
        y, z = *x.values
        Cons[y, unfoldr(z, &block)]
      end
    end
  end

  Nil = List.new

  class Cons < List
    attr_reader :head, :tail

    def self.[](head, tail = Nil)
      self.new(head, tail)
    end

    def initialize(head, tail = Nil)
      @head = head
      @tail = tail
    end

    def Nil.init
      raise EmptyError, "list is empty"
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
      raise EmptyError, "list is empty"
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
      raise EmptyError, "list is empty"
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
