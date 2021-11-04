require "./spec_helper"

describe Crystal::DWARF::LineNumbers do
  describe "ELF" do
    describe "DWARF 4" do
      it "gcc" do
        read_elf "line-gcc-dwarf4.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 4
          line_numbers = dwarf.line_numbers.should_not be_nil
          line_numbers.matrix.should eq [
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401122, "line1.h", 2, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401126, "line1.h", 5, 8),
              Crystal::DWARF::LineNumbers::Row.new(0x40112d, "line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x40112f, "line1.h", 6, 10),
              Crystal::DWARF::LineNumbers::Row.new(0x401139, "line1.h", 5, 22),
              Crystal::DWARF::LineNumbers::Row.new(0x40113d, "line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401143, "line1.h", 7, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401147, "line1.c", 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40114b, "line1.c", 7, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401155, "line1.c", 8, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401164, "line1.c", 9, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401166, "line1.c", 9, 1, true),
            ],
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401166, "line2.c", 4, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40116a, "line2.c", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401174, "line2.c", 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401177, "line2.c", 6, 1, true),
            ],
          ]

          line_numbers.sequences.map(&.file_names.map(&.path)).should eq [
            ["", "line1.h", "line1.c"], ["", "line2.c"],
          ]
        end
      end

      it "clang" do
        read_elf "line-clang-dwarf4.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 4
          line_numbers = dwarf.line_numbers.should_not be_nil
          line_numbers.matrix.should eq [
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401130, "line1.c", 6, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401134, "line1.c", 7, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401139, "line1.c", 8, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401140, "line1.c", 9, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401150, "./line1.h", 2, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401154, "./line1.h", 5, 8),
              Crystal::DWARF::LineNumbers::Row.new(0x40115b, "./line1.h", 5, 15),
              Crystal::DWARF::LineNumbers::Row.new(0x40115f, "./line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401165, "./line1.h", 6, 3),
              Crystal::DWARF::LineNumbers::Row.new(0x401169, "./line1.h", 6, 10),
              Crystal::DWARF::LineNumbers::Row.new(0x40116e, "./line1.h", 5, 22),
              Crystal::DWARF::LineNumbers::Row.new(0x401177, "./line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x40117c, "./line1.h", 7, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40117e, "./line1.h", 7, 1, true),
            ],
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401180, "line2.c", 4, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401184, "line2.c", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401195, "line2.c", 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401197, "line2.c", 6, 1, true),
            ],
          ]

          line_numbers.sequences.map(&.file_names.map(&.path)).should eq [
            ["", "line1.c", "./line1.h"], ["", "line2.c"],
          ]
        end
      end
    end

    describe "DWARF 5" do
      it "gcc" do
        read_elf "line-gcc-dwarf5.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 5
          line_numbers = dwarf.line_numbers.should_not be_nil
          line_numbers.matrix.should eq [
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401122, "line1.h", 2, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401126, "line1.h", 5, 8),
              Crystal::DWARF::LineNumbers::Row.new(0x40112d, "line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x40112f, "line1.h", 6, 10),
              Crystal::DWARF::LineNumbers::Row.new(0x401139, "line1.h", 5, 22),
              Crystal::DWARF::LineNumbers::Row.new(0x40113d, "line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401143, "line1.h", 7, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401147, "line1.c", 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40114b, "line1.c", 7, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401155, "line1.c", 8, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401164, "line1.c", 9, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401166, "line1.c", 9, 1, true),
            ],
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401166, "line2.c", 4, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40116a, "line2.c", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401174, "line2.c", 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401177, "line2.c", 6, 1, true),
            ],
          ]

          line_numbers.sequences.map(&.file_names.map(&.path)).should eq [
            ["", "line1.h", "line1.c"], ["", "line2.c"],
          ]
        end
      end

      it "clang" do
        read_elf "line-clang-dwarf5.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 5
          line_numbers = dwarf.line_numbers.should_not be_nil

          line_numbers.sequences.map(&.file_names.map { |file| File.basename(file.path) }).should eq [
            ["line1.c", "line1.h"], ["line2.c"],
          ]
          line1c_path = line_numbers.sequences[0].file_names[0].path
          line2c_path = line_numbers.sequences[1].file_names[0].path

          line_numbers.matrix.should eq [
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401130, line1c_path, 6, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401134, line1c_path, 7, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401139, line1c_path, 8, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401140, line1c_path, 9, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401150, "./line1.h", 2, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401154, "./line1.h", 5, 8),
              Crystal::DWARF::LineNumbers::Row.new(0x40115b, "./line1.h", 5, 15),
              Crystal::DWARF::LineNumbers::Row.new(0x40115f, "./line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401165, "./line1.h", 6, 3),
              Crystal::DWARF::LineNumbers::Row.new(0x401169, "./line1.h", 6, 10),
              Crystal::DWARF::LineNumbers::Row.new(0x40116e, "./line1.h", 5, 22),
              Crystal::DWARF::LineNumbers::Row.new(0x401177, "./line1.h", 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x40117c, "./line1.h", 7, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x40117e, "./line1.h", 7, 1, true),
            ],
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401180, line2c_path, 4, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401184, line2c_path, 5, 2),
              Crystal::DWARF::LineNumbers::Row.new(0x401195, line2c_path, 6, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401197, line2c_path, 6, 1, true),
            ],
          ]
        end
      end

      it "rnglistx" do
        read_elf "rnglistx-clang-dwarf5.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 5
          line_numbers = dwarf.line_numbers.should_not be_nil

          line_numbers.sequences.map(&.file_names.map { |file| File.basename(file.path) }).should eq [
            ["rnglistx.c"],
          ]
          rnglistx_path = line_numbers.sequences[0].file_names[0].path

          line_numbers.matrix.should eq [
            [
              Crystal::DWARF::LineNumbers::Row.new(0x401020, rnglistx_path, 14, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401020, rnglistx_path, 15, 12),
              Crystal::DWARF::LineNumbers::Row.new(0x401022, rnglistx_path, 15, 7),
              Crystal::DWARF::LineNumbers::Row.new(0x401024, rnglistx_path, 19, 1),
              Crystal::DWARF::LineNumbers::Row.new(0x401027, rnglistx_path, 18, 10),
              Crystal::DWARF::LineNumbers::Row.new(0x40102c, rnglistx_path, 18, 10, true),
            ], [
              Crystal::DWARF::LineNumbers::Row.new(0x401000, rnglistx_path, 4, 0),
              Crystal::DWARF::LineNumbers::Row.new(0x401000, rnglistx_path, 8, 17),
              Crystal::DWARF::LineNumbers::Row.new(0x401002, rnglistx_path, 8, 3),
              Crystal::DWARF::LineNumbers::Row.new(0x401019, rnglistx_path, 11, 3),
              Crystal::DWARF::LineNumbers::Row.new(0x40101c, rnglistx_path, 11, 3),
              Crystal::DWARF::LineNumbers::Row.new(0x40101d, rnglistx_path, 11, 3, true),
            ],
          ]

          line_numbers.sequences.map(&.file_names.map { |file| File.basename(file.path) }).should eq [
            ["rnglistx.c"],
          ]
        end
      end
    end
  end
end
