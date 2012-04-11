require "test/unit"

def with_tailcall_optimization
  old_compile_option = RubyVM::InstructionSequence.compile_option
  RubyVM::InstructionSequence.compile_option = {
    :tailcall_optimization => true,
    :trace_instruction => false
  }
  begin
    yield
  ensure
    RubyVM::InstructionSequence.compile_option = old_compile_option
  end
end

with_tailcall_optimization {
  require "immutable/promise"
  require "immutable/list"
}

module Immutable
  class TestPromise < Test::Unit::TestCase
    def test_eager
      assert_equal(123, Promise.eager(123).force)
    end

    def test_delay
      assert_equal(123, Promise.delay { 123 }.force)
      count = 0
      x = Promise.delay { count += 1; 123 }
      assert_equal(0, count)
      assert_equal(123, x.force)
      assert_equal(1, count)
    end

    def test_memoization1
      count = 0
      s = Promise.delay { count += 1; 1 }
      assert_equal(1, s.force)
      assert_equal(1, s.force)
      assert_equal(1, count)
    end

    def test_memoization2
      count = 0
      s = Promise.delay { count += 1; 2 }
      assert_equal(4, s.force + s.force)
      assert_equal(1, count)
    end

    def test_memoization3
      count = 0
      r = Promise.delay { count += 1; 1 }
      s = Promise.lazy { r }
      t = Promise.lazy { s }
      assert_equal(1, t.force)
      assert_equal(1, s.force)
      assert_equal(1, count)
    end

    def test_memoization4
      stream_drop = ->(s, index) {
        Promise.lazy {
          if index.zero?
            s
          else
            stream_drop[s.force.tail, index - 1]
          end
        }
      }
      count = 0
      ones = -> {
        Promise.delay {
          count += 1
          Cons[1, ones[]]
        }
      }
      s = ones[]
      assert_equal(1, stream_drop[s, 4].force.head)
      assert_equal(1, stream_drop[s, 4].force.head)
      assert_equal(5, count)
    end

    def test_reentrancy1
      count = 0
      x = 5
      p = Promise.delay {
        count += 1
        if count > x
          count
        else
          p.force
        end
      }
      assert_equal(6, p.force)
      x = 10
      assert_equal(6, p.force)
    end

    def test_reentrancy2
      first = true
      f = Promise.delay {
        if first
          first = false
          f.force
        else
          :second
        end
      }
      assert_equal(:second, f.force)
    end

    def test_reentrancy3
      q = -> {
        count = 5
        get_count = -> { count }
        p = Promise.delay {
          if count <= 0
            count
          else
            count -= 1
            p.force
            count += 2
            count
          end
        }
        [get_count, p]
      }[]
      get_count, p = q
      assert_equal(5, get_count[])
      assert_equal(0, p.force)
      assert_equal(10, get_count[])
    end

    def nloop(n)
      Promise.lazy { n <= 0 ? Promise.eager(0) : nloop(n - 1) }
    end

    def test_leak1
      assert_equal(0, nloop(10000).force)
    end

    def test_leak2
      s = nloop(10000)
      assert_equal(0, s.force)
    end

    def from(n)
      Promise.delay {
        Cons[n, from(n + 1)]
      }
    end

    def traverse(s, n)
      Promise.lazy {
        if n <= 0
          s
        else
          traverse(s.force.tail, n - 1)
        end
      }
    end

    def test_leak3
      assert_equal(10000, traverse(from(0), 10000).force.head)
    end

    def test_leak4
      s = traverse(from(0), 10000)
      assert_equal(10000, s.force.head)
    end
  end
end
