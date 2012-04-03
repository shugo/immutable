# -*- tailcall-optimization: true; trace-instruction: false -*-
# ported from http://www.cs.kent.ac.uk/people/staff/smk/redblack/Untyped.hs

module Immutable
  class Map
    class InvarianceViolationError < StandardError
    end

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
      m = del(key)
      if m.empty?
        m
      else
        m.make_black
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
        # balance (T R a x b) y (T R c z d) = T R (T B a x b) y (T B c z d)
        if left.red? && right.red?
          RedNode[left.make_black, key, value, right.make_black]
        # balance (T R (T R a x b) y c) z d = T R (T B a x b) y (T B c z d)
        elsif left.red? && left.left.red?
          RedNode[
            left.left.make_black, left.key, left.value,
            BlackNode[left.right, key, value, right]
          ]
        # balance (T R a x (T R b y c)) z d = T R (T B a x b) y (T B c z d)
        elsif left.red? && left.right.red?
          RedNode[
            BlackNode[left.left, left.key, left.value, left.right.left],
            left.right.key, left.right.value,
            BlackNode[left.right.right, key, value, right]
          ]
        # balance a x (T R b y (T R c z d)) = T R (T B a x b) y (T B c z d)
        elsif right.red? && right.right.red?
          RedNode[
            BlackNode[left, key, value, right.left],
            right.key, right.value, right.right.make_black
          ]
        # balance a x (T R (T R b y c) z d) = T R (T B a x b) y (T B c z d)
        elsif right.red? && right.left.red?
          RedNode[
            BlackNode[left, key, value, right.left.left],
            right.left.key, right.left.value,
            BlackNode[right.left.right, right.key, right.value, right.right]
          ]
        # balance a x b = T B a x b
        else
          BlackNode[left, key, value, right]
        end
      end

      def del_left(left, key, value, right, del_key)
        if left.black?
          bal_left(left.del(del_key), key, value, right)
        else
          RedNode[left.del(del_key), key, value, right]
        end
      end

      def del_right(left, key, value, right, del_key)
        if right.black?
          bal_right(left, key, value, right.del(del_key))
        else
          RedNode[left, key, value, right.del(del_key)]
        end
      end

      def bal_left(left, key, value, right)
        if left.red?
          RedNode[left.make_black, key, value, right]
        elsif right.black?
          balance(left, key, value, right.make_red)
        elsif right.red? && right.left.black?
          RedNode[
            BlackNode[left, key, value, right.left.left],
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
          RedNode[left, key, value, right.make_black]
        elsif left.black?
          balance(left.make_red, key, value, right)
        elsif left.red? && left.right.black?
          RedNode[
            balance(sub1(left.left), left.key, left.value, left.right.left),
            left.right.key, left.right.value,
            BlackNode[left.right.right, key, value, right]
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
            RedNode[
              RedNode[left.left, left.key, left.value, m.left],
              m.key, m.value,
              RedNode[m.right, right.key, right.value, right.right]
            ]
          else
            RedNode[
              left.left, left.key, left.value,
              RedNode[m, right.key, right.value, right.right]
            ]
          end
        elsif left.black? && right.black?
          m = app(left.right, right.left)
          if m.red?
            RedNode[
              BlackNode[left.left, left.key, left.value, m.left],
              m.key, m.value,
              BlackNode[m.right, right.key, right.value, right.right]
            ]
          else
            bal_left(left.left, left.key, left.value,
                     BlackNode[m, right.key, right.value, right.right])
          end
        elsif right.red?
          RedNode[app(left, right.left), right.key, right.value,
            right.right]
        elsif left.red?
          RedNode[left.left, left.key, left.value, app(left.right, right)]
        else
          raise ScriptError, "should not reach here"
        end
      end
    end

    class RedNode < Node
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

      def make_red
        RedNode[left, key, value, right]
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
