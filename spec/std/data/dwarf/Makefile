GCC := gcc
CLANG := clang

LINE_SRC := line1.c line2.c

all: all-gcc all-clang

all-gcc: line-gcc-dwarf4.elf line-gcc-dwarf5.elf
all-clang: line-clang-dwarf4.elf line-clang-dwarf5.elf rnglistx-clang-dwarf5.elf

line-gcc-dwarf4.elf: $(LINE_SRC)
	$(GCC) --version > $@.buildinfo
	$(GCC) -g -gdwarf-4 -o $@ $^

line-gcc-dwarf5.elf: $(LINE_SRC)
	$(GCC) --version > $@.buildinfo
	$(GCC) -g -gdwarf-5 -o $@ $^

line-clang-dwarf4.elf: $(LINE_SRC)
	$(CLANG) --version > $@.buildinfo
	$(CLANG) -g -gdwarf-4 -o $@ $^
line-clang-dwarf5.elf: $(LINE_SRC)
	$(CLANG) --version > $@.buildinfo
	$(CLANG) -g -gdwarf-5 -o $@ $^

rnglistx-clang-dwarf5.elf: rnglistx.c
	$(CLANG) --version > $@.buildinfo
	$(CLANG) -g -gdwarf-5 -O2 -nostdlib -o $@ $^

clean:
	rm -rf *.elf
	rm -rf *.buildinfo
