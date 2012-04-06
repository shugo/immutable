module Immutable
  class Maybe
    def just?
      self != Nothing
    end

    def nothing?
      self == Nothing
    end
  end

  Nothing = Maybe.new

  class Just < Maybe
    attr_reader :value

    def self.[](value)
      new(value)
    end

    def initialize(value)
      @value = value
    end
    
    def ==(other)
      other.just? && @value == other.value
    end

    def Nothing.bind
      Nothing
    end

    def bind
      yield(@value)
    end

    def Nothing.inspect
      "Nothing"
    end

    def inspect
      "Just[" + @value.inspect + "]"
    end
  end
end
