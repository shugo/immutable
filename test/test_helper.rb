require "test/unit"

def with_tailcall_optimization
  old_compile_option = RubyVM::InstructionSequence.compile_option
  RubyVM::InstructionSequence.compile_option = {
    :tailcall_optimization => true,
    :trace_instruction => false
  }
  begin
    yield
  ensure
    RubyVM::InstructionSequence.compile_option = old_compile_option
  end
end
