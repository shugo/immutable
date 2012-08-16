require "benchmark"
require_relative "../lib/immutable/deque"
require_relative "../lib/immutable/map"

TIMES = 100000
key_size = 10

def head(deque)
  TIMES.times do
    deque.head
  end
end

def last(deque)
  TIMES.times do
    deque.last
  end
end

def tail(deque)
  TIMES.times do
    deque.tail
  end
end

def init(deque)
  TIMES.times do
    deque.init
  end
end

def cons(deque)
  TIMES.times do
    deque.cons(0)
  end
end

def snoc(deque)
  TIMES.times do
    deque.snoc(0)
  end
end

def run(bm, deque, num, method)
  bm.report("#{method} for #{num}-elements deque") do
    send(method, deque)
  end
end

Benchmark.bmbm do |bm|
  deques = [100, 1000, 10000].inject(Immutable::Map.empty) { |m, n|
    m.insert(n, (1..n).inject(Immutable::Deque.empty, &:snoc))
  }
  for method in [:head, :last, :tail, :init, :cons, :snoc]
    for num, deque in deques
      run(bm, deque, num, method)
    end
  end
end
