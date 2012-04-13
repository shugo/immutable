require_relative "../test_helper"

with_tailcall_optimization {
  require "immutable/stream"
}

module Immutable
  class TestStream < Test::Unit::TestCase
    def test_s_from_enum
      assert_equal([], Stream.from_enum([]).to_a)
      assert_equal([1, 2, 3], Stream.from_enum([1, 2, 3]).to_a)
      assert_equal(["a", "b", "c"],
                   Stream.from_enum("abc".chars).to_a)
    end

    def test_s_from_enumerator
      e = [1, 2, 3, 4, 5].each
      s1 = Stream.from_enumerator(e)
      s2 = Stream.from_enumerator(e)
      assert_equal(1, s1.head)
      assert_equal(2, s2.head)
      assert_equal(1, s1.head)
      assert_equal([1, 3], s1.take(2).to_a)
      assert_equal(4, s2.drop(1).head)
      assert_equal([1, 3, 5], s1.to_a)
      assert_equal([2, 4], s2.to_a)
    end

    def test_s_from
      s = Stream.from(1)
    end

    def test_head
      assert_raise(List::EmptyError) do
        Stream.null.head
      end
      assert_equal(1, Stream[1].head)
      assert_equal(1, Stream[1, 2, 3].head)
    end

    def test_tail
      assert_raise(List::EmptyError) do
        Stream.null.tail
      end
      assert(Stream[1].tail.null?)
      assert_equal([2, 3], Stream[1, 2, 3].tail.to_a)
    end

    def test_last
      assert_raise(List::EmptyError) do
        Stream.null.last
      end
      assert_equal(1, Stream[1].last)
      assert_equal(3, Stream[1, 2, 3].last)
    end

    def test_aref
      s = Stream[1, 2, 3, 4, 5]
      2.times do
        assert_equal(nil, s[-1])
        assert_equal(1, s[0])
        assert_equal(5, s[4])
        assert_equal(nil, s[5])
        assert_equal(4, s[3])
      end
    end

    def test_empty?
      assert(Stream[].empty?)
      assert(!Stream[1].empty?)
      assert(!Stream[1, 2, 3].empty?)
    end

    def test_each
      a = []
      Stream[].each { |x| a << x }
      assert_equal([], a)

      a = []
      Stream[1, 2, 3].each { |x| a << x }
      assert_equal([1, 2, 3], a)
    end

    def test_foldr
      assert_equal(0, Stream[].foldr(0, &:+))
      assert_equal(123, Stream[].foldr(123, &:+))

      assert_equal(6, Stream[1, 2, 3].foldr(0, &:+))
      # 1 - (2 - (3 - 10))
      assert_equal(-8, Stream[1, 2, 3].foldr(10, &:-))
    end

    def test_foldr1
      assert_raise(List::EmptyError) do
        Stream[].foldr1(&:+)
      end
      assert_equal(1, Stream[1].foldr1(&:+))
      assert_equal(3, Stream[1, 2].foldr1(&:+))
      assert_equal(6, Stream[1, 2, 3].foldr1(&:+))
      assert_equal(2, Stream[1, 2, 3].foldr1(&:-))
    end

    def test_foldl
      assert_equal(0, Stream[].foldl(0, &:+))
      assert_equal(123, Stream[].foldl(123, &:+))

      assert_equal(6, Stream[1, 2, 3].foldl(0, &:+))
      # ((10 - 1) - 2) - 3
      assert_equal(4, Stream[1, 2, 3].foldl(10, &:-))
    end

    def test_foldl1
      assert_raise(List::EmptyError) do
        Stream[].foldl1(&:+)
      end
      assert_equal(1, Stream[1].foldl1(&:+))
      assert_equal(3, Stream[1, 2].foldl1(&:+))
      assert_equal(6, Stream[1, 2, 3].foldl1(&:+))
      assert_equal(-4, Stream[1, 2, 3].foldl1(&:-))
    end

    def test_eq
      assert(Stream[] == Stream[])
      assert(Stream[] != Stream[1])
      assert(Stream[1] != Stream[])
      assert(Stream[1] == Stream[1])
      assert(Stream[1] != Stream[2])
      assert(Stream["foo"] == Stream["foo"])
      assert(Stream["foo"] != Stream["bar"])
      assert(Stream[1, 2, 3] == Stream[1, 2, 3])
      assert(Stream[1, 2, 3] != Stream[1, 2])
      assert(Stream[1, 2, 3] != Stream[1, 2, 3, 4])
      assert(Stream[Stream[1, 2], Stream[3, 4]] ==
             Stream[Stream[1, 2], Stream[3, 4]])
      assert(Stream[Stream[1, 2], Stream[3, 4]] !=
             Stream[Stream[1, 2], Stream[3]])
      assert(Stream[] != Stream.from(1))
      assert(Stream.from(1) != Stream[])
      assert(Stream[1] != Stream.from(1))
      assert(Stream.from(1) != Stream[1])
    end

    def test_inspect
      s = Stream[]
      assert_equal('Stream[...]', s.inspect)
      assert_equal(nil, s[0])
      assert_equal('Stream[]', s.inspect)
      s = Stream[1]
      assert_equal('Stream[...]', s.inspect)
      assert_equal(1, s[0])
      assert_equal('Stream[1, ...]', s.inspect)
      assert_equal(nil, s[1])
      assert_equal('Stream[1]', s.inspect)
      s = Stream["foo"]
      assert_equal("foo", s[0])
      assert_equal('Stream["foo", ...]', s.inspect)
      assert_equal(nil, s[1])
      assert_equal('Stream["foo"]', s.inspect)
      s = Stream[1, 2, 3]
      assert_equal('Stream[...]', s.inspect)
      assert_equal(1, s[0])
      assert_equal('Stream[1, ...]', s.inspect)
      assert_equal(2, s[1])
      assert_equal('Stream[1, 2, ...]', s.inspect)
      assert_equal(3, s[2])
      assert_equal('Stream[1, 2, 3, ...]', s.inspect)
      assert_equal(nil, s[3])
      assert_equal('Stream[1, 2, 3]', s.inspect)
      s = Stream[1, 2, 3]
      assert_equal(2, s[1])
      assert_equal('Stream[?, 2, ...]', s.inspect)
      s = Stream[Stream[1, 2], Stream[3, 4]]
      assert_equal(Stream[1, 2], s[0])
      assert_equal(Stream[3, 4], s[1])
      assert_equal(nil, s[2])
      assert_equal('Stream[Stream[1, 2], Stream[3, 4]]',
                   s.inspect)
    end

    def test_length
      assert_equal(0, Stream[].length)
      assert_equal(1, Stream[1].length)
      assert_equal(3, Stream[1, 2, 3].length)
      assert_equal(100, Stream.from(1).take(100).length)
    end

    def test_plus
      assert_equal(Stream[], Stream[] + Stream[])
      assert_equal(Stream[1, 2, 3], Stream[] + Stream[1, 2, 3])
      assert_equal(Stream[1, 2, 3], Stream[1, 2, 3] + Stream[])
      assert_equal(Stream[1, 2, 3], Stream[1] + Stream[2, 3])
      assert_equal(Stream[1, 2, 3], Stream[1, 2] + Stream[3])
    end

    def test_flatten
      assert_equal(Stream[], Stream[].flatten)
      assert_equal(Stream[1], Stream[Stream[1]].flatten)
      assert_equal(Stream[Stream[1]],
                   Stream[Stream[Stream[1]]].flatten)
      assert_equal(Stream[1, 2, 3], Stream[Stream[1, 2], Stream[3]].flatten)
      assert_equal(Stream[1, 2, 3],
                   Stream[Stream[1], Stream[2], Stream[3]].flatten)
    end

    def test_map
      assert_equal(Stream[], Stream[].map(&:to_s))
      assert_equal(Stream["1", "2", "3"], Stream[1, 2, 3].map(&:to_s))
    end

    def test_filter
      assert_equal(Stream[], Stream[].filter(&:odd?))
      assert_equal(Stream[1, 3, 5], Stream[1, 2, 3, 4, 5].filter(&:odd?))
      assert_equal(Stream[2, 4], Stream[1, 2, 3, 4, 5].filter(&:even?))
    end

    def test_take
      assert_equal(Stream[], Stream[].take(1))
      assert_equal(Stream[], Stream[1, 2, 3].take(0))
      assert_equal(Stream[], Stream[1, 2, 3].take(-1))
      assert_equal(Stream[1], Stream[1, 2, 3].take(1))
      assert_equal(Stream[1, 2], Stream[1, 2, 3].take(2))
      assert_equal(Stream[1, 2, 3], Stream[1, 2, 3].take(3))
      assert_equal(Stream[1, 2, 3], Stream[1, 2, 3].take(4))
    end

    def test_take_while
      assert_equal(Stream[], Stream[].take_while { true })
      assert_equal(Stream[], Stream[1, 2, 3].take_while { |x| x < 1 })
      assert_equal(Stream[1], Stream[1, 2, 3].take_while { |x| x < 2 })
      assert_equal(Stream[1, 2], Stream[1, 2, 3].take_while { |x| x < 3 })
      assert_equal(Stream[1, 2, 3],
                   Stream[1, 2, 3].take_while { |x| x < 4 })
    end

    def test_drop
      assert_equal(Stream[], Stream[].drop(1))
      assert_equal(Stream[1, 2, 3], Stream[1, 2, 3].drop(0))
      assert_equal(Stream[1, 2, 3], Stream[1, 2, 3].drop(-1))
      assert_equal(Stream[2, 3], Stream[1, 2, 3].drop(1))
      assert_equal(Stream[3], Stream[1, 2, 3].drop(2))
      assert_equal(Stream[], Stream[1, 2, 3].drop(3))
      assert_equal(Stream[], Stream[1, 2, 3].drop(4))
    end

    def test_drop_while
      assert_equal(Stream[], Stream[].drop_while { false })
      assert_equal(Stream[1, 2, 3],
                   Stream[1, 2, 3].drop_while { |x| x < 1 })
      assert_equal(Stream[2, 3], Stream[1, 2, 3].drop_while { |x| x < 2 })
      assert_equal(Stream[3], Stream[1, 2, 3].drop_while { |x| x < 3 })
      assert_equal(Stream[], Stream[1, 2, 3].drop_while { |x| x < 4 })
    end

    def test_s_unfoldr
      xs = Stream.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
      assert_equal(Stream[3, 2, 1], xs)
      xs = Stream.unfoldr("foo,bar,baz") { |x|
        if x.empty?
          nil
        else
          y = x.slice(/([^,]*),?/, 1)
          [y, $']
        end
      }
      assert_equal(Stream["foo", "bar", "baz"], xs)
    end
  end
end
