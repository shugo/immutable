require 'benchmark'
require 'immutable/queue'
require 'immutable/map'

TIMES = 100000
key_size = 10

def snoc(queue)
  TIMES.times do
    queue.snoc(0)
  end
end

def head(queue)
  TIMES.times do
    queue.head
  end
end

def tail(queue)
  TIMES.times do
    queue.tail
  end
end

def run(bm, queue, num, method)
  bm.report("#{method} for #{num}-elements queue") do
    send(method, queue)
  end
end

Benchmark.bmbm do |bm|
  queues = [10, 1000, 100000].inject(Immutable::Map.empty) { |m, n|
    m.insert(n, (1..n).inject(Immutable::Queue.empty, &:snoc))
  }
  for method in [:snoc, :head, :tail]
    for num, queue in queues
      run(bm, queue, num, method)
    end
  end
end
