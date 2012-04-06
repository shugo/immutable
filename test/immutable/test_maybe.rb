require "test/unit"
require "immutable/maybe"

module Immutable
  class TestList < Test::Unit::TestCase
    def quo(x, y)
      if y == 0
        Nothing
      else
        Just[x.quo(y)]
      end
    end

    def test_bind
      assert_equal(Nothing, Nothing.bind { |x| Just[x ** 2] })
      assert_equal(Just[4], Just[2].bind { |x| Just[x ** 2] })
      x = Just[0].bind { |y| quo(2, y) }.bind { |y| Just[y ** 2] }
      assert_equal(Nothing, x)
      x = Just[4].bind { |y| quo(2, y) }.bind { |y| Just[y ** 2] }
      assert_equal(Just[Rational(1, 4)], x)
    end
  end
end
