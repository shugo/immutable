require_relative "../test_helper"

with_tailcall_optimization {
  require_relative "../../lib/immutable/stream"
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
      assert_equal(Stream[1], s.take(1))
      assert_equal(Stream[1, 2, 3], s.take(3))
      assert_equal(Stream[1, 3, 5], Stream.from(1, 2).take(3))
    end

    def test_cons
      assert_equal(Stream[1], Stream.empty.cons(1))
      assert_equal(Stream[1, 2], Stream.empty.cons(2).cons(1))
      assert_equal(Stream[1], Stream.empty.cons { 1 })
      assert_equal(Stream[1, 2], Stream.empty.cons { 2 }.cons { 1 })
    end

    def test_head
      assert_raise(EmptyError) do
        Stream.empty.head
      end
      assert_equal(1, Stream[1].head)
      assert_equal(1, Stream[1, 2, 3].head)
    end

    def test_tail
      assert_raise(EmptyError) do
        Stream.empty.tail
      end
      assert(Stream[1].tail.empty?)
      assert_equal([2, 3], Stream[1, 2, 3].tail.to_a)
    end

    def test_last
      assert_raise(EmptyError) do
        Stream.empty.last
      end
      assert_equal(1, Stream[1].last)
      assert_equal(3, Stream[1, 2, 3].last)
    end

    def test_init
      assert_raise(EmptyError) do
        Stream.empty.init.force
      end
      assert_equal(Stream[], Stream[1].init)
      assert_equal(Stream[1], Stream[1, 2].init)
      assert_equal(Stream[1, 2], Stream[1, 2, 3].init)
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
      assert_raise(EmptyError) do
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
      assert_raise(EmptyError) do
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

    def test_reverse
      assert_equal(Stream[], Stream[].reverse)
      assert_equal(Stream[1], Stream[1].reverse)
      assert_equal(Stream[2, 1], Stream[1, 2].reverse)
      assert_equal(Stream[3, 2, 1], Stream[1, 2, 3].reverse)
    end

    def test_intersperse
      assert_equal(Stream[], Stream[].intersperse(0))
      assert_equal(Stream[1], Stream[1].intersperse(0))
      assert_equal(Stream[1, 0, 2], Stream[1, 2].intersperse(0))
      assert_equal(Stream[1, 0, 2, 0, 3], Stream[1, 2, 3].intersperse(0))
      assert_equal(Stream[1, 0, 2, 0, 3],
                   Stream.from(1).intersperse(0).take(5))
    end

    def test_intercalate
      assert_equal(Stream[], Stream[].intercalate(Stream[0]))
      assert_equal(Stream[1], Stream[Stream[1]].intercalate(Stream[0]))
      xs = Stream[Stream[1, 2], Stream[3, 4], Stream[5, 6]].
        intercalate(Stream[0])
      assert_equal(Stream[1, 2, 0, 3, 4, 0, 5, 6], xs)
      xs = Stream.from(1, 2).map { |x| Stream[x, x + 1] }.
        intercalate(Stream[0]).take(8)
      assert_equal(Stream[1, 2, 0, 3, 4, 0, 5, 6], xs)
    end

    def test_find
      assert_equal(nil, Stream[].find(&:odd?))
      assert_equal(1, Stream[1, 2, 3, 4, 5].find(&:odd?))
      assert_equal(2, Stream[1, 2, 3, 4, 5].find(&:even?))
      assert_equal(1, Stream.from(1).find(&:odd?))
      assert_equal(2, Stream.from(1).find(&:even?))
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
      assert_equal(Stream[], Stream.from(1).take(0))
      assert_equal(Stream[1, 2, 3], Stream.from(1).take(3))
      assert_equal(Stream[0, 2, 4], Stream.from(0, 2).take(3))
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
      assert_equal(Stream[6, 7, 8], Stream.from(1).drop(5).take(3))
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
      nats = Stream.unfoldr(0) { |x| [x, x + 1] }
      assert_equal(Stream[0, 1, 2], nats.take(3))
      assert_equal(Stream[0, 1, 2, 3, 4], nats.take(5))
    end

    def test_zip
      s1 = Stream.from(0)
      s2 = Stream.from(0, 2)
      s3 = Stream.from(0, 3)
      assert_equal(Stream[[0, 0, 0], [1, 2, 3], [2, 4, 6]],
                   s1.zip(s2, s3).take(3))

      s1 = Stream[0, 1, 2]
      s2 = Stream.from(0, 2)
      s3 = Stream.from(0, 3)
      assert_equal(Stream[[0, 0, 0], [1, 2, 3], [2, 4, 6]],
                   s1.zip(s2, s3))
    end

    def test_zip_with
      s1 = Stream.from(0)
      s2 = Stream.from(0, 2)
      s3 = Stream.from(0, 3)
      s = s1.zip_with(s2, s3) { |x, y, z|
        x + y + z
      }
      assert_equal(Stream[0, 6, 12, 18], s.take(4))

      s1 = Stream[0, 1, 2, 3]
      s2 = Stream.from(0, 2)
      s3 = Stream.from(0, 3)
      s = s1.zip_with(s2, s3) { |x, y, z|
        x + y + z
      }
      assert_equal(Stream[0, 6, 12, 18], s)
    end

    def test_to_list
      assert_equal(List[], Stream[].to_list)
      assert_equal(List[1, 2, 3], Stream.from(1).take(3).to_list)
    end
  end
end
