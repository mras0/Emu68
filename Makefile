CC := arm-linux-gnueabihf-gcc
CXX := arm-linux-gnueabihf-g++
OBJCOPY := arm-linux-gnueabihf-objcopy
CFLAGS  := $(EXTRA_FLAGS) -mbig-endian -std=gnu11 -O3 -pedantic -pedantic-errors -ffixed-r11 -fomit-frame-pointer -Wall -Wextra -Werror
CXXFLAGS:= $(EXTRA_FLAGS) -mbig-endian -std=c++11 -O3 -pedantic -pedantic-errors -ffixed-r11 -fomit-frame-pointer -Wall -Wextra -Werror
LDFLAGS := -static -lrt -s

HOST_CXX := g++
HOST_CXXFLAGS := -O2 -std=c++11
HOST_LDFLAGS :=

OBJS := start_emu.o tlsf.o HunkLoader.o M68k_Translator.o RegisterAllocator.o M68k_EA.o M68k_SR.o \
        M68k_MOVE.o M68k_LINE0.o M68k_LINE4.o M68k_LINE5.o M68k_LINE6.o M68k_LINE8.o \
        M68k_LINE9.o M68k_LINEB.o M68k_LINEC.o M68k_LINED.o M68k_LINEE.o M68k_MULDIV.o

RPI_OBJS := start_rpi.o support_rpi.o devicetree.o tlsf.o HunkLoader.o M68k_Translator.o RegisterAllocator.o M68k_EA.o M68k_SR.o \
        M68k_MOVE.o M68k_LINE0.o M68k_LINE4.o M68k_LINE5.o M68k_LINE6.o M68k_LINE8.o \
        M68k_LINE9.o M68k_LINEB.o M68k_LINEC.o M68k_LINED.o M68k_LINEE.o M68k_MULDIV.o

OBJDIR := Build

TESTOBJS :=

TESTOBJDIR := BuildTest

raspi: pre-build raspi-build

all: pre-build main-build

pre-build:
	@mkdir -p $(OBJDIR) >/dev/null

raspi-build:
	@make --no-print-directory EXTRA_FLAGS="-ffreestanding -DRASPI" $(OBJDIR)/kernel.img

main-build: pre-build
	@make --no-print-directory $(OBJDIR)/Emu68

test:
	@make --no-print-directory $(TESTOBJDIR)/Emu68Test
	@$(TESTOBJDIR)/Emu68Test

$(TESTOBJDIR)/Emu68Test: $(addprefix $(TESTOBJDIR)/, $(TESTOBJS))
	@echo "Building test: $@"
	@$(HOST_CXX) $(foreach f,$(TESTOBJS),$(TESTOBJDIR)/$(f)) $(HOST_LDFLAGS) -o $@

$(OBJDIR)/Emu68: $(addprefix $(OBJDIR)/, $(OBJS))
	@echo "Building target: $@"
	@$(CC) $(foreach f,$(OBJS),$(OBJDIR)/$(f)) $(LDFLAGS) -o $@
	@echo "Build completed"

$(OBJDIR)/kernel.img: $(addprefix $(OBJDIR)/, $(RPI_OBJS))
	@echo "Building target: $@"
	@$(CC) $(foreach f,$(RPI_OBJS),$(OBJDIR)/$(f)) -Wl,--be8 -Wl,--format=elf32-bigarm -nostdlib -nostartfiles -static -T ldscript-be.lds -o $@.elf
	@$(OBJCOPY) -O binary $@.elf $@
	@echo "Build completed"

.PHONY: all clean
.SECONDARY: main-build pre-build test

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	@echo "Compiling: $*.cpp"
	@$(CXX) -c $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.d: %.cpp
	@mkdir -p $(@D)
	@set -e; rm -f $@; \
         $(CXX) -MM -MT $(basename $@).o $(CXXFLAGS) $< > $@.$$$$; \
         sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
         rm -f $@.$$$$

$(TESTOBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	@echo "Compiling: $*.cpp"
	@$(HOST_CXX) -c $(HOST_CXXFLAGS) $< -o $@

$(TESTOBJDIR)/%.d: %.cpp
	@mkdir -p $(@D)
	@set -e; rm -f $@; \
         $(HOST_CXX) -MM -MT $(basename $@).o $(HOST_CXXFLAGS) $< > $@.$$$$; \
         sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
         rm -f $@.$$$$

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	@echo "Compiling: $*.c"
	@$(CC) -c $(CFLAGS) $< -o $@

$(OBJDIR)/%.d: %.c
	@mkdir -p $(@D)
	@set -e; rm -f $@; \
         $(CC) -MM -MT $(basename $@).o $(CFLAGS) $< > $@.$$$$; \
         sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
         rm -f $@.$$$$

$(TESTOBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	@echo "Compiling: $*.c"
	@$(HOST_CXX) -c $(HOST_CXXFLAGS) $< -o $@

$(TESTOBJDIR)/%.d: %.cpp
	@mkdir -p $(@D)
	@set -e; rm -f $@; \
         $(HOST_CXX) -MM -MT $(basename $@).o $(HOST_CXXFLAGS) $< > $@.$$$$; \
         sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
         rm -f $@.$$$$

clean:
	rm -rf *.o *.d $(OBJDIR) $(TESTOBJDIR)

-include $(foreach f,$(OBJS:.o=.d),$(OBJDIR)/$(f))
-include $(foreach f,$(RPI_OBJS:.o=.d),$(OBJDIR)/$(f))
-include $(foreach f,$(TESTOBJS:.o=.d),$(TESTOBJDIR)/$(f))
