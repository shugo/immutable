require "immutable/list"
require "immutable/promise"

module Immutable
  class Stream < Promise
    def self.null
      delay { StreamNull }
    end

    def self.cons(head = nil, tail = nil, &block)
      if head
        Stream.eager(StreamCons.new(Stream.delay(head),
                                    Stream.lazy(tail)))
      else
        StreamHead.new(block)
      end
    end

    def self.iota(n, delta)
      cons{n}.tail { iota(n + delta, delta) }
    end

    def null?
      force == StreamNull
    end
    alias empty? null?

    def head
      force.head.force
    end

    def tail
      force.tail
    end

    def take(n)
      Stream.lazy {
        if null? || n <= 0
          Stream.null
        else
          Stream.cons { head }.tail { tail.take(n - 1) }
        end
      }
    end

    def to_list
      if null?
        List[]
      else
        Cons[head, tail.to_list]
      end
    end

    def self.unfoldr(e, &block)
      Stream.lazy {
        x = yield(e)
        if x.nil?
          Stream.null
        else
          y, z = x
          Stream.cons { y }.tail { unfoldr(z, &block) }
        end
      }
    end

    def zip_with(*xss, &block)
      Stream.lazy {
        heads = xss.map { |xs| xs.null? ? nil : xs.head }
        tails = xss.map { |xs| xs.null? ? Stream.null : xs.tail }
        h = yield(head, *heads)
        Stream.cons { h }.tail { tail.zip_with(*tails, &block) }
      }
    end
  end

  StreamNull = Object.new
  def StreamNull.inspect
    "StreamNull"
  end

  class StreamHead
    def initialize(head)
      @head = head
    end

    def tail(&block)
      Stream.eager(StreamCons.new(Stream.delay(&@head),
                                  Stream.lazy(&block)))
    end
  end

  class StreamCons
    attr_reader :head, :tail

    def initialize(head, tail)
      @head = head
      @tail = tail
    end
  end
end
