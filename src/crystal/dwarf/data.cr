
module Crystal
  module DWARF
    struct Data
      def self.new(elf : Crystal::ELF)
        data = new
        data.line_strings = elf.read_section?(".debug_line_str") do |sh, io|
          Strings.new(io, sh.offset, sh.size)
        end

        data.strings = elf.read_section?(".debug_str") do |sh, io|
          Strings.new(io, sh.offset, sh.size)
        end

        data.line_numbers = elf.read_section?(".debug_line") do |sh, io|
          LineNumbers.new(io, sh.size, 0, data.strings, data.line_strings)
        end

        elf.read_section?(".debug_info") do |sh, io|
          while (offset = io.pos - sh.offset) < sh.size
            info = Crystal::DWARF::Info.new(io, offset)

            elf.read_section?(".debug_abbrev") do |sh, io|
              info.read_abbreviations(io)
            end

            data.infos << info

            yield data

            io.pos = sh.offset + offset + info.unit_length + 4
          end
        end
        data
      end

      def self.new(elf : Crystal::ELF)
        new(elf) {}
      end

      property line_strings : Strings?
      property strings : Strings?
      property infos = [] of Info
      property! line_numbers : LineNumbers?
      property function_names = [] of {LibC::SizeT, LibC::SizeT, String}

      def initialize
      end
      def info
        infos.last
      end
    end
  end
end
