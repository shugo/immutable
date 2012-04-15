require_relative "../test_helper"

with_tailcall_optimization {
  require "immutable/list"
}

module Immutable
  class TestList < Test::Unit::TestCase
    def test_s_from_array
      assert_equal(List[], List.from_array([]))
      assert_equal(List[1, 2, 3], List.from_array([1, 2, 3]))
    end

    def test_s_from_enum
      assert_equal(List[], List.from_enum([]))
      assert_equal(List[1, 2, 3], List.from_enum(1..3))
      assert_equal(List["a", "b", "c"], List.from_enum("abc".chars))
    end

    def test_head
      assert_raise(List::EmptyError) do
        List[].head
      end
      assert_equal(1, List[1].head)
      assert_equal(1, List[1, 2, 3].head)
    end

    def test_last
      assert_raise(List::EmptyError) do
        List[].last
      end
      assert_equal(1, List[1].last)
      assert_equal(3, List[1, 2, 3].last)
    end

    def test_tail
      assert_raise(List::EmptyError) do
        List[].tail
      end
      assert_equal(List[], List[1].tail)
      assert_equal(List[2, 3], List[1, 2, 3].tail)
    end

    def test_init
      assert_raise(List::EmptyError) do
        List[].init
      end
      assert_equal(List[], List[1].init)
      assert_equal(List[1, 2], List[1, 2, 3].init)
    end

    def test_empty?
      assert(List[].empty?)
      assert(!List[1].empty?)
      assert(!List[1, 2, 3].empty?)
    end

    def test_each
      a = []
      List[].each { |x| a << x }
      assert_equal([], a)

      a = []
      List[1, 2, 3].each { |x| a << x }
      assert_equal([1, 2, 3], a)
    end

    def test_foldr
      assert_equal(0, List[].foldr(0, &:+))
      assert_equal(123, List[].foldr(123, &:+))

      assert_equal(6, List[1, 2, 3].foldr(0, &:+))
      # 1 - (2 - (3 - 10))
      assert_equal(-8, List[1, 2, 3].foldr(10, &:-))
    end

    def test_foldr1
      assert_raise(List::EmptyError) do
        List[].foldr1(&:+)
      end
      assert_equal(1, List[1].foldr1(&:+))
      assert_equal(3, List[1, 2].foldr1(&:+))
      assert_equal(6, List[1, 2, 3].foldr1(&:+))
      assert_equal(2, List[1, 2, 3].foldr1(&:-))
    end

    def test_foldl
      assert_equal(0, List[].foldl(0, &:+))
      assert_equal(123, List[].foldl(123, &:+))

      assert_equal(6, List[1, 2, 3].foldl(0, &:+))
      # ((10 - 1) - 2) - 3
      assert_equal(4, List[1, 2, 3].foldl(10, &:-))
    end

    def test_foldl1
      assert_raise(List::EmptyError) do
        List[].foldl1(&:+)
      end
      assert_equal(1, List[1].foldl1(&:+))
      assert_equal(3, List[1, 2].foldl1(&:+))
      assert_equal(6, List[1, 2, 3].foldl1(&:+))
      assert_equal(-4, List[1, 2, 3].foldl1(&:-))
    end

    def test_eq
      assert(List[] == List[])
      assert(List[] != List[1])
      assert(List[1] != List[])
      assert(List[1] == List[1])
      assert(List[1] != List[2])
      assert(List[1] != [1])
      assert(List["foo"] == List["foo"])
      assert(List["foo"] != List["bar"])
      assert(List[1, 2, 3] == List[1, 2, 3])
      assert(List[1, 2, 3] != List[1, 2])
      assert(List[1, 2, 3] != List[1, 2, 3, 4])
      assert(List[List[1, 2], List[3, 4]] == List[List[1, 2], List[3, 4]])
      assert(List[List[1, 2], List[3, 4]] != List[List[1, 2], List[3]])
    end

    def test_inspect
      assert_equal('List[]', List[].inspect)
      assert_equal('List[1]', List[1].inspect)
      assert_equal('List["foo"]', List["foo"].inspect)
      assert_equal('List[1, 2, 3]', List[1, 2, 3].inspect)
      assert_equal('List[List[1, 2], List[3, 4]]',
                   List[List[1, 2], List[3, 4]].inspect)
    end

    def test_length
      assert_equal(0, List[].length)
      assert_equal(1, List[1].length)
      assert_equal(3, List[1, 2, 3].length)
      assert_equal(100, List[*(1..100)].length)
    end

    def test_plus
      assert_equal(List[], List[] + List[])
      assert_equal(List[1, 2, 3], List[] + List[1, 2, 3])
      assert_equal(List[1, 2, 3], List[1, 2, 3] + List[])
      assert_equal(List[1, 2, 3], List[1] + List[2, 3])
      assert_equal(List[1, 2, 3], List[1, 2] + List[3])
    end

    def test_flatten
      assert_equal(List[], List[].flatten)
      assert_equal(List[1], List[List[1]].flatten)
      assert_equal(List[List[1]], List[List[List[1]]].flatten)
      assert_equal(List[1, 2, 3], List[List[1, 2], List[3]].flatten)
      assert_equal(List[1, 2, 3], List[List[1], List[2], List[3]].flatten)
    end

    def test_map
      assert_equal(List[], List[].map(&:to_s))
      assert_equal(List["1", "2", "3"], List[1, 2, 3].map(&:to_s))
    end

    def test_flat_map
      assert_equal(List[], List[].flat_map {})
      assert_equal(List["1", "2", "3"], List[1, 2, 3].map(&:to_s))
    end

    def test_find
      assert_equal(nil, List[].find(&:odd?))
      assert_equal(1, List[1, 2, 3, 4, 5].find(&:odd?))
      assert_equal(2, List[1, 2, 3, 4, 5].find(&:even?))
    end

    def test_filter
      assert_equal(List[], List[].filter(&:odd?))
      assert_equal(List[1, 3, 5], List[1, 2, 3, 4, 5].filter(&:odd?))
      assert_equal(List[2, 4], List[1, 2, 3, 4, 5].filter(&:even?))
    end

    def test_aref
      assert_equal(nil, List[][0])
      assert_equal(1, List[1, 2, 3][0])
      assert_equal(nil, List[1, 2, 3][-1])
      assert_equal(2, List[1, 2, 3][1])
      assert_equal(3, List[1, 2, 3][2])
      assert_equal(nil, List[1, 2, 3][3])
    end

    def test_take
      assert_equal(List[], List[].take(1))
      assert_equal(List[], List[1, 2, 3].take(0))
      assert_equal(List[], List[1, 2, 3].take(-1))
      assert_equal(List[1], List[1, 2, 3].take(1))
      assert_equal(List[1, 2], List[1, 2, 3].take(2))
      assert_equal(List[1, 2, 3], List[1, 2, 3].take(3))
      assert_equal(List[1, 2, 3], List[1, 2, 3].take(4))
    end

    def test_take_while
      assert_equal(List[], List[].take_while { true })
      assert_equal(List[], List[1, 2, 3].take_while { |x| x < 1 })
      assert_equal(List[1], List[1, 2, 3].take_while { |x| x < 2 })
      assert_equal(List[1, 2], List[1, 2, 3].take_while { |x| x < 3 })
      assert_equal(List[1, 2, 3], List[1, 2, 3].take_while { |x| x < 4 })
    end

    def test_drop
      assert_equal(List[], List[].drop(1))
      assert_equal(List[1, 2, 3], List[1, 2, 3].drop(0))
      assert_equal(List[1, 2, 3], List[1, 2, 3].drop(-1))
      assert_equal(List[2, 3], List[1, 2, 3].drop(1))
      assert_equal(List[3], List[1, 2, 3].drop(2))
      assert_equal(List[], List[1, 2, 3].drop(3))
      assert_equal(List[], List[1, 2, 3].drop(4))
    end

    def test_drop_while
      assert_equal(List[], List[].drop_while { false })
      assert_equal(List[1, 2, 3], List[1, 2, 3].drop_while { |x| x < 1 })
      assert_equal(List[2, 3], List[1, 2, 3].drop_while { |x| x < 2 })
      assert_equal(List[3], List[1, 2, 3].drop_while { |x| x < 3 })
      assert_equal(List[], List[1, 2, 3].drop_while { |x| x < 4 })
    end

    def test_reverse
      assert_equal(List[], List[].reverse)
      assert_equal(List[1], List[1].reverse)
      assert_equal(List[2, 1], List[1, 2].reverse)
      assert_equal(List[3, 2, 1], List[1, 2, 3].reverse)
    end

    def test_intersperse
      assert_equal(List[], List[].intersperse(0))
      assert_equal(List[1], List[1].intersperse(0))
      assert_equal(List[1, 0, 2], List[1, 2].intersperse(0))
      assert_equal(List[1, 0, 2, 0, 3], List[1, 2, 3].intersperse(0))
    end

    def test_intercalate
      assert_equal(List[], List[].intercalate(List[0]))
      assert_equal(List[1], List[List[1]].intercalate(List[0]))
      xs = List[List[1, 2], List[3, 4], List[5, 6]].intercalate(List[0])
      assert_equal(List[1, 2, 0, 3, 4, 0, 5, 6], xs)
    end

    def test_transpose
      assert_equal(List[], List[].transpose)
      assert_equal(List[], List[List[]].transpose)
      assert_equal(List[List[1], List[2]], List[List[1, 2]].transpose)
      assert_equal(List[List[1, 4], List[2, 5], List[3, 6]],
                   List[List[1, 2, 3], List[4, 5, 6]].transpose)
      assert_equal(List[List[1, 4], List[2, 5], List[3]],
                   List[List[1, 2, 3], List[4, 5]].transpose)
    end

    def test_subsequences
      assert_equal(List[List[]], List[].subsequences)
      assert_equal(List[List[], List[1], List[2], List[1, 2],
                        List[3], List[1, 3], List[2, 3], List[1, 2, 3]],
                   List[1, 2, 3].subsequences)
    end

    def test_sum
      assert_equal(0, List[].sum)
      assert_equal(1, List[1].sum)
      assert_equal(10, List[1, 2, 3, 4].sum)
    end

    def test_product
      assert_equal(1, List[].product)
      assert_equal(1, List[1].product)
      assert_equal(24, List[1, 2, 3, 4].product)
    end

    def test_s_unfoldr
      xs = List.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
      assert_equal(List[3, 2, 1], xs)
      xs = List.unfoldr("foo,bar,baz") { |x|
        if x.empty?
          nil
        else
          y = x.slice(/([^,]*),?/, 1)
          [y, $']
        end
      }
      assert_equal(List["foo", "bar", "baz"], xs)
    end

    def test_zip
      xs = List[0, 1, 2]
      ys = List[0, 2, 4]
      zs = List[0, 3, 6]
      assert_equal(List[[0, 0, 0], [1, 2, 3], [2, 4, 6]],
                   xs.zip(ys, zs))
    end

    def test_zip_with
      xs = List[0, 1, 2]
      ys = List[0, 2, 4]
      zs = List[0, 3, 6]
      l = xs.zip_with(ys, zs) { |x, y, z|
        x + y + z
      }
      assert_equal(List[0, 6, 12], l)
    end
  end
end
