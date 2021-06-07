# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2020 StarFiveTech, Inc

# compiler tool chain
CROSSCOMPILE?=riscv64-unknown-elf-
CC=${CROSSCOMPILE}gcc
LD=${CROSSCOMPILE}ld
OBJCOPY=${CROSSCOMPILE}objcopy
OBJDUMP=${CROSSCOMPILE}objdump

# BOARD IS BEAGLEV OR EVBV1
BOARD=BEAGLEV

SUFFIX=$(shell date +%y%m%d)
GIT_VERSION=$(shell git show -s --pretty=format:%h)
BLD_VERSION=$(SUFFIX)-$(GIT_VERSION)

TARGET 	= bootloader-$(BOARD)-$(SUFFIX)
LINKER_SCRIPT := bootloader.lds
MAP_FILE := bootloader.map

INCLUDE_DIR=-I. -I../boot\
			-I../common\
			-I../gpio\
			-I../spi\
			-I../system\
			-I../uart \
			-I../timer 

# compiler options
RISCV_ARCH := rv64imafdc
RISCV_ABI  := lp64d 

CFLAGS += -O2 -g -c -Wall -DVERSION=\"$(BLD_VERSION)\" -D$(BOARD)
CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=medany
CFLAGS += $(INCLUDE_DIR)
CCASFLAGS= -mcmodel=medany -mexplicit-relocs	
					
LDFLAGS = -march=$(RISCV_ARCH) -mabi=$(RISCV_ABI)-T $(LINKER_SCRIPT) -nostartfiles --specs=nano.specs -Wl,-Map,$(MAP_FILE)

# object list
OBJECTLIST=../boot/start.o\
		../boot/bootmain.o\
		../boot/trap.o\
		../uart/uart.o\
		../common/util.o \
		../spi/spi.o\
		../spi/spi_probe.o\
		../spi/cadence_qspi.o\
		../spi/spi_flash.o\
		../spi/cadence_qspi_apb.o\
		../timer/timer.o




all:$(TARGET).elf $(TARGET).bin $(TARGET).asm

$(TARGET).elf:$(OBJECTLIST)
	@echo ================================================================================
	$(CC) -o $(TARGET).elf  $(LDFLAGS) $(OBJECTLIST)
	@echo $(TARGET).elf LINK SUCCEED!	


%.bin: %.elf
	$(OBJCOPY) -O binary $^ $@
	@if [ -f fsz.sh ]; then ./fsz.sh $(TARGET).bin; fi

%.asm: %.elf
	$(OBJDUMP) -S $^ > $@

%.dtb: %.dts
	dtc $^ -o $@ -O dtb

%.o: %.S 
	$(CC) $(CFLAGS) $(CCASFLAGS) -c $< -o $@

%.o: %.c 
	$(CC) $(CFLAGS) -o $@ -c $<
	
.PHONY: clean
clean:
	rm -f ../*/*.o $(TARGET).bin $(TARGET).bin.out $(TARGET).elf $(TARGET).asm *.map
