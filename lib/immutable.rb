# +Immutable+ is a namespace for immutable data structures.
module Immutable
end

if defined?(RubyVM)
  old_compile_option = RubyVM::InstructionSequence.compile_option
  RubyVM::InstructionSequence.compile_option = {
    :tailcall_optimization => true,
    :trace_instruction => false
  }
end
begin
  require_relative "immutable/list"
  require_relative "immutable/map"
  require_relative "immutable/promise"
  require_relative "immutable/stream"
  require_relative "immutable/queue"
  require_relative "immutable/output_restricted_deque"
  require_relative "immutable/deque"
ensure
  if defined?(RubyVM)
    RubyVM::InstructionSequence.compile_option = old_compile_option
  end
end
