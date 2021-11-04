require "crystal/elf"
require "c/link"

struct Exception::CallStack
  protected def self.load_dwarf_impl
    phdr_callback = LibC::DlPhdrCallback.new do |info, size, data|
      # The first entry is the header for the current program
      read_dwarf_sections(info.value.addr)
      1
    end

    # GC needs to be disabled around dl_iterate_phdr in freebsd (#10084)
    {% if flag?(:freebsd) %} GC.disable {% end %}
    LibC.dl_iterate_phdr(phdr_callback, nil)
    {% if flag?(:freebsd) %} GC.enable {% end %}
  end

  protected def self.read_dwarf_sections(base_address = 0)
    program = Process.executable_path
    return unless program && File.readable? program
    Crystal::ELF.open(program) do |elf|
      dwarf = Crystal::DWARF::Data.new(elf)

      @@dwarf_line_numbers = dwarf.line_numbers

      names = [] of {LibC::SizeT, LibC::SizeT, String}

      parse_function_names_from_dwarf(dwarf.info, dwarf.strings, dwarf.line_strings) do |low_pc, high_pc, name|
        names << {low_pc + base_address, high_pc + base_address, name}
      end
      @@dwarf_function_names = names
    end
  end

  protected def self.decode_address(ip)
    ip.address
  end
end
