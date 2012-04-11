module Immutable
  class Promise
    # :nodoc:
    Box = Struct.new(:type, :value)

    def initialize(type, value)
      @box = Box.new(type, value)
    end

    private_class_method :new

    def self.lazy(&block)
      new(:lazy, block)
    end

    def self.eager(value)
      new(:eager, value)
    end

    def self.delay
      lazy {
        eager(yield)
      }
    end

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
