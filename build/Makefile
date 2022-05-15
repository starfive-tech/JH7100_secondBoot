# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (c) 2020 StarFiveTech, Inc

# compiler tool chain
CROSS_COMPILE?=riscv64-unknown-elf-
CC=${CROSS_COMPILE}gcc
LD=${CROSS_COMPILE}ld
OBJCOPY=${CROSS_COMPILE}objcopy
OBJDUMP=${CROSS_COMPILE}objdump

# SoC IS JH7100 FOR VISIONFIVE OR BEAGLEV OR EVBV1 
SoC=JH7100

SUFFIX=$(shell date +%y%m%d)
GIT_VERSION=$(shell git show -s --pretty=format:%h)
BLD_VERSION=$(SUFFIX)-$(GIT_VERSION)

TARGET 	= bootloader-$(SoC)-$(SUFFIX)
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

CFLAGS += -O2 -g -c -Wall -DVERSION=\"$(BLD_VERSION)\" -D$(SoC)
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
	rm -f $(OBJECTLIST) *.bin *.bin.out *.elf *.asm *.map
