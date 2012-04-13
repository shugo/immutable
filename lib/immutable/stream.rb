require "immutable/foldable"
require "immutable/list"
require "immutable/promise"

module Immutable
  # +Immutable::Stream+ represents a stream, also known as a lazy list.
  # A stream is similar to a list. However the evaluation of a stream
  # element is delayed until its value is needed
  #
  # @example Natural numbers
  #   def from(n)
  #     Stream.cons ->{n}, ->{from(n + 1)}
  #   end
  #
  #   nats = from(0)
  #   p from(0).take(10).to_list #=> List[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
  # @example Prime numbers
  #   primes = Stream.from(2).filter { |n|
  #     (2 ... n / 2 + 1).all? { |x|
  #       n % x != 0
  #     }
  #   }
  #   p primes.take_while { |n| n < 10 }.to_list #=> List[2, 3, 5, 7]
  class Stream < Promise
    include Enumerable
    include Foldable

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
    # @example A Stream which has two elements: "abc" and "def".
    #   s = Stream.cons(->{"abc"},
    #         ->{Stream.cons(->{"def"}, ->{Stream.null})})
    #
    # @param [Proc] head a +Proc+ whose value is the head of +self+.
    # @param [Proc] tail a +Proc+ whose value is the tail of +self+.
    # @return [Stream] the created stream.
    def self.cons(head, tail)
      Stream.eager(Pair.new(Stream.delay(&head), Stream.lazy(&tail)))
    end

    # Creates a new stream. Note that the arguments are evaluated eagerly.
    #
    # @param [Object] args the elements of the stream.
    # @return [Stream] the created stream.
    def self.[](*args)
      from_enum(args)
    end

    # Creates a new stream from an +Enumerable+ object.
    #
    # @param [Enumerable] e an +Enumerable+ object.
    # @return [Stream] the created stream.
    def self.from_enum(e)
      from_enumerator(e.each)
    end

    # Creates a new stream from an +Enumerator+ object.
    # Note that +from_enumerator+ has side effects because it calls
    # +Enumerator#next+.
    #
    # @param [Enumerator] e an +Enumerator+ object.
    # @return [Stream] the created stream.
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

    # Creates an infinite stream which starts from +first+ and increments
    # each succeeding element by +step+.
    #
    # @param [#+] first the first element.
    # @param [#+] step the step for succeeding elements.
    # @return [Stream] the created stream.
    def self.from(first, step = 1)
      cons ->{ first }, ->{ from(first + step, step) }
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def null?
      force == NULL
    end
    alias empty? null?

    # Returns the first element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      force.head.force
    end
    alias first head

    # Returns the last element of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the last element of +self+.
    def last
      if tail.null?
        head
      else
        tail.last
      end
    end

    # Returns the stream stored in the tail of +self+. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [List] the stream stored in the tail of +self+.
    def tail
      force.tail
    end

    # Creates a string representation of +self+.
    #
    # @return [String] a stream representation of +self+.
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

    # Calls +block+ once for each element in +self+.
    def each(&block)
      unless null?
        yield(head)
        tail.each(&block)
      end
    end

    # Reduces +self+ using +block+ from right to left. +e+ is used as the
    # starting value. For example:
    #
    #   Stream[1, 2, 3].foldr(9) { |x, y| x + y } #=> 1 - (2 - (3 - 9)) = -7
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldr(e, &block)
      if null?
        e
      else
        yield(head, tail.foldr(e, &block))
      end
    end

    # Reduces +self+ using +block+ from right to left. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the reduced value.
    def foldr1(&block)
      if tail.null?
        head
      else
        yield(head, tail.foldr1(&block))
      end
    end

    # Reduces +self+ using +block+ from left to right. +e+ is used as the
    # starting value. For example:
    #
    #   Stream[1, 2, 3].foldl(9) { |x, y| x + y } #=> ((9 - 1) - 2) - 3 = 3
    #
    # @param [Object] e the start value.
    # @return [Object] the reduced value.
    def foldl(e, &block)
      if null?
        e
      else
        tail.foldl(yield(e, head), &block)
      end
    end

    # Reduces +self+ using +block+ from left to right. If +self+ is empty,
    # <code>Immutable::List::EmptyError</code> is raised.
    #
    # @return [Object] the reduced value.
    def foldl1(&block)
      tail.foldl(head, &block)
    end

    # Returns whether +self+ equals to +s+.
    #
    # @param [Stream] s the stream to compare.
    # @return [true, false] +true+ if +self+ equals to +s+; otherwise,
    # +false+.
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

    # Appends two streams +self+ and +s+.
    #
    # @param [Stream] s the stream to append.
    # @return [Stream] the new stream.
    def +(s)
      Stream.lazy {
        if null?
          s
        else
          Stream.cons ->{head}, ->{tail + s}
        end
      }
    end

    # Concatenates a stream of streams.
    #
    # @return [Stream] the concatenated stream.
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

    # Returns the stream obtained by applying the given block to each
    # element in +self+.
    #
    # @return [Stream] the obtained stream.
    def map(&block)
      Stream.lazy {
        if null?
          Stream.null
        else
          Stream.cons ->{ yield(head) }, ->{ tail.map(&block) }
        end
      }
    end

    # Returns the elements in +self+ for which the given block evaluates to
    # true.
    #
    # @return [Stream] the elements that satisfies the condition.
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

    # Returns the +n+th element of +self+. If +n+ is out of range, +nil+ is
    # returned.
    #
    # @return [Object] the +n+th element.
    def [](n)
      if n < 0 || null?
        nil
      elsif n == 0
        head
      else
        tail[n - 1]
      end
    end

    # Returns the first +n+ elements of +self+, or +self+ itself if
    # <code>n > self.length</code>.
    #
    # @param [Integer] n the number of elements to take.
    # @return [Stream] the first +n+ elements of +self+.
    def take(n)
      Stream.lazy {
        if n <= 0 || null?
          Stream.null
        else
          Stream.cons ->{ head }, ->{ tail.take(n - 1) }
        end
      }
    end

    # Returns the suffix of +self+ after the first +n+ elements, or
    # <code>Stream[]</code> if <code>n > self.length</code>.
    #
    # @param [Integer] n the number of elements to drop.
    # @return [Stream] the suffix of +self+ after the first +n+ elements.
    def drop(n)
      Stream.lazy {
        if n <= 0 || null?
          self
        else
          tail.drop(n - 1)
        end
      }
    end

    # Returns the longest prefix of the elements of +self+ for which +block+
    # evaluates to true.
    #
    # @return [Stream] the prefix of the elements of +self+.
    def take_while(&block)
      Stream.lazy {
        if null? || !yield(head)
          Stream.null
        else
          Stream.cons ->{ head }, ->{ tail.take_while(&block) }
        end
      }
    end

    # Returns the suffix remaining after
    # <code>self.take_while(&block)</code>.
    #
    # @return [Stream] the suffix of the elements of +self+.
    def drop_while(&block)
      Stream.lazy {
        if null? || !yield(head)
          self
        else
          tail.drop_while(&block)
        end
      }
    end

    # Converts +self+ to a list.
    #
    # @return [List] a list.
    def to_list
      foldr(List[]) { |x, xs| Cons[x, xs] }
    end

    # Builds a stream from the seed value +e+ and the given block. The block
    # takes a seed value and returns <code>nil</code> if the seed should
    # unfold to the empty stream, or returns <code>[a, b]</code>, where
    # <code>a</code> is the head of the stream and <code>b</code> is the
    # next seed from which to unfold the tail.  For example:
    #
    #   xs = List.unfoldr(3) { |x| x == 0 ? nil : [x, x - 1] }
    #   p xs #=> List[3, 2, 1]
    #
    # <code>unfoldr</code> is the dual of <code>foldr</code>.
    #
    # @param [Object] e the seed value.
    # @return [Stream] the stream built from the seed value and the block.
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
