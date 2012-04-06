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
    attr_reader :values

    def self.[](*values)
      new(*values)
    end

    def initialize(*values)
      @values = values
    end
    
    def ==(other)
      other.just? && @values == other.values
    end

    def Nothing.bind
      Nothing
    end

    def bind
      yield(*@values)
    end

    def Nothing.inspect
      "Nothing"
    end

    def inspect
      "Just[" + @values.inject(:inspect).join(", ") + "]"
    end
  end
end
