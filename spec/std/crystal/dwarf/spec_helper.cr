require "../../spec_helper"
require "crystal/dwarf"

def read_elf(filename)
  path = datapath("dwarf", filename)
  Crystal::ELF.open(path) do |elf|
    yield elf
  end
end
