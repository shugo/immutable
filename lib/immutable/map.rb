# -*- tailcall-optimization: true; trace-instruction: false -*-
# ported from http://www.cs.kent.ac.uk/people/staff/smk/redblack/Untyped.hs

module Immutable
  class Map
    class InvarianceViolationError < StandardError
    end

    def self.empty
      Leaf
    end

    def self.singleton(key, value)
      Leaf.insert(key, value)
    end

    def self.[](h = {})
      h.inject(Leaf) { |m, (k, v)| m.insert(k, v) }
    end

    def insert(key, value)
      ins(key, value).make_black
    end

    def delete(key)
      m = del(key)
      if m.empty?
        m
      else
        m.make_black
      end
    end

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

    def foldr(e)
      foldr_with_key(e) { |k, v, x| yield(v, x) }
    end

    def foldl(e)
      foldl_with_key(e) { |x, k, v| yield(x, v) }
    end

    def map
      map_with_key { |k, v| yield(v) }
    end

    def map_with_key
      foldr_with_key(List[]) { |k, v, xs| Cons[yield(k, v), xs] }
    end

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

    def Leaf.each
    end

    class Fork < Map
      attr_reader :left, :key, :value, :right

      def initialize(left, key, value, right)
        @left, @key, @value, @right = left, key, value, right
      end

      def self.extract(val)
        accept_self_instance_only(val)
        [val.left, val.key, val.value, val.right]
      end

      class << self
        alias [] new
      end

      def empty?
        false
      end

      def [](key)
        if key < self.key
          left[key]
        elsif key > self.key
          right[key]
        else
          value
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

      def each(&block)
        left.each(&block)
        yield key, value
        right.each(&block)
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

      private

      def balance(left, key, value, right)
        # balance (T R a x b) y (T R c z d) = T R (T B a x b) y (T B c z d)
        if left.red? && right.red?
          RedFork[left.make_black, key, value, right.make_black]
        # balance (T R (T R a x b) y c) z d = T R (T B a x b) y (T B c z d)
        elsif left.red? && left.left.red?
          RedFork[
            left.left.make_black, left.key, left.value,
            BlackFork[left.right, key, value, right]
          ]
        # balance (T R a x (T R b y c)) z d = T R (T B a x b) y (T B c z d)
        elsif left.red? && left.right.red?
          RedFork[
            BlackFork[left.left, left.key, left.value, left.right.left],
            left.right.key, left.right.value,
            BlackFork[left.right.right, key, value, right]
          ]
        # balance a x (T R b y (T R c z d)) = T R (T B a x b) y (T B c z d)
        elsif right.red? && right.right.red?
          RedFork[
            BlackFork[left, key, value, right.left],
            right.key, right.value, right.right.make_black
          ]
        # balance a x (T R (T R b y c) z d) = T R (T B a x b) y (T B c z d)
        elsif right.red? && right.left.red?
          RedFork[
            BlackFork[left, key, value, right.left.left],
            right.left.key, right.left.value,
            BlackFork[right.left.right, right.key, right.value, right.right]
          ]
        # balance a x b = T B a x b
        else
          BlackFork[left, key, value, right]
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

      def bal_left(left, key, value, right)
        if left.red?
          RedFork[left.make_black, key, value, right]
        elsif right.black?
          balance(left, key, value, right.make_red)
        elsif right.red? && right.left.black?
          RedFork[
            BlackFork[left, key, value, right.left.left],
            right.left.key, right.left.value,
            balance(right.left.right, right.key, right.value,
                    sub1(right.right))
          ]
        else
          raise ScriptError, "should not reach here"
        end
      end

      def bal_right(left, key, value, right)
        if right.red?
          RedFork[left, key, value, right.make_black]
        elsif left.black?
          balance(left.make_red, key, value, right)
        elsif left.red? && left.right.black?
          RedFork[
            balance(sub1(left.left), left.key, left.value, left.right.left),
            left.right.key, left.right.value,
            BlackFork[left.right.right, key, value, right]
          ]
        else
          raise ScriptError, "should not reach here"
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

    class RedFork < Fork
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
        if key < self.key
          RedFork[left.ins(key, value), self.key, self.value, right]
        elsif key > self.key
          RedFork[left, self.key, self.value, right.ins(key, value)]
        else
          RedFork[left, key, value, right]
        end
      end
    end

    class BlackFork < Fork
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
        if key < self.key
          balance(left.ins(key, value), self.key, self.value, right)
        elsif key > self.key
          balance(left, self.key, self.value, right.ins(key, value))
        else
          BlackFork[left, key, value, right]
        end
      end
    end
  end
end
