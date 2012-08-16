require_relative "../test_helper"

with_tailcall_optimization {
  require_relative "../../lib/immutable/deque"
}

module Immutable
  class TestDeque < Test::Unit::TestCase
    def test_head
      assert_raise(EmptyError) do
        Deque[].head
      end
      assert_equal(1, Deque[1].head)
      assert_equal(1, Deque[1, 2, 3].head)
    end

    def test_last
      assert_raise(EmptyError) do
        Deque[].last
      end
      assert_equal(1, Deque[1].last)
      assert_equal(3, Deque[1, 2, 3].last)
    end

    def test_tail
      assert_raise(EmptyError) do
        Deque[].tail
      end
      assert(Deque[1].tail.empty?)
      assert_equal(2, Deque[1, 2].tail.head)
      assert_equal(2, Deque[1, 2, 3].tail.head)
      assert_equal(3, Deque[1, 2, 3].tail.tail.head)
    end

    def test_init
      assert_raise(EmptyError) do
        Deque[].init
      end
      assert(Deque[1].init.empty?)
      assert_equal(1, Deque[1, 2].init.last)
      assert_equal(2, Deque[1, 2, 3].init.last)
      assert_equal(1, Deque[1, 2, 3].init.init.last)
    end

    def test_cons
      q1 = Deque.empty.cons(1)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)
      q2 = q1.cons(2)
      assert_equal(2, q2.head)
      assert_equal(1, q2.tail.head)
      assert(q2.tail.tail.empty?)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)

      a = (1..1000).to_a.shuffle
      q = a.inject(Deque.empty, :cons)
      assert_equal(a.reverse, q.to_a)
    end

    def test_snoc
      q1 = Deque.empty.snoc(1)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)
      q2 = q1.snoc(2)
      assert_equal(1, q2.head)
      assert_equal(2, q2.tail.head)
      assert(q2.tail.tail.empty?)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)

      a = (1..1000).to_a.shuffle
      q = a.inject(Deque.empty, :snoc)
      assert_equal(a, q.to_a)
    end

    def test_invariants
      a = (1..1000).to_a.shuffle
      deque = a.inject(Deque.empty) { |d, i|
        assert_deque_invariants(d)
        if rand(2) == 0
          d2 = d.snoc(i)
        else
          d2 = d.cons(i)
        end
        case rand(4)
        when 0
          d2.tail
        when 1
          d2.init
        else
          d2
        end
      }
      assert_deque_invariants(deque)
      until deque.empty?
        if rand(2) == 0
          deque = deque.tail
        else
          deque = deque.init
        end
        assert_deque_invariants(deque)
      end
    end

    private

    def assert_deque_invariants(d)
      c = d.instance_variable_get(:@c)
      front_len = d.instance_variable_get(:@front_len)
      rear_len = d.instance_variable_get(:@rear_len)
      assert(front_len <= c * rear_len + 1)
      assert(rear_len <= c * front_len + 1)
    end
  end
end
