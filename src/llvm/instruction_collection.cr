struct LLVM::InstructionCollection
  include Enumerable(LLVM::Value)

  def initialize(@basic_block : BasicBlock)
  end

  def empty?
    first?.nil?
  end

  def each : Nil
    inst = LibLLVM.get_first_instruction @basic_block

    while inst
      yield LLVM::Value.new inst
      inst = LibLLVM.get_next_instruction(inst)
    end
  end

  def size
    raise NotImplementedError.new("LLVM::InstructionCollection#size")
  end
end
