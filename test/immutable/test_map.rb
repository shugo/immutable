require_relative "../test_helper"

with_tailcall_optimization {
  require_relative "../../lib/immutable/list"
  require_relative "../../lib/immutable/map"
}

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

    def test_to_s
      assert_equal("Map[]", Map.empty.to_s)
      assert_equal("Map[:a => 1, :b => 2]", Map[a: 1, b: 2].to_s)
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

    def test_eq
      assert_same(true, Map[] == Map[])
      assert_same(true, Map[a: 1, c: 3, b: 2] == Map[c: 3, b: 2, a: 1])
      assert_same(false, Map[] == {})
      assert_same(false, Map[a: 1, c: 3, b: 2] == Map[c: 3, b: 2, a: 1, A: 1])
      assert_same(false, Map[a: 1, c: 3, b: 2] == Map[c: 3, b: 2, a: '1'])
      assert_same(false, Map[a: 1, c: 3, b: 2] == Map[c: 3, b: 2])
    end

    def test_case_equal
      assert_same(true, Map[] === Map[])
      assert_same(true, Map[a: 1, c: 3, b: 2] === Map[c: 3, b: 2, a: 1])
      assert_same(false, Map[] === {})
      assert_same(false, Map[a: 1, c: 3, b: 2] === Map[c: 3, b: 2, a: 1, A: 1])
      assert_same(false, Map[a: 1, c: 3, b: 2] === Map[c: 3, b: 2, a: '1'])
      assert_same(false, Map[a: 1, c: 3, b: 2] === Map[c: 3, b: 2])
    end

    def test_eql
      assert_same(true, Map[] == Map[])
      assert_same(true, Map[a: 1, c: 3, b: 2].eql?(Map[c: 3, b: 2, a: 1]))
      assert_same(false, Map[].eql?({}))
      assert_same(false, Map[a: 1, c: 3, b: 2].eql?(Map[c: 3, b: 2, a: 1, A: 1]))
      assert_same(false, Map[a: 1, c: 3, b: 2].eql?(Map[c: 3, b: 2, a: '1']))
      assert_same(false, Map[a: 1, c: 3, b: 2].eql?(Map[c: 3, b: 2]))
    end

    def test_hash_key
      map1 = Map[1 => 1, 2 => 3]
      map2 = Map[1 => 1, 2 => 3]
      map3 = Map[1 => 1, 2.0 => 3]
      hash = {map1 => true}
      assert_same(true, hash.has_key?(map1))
      assert_same(true, hash.has_key?(map2))
      assert_same(false, hash.has_key?(map3))
    end

    def test_each
      a = []
      map = Map[]
      ret = map.each { |x| a << x }
      assert_equal([], a)
      assert_same(ret, map)
      enum = map.each
      assert_instance_of(Enumerator, enum)

      a = []
      map = Map[a: 1, c: 3, b: 2]
      ret = map.each { |x| a << x }
      assert_equal([[:a, 1], [:b, 2], [:c, 3]], a)
      assert_same(ret, map)
      enum = map.each
      assert_instance_of(Enumerator, enum)
      assert_equal([:a, 1], enum.next)
      assert_equal([:b, 2], enum.next)
      assert_equal([:c, 3], enum.next)
      assert_raise(StopIteration) do
        enum.next
      end
    end

    def test_each_pair
      a = []
      map = Map[]
      ret = map.each_pair { |x| a << x }
      assert_equal([], a)
      assert_same(ret, map)
      enum = map.each_pair
      assert_instance_of(Enumerator, enum)

      a = []
      map = Map[a: 1, c: 3, b: 2]
      ret = map.each_pair { |x| a << x }
      assert_equal([[:a, 1], [:b, 2], [:c, 3]], a)
      assert_same(ret, map)
      enum = map.each_pair
      assert_instance_of(Enumerator, enum)
      assert_equal([:a, 1], enum.next)
      assert_equal([:b, 2], enum.next)
      assert_equal([:c, 3], enum.next)
      assert_raise(StopIteration) do
        enum.next
      end
    end

    def test_to_h
      assert_equal({}, Map[].to_h)
      assert_equal({a: 1, c: 3, b: 2}, Map[a: 1, c: 3, b: 2].to_h)
    end

    def test_foldr
      xs = Map[].foldr(List[]) { |v, ys| Cons[v, ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldr(List[]) { |v, ys| Cons[v, ys] }
      assert_equal(List[1, 2, 3], xs)
    end

    def test_foldl
      xs = Map[].foldl(List[]) { |ys, v| Cons[v, ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldl(List[]) { |ys, v| Cons[v, ys] }
      assert_equal(List[3, 2, 1], xs)
    end

    def test_foldl_with_key
      xs = Map[].foldl_with_key(List[]) { |ys, k, v| Cons[[k, v], ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldl_with_key(List[]) { |ys, k, v|
        Cons[[k, v], ys]
      }
      assert_equal(List[[:c, 3], [:b, 2], [:a, 1]], xs)
    end

    def test_foldr_with_key
      xs = Map[].foldr_with_key(List[]) { |k, v, ys| Cons[[k, v], ys] }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].foldr_with_key(List[]) { |k, v, ys|
        Cons[[k, v], ys]
      }
      assert_equal(List[[:a, 1], [:b, 2], [:c, 3]], xs)
    end

    def test_map
      xs = Map[].map { |v| v.to_s }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].map { |v| v.to_s }
      assert_equal(List["1", "2", "3"], xs)
    end

    def test_map_with_key
      xs = Map[].map_with_key { |k, v| [k, v].join(":") }
      assert_equal(List[], xs)

      xs = Map[a: 1, c: 3, b: 2].map_with_key { |k, v| [k, v].join(":") }
      assert_equal(List["a:1", "b:2", "c:3"], xs)
    end
  end
end
