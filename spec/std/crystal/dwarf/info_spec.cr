require "./spec_helper"

describe Crystal::DWARF::LineNumbers do
  describe "ELF" do
    describe "DWARF 4" do
      it "gcc" do
        read_elf "line-gcc-dwarf4.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 4
          info.unit_length.should eq 167
          info.unit_type.should eq 0
          info.debug_abbrev_offset.should eq 0
          info.address_size.should eq 8
          info.abbreviations?.should be_nil
          info.dwarf64.should be_false
        end
      end

      it "clang" do
        read_elf "line-clang-dwarf4.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 4
          info.unit_length.should eq 147
          info.unit_type.should eq 0
          info.debug_abbrev_offset.should eq 0
          info.address_size.should eq 8
          info.abbreviations?.should be_nil
          info.dwarf64.should be_false
        end
      end
    end

    describe "DWARF 5" do
      it "gcc" do
        read_elf "line-gcc-dwarf5.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 5
          info.unit_length.should eq 166
          info.unit_type.should eq 1
          info.debug_abbrev_offset.should eq 0
          info.address_size.should eq 8
          info.abbreviations?.should be_nil
          info.dwarf64.should be_false
        end
      end

      it "clang" do
        read_elf "line-clang-dwarf5.elf" do |elf|
          dwarf = Crystal::DWARF::Data.new(elf)
          info = dwarf.info.should_not be_nil
          info.version.should eq 5
          info.unit_length.should eq 105
          info.unit_type.should eq 1
          info.debug_abbrev_offset.should eq 0
          info.address_size.should eq 8
          info.abbreviations?.should be_nil
          info.dwarf64.should be_false
        end
      end
    end
  end
end
