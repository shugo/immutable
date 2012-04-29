require "immutable/consable"

module Immutable
  # +Immutable::List+ represents an immutable list.
  #
  # +Immutable::List+ is an abstract class and
  # {Immutable::List.[]} should be used instead of
  # {Immutable::List.new}. For example:
  #
  #   include Immutable
  #   p List[]      #=> List[]
  #   p List[1, 2]  #=> List[1, 2]
  #
  # +Immutable::Nil+ represents an empty list, and
  # +Immutable::Cons+ represents a cons cell, which is a node in
  # a list. For example:
  #
  #   p Nil                    #=> List[]
  #   p Cons[1, Cons[2, Nil]]  #=> List[1, 2]
  class List
    include Consable

    # Returns an empty list.
    #
    # @return [list] the empty list.
    def self.empty
      Nil
    end

    # Adds a new element at the head of +self+.
    #
    # @param [Object] x the element to add.
    # @return [List] a new list.
    def cons(x)
      Cons[x, self]
    end

    # Returns the first element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the first element of +self+.
    def head
      # this method should be overriden
    end

    # Returns the last element of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [Object] the last element of +self+.
    def last
      # this method should be overriden
    end

    # Returns the elements after the head of +self+. If +self+ is empty,
    # +Immutable::EmptyError+ is raised.
    #
    # @return [List] the elements after the head of +self+.
    def tail
      # this method should be overriden
    end

    # Returns all the elements of +self+ except the last one.
    # If +self+ is empty, +Immutable::EmptyError+ is
    # raised.
    #
    # @return [List] the elements of +self+ except the last one.
    def init
      # this method should be overriden
    end

    # Same as {#init}.
    #
    # @return [List] the elements of +self+ except the last one.
    def pop
      init
    end

    # Returns whether +self+ is empty.
    #
    # @return [true, false] +true+ if +self+ is empty; otherwise, +false+.
    def empty?
      # this method should be overriden
    end

    # Returns +self+.
    #
    # @return [List] +self+.
    def to_list
      self
    end

    # Takes zero or more lists and returns a new list in which each element
    # is an array of the corresponding elements of +self+ and the input
    # lists.
    #
    # @param [Array<List>] xss the input lists.
    # @return [List] the new list.
    def zip(*xss)
      # this method should be overriden
    end

    # Takes zero or more lists and returns the list obtained by applying the
    # given block to an array of the corresponding elements of +self+ and
    # the input lists.
    # +xs.zip_with(*yss, &block)+ is equivalent to
    # +xs.zip(*yss).map(&block)+.
    #
    # @param [Array<List>] xss the input lists.
    # @return [List] the new list.
    def zip_with(*xss, &block)
      # this method should be overriden
    end

    private

    def class_name
      "List"
    end
  end

  # +Immutable::Nil+ represents an empty list.
  Nil = List.new

  # +Immutable::Cons+ represents a cons cell.
  class Cons < List
    # Creates a new list obtained by prepending +head+ to the list +tail+.
    #
    # @return [Cons] the new list.
    def self.[](head, tail = Nil)
      self.new(head, tail)
    end

    # Creates a list obtained by prepending +head+ to the list +tail+.
    def initialize(head, tail = Nil)
      @head = head
      @tail = tail
    end

    def Nil.head
      raise EmptyError
    end

    attr_reader :head

    def Nil.last
      raise EmptyError
    end

    def last
      if @tail.empty?
        @head
      else
        @tail.last
      end
    end

    def Nil.tail
      raise EmptyError
    end

    attr_reader :tail

    def Nil.init
      raise EmptyError
    end

    def init
      if @tail.empty?
        Nil
      else
        Cons[@head, @tail.init]
      end
    end

    def Nil.empty?
      true
    end

    def empty?
      false
    end

    def Nil.zip(*xss)
      Nil
    end

    def zip(*xss)
      heads = xss.map { |xs| xs.null? ? nil : xs.head }
      tails = xss.map { |xs| xs.null? ? Nil : xs.tail }
      Cons[[head, *heads], tail.zip(*tails)]
    end

    def Nil.zip_with(*xss, &block)
      Nil
    end

    def zip_with(*xss, &block)
      heads = xss.map { |xs| xs.null? ? nil : xs.head }
      tails = xss.map { |xs| xs.null? ? Nil : xs.tail }
      Cons[yield(head, *heads), tail.zip_with(*tails, &block)]
    end
  end
end
