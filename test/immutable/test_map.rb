require "test/unit"
require "immutable/map"

module Immutable
  class TestMap < Test::Unit::TestCase
    def test_empty?
      assert(Map[].empty?)
      assert(!Map[a: 1].empty?)
      assert(!Map[a: 1, b: 2].empty?)
    end

    def test_inspect
      assert_equal("Map[]", Map.empty.inspect)
      assert_equal("Map[:a => 1, :b => 2]", Map[a: 1, b: 2].inspect)
    end

    def test_insert
      5.times do
        map = (1..100).to_a.shuffle.inject(Map.empty) { |m, k|
          m.insert(k, k.to_s)
        }
        for i in 1..100
          assert_equal(i.to_s, map[i])
        end
      end
    end

    def test_delete
      5.times do
        keys = (1..100).to_a.shuffle
        map = keys.inject(Map.empty) { |m, k|
          m.insert(k, k.to_s)
        }
        keys.shuffle!
        deleted_keys = keys.shift(20)
        map2 = deleted_keys.inject(map) { |m, k|
          m.delete(k)
        }
        for i in 1..100
          assert_equal(i.to_s, map[i])
        end
        keys.each do |k|
          assert_equal(k.to_s, map2[k])
        end
        deleted_keys.each do |k|
          assert_equal(nil, map2[k])
        end
      end
    end

    def test_foldr_with_key
      xs = Map[].foldr_with_key(List[]) { |k, v, ys| Cons[[k, v], ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldr_with_key(List[]) { |k, v, ys|
        Cons[[k, v], ys]
      }
      assert_equal(List[[:a, 1], [:b, 2], [:c, 3]], xs)
    end

    def test_foldl_with_key
      xs = Map[].foldl_with_key(List[]) { |ys, k, v| Cons[[k, v], ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldl_with_key(List[]) { |ys, k, v|
        Cons[[k, v], ys]
      }
      assert_equal(List[[:c, 3], [:b, 2], [:a, 1]], xs)
    end
  end
end
