require_relative "../test_helper"

with_tailcall_optimization {
  require "immutable/queue"
}

module Immutable
  class TestQueue < Test::Unit::TestCase
    def test_head
      assert_raise(EmptyError) do
        Queue[].head
      end
      assert_equal(1, Queue[1].head)
      assert_equal(1, Queue[1, 2, 3].head)
    end

    def test_tail
      assert_raise(EmptyError) do
        Queue[].tail
      end
      assert(Queue[1].tail.empty?)
      assert_equal(2, Queue[1, 2].tail.head)
      assert_equal(2, Queue[1, 2, 3].tail.head)
      assert_equal(3, Queue[1, 2, 3].tail.tail.head)
    end

    def test_snoc
      q1 = Queue.empty.snoc(1)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)
      q2 = q1.snoc(2)
      assert_equal(1, q2.head)
      assert_equal(2, q2.tail.head)
      assert(q2.tail.tail.empty?)
      assert_equal(1, q1.head)
      assert(q1.tail.empty?)

      a = (1..1000).to_a.shuffle
      q = a.inject(Queue.empty, :snoc)
      assert_equal(a, q.to_a)
    end

    def test_invariant
      a = (1..100).to_a.shuffle
      queue = a.inject(Queue.empty) { |q, i|
        assert_queue_invariant(q)
        q2 = q.snoc(i)
        if rand(3) == 0
          q2.tail
        else
          q2
        end
      }
      assert_queue_invariant(queue)
      until queue.empty?
        queue = queue.tail
        assert_queue_invariant(queue)
      end
    end

    private

    def assert_queue_invariant(d)
      front = d.instance_variable_get(:@front)
      rear = d.instance_variable_get(:@rear)
      schedule = d.instance_variable_get(:@schedule)
      assert_equal(schedule.length, front.length - rear.length)
    end
  end
end
