/* Copyright (c) 2020 StarFiveTech, Inc */

OUTPUT_ARCH( "riscv" )

MEMORY
{
  rom (rx) : ORIGIN = 0x18000000, LENGTH = 64K
  ram (rwx) : ORIGIN = 0x18010000, LENGTH = 32K
}

ENTRY( _start )

PHDRS
{
  text PT_LOAD;
  rodata PT_LOAD;
  data PT_LOAD;
  bss PT_LOAD;
}

SECTIONS
{
  __stack_size = DEFINED(__stack_size) ? __stack_size : 2K;
  
  .init  ALIGN((ORIGIN(rom) + 0x0), 64) : AT(ALIGN((ORIGIN(rom) + 0x0), 64))
  {
    KEEP (*(SORT_NONE(.init)))
  } >rom :text
  
  .text ALIGN((ADDR(.init) + SIZEOF(.init)), 64) : AT(ALIGN((LOADADDR(.init) + SIZEOF(.init)), 64))
  {
    PROVIDE(_ftext = .);
    *(.text.unlikely .text.unlikely.*)
    *(.text.startup .text.startup.*)
    *(.text .text.*)
    *(.gnu.linkonce.t.*)
	PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);
  } >rom :text
  
  .rodata ALIGN((ADDR(.text) + SIZEOF(.text)), 64) : AT(ALIGN((LOADADDR(.text) + SIZEOF(.text)), 64))
  {
    *(.rdata)
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
  } >rom :rodata
  
  .eh_frame ALIGN((ADDR(.rodata) + SIZEOF(.rodata)), 64) : AT(ALIGN((LOADADDR(.rodata) + SIZEOF(.rodata)), 64)) 
  {
    *(.eh_frame)
  } >rom  :text
  

  
  .srodata ALIGN((ADDR(.eh_frame) + SIZEOF(.eh_frame)), 64) : AT(ALIGN((LOADADDR(.eh_frame) + SIZEOF(.eh_frame)), 64)) 
  {
    *(.srodata.cst16)
    *(.srodata.cst8)
    *(.srodata.cst4)
    *(.srodata.cst2)
    *(.srodata.*)
  } >rom  :rodata
  
  .data ALIGN((ORIGIN(ram)), 64) : AT(ALIGN((LOADADDR(.srodata) + SIZEOF(.srodata)), 64))
  {
    *(.data .data.* .gnu.linkonce.d.*)
	. = ALIGN(8);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.tohost) /* TODO: Support sections that aren't explicitly listed in this linker script */
  } >ram :data

  .sdata ALIGN((ADDR(.data) + SIZEOF(.data)), 64) : AT(ALIGN((LOADADDR(.data) + SIZEOF(.data)), 64))
  {
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  } >ram :data

  PROVIDE(_data = ADDR(.data));
  PROVIDE(_data_lma = LOADADDR(.data));
  
  PROVIDE( _edata = . );

  . = ALIGN(8);
  PROVIDE( _bss_start = . );
  
  .bss ALIGN((ADDR(.sdata) + SIZEOF(.sdata)), 64) : AT(ALIGN((LOADADDR(.sdata)), 64)) ALIGN(8)
  {
    *(.sbss*)
    *(.gnu.linkonce.sb.*)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
	. = ALIGN(8);
    PROVIDE(_ebss = .);
  } >ram :bss

  PROVIDE( _end = . );
  PROVIDE( _bss_end = . );
  
  /*
   * heap_stack_region_usable_end: (ORIGIN(ram) + LENGTH(ram))
   * heap_stack_min_size: 4096
   * heap_stack_max_size: 8292
   */
  PROVIDE(_sp = ALIGN(MIN((ORIGIN(ram) + LENGTH(ram)), _bss_end + 8292) - 7, 8));
  
  /*
	* Protect top of stack from heap, but this will not protect the heap from
	* stack overruns.
  */
  PROVIDE(_heap_end = _sp - 0x100);
  
  .stack :
  {
     ASSERT(_sp >= (_bss_end + 4096), "Error: No room left for the heap and stack");
  }
}