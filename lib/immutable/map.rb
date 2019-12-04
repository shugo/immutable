require_relative "foldable"

module Immutable
  # +Immutable::Map+ represents an immutable map from keys to
  # values.
  #
  # +Immutable::Map+ is an abstract class and
  # {Immutable::Map.[]} should be used instead of
  # {Immutable::Map.new}. For example:
  #
  #   include Immutable
  #   p Map[]            #=> Map[]
  #   p Map[a: 1, b: 2]  #=> Map[:a => 1, :b => 2]
  #
  # {#insert} inserts a key/value pair and
  # returns a new +Immutable::Map+. The original map never be
  # changed by {#insert}. For example:
  #
  #   m = Map[a: 1]
  #   p m   #=> Map[:a => 1]
  #   m2 = m.insert(:b, 2)
  #   p m2  #=> Map[:a => 1, :b => 2]
  #   p m   #=> Map[:a => 1]
  class Map
    include Enumerable
    include Foldable

    class InvarianceViolationError < StandardError
    end

    # Returns an empty map.
    def self.empty
      Leaf
    end

    # Returns a map that has only one pair whose key is +key+ and whose
    # value is +value+.
    def self.singleton(key, value)
      Leaf.insert(key, value)
    end

    # Returns a map that has the same key/value pairs as the
    # +Hash+ object +h+.
    def self.[](h = {})
      h.inject(Leaf) { |m, (k, v)| m.insert(k, v) }
    end

    # Inserts +key+/+value+ in +self+.
    def insert(key, value)
      ins(key, value).make_black
    end

    # Returns the value at +key+ in +self+, or +nil+ if +key+
    # isn't in +self+.
    def [](key)
      raise ScriptError, "this method should be overriden"
    end

    # Deletes +key+ and its value from +self+.
    def delete(key)
      m = del(key)
      if m.empty?
        m
      else
        m.make_black
      end
    end

    # @return [Boolean]
    def ==(x)
      x.is_a?(self.class) && (to_h == x.to_h)
    end

    alias === ==

    def eql?(x)
      x.is_a?(self.class) && to_h.eql?(x.to_h)
    end

    # @return [Integer]
    def hash
      to_h.hash
    end

    # @return [String]
    def inspect
      "Map[" + foldr_with_key("") { |k, v, s|
        x = k.inspect + " => " + v.inspect
        if s.empty?
          x
        else
          x + ", " + s
        end
      } + "]"
    end

    alias to_s inspect

    # Calls +block+ once for each key/value in +self+.
    # @yield [key, element]
    # @yieldreturn [self]
    # @return [self]
    def each(&block)
      return to_enum(__callee__) unless block_given?

      foldl_with_key(nil) { |x, k, v| yield([k, v]) }
      self
    end

    alias each_pair each

    # Folds the values in +self+ from right to left.
    def foldr(e)
      foldr_with_key(e) { |k, v, x| yield(v, x) }
    end

    # Folds the values in +self+ from left to right.
    def foldl(e)
      foldl_with_key(e) { |x, k, v| yield(x, v) }
    end

    # Maps the given block over all values in +self+.
    def map
      map_with_key { |k, v| yield(v) }
    end

    # Maps the given block over all keys and values in +self+.
    def map_with_key
      foldr_with_key(List[]) { |k, v, xs| Cons[yield(k, v), xs] }
    end

    # @return [Hash]
    def to_h
      Hash[each_pair.to_a]
    end

    # :nodoc:
    Leaf = Map.new

    def Leaf.empty?
      true
    end

    def Leaf.red?
      false
    end

    def Leaf.black?
      true
    end

    def Leaf.[](key)
      nil
    end

    def Leaf.ins(key, value)
      RedFork[Leaf, key, value, Leaf]
    end

    def Leaf.del(key)
      Leaf
    end

    class Fork < Map  #:nodoc:
      attr_reader :left, :key, :value, :right

      def initialize(left, key, value, right)
        @left = left
        @key = key
        @value = value
        @right = right
      end

      class << self
        alias [] new
      end

      def empty?
        false
      end

      def [](key)
        x = key <=> @key
        if x < 0
          @left[key]
        elsif x > 0
          @right[key]
        else
          @value
        end
      end

      def del(key)
        if key < self.key
          del_left(left, self.key, self.value, right, key)
        elsif key > self.key
          del_right(left, self.key, self.value, right, key)
        else
          app(left, right)
        end
      end

      def Leaf.foldr_with_key(e)
        e
      end

      def foldr_with_key(e, &block)
        r = @right.foldr_with_key(e, &block)
        @left.foldr_with_key(yield(@key, @value, r), &block)
      end

      def Leaf.foldl_with_key(e)
        e
      end

      def foldl_with_key(e, &block)
        l = @left.foldl_with_key(e, &block)
        @right.foldl_with_key(yield(l, @key, @value), &block)
      end

      def deconstruct
        [@left, @key, @value, @right]
      end

      private

      def balance(*args)
        case args
        in [RedFork[a, xk, xv, b], yk, yv, RedFork[c, zk, zv, d]]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, BlackFork[c, zk, zv, d]]
        in [RedFork[RedFork[a, xk, xv, b], yk, yv, c], zk, zv, d]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, BlackFork[c, zk, zv, d]]
        in [RedFork[a, xk, xv, RedFork[b, yk, yv, c]], zk, zv, d]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, BlackFork[c, zk, zv, d]]
        in [a, xk, xv, RedFork[b, yk, yv, RedFork[c, zk, zv, d]]]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, BlackFork[c, zk, zv, d]]
        in [a, xk, xv, RedFork[RedFork[b, yk, yv, c], zk, zv, d]]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, BlackFork[c, zk, zv, d]]
        in [a, xk, xv, b]
          BlackFork[a, xk, xv, b]
        end
      end

      def del_left(left, key, value, right, del_key)
        if left.black?
          bal_left(left.del(del_key), key, value, right)
        else
          RedFork[left.del(del_key), key, value, right]
        end
      end

      def del_right(left, key, value, right, del_key)
        if right.black?
          bal_right(left, key, value, right.del(del_key))
        else
          RedFork[left, key, value, right.del(del_key)]
        end
      end

      def bal_left(*args)
        case args
        in [RedFork[a, xk, xv, b], yk, yv, c]
          RedFork[BlackFork[a, xk, xv, b], yk, yv, c]
        in [a, xk, xv, BlackFork[b, yk, yv, c]]
          balance(a, xk, xv, RedFork[b, yk, yv, c])
        in [a, xk, xv, RedFork[BlackFork[b, yk, yv, c], zk, zv, d]]
          RedFork[
            BlackFork[a, xk, xv, b],
            yk, yv,
            balance(c, zk, zv, sub1(d))
          ]
        end
      end

      def bal_right(*args)
        case args
        in [a, xk, xv, RedFork[b, yk, yv, c]]
          RedFork[a, xk, xv, BlackFork[b, yk, yv, c]]
        in [BlackFork[a, xk, xv, b], yk, yv, c]
          balance(RedFork[a, xk, xv, b], yk, yv, c)
        in [RedFork[a, xk, xv, BlackFork[b, yk, yv, c]], zk, zv, d]
          RedFork[
            balance(sub1(a), xk, xv, b),
            yk, yv,
            BlackFork[c, zk, zv, d]
          ]
        end
      end

      def sub1(node)
        if node.black?
          node.make_red
        else
          raise InvarianceViolationError, "invariance violation"
        end
      end

      def app(left, right)
        if left.empty?
          right
        elsif right.empty?
          left
        elsif left.red? && right.red?
          m = app(left.right, right.left)
          if m.red?
            RedFork[
              RedFork[left.left, left.key, left.value, m.left],
              m.key, m.value,
              RedFork[m.right, right.key, right.value, right.right]
            ]
          else
            RedFork[
              left.left, left.key, left.value,
              RedFork[m, right.key, right.value, right.right]
            ]
          end
        elsif left.black? && right.black?
          m = app(left.right, right.left)
          if m.red?
            RedFork[
              BlackFork[left.left, left.key, left.value, m.left],
              m.key, m.value,
              BlackFork[m.right, right.key, right.value, right.right]
            ]
          else
            bal_left(left.left, left.key, left.value,
                     BlackFork[m, right.key, right.value, right.right])
          end
        elsif right.red?
          RedFork[app(left, right.left), right.key, right.value,
            right.right]
        elsif left.red?
          RedFork[left.left, left.key, left.value, app(left.right, right)]
        else
          raise ScriptError, "should not reach here"
        end
      end
    end

    class RedFork < Fork  #:nodoc:
      def red?
        true
      end

      def black?
        false
      end

      def make_red
        self
      end

      def make_black
        BlackFork[left, key, value, right]
      end

      def ins(key, value)
        x = key <=> @key
        if x < 0
          RedFork[@left.ins(key, value), @key, @value, @right]
        elsif x > 0
          RedFork[@left, @key, @value, @right.ins(key, value)]
        else
          RedFork[@left, key, value, @right]
        end
      end
    end

    class BlackFork < Fork  #:nodoc:
      def red?
        false
      end

      def black?
        true
      end

      def make_red
        RedFork[left, key, value, right]
      end

      def make_black
        self
      end

      def ins(key, value)
        x = key <=> @key
        if x < 0
          balance(@left.ins(key, value), @key, @value, @right)
        elsif x > 0
          balance(@left, @key, @value, @right.ins(key, value))
        else
          BlackFork[@left, key, value, @right]
        end
      end
    end
  end
end
