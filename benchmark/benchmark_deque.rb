require 'benchmark'
require 'immutable/deque'
require 'immutable/map'

TIMES = 100000
key_size = 10

def snoc(deque)
  TIMES.times do
    deque.snoc(0)
  end
end

def head(deque)
  TIMES.times do
    deque.head
  end
end

def tail(deque)
  TIMES.times do
    deque.tail
  end
end

def run(bm, deque, num, method)
  bm.report("#{method} for #{num}-elements deque") do
    send(method, deque)
  end
end

Benchmark.bmbm do |bm|
  deques = [10, 100, 1000].inject(Immutable::Map.empty) { |m, n|
    m.insert(n, (1..n).inject(Immutable::Deque.empty, &:snoc))
  }
  for method in [:snoc, :head, :tail]
    for num, deque in deques
      run(bm, deque, num, method)
    end
  end
end
