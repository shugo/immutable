
module Immutable
  class EmptyError < StandardError
    def initialize(msg = "collection is empty")
      super(msg)
    end
  end
end
