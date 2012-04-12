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

    def self.[](*args)
      from_enum(args)
    end

    def self.from_enum(e)
      from_enumerator(e.each)
    end

    def self.from_enumerator(e)
      lazy {
        begin
          x = e.next
          Stream.cons { x }.tail { from_enumerator(e) }
        rescue StopIteration
          Stream.null
        end
      }
    end

    def self.from(first, step = 1)
      cons { first }.tail { from(first + step, step) }
    end

    def null?
      force == StreamNull
    end
    alias empty? null?

    def head
      force.head.force
    end

    def last
      if tail.null?
        head
      else
        tail.last
      end
    end

    def tail
      force.tail
    end

    def inspect
      "Stream[" + inspect_i + "]"
    end

    def inspect_i(s = nil)
      if eager?
        if null?
          s || ""
        else
          h = force.head.eager? ? head.inspect : "?"
          if s
            tail.inspect_i(s + ", " + h)
          else
            tail.inspect_i(h)
          end
        end
      else
        if s
          s + ", ..."
        else
          "..."
        end
      end
    end
    protected :inspect_i

    def foldr(e, &block)
      if null?
        e
      else
        yield(head, tail.foldr(e, &block))
      end
    end

    def foldr1(&block)
      if tail.null?
        head
      else
        yield(head, tail.foldr1(&block))
      end
    end

    def foldl(e, &block)
      if null?
        e
      else
        tail.foldl(yield(e, head), &block)
      end
    end

    def foldl1(&block)
      tail.foldl(head, &block)
    end

    def ==(s)
      if !s.is_a?(Stream)
        false
      else
        if null?
          s.null?
        else
          !s.null? && head == s.head && tail == s.tail
        end
      end
    end
    
    def length
      foldl(0) { |x, y| x + 1 }
    end

    def map(&block)
      Stream.lazy {
        if null?
          Stream.null
        else
          Stream.cons { yield(head) }.tail { tail.map(&block) }
        end
      }
    end

    def filter(&block)
      Stream.lazy {
        if null?
          Stream.null
        else
          if yield(head)
            Stream.cons { head }.tail { tail.filter(&block) }
          else
            tail.filter(&block)
          end
        end
      }
    end

    def [](n)
      if n < 0 || null?
        nil
      elsif n == 0
        head
      else
        tail[n - 1]
      end
    end

    def take(n)
      Stream.lazy {
        if n <= 0 || null?
          Stream.null
        else
          Stream.cons { head }.tail { tail.take(n - 1) }
        end
      }
    end

    def drop(n)
      Stream.lazy {
        if n <= 0 || null?
          self
        else
          tail.drop(n - 1)
        end
      }
    end

    def take_while(&block)
      Stream.lazy {
        if null? || !yield(head)
          Stream.null
        else
          Stream.cons { head }.tail { tail.take_while(&block) }
        end
      }
    end

    def drop_while(&block)
      Stream.lazy {
        if null? || !yield(head)
          self
        else
          tail.drop_while(&block)
        end
      }
    end

    def to_list
      foldr(List[]) { |x, xs| Cons[x, xs] }
    end

    def to_a
      foldl([]) { |ary, x| ary << x; ary }
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

  def StreamNull.head
    raise List::EmptyError
  end

  def StreamNull.tail
    raise List::EmptyError
  end

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
