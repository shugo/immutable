require "test/unit"
require "immutable/map"

module Immutable
  class TestMap < Test::Unit::TestCase
    def test_empty?
      assert(Map.empty.empty?)
      assert(!Map.singleton(1, "a").empty?)
    end

    def test_insert
      map = (1..100).to_a.shuffle.inject(Map.empty) { |m, k|
        m.insert(k, k.to_s)
      }
      for i in 1..100
        assert_equal(i.to_s, map[i])
      end
    end

    def test_delete
      keys = (1..100).to_a.shuffle
      map = keys.inject(Map.empty) { |m, k|
        m.insert(k, k.to_s)
      }
      keys.shuffle!
      deleted_keys = keys.shift(10)
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
end
