# ported from http://www.cs.kent.ac.uk/people/staff/smk/redblack/Untyped.hs

require "pattern-match"

module Immutable
  class Map
    include PatternMatch::Extractable

    def self.empty
      EMPTY
    end

    def self.singleton(key, value)
      EMPTY.insert(key, value)
    end

    def insert(key, value)
      ins(key, value).make_black
    end

    def delete(key)
      match del(key) do
        with(EMPTY) { EMPTY }
        with(node) { node.make_black }
      end
    end

    EMPTY = Map.new

    def EMPTY.empty?
      true
    end

    def EMPTY.red?
      false
    end

    def EMPTY.black?
      true
    end

    def EMPTY.inspect
      "Map::EMPTY"
    end

    def EMPTY.[](key)
      nil
    end

    def EMPTY.ins(key, value)
      RedNode[EMPTY, key, value, EMPTY]
    end

    def EMPTY.del(key)
      EMPTY
    end

    def EMPTY.each
    end

    class Node < Map
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

      private

      def balance(left, key, value, right)
        if left.red? && right.red?
          RedNode[left.make_black, key, value, right.make_black]
        elsif left.red? && left.left.red?
          RedNode[left.left.make_black, left.key, left.value,
            BlackNode[left.right, key, value, right]]
        elsif left.red? && left.right.red?
          RedNode[BlackNode[left.left, left.key, left.value, left.right.left],
            left.right.key, left.right.value,
            BlackNode[left.right.right, key, value, right]]
        elsif right.red? && right.right.red?
          RedNode[BlackNode[left, key, value, right.left],
            right.key, right.value, right.right.make_black]
        elsif right.red? && right.left.red?
          RedNode[BlackNode[left, key, value, right.left.left],
            right.left.key, right.left.value,
            BlackNode[right.left.right, right.key, right.value, right.right]]
        else
          BlackNode[left, key, value, right]
        end
      end

      def del_left(left, key, value, right, del_key)
        match left do
          with(BlackNode.(_)) { bal_left(left.del(del_key), key, value, right) }
          with(_) { RedNode[left.del(del_key), key, value, right] }
        end
      end

      def del_right(left, key, value, right, del_key)
        match right do
          with(BlackNode.(_)) { bal_right(left, key, value, right.del(del_key)) }
          with(_) { RedNode[left, key, value, right.del(del_key)] }
        end
      end

      def bal_left(left, key, value, right)
        match [left, key, value, right] do
          with _[RedNode.(a, x, xv, b), y, yz, c] do
            RedNode[BlackNode[a, x, xv, b], y, yz, c]
          end
          with _[bl, x, xv, BlackNode.(a, y, yv, b)] do
            balance(bl, x, xv, RedNode[a, y, yv, b])
          end
          with _[bl, x, xv, RedNode.(BlackNode.(a, y, yv, b), z, zv, c)] do
            RedNode[BlackNode[bl, x, xv, a], y, yz, balance(b, z, zv, sub1(c))]
          end
        end
      end

      def bal_right(left, key, value, right)
        match [left, key, value, right] do
          with _[a, x, xv, RedNode.(b, y, yv, c)] do
            RedNode[a, x, xv, BlackNode[b, y, yv, c]]
          end
          with _[BlackNode.(a, x, xv, b), y, yv, bl] do
            balance(RedNode[a, x, xv, b], y, yz, bl)
          end
          with _[RedNode.(a, x, xv, BlackNode.(b, y, yz, c)), z, zv, bl] do
            RedNode[balance(sub1(a), x, xv, b), y, yz, BlackNode[c, z, zv, bl]]
          end
        end
      end

      def sub1(node)
        match node do
          with BlackNode.(a, x, xv, b) do
            RedNode[a, x, xv, b]
          end
          with _ do
            raise "invariance violation"
          end
        end
      end

      def app(left, right)
        match [left, right] do
          with(_[EMPTY, x]) { x }
          with(_[x, EMPTY]) { x }
          with _[RedNode.(a, x, xv, b), RedNode.(c, y, yz, d)] do
            app_RR(a, x, xv, b, c, y, yz, d)
          end
          with _[BlackNode.(a, x, xv, b), BlackNode.(c, y, yz, d)] do
            app_BB(a, x, xv, b, c, y, yz, d)
          end
          with _[a, RedNode.(b, x, xv, c)] do
            app_BR(a, b, x, xv, c)
          end
          with _[RedNode.(a, x, xv, b), c] do
            app_RB(a, x, xv, b, c)
          end
        end
      end

      def app_RR(a, x, xv, b, c, y, yz, d)
        match app(b, c) do
          with RedNode.(b2, z, zv, c2) do
            RedNode[RedNode[a, x, xv, b2], z, zv, RedNode[c2, y, yz, d]]
          end
          with bc do
            RedNode[a, x, xv, RedNode[bc, y, yz, d]]
          end
        end
      end

      def app_BB(a, x, xv, b, c, y, yz, d)
        match app(b, c) do
          with RedNode.(b2, z, zv, c2) do
            RedNode[BlackNode[a, x, xv, b2], z, zv, BlackNode[c2, y, yz, d]]
          end
          with bc do
            bal_left(a, x, xv, BlackNode[bc, y, yz, d])
          end
        end
      end

      def app_BR(a, b, x, xv, c)
        RedNode[app(a, b), x, xv, c]
      end

      def app_RB(a, x, xv, b, c)
        RedNode[a, x, xv, app(b, c)]
      end
    end

    class RedNode < Node
      def red?
        true
      end

      def black?
        false
      end

      def make_black
        BlackNode[left, key, value, right]
      end

      def ins(key, value)
        if key < self.key
          RedNode[left.ins(key, value), self.key, self.value, right]
        elsif key > self.key
          RedNode[left, self.key, self.value, right.ins(key, value)]
        else
          RedNode[left, key, value, right]
        end
      end
    end

    class BlackNode < Node
      def red?
        false
      end

      def black?
        true
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
          BlackNode[left, key, value, right]
        end
      end
    end
  end
end

if __FILE__ == $0
  require "pp"
  tree = ("a".."z").to_a.shuffle.each_with_index.inject(RedBlack::EMPTY) {
    |t, (k, v)|
    t.insert(k, v)
  }
  p tree["a"]
  tree2 = ("a".."g").inject(tree) { |t, k| t.delete(k) }
  p tree2["a"]
  p tree["a"]
end
