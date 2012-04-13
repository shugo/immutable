module Immutable
  # +Immutable::Promise+ represents a promise to evaluate an expression
  # later.
  #
  # @example Delayed computation
  #   promise = Promise.delay { puts "hello"; 1 + 2 }
  #   x = promise.force #=> hello
  #   p x               #=> 3
  #   y = promise.force #=> (no output; the value is memoized)
  #   p y               #=> 3
  # @example Infinite stream
  #   def from(n)
  #     Promise.delay {
  #       Cons[n, from(n + 1)]
  #     }
  #   end
  #   
  #   def stream_ref(s, n)
  #     xs = s.force
  #     if xs.empty?
  #       nil
  #     else
  #       n == 0 ? xs.head : stream_ref(xs.tail, n - 1)
  #     end
  #   end
  #   
  #   nats = from(0)
  #   p stream_ref(nats, 0) #=> 0
  #   p stream_ref(nats, 3) #=> 3
  class Promise
    # :nodoc:
    Box = Struct.new(:type, :value)

    def initialize(type, value)
      @box = Box.new(type, value)
    end

    private_class_method :new

    # Takes a block which evaluates to a promise, and returns a promise
    # which at some point in the future may be asked (by +Promise#force+)
    # to evaluate the block and deliver the resulting promise.
    #
    # @yieldreturn [Promise] the promise to be returned by +Promise#force+.
    # @return [Promise] the created promise.
    def self.lazy(&block)
      new(:lazy, block)
    end

    # Takes an argument, and returns a promise which deliver the value of
    # the argument.
    #
    # <code>Promise.eager(expresion)</code> is equivalent to
    # <code>(value = Promise.eager; Promise.delay { value })</code>.
    #
    # @param [Object] value the value to be returned by +Promise#force+.
    # @return [Promise] the created promise.
    def self.eager(value)
      new(:eager, value)
    end

    # Returns whether +self+ is lazy.
    #
    # @return [true, false] +true+ if +self+ is lazy; otherwise, +false+.
    def lazy?
      box.type == :lazy
    end

    # Returns whether +self+ is eager.
    #
    # @return [true, false] +true+ if +self+ is eager; otherwise, +false+.
    def eager?
      box.type == :eager
    end

    # Takes a block, and returns a promise which at some point in the future
    # may be asked (by +Promise#force+) to evaluate the block and deliver
    # the resulting value.
    #
    # <code>Promise.delay { expression }</code> is equivalent to
    # <code>Promise.lazy { Promise.eager(expression) }</code>.
    #
    # @yieldreturn [Object] the value to be returned by +Promise#force+.
    # @return [Promise] the created promise.
    def self.delay
      lazy {
        eager(yield)
      }
    end

    # Returns the value of +self+ as follows:
    # If a value of +self+ has already been computated, the value is
    # returned. Otherwise, the promise is first evaluated, and the resulting
    # value is returned.
    #
    # @return [Object] the value of +self+.
    def force
      content = box
      case content.type
      when :eager
        content.value
      when :lazy
        promise = content.value.call
        content = box
        if content.type != :eager
          content.type = promise.box.type
          content.value = promise.box.value
          promise.box = content
        end
        force
      else
        raise ScriptError, "should not reach here"
      end
    end

    protected

    attr_accessor :box
  end
end
