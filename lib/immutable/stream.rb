require "immutable/foldable"
require "immutable/list"
require "immutable/promise"

module Immutable
  # +Immutable::Stream+ represents a stream, also known as a lazy list.
  # A stream is similar to a list. However the evaluation of a stream
  # element is delayed until its value is needed
  #
  # @example An infinite stream which represents natural numbers.
  #   def from(n)
  #     Stream.cons ->{n}, ->{from(n + 1)}
  #   end
  #
  #   nats = from(0)
  #   p from(0).drop(100).take(5).to_list #=> List[100, 101, 102, 103, 104]
  class Stream < Promise
    include Enumerable
    include Foldable

    # :nodoc:
    NULL = Object.new

    def NULL.head
      raise List::EmptyError
    end

    def NULL.tail
      raise List::EmptyError
    end

    def NULL.inspect
      "NULL"
    end

    # :nodoc:
    class Pair
      attr_reader :head, :tail

      def initialize(head, tail)
        @head = head
        @tail = tail
      end
    end

    # Returns an empty stream.
    #
    # @return [Stream] an empty stream.
    def self.null
      delay { NULL }
    end

    # Creates a new stream.
    #
    # @example A Stream which has 123 as the only element.
    #   s = Stream.cons(->{123}, ->{Stream.null})
    #
    # @param [Proc] head a +Proc+ whose value is the head of +self+.
    # @param [Proc] tail a +Proc+ whose value is the tail of +self+.
    def self.cons(head, tail)
      Stream.eager(Pair.new(Stream.delay(&head), Stream.lazy(&tail)))
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
          cons ->{ x }, ->{ from_enumerator(e) }
        rescue StopIteration
          null
        end
      }
    end

    def self.from(first, step = 1)
      cons ->{ first }, ->{ from(first + step, step) }
    end

    def null?
      force == NULL
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

    def each(&block)
      unless null?
        yield(head)
        tail.each(&block)
      end
    end

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

    def +(s)
      Stream.lazy {
        if null?
          s
        else
          Stream.cons ->{head}, ->{tail + s}
        end
      }
    end

    def flatten
      Stream.lazy {
        if null?
          self
        else
          if head.null?
            tail.flatten
          else
            Stream.cons ->{head.head}, ->{
              Stream.cons(->{head.tail}, ->{tail}).flatten
            }
          end
        end
      }
    end

    def map(&block)
      Stream.lazy {
        if null?
          Stream.null
        else
          Stream.cons ->{ yield(head) }, ->{ tail.map(&block) }
        end
      }
    end

    def filter(&block)
      Stream.lazy {
        if null?
          Stream.null
        else
          if yield(head)
            Stream.cons ->{ head }, ->{ tail.filter(&block) }
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
          Stream.cons ->{ head }, ->{ tail.take(n - 1) }
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
          Stream.cons ->{ head }, ->{ tail.take_while(&block) }
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
          Stream.cons ->{ y }, ->{ unfoldr(z, &block) }
        end
      }
    end

    def zip_with(*xss, &block)
      Stream.lazy {
        heads = xss.map { |xs| xs.null? ? nil : xs.head }
        tails = xss.map { |xs| xs.null? ? Stream.null : xs.tail }
        h = yield(head, *heads)
        Stream.cons ->{ h }, ->{ tail.zip_with(*tails, &block) }
      }
    end
  end
end
