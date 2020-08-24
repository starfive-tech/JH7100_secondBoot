
bootloader.elf:     file format elf64-littleriscv


Disassembly of section .init:

0000000018000000 <_start>:
	.section .init
	.globl _start

_start:

	la t0, trap_entry
    18000000:	00000297          	auipc	t0,0x0
    18000004:	2c028293          	addi	t0,t0,704 # 180002c0 <trap_entry>
	csrw mtvec, t0
    18000008:	30529073          	csrw	mtvec,t0
	csrwi mstatus, 0
    1800000c:	30005073          	csrwi	mstatus,0
	csrwi mie, 0
    18000010:	30405073          	csrwi	mie,0

	// Allocate 4 KiB stack for each hart
	csrr t0, mhartid
    18000014:	f14022f3          	csrr	t0,mhartid
	slli t0, t0, 12
    18000018:	02b2                	slli	t0,t0,0xc
	la sp, _sp
    1800001a:	00012117          	auipc	sp,0x12
    1800001e:	13e10113          	addi	sp,sp,318 # 18012158 <_sp>
	sub sp, sp, t0
    18000022:	40510133          	sub	sp,sp,t0

	li	 a1, NONSMP_HART;
    18000026:	4581                	li	a1,0
	csrr a0, mhartid;
    18000028:	f1402573          	csrr	a0,mhartid
	bne  a0, a1, .LbootOtherHart //other hart
    1800002c:	04b51c63          	bne	a0,a1,18000084 <_start+0x84>

	// Load data section
	la t0, _data_lma
    18000030:	00002297          	auipc	t0,0x2
    18000034:	41028293          	addi	t0,t0,1040 # 18002440 <_data_lma>
	la t1, _data
    18000038:	00010317          	auipc	t1,0x10
    1800003c:	fc830313          	addi	t1,t1,-56 # 18010000 <_data>
	beq t0, t1, 2f
    18000040:	02628063          	beq	t0,t1,18000060 <_start+0x60>
	la t2, _edata
    18000044:	00010397          	auipc	t2,0x10
    18000048:	fbc38393          	addi	t2,t2,-68 # 18010000 <_data>
	bgeu t1, t2, 2f
    1800004c:	00737a63          	bgeu	t1,t2,18000060 <_start+0x60>
1:
	ld t3, 0(t0)
    18000050:	0002be03          	ld	t3,0(t0)
	sd t3, 0(t1)
    18000054:	01c33023          	sd	t3,0(t1)
	addi t0, t0, 8
    18000058:	02a1                	addi	t0,t0,8
	addi t1, t1, 8
    1800005a:	0321                	addi	t1,t1,8
	bltu t1, t2, 1b
    1800005c:	fe736ae3          	bltu	t1,t2,18000050 <_start+0x50>
2:

	/* Clear bss section */
	la t1, _bss_start
    18000060:	00010317          	auipc	t1,0x10
    18000064:	fa030313          	addi	t1,t1,-96 # 18010000 <_data>
	la t2, _bss_end
    18000068:	00010397          	auipc	t2,0x10
    1800006c:	09038393          	addi	t2,t2,144 # 180100f8 <_bss_end>
	bgeu t1, t2, 4f
    18000070:	00737763          	bgeu	t1,t2,1800007e <_start+0x7e>
3:
  sd   x0, 0(t1)
    18000074:	00033023          	sd	zero,0(t1)
  addi t1, t1, 8
    18000078:	0321                	addi	t1,t1,8
  blt  t1, t2, 3b
    1800007a:	fe734de3          	blt	t1,t2,18000074 <_start+0x74>
4:
	/*only hart 0*/
	call BootMain
    1800007e:	1b2000ef          	jal	ra,18000230 <BootMain>
	j .enter_uboot
    18000082:	a881                	j	180000d2 <.enter_uboot>
	
.LbootOtherHart:
	li s1, CLINT_CTRL_ADDR
    18000084:	020004b7          	lui	s1,0x2000
	csrr a0, mhartid
    18000088:	f1402573          	csrr	a0,mhartid
	slli s2, a0, 2
    1800008c:	00251913          	slli	s2,a0,0x2
	add s2, s2, s1
    18000090:	9926                	add	s2,s2,s1
	sw zero, 0(s2)
    18000092:	00092023          	sw	zero,0(s2)
	fence
    18000096:	0ff0000f          	fence
	csrw mip, 0
    1800009a:	34405073          	csrwi	mip,0

	# core 1 jumps to main_other_hart
	# Set MSIE bit to receive IPI
	li a2, MIP_MSIP
    1800009e:	4621                	li	a2,8
	csrw mie, a2
    180000a0:	30461073          	csrw	mie,a2
	
.LwaitOtherHart:
	# Wait for an IPI to signal that its safe to boot
//	call second_hart
	wfi 	
    180000a4:	10500073          	wfi
	# Only start if MIP_MSIP is set
	csrr a2, mip
    180000a8:	34402673          	csrr	a2,mip
	andi a2, a2, MIP_MSIP
    180000ac:	8a21                	andi	a2,a2,8
	beqz a2, .LwaitOtherHart
    180000ae:	da7d                	beqz	a2,180000a4 <_start+0xa4>

	li s1, CLINT_CTRL_ADDR
    180000b0:	020004b7          	lui	s1,0x2000
	csrr a0, mhartid
    180000b4:	f1402573          	csrr	a0,mhartid
	slli s2, a0, 2
    180000b8:	00251913          	slli	s2,a0,0x2
	add s2, s2, s1
    180000bc:	9926                	add	s2,s2,s1
	sw zero, 0(s2)
    180000be:	00092023          	sw	zero,0(s2)
	fence
    180000c2:	0ff0000f          	fence
	csrw mip, 0
    180000c6:	34405073          	csrwi	mip,0
	li a2, NUM_CORES  
    180000ca:	4609                	li	a2,2
	bltu a0, a2, .enter_uboot
    180000cc:	00c56363          	bltu	a0,a2,180000d2 <.enter_uboot>
	j .LwaitOtherHart
    180000d0:	bfd1                	j	180000a4 <_start+0xa4>

00000000180000d2 <.enter_uboot>:

.enter_uboot:
	li t0, DEFAULT_DDR_ADDR
    180000d2:	180802b7          	lui	t0,0x18080
	csrr a0, mhartid
    180000d6:	f1402573          	csrr	a0,mhartid
	la a1, 0
    180000da:	0000059b          	sext.w	a1,zero
	jr t0
    180000de:	8282                	jr	t0

Disassembly of section .text:

0000000018000100 <load_data.constprop.0>:
 *des_addr: store the data read from flash
 *page_offset:Offset of data stored in flash 
 *mode:flash work mode
*/

static int load_data(struct spi_flash* spi_flash,unsigned int des_addr,unsigned int page_offset,int mode)
    18000100:	710d                	addi	sp,sp,-352
    18000102:	f656                	sd	s5,296(sp)
	u8 *addr;
	int ret;
	int i;
	u32 offset;

	pageSize = spi_flash->page_size;
    18000104:	01452a83          	lw	s5,20(a0)
	addr = (u8 *)des_addr;
	offset = page_offset*pageSize;
	
	/*read first page,get the file size*/
	ret = spi_flash->read(spi_flash,offset,pageSize,dataBuf,mode);
    18000108:	711c                	ld	a5,32(a0)
static int load_data(struct spi_flash* spi_flash,unsigned int des_addr,unsigned int page_offset,int mode)
    1800010a:	f25a                	sd	s6,288(sp)
	ret = spi_flash->read(spi_flash,offset,pageSize,dataBuf,mode);
    1800010c:	8b2e                	mv	s6,a1
static int load_data(struct spi_flash* spi_flash,unsigned int des_addr,unsigned int page_offset,int mode)
    1800010e:	e2ca                	sd	s2,320(sp)
    18000110:	fa52                	sd	s4,304(sp)
    18000112:	ee86                	sd	ra,344(sp)
    18000114:	eaa2                	sd	s0,336(sp)
    18000116:	e6a6                	sd	s1,328(sp)
    18000118:	fe4e                	sd	s3,312(sp)
    1800011a:	ee5e                	sd	s7,280(sp)
    1800011c:	ea62                	sd	s8,272(sp)
	offset = page_offset*pageSize;
    1800011e:	008a959b          	slliw	a1,s5,0x8
	ret = spi_flash->read(spi_flash,offset,pageSize,dataBuf,mode);
    18000122:	875a                	mv	a4,s6
    18000124:	0034                	addi	a3,sp,8
    18000126:	8656                	mv	a2,s5
static int load_data(struct spi_flash* spi_flash,unsigned int des_addr,unsigned int page_offset,int mode)
    18000128:	892a                	mv	s2,a0
	offset = page_offset*pageSize;
    1800012a:	8a2e                	mv	s4,a1
	ret = spi_flash->read(spi_flash,offset,pageSize,dataBuf,mode);
    1800012c:	9782                	jalr	a5
	if(ret != 0)
    1800012e:	e949                	bnez	a0,180001c0 <load_data.constprop.0+0xc0>
        printk("read fail#\r\n");
		return -1;
    }
	
	/*calculate file size*/
	fileSize = (dataBuf[3] << 24) | (dataBuf[2] << 16) | (dataBuf[1] << 8) | (dataBuf[0]) ;
    18000130:	49a2                	lw	s3,8(sp)
	if(fileSize == 0)
    18000132:	08098563          	beqz	s3,180001bc <load_data.constprop.0+0xbc>
		return -1;

	endPage = ((fileSize + 255) >> 8);//page align
    18000136:	0ff9899b          	addiw	s3,s3,255
    1800013a:	8c2a                	mv	s8,a0
	/*copy the first page data*/
	sys_memcpy(addr, &dataBuf[4], SPIBOOT_LOAD_ADDR_OFFSET);
    1800013c:	0fc00613          	li	a2,252
    18000140:	006c                	addi	a1,sp,12
    18000142:	18080537          	lui	a0,0x18080
	endPage = ((fileSize + 255) >> 8);//page align
    18000146:	0089d41b          	srliw	s0,s3,0x8
	sys_memcpy(addr, &dataBuf[4], SPIBOOT_LOAD_ADDR_OFFSET);
    1800014a:	23b000ef          	jal	ra,18000b84 <sys_memcpy>

	offset += pageSize;
    1800014e:	015a0a3b          	addw	s4,s4,s5
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
	
	/*read Remaining pages data*/
	for(i=1; i<=endPage; i++)
    18000152:	c821                	beqz	s0,180001a2 <load_data.constprop.0+0xa2>
	{ 		
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    18000154:	e7f807b7          	lui	a5,0xe7f80
    18000158:	0014099b          	addiw	s3,s0,1
    1800015c:	f047879b          	addiw	a5,a5,-252
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
    18000160:	18080437          	lui	s0,0x18080
        {
            printk("read fail##\r\n");
			return -1;
        }
		offset += pageSize;
		addr +=pageSize;
    18000164:	020a9b93          	slli	s7,s5,0x20
	for(i=1; i<=endPage; i++)
    18000168:	4485                	li	s1,1
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
    1800016a:	0fc40413          	addi	s0,s0,252 # 180800fc <_sp+0x6dfa4>
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    1800016e:	00fa0a3b          	addw	s4,s4,a5
		addr +=pageSize;
    18000172:	020bdb93          	srli	s7,s7,0x20
    18000176:	a021                	j	1800017e <load_data.constprop.0+0x7e>
    18000178:	945e                	add	s0,s0,s7
	for(i=1; i<=endPage; i++)
    1800017a:	02998463          	beq	s3,s1,180001a2 <load_data.constprop.0+0xa2>
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    1800017e:	02093783          	ld	a5,32(s2)
    18000182:	86a2                	mv	a3,s0
    18000184:	008a05bb          	addw	a1,s4,s0
    18000188:	875a                	mv	a4,s6
    1800018a:	8656                	mv	a2,s5
    1800018c:	854a                	mv	a0,s2
    1800018e:	9782                	jalr	a5
	for(i=1; i<=endPage; i++)
    18000190:	2485                	addiw	s1,s1,1
		if(ret != 0)
    18000192:	d17d                	beqz	a0,18000178 <load_data.constprop.0+0x78>
            printk("read fail##\r\n");
    18000194:	00002517          	auipc	a0,0x2
    18000198:	13c50513          	addi	a0,a0,316 # 180022d0 <udelay+0x4a>
    1800019c:	1c5000ef          	jal	ra,18000b60 <printk>
			return -1;
    180001a0:	5c7d                	li	s8,-1
	}
	return 0;
}
    180001a2:	60f6                	ld	ra,344(sp)
    180001a4:	6456                	ld	s0,336(sp)
    180001a6:	8562                	mv	a0,s8
    180001a8:	64b6                	ld	s1,328(sp)
    180001aa:	6916                	ld	s2,320(sp)
    180001ac:	79f2                	ld	s3,312(sp)
    180001ae:	7a52                	ld	s4,304(sp)
    180001b0:	7ab2                	ld	s5,296(sp)
    180001b2:	7b12                	ld	s6,288(sp)
    180001b4:	6bf2                	ld	s7,280(sp)
    180001b6:	6c52                	ld	s8,272(sp)
    180001b8:	6135                	addi	sp,sp,352
    180001ba:	8082                	ret
		return -1;
    180001bc:	5c7d                	li	s8,-1
    180001be:	b7d5                	j	180001a2 <load_data.constprop.0+0xa2>
        printk("read fail#\r\n");
    180001c0:	00002517          	auipc	a0,0x2
    180001c4:	10050513          	addi	a0,a0,256 # 180022c0 <udelay+0x3a>
    180001c8:	199000ef          	jal	ra,18000b60 <printk>
		return -1;
    180001cc:	5c7d                	li	s8,-1
    180001ce:	bfd1                	j	180001a2 <load_data.constprop.0+0xa2>

00000000180001d0 <start2run32>:
	(( STARTRUNNING )(start))(0);		
    180001d0:	02051313          	slli	t1,a0,0x20
    180001d4:	02035313          	srli	t1,t1,0x20
    180001d8:	4501                	li	a0,0
    180001da:	8302                	jr	t1

00000000180001dc <load_and_run_ddr>:

void load_and_run_ddr(struct spi_flash* spi_flash,int mode)
{
    180001dc:	1141                	addi	sp,sp,-16
    180001de:	e406                	sd	ra,8(sp)
	unsigned int addr;
	int ret;

	addr = DEFAULT_DDR_ADDR;

	ret = load_data(spi_flash,addr,DEFAULT_DDR_OFFSET,mode);
    180001e0:	f21ff0ef          	jal	ra,18000100 <load_data.constprop.0>
	
	if(!ret)
    180001e4:	e911                	bnez	a0,180001f8 <load_and_run_ddr+0x1c>
#endif

#ifndef writel
static inline void writel(u32 val, volatile void *addr)
{
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180001e6:	020007b7          	lui	a5,0x2000
    180001ea:	4705                	li	a4,1
    180001ec:	0791                	addi	a5,a5,4
    180001ee:	c398                	sw	a4,0(a5)
	(( STARTRUNNING )(start))(0);		
    180001f0:	180807b7          	lui	a5,0x18080
    180001f4:	9782                	jalr	a5
	}
	else
		printk("\nload ddr bin fail.\n");
		
	/*never run to here*/
	while(1);
    180001f6:	a001                	j	180001f6 <load_and_run_ddr+0x1a>
		printk("\nload ddr bin fail.\n");
    180001f8:	00002517          	auipc	a0,0x2
    180001fc:	0e850513          	addi	a0,a0,232 # 180022e0 <udelay+0x5a>
    18000200:	161000ef          	jal	ra,18000b60 <printk>
    18000204:	bfcd                	j	180001f6 <load_and_run_ddr+0x1a>

0000000018000206 <boot_from_spi>:
}

void boot_from_spi(int mode)
{
    18000206:	1141                	addi	sp,sp,-16
	struct spi_flash* spi_flash;
	int ret;
	u32	*addr;
	u32 val;

    cadence_qspi_init(0, mode);
    18000208:	85aa                	mv	a1,a0
{
    1800020a:	e022                	sd	s0,0(sp)
    1800020c:	842a                	mv	s0,a0
    cadence_qspi_init(0, mode);
    1800020e:	4501                	li	a0,0
{
    18000210:	e406                	sd	ra,8(sp)
    cadence_qspi_init(0, mode);
    18000212:	7b3000ef          	jal	ra,180011c4 <cadence_qspi_init>
	spi_flash = spi_flash_probe(0, 0, 50000000, 0, (u32)SPI_DATAMODE_8);
    18000216:	02faf637          	lui	a2,0x2faf
    1800021a:	4581                	li	a1,0
    1800021c:	4721                	li	a4,8
    1800021e:	4681                	li	a3,0
    18000220:	08060613          	addi	a2,a2,128 # 2faf080 <__stack_size+0x2fae880>
    18000224:	4501                	li	a0,0
    18000226:	37b000ef          	jal	ra,18000da0 <spi_flash_probe>

	/*init ddr*/
	load_and_run_ddr(spi_flash,mode);
    1800022a:	85a2                	mv	a1,s0
    1800022c:	fb1ff0ef          	jal	ra,180001dc <load_and_run_ddr>

0000000018000230 <BootMain>:

}

static void chip_clk_init() 
{
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    18000230:	118007b7          	lui	a5,0x11800
    18000234:	4390                	lw	a2,0(a5)
    18000236:	fd0006b7          	lui	a3,0xfd000
    1800023a:	fff68593          	addi	a1,a3,-1 # fffffffffcffffff <_sp+0xffffffffe4fedea7>
    1800023e:	2601                	sext.w	a2,a2
    18000240:	01000837          	lui	a6,0x1000
	_SWITCH_CLOCK_clk_perh0_root_SOURCE_clk_pll0_out_;
}

/*only hartid 0 call this function*/
void BootMain(void)
{	
    18000244:	1141                	addi	sp,sp,-16
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    18000246:	8e6d                	and	a2,a2,a1
{	
    18000248:	e406                	sd	ra,8(sp)
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    1800024a:	01066633          	or	a2,a2,a6
    1800024e:	c390                	sw	a2,0(a5)
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
    18000250:	43d0                	lw	a2,4(a5)
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
    18000252:	03000737          	lui	a4,0x3000
	int boot_mode = 0;

	/*switch to pll mode*/
	chip_clk_init();

	uart_init(3);
    18000256:	450d                	li	a0,3
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
    18000258:	2601                	sext.w	a2,a2
    1800025a:	8e6d                	and	a2,a2,a1
    1800025c:	01066633          	or	a2,a2,a6
    18000260:	c3d0                	sw	a2,4(a5)
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
    18000262:	4794                	lw	a3,8(a5)
    18000264:	2681                	sext.w	a3,a3
    18000266:	8eed                	and	a3,a3,a1
    18000268:	8ed9                	or	a3,a3,a4
    1800026a:	c794                	sw	a3,8(a5)
	_SWITCH_CLOCK_clk_perh0_root_SOURCE_clk_pll0_out_;
    1800026c:	4b98                	lw	a4,16(a5)
    1800026e:	ff0006b7          	lui	a3,0xff000
    18000272:	16fd                	addi	a3,a3,-1
    18000274:	2701                	sext.w	a4,a4
    18000276:	8f75                	and	a4,a4,a3
    18000278:	01076733          	or	a4,a4,a6
    1800027c:	cb98                	sw	a4,16(a5)
	uart_init(3);
    1800027e:	078000ef          	jal	ra,180002f6 <uart_init>
    18000282:	180207b7          	lui	a5,0x18020
    18000286:	18000737          	lui	a4,0x18000
    1800028a:	17f1                	addi	a5,a5,-4
    1800028c:	c398                	sw	a4,0(a5)
    1800028e:	020007b7          	lui	a5,0x2000
    18000292:	4705                	li	a4,1
    18000294:	0791                	addi	a5,a5,4
    18000296:	c398                	sw	a4,0(a5)
	
	writel(0x18000000, 0x1801fffc);
	writel(0x1, 0x2000004); 		/*从bootrom中恢复hart1*/
	boot_from_spi(1);
    18000298:	4505                	li	a0,1
    1800029a:	f6dff0ef          	jal	ra,18000206 <boot_from_spi>

000000001800029e <handle_trap>:
   #define MCAUSE_CAUSE       0x00000000000003FFUL
#endif


uintptr_t handle_trap(uintptr_t mcause, uintptr_t epc)
{
    1800029e:	1141                	addi	sp,sp,-16
    180002a0:	e022                	sd	s0,0(sp)
	}
	else {
		rlSendString("unhandle trap.\n");
	}
#endif
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    180002a2:	862e                	mv	a2,a1
{
    180002a4:	842e                	mv	s0,a1
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    180002a6:	85aa                	mv	a1,a0
    180002a8:	00002517          	auipc	a0,0x2
    180002ac:	05050513          	addi	a0,a0,80 # 180022f8 <udelay+0x72>
{
    180002b0:	e406                	sd	ra,8(sp)
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    180002b2:	0af000ef          	jal	ra,18000b60 <printk>
	return epc;
}
    180002b6:	8522                	mv	a0,s0
    180002b8:	60a2                	ld	ra,8(sp)
    180002ba:	6402                	ld	s0,0(sp)
    180002bc:	0141                	addi	sp,sp,16
    180002be:	8082                	ret

00000000180002c0 <trap_entry>:

void trap_entry(void)
{
  unsigned long mcause = read_csr(mcause);
    180002c0:	342025f3          	csrr	a1,mcause
  unsigned long mepc = read_csr(mepc);
    180002c4:	34102673          	csrr	a2,mepc
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    180002c8:	00002517          	auipc	a0,0x2
    180002cc:	03050513          	addi	a0,a0,48 # 180022f8 <udelay+0x72>
    180002d0:	0910006f          	j	18000b60 <printk>

00000000180002d4 <__serial_tstc>:
};

static unsigned int serial_in(int offset)
{
	offset <<= 2;
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180002d4:	00010797          	auipc	a5,0x10
    180002d8:	d2c7e783          	lwu	a5,-724(a5) # 18010000 <_data>
    180002dc:	00379713          	slli	a4,a5,0x3
    180002e0:	00002797          	auipc	a5,0x2
    180002e4:	09078793          	addi	a5,a5,144 # 18002370 <uart_base>
    180002e8:	97ba                	add	a5,a5,a4
    180002ea:	6388                	ld	a0,0(a5)
    180002ec:	0551                	addi	a0,a0,20
#ifndef readl
static inline u32 readl(volatile void *addr)
{
	u32 val;

	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180002ee:	4108                	lw	a0,0(a0)
}

int __serial_tstc()
{
	return ((serial_in(REG_LSR)) & (1 << 0));
}
    180002f0:	8905                	andi	a0,a0,1
    180002f2:	8082                	ret

00000000180002f4 <serial_tstc>:
    180002f4:	b7c5                	j	180002d4 <__serial_tstc>

00000000180002f6 <uart_init>:
void uart_init(int id)
{
	unsigned int divisor;
	unsigned char lcr_cache;

	switch(id)
    180002f6:	4785                	li	a5,1
    180002f8:	2ef50363          	beq	a0,a5,180005de <uart_init+0x2e8>
    180002fc:	10a7d963          	bge	a5,a0,1800040e <uart_init+0x118>
    18000300:	4789                	li	a5,2
    18000302:	1cf50363          	beq	a0,a5,180004c8 <uart_init+0x1d2>
    18000306:	478d                	li	a5,3
    18000308:	1af51f63          	bne	a0,a5,180004c6 <uart_init+0x1d0>
		case 2:
			vic_uart2_reset_clk_gpio_misc_enable
			break;
			
		case 3:
			_ENABLE_CLOCK_clk_uart3_apb_;
    1800030c:	118006b7          	lui	a3,0x11800
    18000310:	2846a703          	lw	a4,644(a3) # 11800284 <__stack_size+0x117ffa84>
    18000314:	800007b7          	lui	a5,0x80000
    18000318:	fff7c613          	not	a2,a5
    1800031c:	2701                	sext.w	a4,a4
    1800031e:	80000837          	lui	a6,0x80000
    18000322:	8f71                	and	a4,a4,a2
    18000324:	01076733          	or	a4,a4,a6
    18000328:	2701                	sext.w	a4,a4
    1800032a:	28e6a223          	sw	a4,644(a3)
			_ENABLE_CLOCK_clk_uart3_core_;
    1800032e:	2886a783          	lw	a5,648(a3)

			_ASSERT_RESET_rstgen_rstn_uart3_apb_;
    18000332:	118405b7          	lui	a1,0x11840
    18000336:	fe000737          	lui	a4,0xfe000
			_ENABLE_CLOCK_clk_uart3_core_;
    1800033a:	2781                	sext.w	a5,a5
    1800033c:	8ff1                	and	a5,a5,a2
    1800033e:	0107e7b3          	or	a5,a5,a6
    18000342:	2781                	sext.w	a5,a5
    18000344:	28f6a423          	sw	a5,648(a3)
			_ASSERT_RESET_rstgen_rstn_uart3_apb_;
    18000348:	459c                	lw	a5,8(a1)
    1800034a:	177d                	addi	a4,a4,-1
    1800034c:	020006b7          	lui	a3,0x2000
    18000350:	2781                	sext.w	a5,a5
    18000352:	8ff9                	and	a5,a5,a4
    18000354:	02000737          	lui	a4,0x2000
    18000358:	8fd9                	or	a5,a5,a4
    1800035a:	c59c                	sw	a5,8(a1)
    1800035c:	11840737          	lui	a4,0x11840
    18000360:	4f1c                	lw	a5,24(a4)
    18000362:	2781                	sext.w	a5,a5
    18000364:	8ff5                	and	a5,a5,a3
    18000366:	ffed                	bnez	a5,18000360 <uart_init+0x6a>
			_ASSERT_RESET_rstgen_rstn_uart3_core_;
    18000368:	471c                	lw	a5,8(a4)
    1800036a:	fc0006b7          	lui	a3,0xfc000
    1800036e:	16fd                	addi	a3,a3,-1
    18000370:	2781                	sext.w	a5,a5
    18000372:	8ff5                	and	a5,a5,a3
    18000374:	040006b7          	lui	a3,0x4000
    18000378:	8fd5                	or	a5,a5,a3
    1800037a:	c71c                	sw	a5,8(a4)
    1800037c:	11840737          	lui	a4,0x11840
    18000380:	4f1c                	lw	a5,24(a4)
    18000382:	2781                	sext.w	a5,a5
    18000384:	8ff5                	and	a5,a5,a3
    18000386:	ffed                	bnez	a5,18000380 <uart_init+0x8a>
			_CLEAR_RESET_rstgen_rstn_uart3_core_;
    18000388:	471c                	lw	a5,8(a4)
    1800038a:	fc0006b7          	lui	a3,0xfc000
    1800038e:	16fd                	addi	a3,a3,-1
    18000390:	2781                	sext.w	a5,a5
    18000392:	8ff5                	and	a5,a5,a3
    18000394:	c71c                	sw	a5,8(a4)
    18000396:	040006b7          	lui	a3,0x4000
    1800039a:	11840737          	lui	a4,0x11840
    1800039e:	4f1c                	lw	a5,24(a4)
    180003a0:	2781                	sext.w	a5,a5
    180003a2:	8ff5                	and	a5,a5,a3
    180003a4:	dfed                	beqz	a5,1800039e <uart_init+0xa8>
			_CLEAR_RESET_rstgen_rstn_uart3_apb_;
    180003a6:	471c                	lw	a5,8(a4)
    180003a8:	fe0006b7          	lui	a3,0xfe000
    180003ac:	16fd                	addi	a3,a3,-1
    180003ae:	2781                	sext.w	a5,a5
    180003b0:	8ff5                	and	a5,a5,a3
    180003b2:	c71c                	sw	a5,8(a4)
    180003b4:	118406b7          	lui	a3,0x11840
    180003b8:	02000737          	lui	a4,0x2000
    180003bc:	4e9c                	lw	a5,24(a3)
    180003be:	2781                	sext.w	a5,a5
    180003c0:	8ff9                	and	a5,a5,a4
    180003c2:	dfed                	beqz	a5,180003bc <uart_init+0xc6>
			SET_GPIO_14_dout_uart3_pad_sout;
    180003c4:	119107b7          	lui	a5,0x11910
    180003c8:	0c07a703          	lw	a4,192(a5) # 119100c0 <__stack_size+0x1190f8c0>
    180003cc:	2701                	sext.w	a4,a4
    180003ce:	f0077713          	andi	a4,a4,-256
    180003d2:	08476713          	ori	a4,a4,132
    180003d6:	0ce7a023          	sw	a4,192(a5)
			SET_GPIO_14_doen_LOW;
    180003da:	0c47a703          	lw	a4,196(a5)
    180003de:	2701                	sext.w	a4,a4
    180003e0:	f0077713          	andi	a4,a4,-256
    180003e4:	0ce7a223          	sw	a4,196(a5)
			SET_GPIO_13_doen_HIGH;
    180003e8:	0bc7a703          	lw	a4,188(a5)
    180003ec:	2701                	sext.w	a4,a4
    180003ee:	f0077713          	andi	a4,a4,-256
    180003f2:	00176713          	ori	a4,a4,1
    180003f6:	0ae7ae23          	sw	a4,188(a5)
			SET_GPIO_uart3_pad_sin(13);
    180003fa:	3747a703          	lw	a4,884(a5)
    180003fe:	2701                	sext.w	a4,a4
    18000400:	f0077713          	andi	a4,a4,-256
    18000404:	00f76713          	ori	a4,a4,15
    18000408:	36e7aa23          	sw	a4,884(a5)
			break;
    1800040c:	a449                	j	1800068e <uart_init+0x398>
	switch(id)
    1800040e:	e95d                	bnez	a0,180004c4 <uart_init+0x1ce>
			vic_uart0_reset_clk_gpio_misc_enable;
    18000410:	118006b7          	lui	a3,0x11800
    18000414:	2486a703          	lw	a4,584(a3) # 11800248 <__stack_size+0x117ffa48>
    18000418:	800007b7          	lui	a5,0x80000
    1800041c:	fff7c613          	not	a2,a5
    18000420:	2701                	sext.w	a4,a4
    18000422:	80000837          	lui	a6,0x80000
    18000426:	8f71                	and	a4,a4,a2
    18000428:	01076733          	or	a4,a4,a6
    1800042c:	2701                	sext.w	a4,a4
    1800042e:	24e6a423          	sw	a4,584(a3)
    18000432:	24c6a783          	lw	a5,588(a3)
    18000436:	118405b7          	lui	a1,0x11840
    1800043a:	777d                	lui	a4,0xfffff
    1800043c:	2781                	sext.w	a5,a5
    1800043e:	8ff1                	and	a5,a5,a2
    18000440:	0107e7b3          	or	a5,a5,a6
    18000444:	2781                	sext.w	a5,a5
    18000446:	24f6a623          	sw	a5,588(a3)
    1800044a:	459c                	lw	a5,8(a1)
    1800044c:	7ff70713          	addi	a4,a4,2047 # fffffffffffff7ff <_sp+0xffffffffe7fed6a7>
    18000450:	6685                	lui	a3,0x1
    18000452:	2781                	sext.w	a5,a5
    18000454:	8ff9                	and	a5,a5,a4
    18000456:	c59c                	sw	a5,8(a1)
    18000458:	11840737          	lui	a4,0x11840
    1800045c:	80068693          	addi	a3,a3,-2048 # 800 <__stack_size>
    18000460:	4f1c                	lw	a5,24(a4)
    18000462:	2781                	sext.w	a5,a5
    18000464:	8ff5                	and	a5,a5,a3
    18000466:	dfed                	beqz	a5,18000460 <uart_init+0x16a>
    18000468:	471c                	lw	a5,8(a4)
    1800046a:	118406b7          	lui	a3,0x11840
    1800046e:	2781                	sext.w	a5,a5
    18000470:	bff7f793          	andi	a5,a5,-1025
    18000474:	c71c                	sw	a5,8(a4)
    18000476:	4e9c                	lw	a5,24(a3)
    18000478:	4007f793          	andi	a5,a5,1024
    1800047c:	dfed                	beqz	a5,18000476 <uart_init+0x180>
    1800047e:	119107b7          	lui	a5,0x11910
    18000482:	3587a703          	lw	a4,856(a5) # 11910358 <__stack_size+0x1190fb58>
    18000486:	2701                	sext.w	a4,a4
    18000488:	f0077713          	andi	a4,a4,-256
    1800048c:	00776713          	ori	a4,a4,7
    18000490:	34e7ac23          	sw	a4,856(a5)
    18000494:	5ff8                	lw	a4,124(a5)
    18000496:	2701                	sext.w	a4,a4
    18000498:	f0077713          	andi	a4,a4,-256
    1800049c:	00176713          	ori	a4,a4,1
    180004a0:	dff8                	sw	a4,124(a5)
    180004a2:	0807a703          	lw	a4,128(a5)
    180004a6:	2701                	sext.w	a4,a4
    180004a8:	f0077713          	andi	a4,a4,-256
    180004ac:	07f76713          	ori	a4,a4,127
    180004b0:	08e7a023          	sw	a4,128(a5)
    180004b4:	0847a703          	lw	a4,132(a5)
    180004b8:	2701                	sext.w	a4,a4
    180004ba:	f0077713          	andi	a4,a4,-256
    180004be:	08e7a223          	sw	a4,132(a5)
			break;
    180004c2:	a2f1                	j	1800068e <uart_init+0x398>
    180004c4:	8082                	ret
    180004c6:	8082                	ret
			vic_uart2_reset_clk_gpio_misc_enable
    180004c8:	11800737          	lui	a4,0x11800
    180004cc:	27c72783          	lw	a5,636(a4) # 1180027c <__stack_size+0x117ffa7c>
    180004d0:	118406b7          	lui	a3,0x11840
    180004d4:	1786                	slli	a5,a5,0x21
    180004d6:	9385                	srli	a5,a5,0x21
    180004d8:	26f72e23          	sw	a5,636(a4)
    180004dc:	469c                	lw	a5,8(a3)
    180004de:	ff800737          	lui	a4,0xff800
    180004e2:	177d                	addi	a4,a4,-1
    180004e4:	2781                	sext.w	a5,a5
    180004e6:	8ff9                	and	a5,a5,a4
    180004e8:	00800737          	lui	a4,0x800
    180004ec:	8fd9                	or	a5,a5,a4
    180004ee:	c69c                	sw	a5,8(a3)
    180004f0:	11840737          	lui	a4,0x11840
    180004f4:	008006b7          	lui	a3,0x800
    180004f8:	4f1c                	lw	a5,24(a4)
    180004fa:	2781                	sext.w	a5,a5
    180004fc:	8ff5                	and	a5,a5,a3
    180004fe:	ffed                	bnez	a5,180004f8 <uart_init+0x202>
    18000500:	471c                	lw	a5,8(a4)
    18000502:	ff0006b7          	lui	a3,0xff000
    18000506:	16fd                	addi	a3,a3,-1
    18000508:	2781                	sext.w	a5,a5
    1800050a:	8ff5                	and	a5,a5,a3
    1800050c:	010006b7          	lui	a3,0x1000
    18000510:	8fd5                	or	a5,a5,a3
    18000512:	c71c                	sw	a5,8(a4)
    18000514:	118406b7          	lui	a3,0x11840
    18000518:	01000737          	lui	a4,0x1000
    1800051c:	4e9c                	lw	a5,24(a3)
    1800051e:	2781                	sext.w	a5,a5
    18000520:	8ff9                	and	a5,a5,a4
    18000522:	ffed                	bnez	a5,1800051c <uart_init+0x226>
    18000524:	11800637          	lui	a2,0x11800
    18000528:	27c62703          	lw	a4,636(a2) # 1180027c <__stack_size+0x117ffa7c>
    1800052c:	800007b7          	lui	a5,0x80000
    18000530:	fff7c593          	not	a1,a5
    18000534:	2701                	sext.w	a4,a4
    18000536:	80000837          	lui	a6,0x80000
    1800053a:	8f6d                	and	a4,a4,a1
    1800053c:	01076733          	or	a4,a4,a6
    18000540:	2701                	sext.w	a4,a4
    18000542:	26e62e23          	sw	a4,636(a2)
    18000546:	28062783          	lw	a5,640(a2)
    1800054a:	11840737          	lui	a4,0x11840
    1800054e:	2781                	sext.w	a5,a5
    18000550:	8fed                	and	a5,a5,a1
    18000552:	0107e7b3          	or	a5,a5,a6
    18000556:	2781                	sext.w	a5,a5
    18000558:	28f62023          	sw	a5,640(a2)
    1800055c:	469c                	lw	a5,8(a3)
    1800055e:	ff0005b7          	lui	a1,0xff000
    18000562:	15fd                	addi	a1,a1,-1
    18000564:	2781                	sext.w	a5,a5
    18000566:	8fed                	and	a5,a5,a1
    18000568:	01000637          	lui	a2,0x1000
    1800056c:	c69c                	sw	a5,8(a3)
    1800056e:	4f1c                	lw	a5,24(a4)
    18000570:	2781                	sext.w	a5,a5
    18000572:	8ff1                	and	a5,a5,a2
    18000574:	dfed                	beqz	a5,1800056e <uart_init+0x278>
    18000576:	471c                	lw	a5,8(a4)
    18000578:	ff8006b7          	lui	a3,0xff800
    1800057c:	16fd                	addi	a3,a3,-1
    1800057e:	2781                	sext.w	a5,a5
    18000580:	8ff5                	and	a5,a5,a3
    18000582:	c71c                	sw	a5,8(a4)
    18000584:	118406b7          	lui	a3,0x11840
    18000588:	00800737          	lui	a4,0x800
    1800058c:	4e9c                	lw	a5,24(a3)
    1800058e:	2781                	sext.w	a5,a5
    18000590:	8ff9                	and	a5,a5,a4
    18000592:	dfed                	beqz	a5,1800058c <uart_init+0x296>
    18000594:	119107b7          	lui	a5,0x11910
    18000598:	3707a703          	lw	a4,880(a5) # 11910370 <__stack_size+0x1190fb70>
    1800059c:	2701                	sext.w	a4,a4
    1800059e:	f0077713          	andi	a4,a4,-256
    180005a2:	00f76713          	ori	a4,a4,15
    180005a6:	36e7a823          	sw	a4,880(a5)
    180005aa:	0bc7a703          	lw	a4,188(a5)
    180005ae:	2701                	sext.w	a4,a4
    180005b0:	f0077713          	andi	a4,a4,-256
    180005b4:	00176713          	ori	a4,a4,1
    180005b8:	0ae7ae23          	sw	a4,188(a5)
    180005bc:	0c07a703          	lw	a4,192(a5)
    180005c0:	2701                	sext.w	a4,a4
    180005c2:	f0077713          	andi	a4,a4,-256
    180005c6:	08376713          	ori	a4,a4,131
    180005ca:	0ce7a023          	sw	a4,192(a5)
    180005ce:	0c47a703          	lw	a4,196(a5)
    180005d2:	2701                	sext.w	a4,a4
    180005d4:	f0077713          	andi	a4,a4,-256
    180005d8:	0ce7a223          	sw	a4,196(a5)
			break;
    180005dc:	a84d                	j	1800068e <uart_init+0x398>
			vic_uart1_reset_clk_gpio_misc_enable;
    180005de:	118006b7          	lui	a3,0x11800
    180005e2:	2506a703          	lw	a4,592(a3) # 11800250 <__stack_size+0x117ffa50>
    180005e6:	800007b7          	lui	a5,0x80000
    180005ea:	fff7c613          	not	a2,a5
    180005ee:	2701                	sext.w	a4,a4
    180005f0:	80000837          	lui	a6,0x80000
    180005f4:	8f71                	and	a4,a4,a2
    180005f6:	01076733          	or	a4,a4,a6
    180005fa:	2701                	sext.w	a4,a4
    180005fc:	24e6a823          	sw	a4,592(a3)
    18000600:	2546a783          	lw	a5,596(a3)
    18000604:	118405b7          	lui	a1,0x11840
    18000608:	11840737          	lui	a4,0x11840
    1800060c:	2781                	sext.w	a5,a5
    1800060e:	8ff1                	and	a5,a5,a2
    18000610:	0107e7b3          	or	a5,a5,a6
    18000614:	2781                	sext.w	a5,a5
    18000616:	24f6aa23          	sw	a5,596(a3)
    1800061a:	459c                	lw	a5,8(a1)
    1800061c:	76f9                	lui	a3,0xffffe
    1800061e:	16fd                	addi	a3,a3,-1
    18000620:	2781                	sext.w	a5,a5
    18000622:	8ff5                	and	a5,a5,a3
    18000624:	c59c                	sw	a5,8(a1)
    18000626:	6689                	lui	a3,0x2
    18000628:	4f1c                	lw	a5,24(a4)
    1800062a:	2781                	sext.w	a5,a5
    1800062c:	8ff5                	and	a5,a5,a3
    1800062e:	dfed                	beqz	a5,18000628 <uart_init+0x332>
    18000630:	471c                	lw	a5,8(a4)
    18000632:	76fd                	lui	a3,0xfffff
    18000634:	16fd                	addi	a3,a3,-1
    18000636:	2781                	sext.w	a5,a5
    18000638:	8ff5                	and	a5,a5,a3
    1800063a:	c71c                	sw	a5,8(a4)
    1800063c:	118406b7          	lui	a3,0x11840
    18000640:	6705                	lui	a4,0x1
    18000642:	4e9c                	lw	a5,24(a3)
    18000644:	2781                	sext.w	a5,a5
    18000646:	8ff9                	and	a5,a5,a4
    18000648:	dfed                	beqz	a5,18000642 <uart_init+0x34c>
    1800064a:	119107b7          	lui	a5,0x11910
    1800064e:	0807a703          	lw	a4,128(a5) # 11910080 <__stack_size+0x1190f880>
    18000652:	2701                	sext.w	a4,a4
    18000654:	f0077713          	andi	a4,a4,-256
    18000658:	08076713          	ori	a4,a4,128
    1800065c:	08e7a023          	sw	a4,128(a5)
    18000660:	35c7a703          	lw	a4,860(a5)
    18000664:	2701                	sext.w	a4,a4
    18000666:	f0077713          	andi	a4,a4,-256
    1800066a:	00776713          	ori	a4,a4,7
    1800066e:	34e7ae23          	sw	a4,860(a5)
    18000672:	5ff8                	lw	a4,124(a5)
    18000674:	2701                	sext.w	a4,a4
    18000676:	f0077713          	andi	a4,a4,-256
    1800067a:	00176713          	ori	a4,a4,1
    1800067e:	dff8                	sw	a4,124(a5)
    18000680:	0847a703          	lw	a4,132(a5)
    18000684:	2701                	sext.w	a4,a4
    18000686:	f0077713          	andi	a4,a4,-256
    1800068a:	08e7a223          	sw	a4,132(a5)
			
		default:
			return;
	}

 	uart_id = id;
    1800068e:	2501                	sext.w	a0,a0
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000690:	02051793          	slli	a5,a0,0x20
    18000694:	01d7d713          	srli	a4,a5,0x1d
    18000698:	00002797          	auipc	a5,0x2
    1800069c:	cd878793          	addi	a5,a5,-808 # 18002370 <uart_base>
    180006a0:	97ba                	add	a5,a5,a4
    180006a2:	639c                	ld	a5,0(a5)
 	uart_id = id;
    180006a4:	00010717          	auipc	a4,0x10
    180006a8:	94a72e23          	sw	a0,-1700(a4) # 18010000 <_data>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006ac:	00c78713          	addi	a4,a5,12
    180006b0:	4314                	lw	a3,0(a4)
	
	divisor = (UART_CLK / UART_BUADRATE_32MCLK_115200) >> 4;

	lcr_cache = serial_in(REG_LCR);
	serial_out(REG_LCR, (LCR_DLAB | lcr_cache));
    180006b2:	0ff6f613          	andi	a2,a3,255
	writel(value, (volatile void *)(uart_base[uart_id] + offset));
    180006b6:	08066613          	ori	a2,a2,128
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180006ba:	c310                	sw	a2,0(a4)
    180006bc:	03600613          	li	a2,54
    180006c0:	c390                	sw	a2,0(a5)
    180006c2:	4601                	li	a2,0
    180006c4:	00478593          	addi	a1,a5,4
    180006c8:	c190                	sw	a2,0(a1)
    180006ca:	0ff6f693          	andi	a3,a3,255
    180006ce:	c314                	sw	a3,0(a4)
    180006d0:	468d                	li	a3,3
    180006d2:	c314                	sw	a3,0(a4)
    180006d4:	01078713          	addi	a4,a5,16
    180006d8:	c310                	sw	a2,0(a4)
    180006da:	08f00713          	li	a4,143
    180006de:	07a1                	addi	a5,a5,8
    180006e0:	c398                	sw	a4,0(a5)
    180006e2:	c190                	sw	a2,0(a1)
	 * Clear TX and RX FIFO
	 */
	serial_out(REG_FCR, (FCR_FIFO | FCR_MODE1 | /*FCR_FIFO_1*/FCR_FIFO_8 | FCR_RCVRCLR | FCR_XMITCLR));
	
	serial_out(REG_IER, 0);//dis the ser interrupt
}
    180006e4:	8082                	ret

00000000180006e6 <_putc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006e6:	00010797          	auipc	a5,0x10
    180006ea:	91a7e783          	lwu	a5,-1766(a5) # 18010000 <_data>
    180006ee:	00379713          	slli	a4,a5,0x3
    180006f2:	00002797          	auipc	a5,0x2
    180006f6:	c7e78793          	addi	a5,a5,-898 # 18002370 <uart_base>
    180006fa:	97ba                	add	a5,a5,a4
    180006fc:	6394                	ld	a3,0(a5)
    180006fe:	01468713          	addi	a4,a3,20 # 11840014 <__stack_size+0x1183f814>
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000702:	431c                	lw	a5,0(a4)

int _putc(char c) {
	do
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000704:	0207f793          	andi	a5,a5,32
    18000708:	dfed                	beqz	a5,18000702 <_putc+0x1c>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800070a:	c288                	sw	a0,0(a3)

	serial_out(REG_THR, c);
	return 0;
}
    1800070c:	4501                	li	a0,0
    1800070e:	8082                	ret

0000000018000710 <rlSendString>:

void rlSendString(char *s)
{
	while (*s){
    18000710:	00054683          	lbu	a3,0(a0)
    18000714:	ca85                	beqz	a3,18000744 <rlSendString+0x34>
    18000716:	00010797          	auipc	a5,0x10
    1800071a:	8ea7e783          	lwu	a5,-1814(a5) # 18010000 <_data>
    1800071e:	00379713          	slli	a4,a5,0x3
    18000722:	00002797          	auipc	a5,0x2
    18000726:	c4e78793          	addi	a5,a5,-946 # 18002370 <uart_base>
    1800072a:	97ba                	add	a5,a5,a4
    1800072c:	6390                	ld	a2,0(a5)
    1800072e:	01460713          	addi	a4,a2,20 # 1000014 <__stack_size+0xfff814>
		_putc(*s++);
    18000732:	0505                	addi	a0,a0,1
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000734:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000736:	0207f793          	andi	a5,a5,32
    1800073a:	dfed                	beqz	a5,18000734 <rlSendString+0x24>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800073c:	c214                	sw	a3,0(a2)
	while (*s){
    1800073e:	00054683          	lbu	a3,0(a0)
    18000742:	fae5                	bnez	a3,18000732 <rlSendString+0x22>
	}
}
    18000744:	8082                	ret

0000000018000746 <CtrlBreak>:

int CtrlBreak( void )
{
    18000746:	00010797          	auipc	a5,0x10
    1800074a:	8ba7e783          	lwu	a5,-1862(a5) # 18010000 <_data>
    1800074e:	00379713          	slli	a4,a5,0x3
    18000752:	00002797          	auipc	a5,0x2
    18000756:	c1e78793          	addi	a5,a5,-994 # 18002370 <uart_base>
    1800075a:	97ba                	add	a5,a5,a4
    1800075c:	6394                	ld	a3,0(a5)
	int retflag;

	do{
		retflag	= serial_getc();
		if( retflag == 0x03 ){
    1800075e:	460d                	li	a2,3
    18000760:	01468713          	addi	a4,a3,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000764:	431c                	lw	a5,0(a4)
	return retflag;
}
int serial_getc()
{	
	/* Wait here until the the FIFO is not full */
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    18000766:	8b85                	andi	a5,a5,1
    18000768:	dff5                	beqz	a5,18000764 <CtrlBreak+0x1e>
    1800076a:	4288                	lw	a0,0(a3)

	return serial_in(REG_RDR);
    1800076c:	2501                	sext.w	a0,a0
		if( retflag == 0x03 ){
    1800076e:	00c50363          	beq	a0,a2,18000774 <CtrlBreak+0x2e>
	}while( retflag );
    18000772:	f96d                	bnez	a0,18000764 <CtrlBreak+0x1e>
}
    18000774:	8082                	ret

0000000018000776 <serial_getc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000776:	00010797          	auipc	a5,0x10
    1800077a:	88a7e783          	lwu	a5,-1910(a5) # 18010000 <_data>
    1800077e:	00379713          	slli	a4,a5,0x3
    18000782:	00002797          	auipc	a5,0x2
    18000786:	bee78793          	addi	a5,a5,-1042 # 18002370 <uart_base>
    1800078a:	97ba                	add	a5,a5,a4
    1800078c:	6388                	ld	a0,0(a5)
    1800078e:	01450713          	addi	a4,a0,20
    18000792:	431c                	lw	a5,0(a4)
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    18000794:	8b85                	andi	a5,a5,1
    18000796:	dff5                	beqz	a5,18000792 <serial_getc+0x1c>
    18000798:	4108                	lw	a0,0(a0)
}
    1800079a:	2501                	sext.w	a0,a0
    1800079c:	8082                	ret

000000001800079e <serial_gets>:
void serial_gets(char *pstr)
{
	unsigned char c;
	unsigned char *pstrorg;
	
	pstrorg = (unsigned char *) pstr;
    1800079e:	00010797          	auipc	a5,0x10
    180007a2:	8627e783          	lwu	a5,-1950(a5) # 18010000 <_data>
    180007a6:	00002e97          	auipc	t4,0x2
    180007aa:	bcae8e93          	addi	t4,t4,-1078 # 18002370 <uart_base>
    180007ae:	078e                	slli	a5,a5,0x3
    180007b0:	97f6                	add	a5,a5,t4
    180007b2:	6390                	ld	a2,0(a5)

	while ((c = serial_getc()) != '\r')
    180007b4:	88aa                	mv	a7,a0
    180007b6:	4335                	li	t1,13
    180007b8:	01460713          	addi	a4,a2,20
	{
		if (c == '\b'){
    180007bc:	4e21                	li	t3,8
    180007be:	431c                	lw	a5,0(a4)
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    180007c0:	8b85                	andi	a5,a5,1
    180007c2:	dff5                	beqz	a5,180007be <serial_gets+0x20>
    180007c4:	420c                	lw	a1,0(a2)
    180007c6:	0005879b          	sext.w	a5,a1
	while ((c = serial_getc()) != '\r')
    180007ca:	0ff7f693          	andi	a3,a5,255
    180007ce:	06668263          	beq	a3,t1,18000832 <serial_gets+0x94>
		if (c == '\b'){
    180007d2:	03c69a63          	bne	a3,t3,18000806 <serial_gets+0x68>
			if ((int) *pstrorg < (int) *pstr){
    180007d6:	00054583          	lbu	a1,0(a0)
    180007da:	0008c783          	lbu	a5,0(a7)
    180007de:	fef5f0e3          	bgeu	a1,a5,180007be <serial_gets+0x20>
    180007e2:	02000813          	li	a6,32
    180007e6:	00002597          	auipc	a1,0x2
    180007ea:	bba58593          	addi	a1,a1,-1094 # 180023a0 <digits.1744+0x10>
		_putc(*s++);
    180007ee:	0585                	addi	a1,a1,1
    180007f0:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    180007f2:	0207f793          	andi	a5,a5,32
    180007f6:	dfed                	beqz	a5,180007f0 <serial_gets+0x52>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180007f8:	c214                	sw	a3,0(a2)
	while (*s){
    180007fa:	02080a63          	beqz	a6,1800082e <serial_gets+0x90>
    180007fe:	86c2                	mv	a3,a6
    18000800:	0015c803          	lbu	a6,1(a1)
    18000804:	b7ed                	j	180007ee <serial_gets+0x50>
				rlSendString("\b \b");
				pstr--;
			}
		}else{
			*pstr++ = c;
    18000806:	00f88023          	sb	a5,0(a7)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800080a:	0000f797          	auipc	a5,0xf
    1800080e:	7f67e783          	lwu	a5,2038(a5) # 18010000 <_data>
    18000812:	078e                	slli	a5,a5,0x3
    18000814:	97f6                	add	a5,a5,t4
    18000816:	6390                	ld	a2,0(a5)
			*pstr++ = c;
    18000818:	0885                	addi	a7,a7,1
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800081a:	01460713          	addi	a4,a2,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    1800081e:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000820:	0207f793          	andi	a5,a5,32
    18000824:	dfed                	beqz	a5,1800081e <serial_gets+0x80>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000826:	0ff5f593          	andi	a1,a1,255
    1800082a:	c20c                	sw	a1,0(a2)
	return 0;
    1800082c:	bf49                	j	180007be <serial_gets+0x20>
				pstr--;
    1800082e:	18fd                	addi	a7,a7,-1
    18000830:	b779                	j	180007be <serial_gets+0x20>
			_putc(c);
		}
	}

	*pstr = '\0';
    18000832:	00088023          	sb	zero,0(a7)
	while (*s){
    18000836:	0000f797          	auipc	a5,0xf
    1800083a:	7ca7e783          	lwu	a5,1994(a5) # 18010000 <_data>
    1800083e:	078e                	slli	a5,a5,0x3
    18000840:	9ebe                	add	t4,t4,a5
    18000842:	000eb503          	ld	a0,0(t4)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000846:	45a9                	li	a1,10
    18000848:	00002617          	auipc	a2,0x2
    1800084c:	b6060613          	addi	a2,a2,-1184 # 180023a8 <digits.1744+0x18>
    18000850:	01450713          	addi	a4,a0,20
		_putc(*s++);
    18000854:	0605                	addi	a2,a2,1
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000856:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000858:	0207f793          	andi	a5,a5,32
    1800085c:	dfed                	beqz	a5,18000856 <serial_gets+0xb8>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800085e:	c114                	sw	a3,0(a0)
	while (*s){
    18000860:	c589                	beqz	a1,1800086a <serial_gets+0xcc>
    18000862:	86ae                	mv	a3,a1
    18000864:	00164583          	lbu	a1,1(a2)
    18000868:	b7f5                	j	18000854 <serial_gets+0xb6>

	rlSendString("\r\n");
		
}
    1800086a:	8082                	ret

000000001800086c <_puts>:
    1800086c:	b555                	j	18000710 <rlSendString>

000000001800086e <print_ubyte_hex>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800086e:	0000f717          	auipc	a4,0xf
    18000872:	79276703          	lwu	a4,1938(a4) # 18010000 <_data>
	static const char digits[16] = "0123456789ABCDEF";
	char tmp[2];
	int dig=0;

	dig = ((bval&0xf0)>>4);
	tmp[0] = digits[dig];
    18000876:	00002797          	auipc	a5,0x2
    1800087a:	afa78793          	addi	a5,a5,-1286 # 18002370 <uart_base>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800087e:	070e                	slli	a4,a4,0x3
	tmp[0] = digits[dig];
    18000880:	00455693          	srli	a3,a0,0x4
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000884:	973e                	add	a4,a4,a5
	dig = (bval&0x0f);
	tmp[1] = digits[dig];
    18000886:	893d                	andi	a0,a0,15
	tmp[0] = digits[dig];
    18000888:	00d78633          	add	a2,a5,a3
	tmp[1] = digits[dig];
    1800088c:	97aa                	add	a5,a5,a0
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800088e:	6314                	ld	a3,0(a4)
	tmp[0] = digits[dig];
    18000890:	02064583          	lbu	a1,32(a2)
	tmp[1] = digits[dig];
    18000894:	0207c603          	lbu	a2,32(a5)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000898:	01468713          	addi	a4,a3,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    1800089c:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    1800089e:	0207f793          	andi	a5,a5,32
    180008a2:	dfed                	beqz	a5,1800089c <print_ubyte_hex+0x2e>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180008a4:	c28c                	sw	a1,0(a3)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180008a6:	431c                	lw	a5,0(a4)
    180008a8:	0207f793          	andi	a5,a5,32
    180008ac:	dfed                	beqz	a5,180008a6 <print_ubyte_hex+0x38>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180008ae:	c290                	sw	a2,0(a3)
	_putc(tmp[0]);
	_putc(tmp[1]);
}
    180008b0:	8082                	ret

00000000180008b2 <serial_nowait_getc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180008b2:	0000f797          	auipc	a5,0xf
    180008b6:	74e7e783          	lwu	a5,1870(a5) # 18010000 <_data>
    180008ba:	00379713          	slli	a4,a5,0x3
    180008be:	00002797          	auipc	a5,0x2
    180008c2:	ab278793          	addi	a5,a5,-1358 # 18002370 <uart_base>
    180008c6:	97ba                	add	a5,a5,a4
    180008c8:	6398                	ld	a4,0(a5)
    180008ca:	01470793          	addi	a5,a4,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180008ce:	439c                	lw	a5,0(a5)
int serial_nowait_getc()
{
	unsigned int status;

	status = serial_in(REG_LSR);
	if (!(status & (1 << 0))) {
    180008d0:	8b85                	andi	a5,a5,1
    180008d2:	4501                	li	a0,0
    180008d4:	c781                	beqz	a5,180008dc <serial_nowait_getc+0x2a>
    180008d6:	4318                	lw	a4,0(a4)
	return val;
    180008d8:	0007051b          	sext.w	a0,a4
		goto out;
	}
	status = serial_in(REG_RDR);
out:
	return status;
}
    180008dc:	8082                	ret

00000000180008de <vnprintf>:
int vnprintf(char* out, size_t n, const char* s, va_list vl)
{
  bool format = false;
  bool longarg = false;
  size_t pos = 0;
  for( ; *s; s++)
    180008de:	00064783          	lbu	a5,0(a2)
    180008e2:	20078663          	beqz	a5,18000aee <vnprintf+0x210>
{
    180008e6:	7179                	addi	sp,sp,-48
    180008e8:	f422                	sd	s0,40(sp)
    180008ea:	f026                	sd	s1,32(sp)
    180008ec:	ec4a                	sd	s2,24(sp)
    180008ee:	e84e                	sd	s3,16(sp)
    180008f0:	e452                	sd	s4,8(sp)
    180008f2:	e056                	sd	s5,0(sp)
  size_t pos = 0;
    180008f4:	4701                	li	a4,0
  bool longarg = false;
    180008f6:	4901                	li	s2,0
  bool format = false;
    180008f8:	4801                	li	a6,0
        }
        default:
          break;
      }
    }
    else if(*s == '%')
    180008fa:	02500293          	li	t0,37
      switch(*s)
    180008fe:	4fd5                	li	t6,21
    18000900:	00002e97          	auipc	t4,0x2
    18000904:	a18e8e93          	addi	t4,t4,-1512 # 18002318 <udelay+0x92>
          for (long nn = num; nn /= 10; digits++)
    18000908:	4329                	li	t1,10
            if (++pos < n) out[pos-1] = '-';
    1800090a:	02d00493          	li	s1,45
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    1800090e:	4f25                	li	t5,9
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000910:	5e7d                	li	t3,-1
          if (++pos < n) out[pos-1] = 'x';
    18000912:	07800413          	li	s0,120
          if (++pos < n) out[pos-1] = '0';
    18000916:	03000393          	li	t2,48
    if(format)
    1800091a:	0e080b63          	beqz	a6,18000a10 <vnprintf+0x132>
      switch(*s)
    1800091e:	f9d7879b          	addiw	a5,a5,-99
    18000922:	0ff7f793          	andi	a5,a5,255
    18000926:	0cffef63          	bltu	t6,a5,18000a04 <vnprintf+0x126>
    1800092a:	078a                	slli	a5,a5,0x2
    1800092c:	97f6                	add	a5,a5,t4
    1800092e:	439c                	lw	a5,0(a5)
    18000930:	97f6                	add	a5,a5,t4
    18000932:	8782                	jr	a5
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000934:	00868793          	addi	a5,a3,8
    18000938:	14090f63          	beqz	s2,18000a96 <vnprintf+0x1b8>
    1800093c:	0006ba03          	ld	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000940:	4abd                	li	s5,15
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000942:	86be                	mv	a3,a5
    18000944:	a041                	j	180009c4 <vnprintf+0xe6>
          const char* s2 = va_arg(vl, const char*);
    18000946:	0006b883          	ld	a7,0(a3)
    1800094a:	06a1                	addi	a3,a3,8
          while (*s2) {
    1800094c:	0008c803          	lbu	a6,0(a7)
    18000950:	14080063          	beqz	a6,18000a90 <vnprintf+0x1b2>
    18000954:	87ba                	mv	a5,a4
            if (++pos < n)
    18000956:	0785                	addi	a5,a5,1
    18000958:	00b7f663          	bgeu	a5,a1,18000964 <vnprintf+0x86>
              out[pos-1] = *s2;
    1800095c:	00f50933          	add	s2,a0,a5
    18000960:	ff090fa3          	sb	a6,-1(s2)
          while (*s2) {
    18000964:	40e78833          	sub	a6,a5,a4
    18000968:	9846                	add	a6,a6,a7
    1800096a:	00084803          	lbu	a6,0(a6) # ffffffff80000000 <_sp+0xffffffff67fedea8>
    1800096e:	fe0814e3          	bnez	a6,18000956 <vnprintf+0x78>
  for( ; *s; s++)
    18000972:	0605                	addi	a2,a2,1
            if (++pos < n)
    18000974:	873e                	mv	a4,a5
  for( ; *s; s++)
    18000976:	00064783          	lbu	a5,0(a2)
          longarg = false;
    1800097a:	4901                	li	s2,0
  for( ; *s; s++)
    1800097c:	ffd9                	bnez	a5,1800091a <vnprintf+0x3c>
    1800097e:	0007079b          	sext.w	a5,a4
      format = true;
    else
      if (++pos < n) out[pos-1] = *s;
  }
  if (pos < n)
    18000982:	12b76363          	bltu	a4,a1,18000aa8 <vnprintf+0x1ca>
    out[pos] = 0;
  else if (n)
    18000986:	c589                	beqz	a1,18000990 <vnprintf+0xb2>
    out[n-1] = 0;
    18000988:	00b50733          	add	a4,a0,a1
    1800098c:	fe070fa3          	sb	zero,-1(a4)
  return pos;
}
    18000990:	7422                	ld	s0,40(sp)
    18000992:	7482                	ld	s1,32(sp)
    18000994:	6962                	ld	s2,24(sp)
    18000996:	69c2                	ld	s3,16(sp)
    18000998:	6a22                	ld	s4,8(sp)
    1800099a:	6a82                	ld	s5,0(sp)
    1800099c:	853e                	mv	a0,a5
    1800099e:	6145                	addi	sp,sp,48
    180009a0:	8082                	ret
          if (++pos < n) out[pos-1] = '0';
    180009a2:	00170793          	addi	a5,a4,1
    180009a6:	00b7f663          	bgeu	a5,a1,180009b2 <vnprintf+0xd4>
    180009aa:	00e50833          	add	a6,a0,a4
    180009ae:	00780023          	sb	t2,0(a6)
          if (++pos < n) out[pos-1] = 'x';
    180009b2:	0709                	addi	a4,a4,2
    180009b4:	00868813          	addi	a6,a3,8
    180009b8:	0eb76c63          	bltu	a4,a1,18000ab0 <vnprintf+0x1d2>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    180009bc:	0006ba03          	ld	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180009c0:	4abd                	li	s5,15
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    180009c2:	86c2                	mv	a3,a6
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180009c4:	8856                	mv	a6,s5
    180009c6:	87ba                	mv	a5,a4
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    180009c8:	0785                	addi	a5,a5,1
    180009ca:	02b7f463          	bgeu	a5,a1,180009f2 <vnprintf+0x114>
            int d = (num >> (4*i)) & 0xF;
    180009ce:	0028189b          	slliw	a7,a6,0x2
    180009d2:	411a58b3          	sra	a7,s4,a7
    180009d6:	00f8f893          	andi	a7,a7,15
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    180009da:	0ff8f993          	andi	s3,a7,255
    180009de:	05798913          	addi	s2,s3,87
    180009e2:	011f4463          	blt	t5,a7,180009ea <vnprintf+0x10c>
    180009e6:	03098913          	addi	s2,s3,48
    180009ea:	00f508b3          	add	a7,a0,a5
    180009ee:	ff288fa3          	sb	s2,-1(a7)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180009f2:	387d                	addiw	a6,a6,-1
    180009f4:	fdc81ae3          	bne	a6,t3,180009c8 <vnprintf+0xea>
    180009f8:	0705                	addi	a4,a4,1
    180009fa:	9756                	add	a4,a4,s5
          longarg = false;
    180009fc:	4901                	li	s2,0
          format = false;
    180009fe:	4801                	li	a6,0
    18000a00:	a011                	j	18000a04 <vnprintf+0x126>
          longarg = true;
    18000a02:	8942                	mv	s2,a6
  for( ; *s; s++)
    18000a04:	0605                	addi	a2,a2,1
    18000a06:	00064783          	lbu	a5,0(a2)
    18000a0a:	dbb5                	beqz	a5,1800097e <vnprintf+0xa0>
    if(format)
    18000a0c:	f00819e3          	bnez	a6,1800091e <vnprintf+0x40>
    else if(*s == '%')
    18000a10:	08578863          	beq	a5,t0,18000aa0 <vnprintf+0x1c2>
      if (++pos < n) out[pos-1] = *s;
    18000a14:	00170893          	addi	a7,a4,1
    18000a18:	08b8f663          	bgeu	a7,a1,18000aa4 <vnprintf+0x1c6>
    18000a1c:	972a                	add	a4,a4,a0
    18000a1e:	00f70023          	sb	a5,0(a4)
    18000a22:	8746                	mv	a4,a7
    18000a24:	b7c5                	j	18000a04 <vnprintf+0x126>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000a26:	00868993          	addi	s3,a3,8
    18000a2a:	08090763          	beqz	s2,18000ab8 <vnprintf+0x1da>
    18000a2e:	0006b803          	ld	a6,0(a3)
          if (num < 0) {
    18000a32:	08084763          	bltz	a6,18000ac0 <vnprintf+0x1e2>
          for (long nn = num; nn /= 10; digits++)
    18000a36:	026847b3          	div	a5,a6,t1
    18000a3a:	c3f9                	beqz	a5,18000b00 <vnprintf+0x222>
          long digits = 1;
    18000a3c:	4685                	li	a3,1
          for (long nn = num; nn /= 10; digits++)
    18000a3e:	0267c7b3          	div	a5,a5,t1
    18000a42:	0685                	addi	a3,a3,1
    18000a44:	ffed                	bnez	a5,18000a3e <vnprintf+0x160>
          for (int i = digits-1; i >= 0; i--) {
    18000a46:	fff6879b          	addiw	a5,a3,-1
    18000a4a:	88b6                	mv	a7,a3
    18000a4c:	0207c863          	bltz	a5,18000a7c <vnprintf+0x19e>
    18000a50:	00170a13          	addi	s4,a4,1
            if (pos + i + 1 < n) out[pos + i] = '0' + (num % 10);
    18000a54:	00fa06b3          	add	a3,s4,a5
    18000a58:	00b6fb63          	bgeu	a3,a1,18000a6e <vnprintf+0x190>
    18000a5c:	026866b3          	rem	a3,a6,t1
    18000a60:	00f70933          	add	s2,a4,a5
    18000a64:	992a                	add	s2,s2,a0
    18000a66:	0306869b          	addiw	a3,a3,48
    18000a6a:	00d90023          	sb	a3,0(s2)
            num /= 10;
    18000a6e:	17fd                	addi	a5,a5,-1
          for (int i = digits-1; i >= 0; i--) {
    18000a70:	02079693          	slli	a3,a5,0x20
            num /= 10;
    18000a74:	02684833          	div	a6,a6,t1
          for (int i = digits-1; i >= 0; i--) {
    18000a78:	fc06dee3          	bgez	a3,18000a54 <vnprintf+0x176>
          pos += digits;
    18000a7c:	9746                	add	a4,a4,a7
          break;
    18000a7e:	86ce                	mv	a3,s3
          longarg = false;
    18000a80:	4901                	li	s2,0
          format = false;
    18000a82:	4801                	li	a6,0
          break;
    18000a84:	b741                	j	18000a04 <vnprintf+0x126>
          if (++pos < n) out[pos-1] = (char)va_arg(vl,int);
    18000a86:	00170793          	addi	a5,a4,1
    18000a8a:	04b7e663          	bltu	a5,a1,18000ad6 <vnprintf+0x1f8>
    18000a8e:	873e                	mv	a4,a5
          longarg = false;
    18000a90:	4901                	li	s2,0
          format = false;
    18000a92:	4801                	li	a6,0
    18000a94:	bf85                	j	18000a04 <vnprintf+0x126>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000a96:	0006aa03          	lw	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000a9a:	4a9d                	li	s5,7
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000a9c:	86be                	mv	a3,a5
    18000a9e:	b71d                	j	180009c4 <vnprintf+0xe6>
      format = true;
    18000aa0:	4805                	li	a6,1
    18000aa2:	b78d                	j	18000a04 <vnprintf+0x126>
    18000aa4:	8746                	mv	a4,a7
    18000aa6:	bfb9                	j	18000a04 <vnprintf+0x126>
    out[pos] = 0;
    18000aa8:	972a                	add	a4,a4,a0
    18000aaa:	00070023          	sb	zero,0(a4)
    18000aae:	b5cd                	j	18000990 <vnprintf+0xb2>
          if (++pos < n) out[pos-1] = 'x';
    18000ab0:	97aa                	add	a5,a5,a0
    18000ab2:	00878023          	sb	s0,0(a5)
    18000ab6:	b719                	j	180009bc <vnprintf+0xde>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000ab8:	0006a803          	lw	a6,0(a3)
          if (num < 0) {
    18000abc:	f6085de3          	bgez	a6,18000a36 <vnprintf+0x158>
            if (++pos < n) out[pos-1] = '-';
    18000ac0:	00170793          	addi	a5,a4,1
            num = -num;
    18000ac4:	41000833          	neg	a6,a6
            if (++pos < n) out[pos-1] = '-';
    18000ac8:	02b7f163          	bgeu	a5,a1,18000aea <vnprintf+0x20c>
    18000acc:	972a                	add	a4,a4,a0
    18000ace:	00970023          	sb	s1,0(a4)
    18000ad2:	873e                	mv	a4,a5
    18000ad4:	b78d                	j	18000a36 <vnprintf+0x158>
          if (++pos < n) out[pos-1] = (char)va_arg(vl,int);
    18000ad6:	0006a803          	lw	a6,0(a3)
    18000ada:	972a                	add	a4,a4,a0
    18000adc:	06a1                	addi	a3,a3,8
    18000ade:	01070023          	sb	a6,0(a4)
          longarg = false;
    18000ae2:	4901                	li	s2,0
          if (++pos < n) out[pos-1] = (char)va_arg(vl,int);
    18000ae4:	873e                	mv	a4,a5
          format = false;
    18000ae6:	4801                	li	a6,0
    18000ae8:	bf31                	j	18000a04 <vnprintf+0x126>
    18000aea:	873e                	mv	a4,a5
    18000aec:	b7a9                	j	18000a36 <vnprintf+0x158>
  size_t pos = 0;
    18000aee:	4701                	li	a4,0
  for( ; *s; s++)
    18000af0:	4781                	li	a5,0
  if (pos < n)
    18000af2:	00b77a63          	bgeu	a4,a1,18000b06 <vnprintf+0x228>
    out[pos] = 0;
    18000af6:	972a                	add	a4,a4,a0
    18000af8:	00070023          	sb	zero,0(a4)
}
    18000afc:	853e                	mv	a0,a5
    18000afe:	8082                	ret
          for (long nn = num; nn /= 10; digits++)
    18000b00:	4885                	li	a7,1
          for (int i = digits-1; i >= 0; i--) {
    18000b02:	4781                	li	a5,0
    18000b04:	b7b1                	j	18000a50 <vnprintf+0x172>
  else if (n)
    18000b06:	d9fd                	beqz	a1,18000afc <vnprintf+0x21e>
    out[n-1] = 0;
    18000b08:	00b50733          	add	a4,a0,a1
    18000b0c:	fe070fa3          	sb	zero,-1(a4)
    18000b10:	b7f5                	j	18000afc <vnprintf+0x21e>

0000000018000b12 <vprintk>:

static void vprintk(const char* s, va_list vl)
{
    18000b12:	716d                	addi	sp,sp,-272
  char out[256]; 
  int res = vnprintf(out, sizeof(out), s, vl);
    18000b14:	862a                	mv	a2,a0
    18000b16:	86ae                	mv	a3,a1
    18000b18:	850a                	mv	a0,sp
    18000b1a:	10000593          	li	a1,256
{
    18000b1e:	e606                	sd	ra,264(sp)
  int res = vnprintf(out, sizeof(out), s, vl);
    18000b20:	dbfff0ef          	jal	ra,180008de <vnprintf>
  while (*s != '\0'){
    18000b24:	00014603          	lbu	a2,0(sp)
    18000b28:	ca0d                	beqz	a2,18000b5a <vprintk+0x48>
    18000b2a:	0000f797          	auipc	a5,0xf
    18000b2e:	4d67e783          	lwu	a5,1238(a5) # 18010000 <_data>
    18000b32:	00379713          	slli	a4,a5,0x3
    18000b36:	00002797          	auipc	a5,0x2
    18000b3a:	83a78793          	addi	a5,a5,-1990 # 18002370 <uart_base>
    18000b3e:	97ba                	add	a5,a5,a4
    18000b40:	638c                	ld	a1,0(a5)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000b42:	868a                	mv	a3,sp
    18000b44:	01458713          	addi	a4,a1,20
    _putc(*s++);
    18000b48:	0685                	addi	a3,a3,1
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000b4a:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000b4c:	0207f793          	andi	a5,a5,32
    18000b50:	dfed                	beqz	a5,18000b4a <vprintk+0x38>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000b52:	c190                	sw	a2,0(a1)
  while (*s != '\0'){
    18000b54:	0006c603          	lbu	a2,0(a3)
    18000b58:	fa65                	bnez	a2,18000b48 <vprintk+0x36>
  _puts(out);
}
    18000b5a:	60b2                	ld	ra,264(sp)
    18000b5c:	6151                	addi	sp,sp,272
    18000b5e:	8082                	ret

0000000018000b60 <printk>:

void printk(const char* s, ...)
{
    18000b60:	711d                	addi	sp,sp,-96
  va_list vl;
  va_start(vl, s);
    18000b62:	02810313          	addi	t1,sp,40
{
    18000b66:	f42e                	sd	a1,40(sp)

  vprintk(s, vl);
    18000b68:	859a                	mv	a1,t1
{
    18000b6a:	ec06                	sd	ra,24(sp)
    18000b6c:	f832                	sd	a2,48(sp)
    18000b6e:	fc36                	sd	a3,56(sp)
    18000b70:	e0ba                	sd	a4,64(sp)
    18000b72:	e4be                	sd	a5,72(sp)
    18000b74:	e8c2                	sd	a6,80(sp)
    18000b76:	ecc6                	sd	a7,88(sp)
  va_start(vl, s);
    18000b78:	e41a                	sd	t1,8(sp)
  vprintk(s, vl);
    18000b7a:	f99ff0ef          	jal	ra,18000b12 <vprintk>

  va_end(vl);
}
    18000b7e:	60e2                	ld	ra,24(sp)
    18000b80:	6125                	addi	sp,sp,96
    18000b82:	8082                	ret

0000000018000b84 <sys_memcpy>:
void * sys_memcpy(void *p_des,const void * p_src,unsigned long size)
{
	char *tmp = p_des;
	const char *s = p_src;

	while (size--)
    18000b84:	ca19                	beqz	a2,18000b9a <sys_memcpy+0x16>
    18000b86:	962a                	add	a2,a2,a0
	char *tmp = p_des;
    18000b88:	87aa                	mv	a5,a0
		*tmp++ = *s++;
    18000b8a:	0585                	addi	a1,a1,1
    18000b8c:	fff5c703          	lbu	a4,-1(a1)
    18000b90:	0785                	addi	a5,a5,1
    18000b92:	fee78fa3          	sb	a4,-1(a5)
	while (size--)
    18000b96:	fec79ae3          	bne	a5,a2,18000b8a <sys_memcpy+0x6>

	return p_des;
}
    18000b9a:	8082                	ret

0000000018000b9c <sys_memcmp>:
 int sys_memcmp(const void * cs,const void * ct,unsigned int count)
{
    18000b9c:	87aa                	mv	a5,a0
	const unsigned char *su1, *su2;
	int res = 0;

	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000b9e:	ca1d                	beqz	a2,18000bd4 <sys_memcmp+0x38>
		if ((res = *su1 - *su2) != 0)
    18000ba0:	00054503          	lbu	a0,0(a0)
    18000ba4:	0005c703          	lbu	a4,0(a1)
    18000ba8:	9d19                	subw	a0,a0,a4
    18000baa:	e505                	bnez	a0,18000bd2 <sys_memcmp+0x36>
    18000bac:	fff6069b          	addiw	a3,a2,-1
    18000bb0:	1682                	slli	a3,a3,0x20
    18000bb2:	9281                	srli	a3,a3,0x20
    18000bb4:	0685                	addi	a3,a3,1
    18000bb6:	96be                	add	a3,a3,a5
    18000bb8:	a039                	j	18000bc6 <sys_memcmp+0x2a>
    18000bba:	0007c703          	lbu	a4,0(a5)
    18000bbe:	0005c603          	lbu	a2,0(a1)
    18000bc2:	9f11                	subw	a4,a4,a2
    18000bc4:	e711                	bnez	a4,18000bd0 <sys_memcmp+0x34>
	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000bc6:	0785                	addi	a5,a5,1
    18000bc8:	0585                	addi	a1,a1,1
    18000bca:	fed798e3          	bne	a5,a3,18000bba <sys_memcmp+0x1e>
    18000bce:	8082                	ret
		if ((res = *su1 - *su2) != 0)
    18000bd0:	853a                	mv	a0,a4
			break;
	return res;
}
    18000bd2:	8082                	ret
	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000bd4:	4501                	li	a0,0
    18000bd6:	8082                	ret

0000000018000bd8 <_memcpy>:
void * _memcpy(void * dest,const void *src,unsigned int count)
{
	char *tmp = (char *) dest;
	const char *s = (char *) src;

	while (count--)
    18000bd8:	fff6069b          	addiw	a3,a2,-1
    18000bdc:	ce11                	beqz	a2,18000bf8 <_memcpy+0x20>
    18000bde:	1682                	slli	a3,a3,0x20
    18000be0:	9281                	srli	a3,a3,0x20
    18000be2:	0685                	addi	a3,a3,1
    18000be4:	96aa                	add	a3,a3,a0
	char *tmp = (char *) dest;
    18000be6:	87aa                	mv	a5,a0
		*tmp++ = *s++;
    18000be8:	0585                	addi	a1,a1,1
    18000bea:	fff5c703          	lbu	a4,-1(a1)
    18000bee:	0785                	addi	a5,a5,1
    18000bf0:	fee78fa3          	sb	a4,-1(a5)
	while (count--)
    18000bf4:	fef69ae3          	bne	a3,a5,18000be8 <_memcpy+0x10>
	return dest;
}
    18000bf8:	8082                	ret

0000000018000bfa <sys_memcpy_32>:
RETURN VALUE:
===========================================================================*/
void sys_memcpy_32(void *p_des,const void * p_src,unsigned long size)
{
	unsigned long i;
	for (i=0;i<size;i++)
    18000bfa:	ca11                	beqz	a2,18000c0e <sys_memcpy_32+0x14>
    18000bfc:	060e                	slli	a2,a2,0x3
    18000bfe:	962e                	add	a2,a2,a1
		*((unsigned long*)p_des+i) = *((unsigned long*)p_src+i);
    18000c00:	619c                	ld	a5,0(a1)
    18000c02:	0521                	addi	a0,a0,8
    18000c04:	05a1                	addi	a1,a1,8
    18000c06:	fef53c23          	sd	a5,-8(a0)
	for (i=0;i<size;i++)
    18000c0a:	fec59be3          	bne	a1,a2,18000c00 <sys_memcpy_32+0x6>
}
    18000c0e:	8082                	ret

0000000018000c10 <sys_memset>:
RETURN VALUE:
===========================================================================*/
void sys_memset(void *p_des,unsigned char c,unsigned long size)
{
	unsigned long i;
	for (i=0;i<size;i++)
    18000c10:	c619                	beqz	a2,18000c1e <sys_memset+0xe>
    18000c12:	962a                	add	a2,a2,a0
		*((char*)p_des+i) = c;
    18000c14:	00b50023          	sb	a1,0(a0)
    18000c18:	0505                	addi	a0,a0,1
	for (i=0;i<size;i++)
    18000c1a:	fec51de3          	bne	a0,a2,18000c14 <sys_memset+0x4>
}
    18000c1e:	8082                	ret

0000000018000c20 <sys_memset32>:
RETURN VALUE:
===========================================================================*/
void sys_memset32(void *p_des,int c,unsigned long size)
{
	unsigned long i;
	for(i=0; i< size; i++)
    18000c20:	00361793          	slli	a5,a2,0x3
    18000c24:	97aa                	add	a5,a5,a0
    18000c26:	c609                	beqz	a2,18000c30 <sys_memset32+0x10>
		((unsigned long*)p_des)[i] = c;
    18000c28:	e10c                	sd	a1,0(a0)
    18000c2a:	0521                	addi	a0,a0,8
	for(i=0; i< size; i++)
    18000c2c:	fef51ee3          	bne	a0,a5,18000c28 <sys_memset32+0x8>
}
    18000c30:	8082                	ret

0000000018000c32 <spi_register>:
#define SPI_CONTROLLER_NUM	1
struct spi_operation *operations[SPI_CONTROLLER_NUM];

int spi_register(unsigned int bus, struct spi_operation *operation)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000c32:	e511                	bnez	a0,18000c3e <spi_register+0xc>
		return -1;

	operations[bus] = operation;
    18000c34:	0000f797          	auipc	a5,0xf
    18000c38:	40b7b623          	sd	a1,1036(a5) # 18010040 <operations>

	return 0;
    18000c3c:	8082                	ret
		return -1;
    18000c3e:	557d                	li	a0,-1
}
    18000c40:	8082                	ret

0000000018000c42 <spi_unregister>:

int spi_unregister(unsigned int bus)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000c42:	e511                	bnez	a0,18000c4e <spi_unregister+0xc>
		return -1;

	operations[bus] = 0;
    18000c44:	0000f797          	auipc	a5,0xf
    18000c48:	3e07be23          	sd	zero,1020(a5) # 18010040 <operations>

	return 0;
    18000c4c:	8082                	ret
		return -1;
    18000c4e:	557d                	li	a0,-1
}
    18000c50:	8082                	ret

0000000018000c52 <spi_setup_slave>:

struct spi_slave *spi_setup_slave(unsigned int bus, unsigned int cs,
		unsigned int max_hz, unsigned int mode, unsigned int bus_width)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000c52:	e919                	bnez	a0,18000c68 <spi_setup_slave+0x16>
		return NULL;

	if(operations[bus]->setup_slave)
    18000c54:	0000f797          	auipc	a5,0xf
    18000c58:	3ec78793          	addi	a5,a5,1004 # 18010040 <operations>
    18000c5c:	639c                	ld	a5,0(a5)
    18000c5e:	0007b303          	ld	t1,0(a5)
    18000c62:	00030363          	beqz	t1,18000c68 <spi_setup_slave+0x16>
	{
		return operations[bus]->setup_slave(bus,cs,max_hz,mode,bus_width);
    18000c66:	8302                	jr	t1
	}
	return NULL;
}
    18000c68:	4501                	li	a0,0
    18000c6a:	8082                	ret

0000000018000c6c <spi_xfer>:
		void *din, unsigned long flags,int bit_mode)
{
	unsigned int bus = slave->bus;
	int ret = -1;

	if(bus> SPI_CONTROLLER_NUM-1)
    18000c6c:	00052803          	lw	a6,0(a0)
    18000c70:	00081d63          	bnez	a6,18000c8a <spi_xfer+0x1e>
		return -1;

	if(operations[bus]->spi_xfer)
    18000c74:	0000f817          	auipc	a6,0xf
    18000c78:	3cc80813          	addi	a6,a6,972 # 18010040 <operations>
    18000c7c:	00083803          	ld	a6,0(a6)
    18000c80:	00883303          	ld	t1,8(a6)
    18000c84:	00030363          	beqz	t1,18000c8a <spi_xfer+0x1e>
		ret = operations[bus]->spi_xfer(slave, bitlen, dout, din, flags, bit_mode);
    18000c88:	8302                	jr	t1

	return ret;
}
    18000c8a:	557d                	li	a0,-1
    18000c8c:	8082                	ret

0000000018000c8e <spi_flash_probe_nor>:
	struct spi_flash_params *params;
	struct spi_flash *flash;
	u32 id = 0;
	static int i = 0;

	id = ((idcode[2] << 16) | (idcode[1] << 8) | idcode[0]);
    18000c8e:	0025c703          	lbu	a4,2(a1)
    18000c92:	0015c683          	lbu	a3,1(a1)
    18000c96:	0005c603          	lbu	a2,0(a1)
    18000c9a:	0107179b          	slliw	a5,a4,0x10
    18000c9e:	0086969b          	slliw	a3,a3,0x8
    18000ca2:	8fd5                	or	a5,a5,a3
    18000ca4:	8fd1                	or	a5,a5,a2
    18000ca6:	0007871b          	sext.w	a4,a5
    if(id == 0x0)
    18000caa:	c7f9                	beqz	a5,18000d78 <spi_flash_probe_nor+0xea>
    {
        return NULL;
    }
	params = spi_flash_table;
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000cac:	0000f797          	auipc	a5,0xf
    18000cb0:	3407ac23          	sw	zero,856(a5) # 18010004 <i.1823>
	{
		if ((spi_flash_table[i].id & 0xFFFFFF) == id)
    18000cb4:	002007b7          	lui	a5,0x200
    18000cb8:	20178793          	addi	a5,a5,513 # 200201 <__stack_size+0x1ffa01>
    18000cbc:	0cf70063          	beq	a4,a5,18000d7c <spi_flash_probe_nor+0xee>
    18000cc0:	001967b7          	lui	a5,0x196
    18000cc4:	0c878793          	addi	a5,a5,200 # 1960c8 <__stack_size+0x1958c8>
    18000cc8:	08f70d63          	beq	a4,a5,18000d62 <spi_flash_probe_nor+0xd4>
    18000ccc:	4789                	li	a5,2
    18000cce:	0000f717          	auipc	a4,0xf
    18000cd2:	32f72b23          	sw	a5,822(a4) # 18010004 <i.1823>
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000cd6:	4609                	li	a2,2
		if ((spi_flash_table[i].id & 0xFFFFFF) == id)
    18000cd8:	4681                	li	a3,0
		{
			break;
		}
	}

	flash = &g_spi_flash[spi->bus];
    18000cda:	00056703          	lwu	a4,0(a0)
    18000cde:	0000f797          	auipc	a5,0xf
    18000ce2:	32a78793          	addi	a5,a5,810 # 18010008 <g_spi_flash>
    18000ce6:	00371513          	slli	a0,a4,0x3
    18000cea:	8d19                	sub	a0,a0,a4
    18000cec:	050e                	slli	a0,a0,0x3
    18000cee:	953e                	add	a0,a0,a5
	{
		//uart_printf("SF: Failed to allocate memory\r\n");
		return NULL;
	}

	flash->name = spi_flash_table[i].name;
    18000cf0:	e514                	sd	a3,8(a0)
	{
		/* Assuming power-of-two page size initially. */
		flash->write = spi_flash_cmd_write_mode;
		flash->erase = spi_flash_erase_mode;
		flash->read = spi_flash_read_mode;
		flash->page_size = 1 << spi_flash_table[i].l2_page_size;
    18000cf2:	00161693          	slli	a3,a2,0x1
    18000cf6:	96b2                	add	a3,a3,a2
    18000cf8:	00369613          	slli	a2,a3,0x3
    18000cfc:	00001697          	auipc	a3,0x1
    18000d00:	6b468693          	addi	a3,a3,1716 # 180023b0 <spi_flash_table>
    18000d04:	96b2                	add	a3,a3,a2
    18000d06:	00c6c883          	lbu	a7,12(a3)
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000d0a:	00e6d583          	lhu	a1,14(a3)
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000d0e:	0106d603          	lhu	a2,16(a3)
		flash->size = flash->page_size * spi_flash_table[i].pages_per_sector
						* spi_flash_table[i].sectors_per_block
						* spi_flash_table[i].nr_blocks;
    18000d12:	0126d803          	lhu	a6,18(a3)
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000d16:	011595bb          	sllw	a1,a1,a7
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000d1a:	02b6063b          	mulw	a2,a2,a1
		flash->write = spi_flash_cmd_write_mode;
    18000d1e:	00371693          	slli	a3,a4,0x3
    18000d22:	40e68733          	sub	a4,a3,a4
    18000d26:	070e                	slli	a4,a4,0x3
    18000d28:	97ba                	add	a5,a5,a4
		flash->page_size = 1 << spi_flash_table[i].l2_page_size;
    18000d2a:	4685                	li	a3,1
    18000d2c:	011696bb          	sllw	a3,a3,a7
    18000d30:	cbd4                	sw	a3,20(a5)
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000d32:	cf8c                	sw	a1,24(a5)
						* spi_flash_table[i].nr_blocks;
    18000d34:	02c8073b          	mulw	a4,a6,a2
		flash->write = spi_flash_cmd_write_mode;
    18000d38:	00001817          	auipc	a6,0x1
    18000d3c:	a7680813          	addi	a6,a6,-1418 # 180017ae <spi_flash_cmd_write_mode>
    18000d40:	0307b423          	sd	a6,40(a5)
		flash->erase = spi_flash_erase_mode;
    18000d44:	00001817          	auipc	a6,0x1
    18000d48:	a3680813          	addi	a6,a6,-1482 # 1800177a <spi_flash_erase_mode>
    18000d4c:	0307b823          	sd	a6,48(a5)
		flash->read = spi_flash_read_mode;
    18000d50:	00001817          	auipc	a6,0x1
    18000d54:	c6880813          	addi	a6,a6,-920 # 180019b8 <spi_flash_read_mode>
    18000d58:	0307b023          	sd	a6,32(a5)
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000d5c:	cfd0                	sw	a2,28(a5)
		flash->size = flash->page_size * spi_flash_table[i].pages_per_sector
    18000d5e:	cb98                	sw	a4,16(a5)
    18000d60:	8082                	ret
    18000d62:	4785                	li	a5,1
    18000d64:	0000f717          	auipc	a4,0xf
    18000d68:	2af72023          	sw	a5,672(a4) # 18010004 <i.1823>
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000d6c:	4605                	li	a2,1
		if ((spi_flash_table[i].id & 0xFFFFFF) == id)
    18000d6e:	00001697          	auipc	a3,0x1
    18000d72:	67268693          	addi	a3,a3,1650 # 180023e0 <spi_flash_table+0x30>
    18000d76:	b795                	j	18000cda <spi_flash_probe_nor+0x4c>
        return NULL;
    18000d78:	4501                	li	a0,0
	}

	//uart_printf("spi probe complete\r\n");

	return flash;
}
    18000d7a:	8082                	ret
	flash = &g_spi_flash[spi->bus];
    18000d7c:	00056703          	lwu	a4,0(a0)
    18000d80:	0000f797          	auipc	a5,0xf
    18000d84:	28878793          	addi	a5,a5,648 # 18010008 <g_spi_flash>
	flash->name = spi_flash_table[i].name;
    18000d88:	00001697          	auipc	a3,0x1
    18000d8c:	66868693          	addi	a3,a3,1640 # 180023f0 <spi_flash_table+0x40>
	flash = &g_spi_flash[spi->bus];
    18000d90:	00371513          	slli	a0,a4,0x3
    18000d94:	8d19                	sub	a0,a0,a4
    18000d96:	050e                	slli	a0,a0,0x3
    18000d98:	953e                	add	a0,a0,a5
	flash->name = spi_flash_table[i].name;
    18000d9a:	e514                	sd	a3,8(a0)
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000d9c:	4601                	li	a2,0
    18000d9e:	bf91                	j	18000cf2 <spi_flash_probe_nor+0x64>

0000000018000da0 <spi_flash_probe>:

static struct spi_flash aic_flash;

struct spi_flash *spi_flash_probe(unsigned int bus, unsigned int cs,
		unsigned int max_hz, unsigned int mode, unsigned int bus_width)
{
    18000da0:	1101                	addi	sp,sp,-32
    18000da2:	ec06                	sd	ra,24(sp)
    18000da4:	e822                	sd	s0,16(sp)
	struct spi_slave *spi;
	struct spi_flash *flash = &aic_flash;
	int ret = 0;
	u8 idcode[IDCODE_LEN];

	spi = spi_setup_slave(bus, cs, max_hz, mode, bus_width);
    18000da6:	eadff0ef          	jal	ra,18000c52 <spi_setup_slave>
	if (!spi) {
    18000daa:	c121                	beqz	a0,18000dea <spi_flash_probe+0x4a>
	buf[0] = cmd;
    18000dac:	f9f00813          	li	a6,-97
	unsigned char buf[4] = {0};// = {(u8)cmd, 0x00, 0x00, 0x00};
    18000db0:	c402                	sw	zero,8(sp)
	ret1 = spi_xfer(spi, 1*8, &buf[0], NULL, SPI_XFER_BEGIN, 8);
    18000db2:	47a1                	li	a5,8
    18000db4:	4705                	li	a4,1
    18000db6:	4681                	li	a3,0
    18000db8:	0030                	addi	a2,sp,8
    18000dba:	45a1                	li	a1,8
    18000dbc:	842a                	mv	s0,a0
	buf[0] = cmd;
    18000dbe:	01010423          	sb	a6,8(sp)
	ret1 = spi_xfer(spi, 1*8, &buf[0], NULL, SPI_XFER_BEGIN, 8);
    18000dc2:	eabff0ef          	jal	ra,18000c6c <spi_xfer>
	ret2 = spi_xfer(spi, len*8, NULL, response, SPI_XFER_END, 8);
    18000dc6:	45e1                	li	a1,24
    18000dc8:	47a1                	li	a5,8
    18000dca:	4709                	li	a4,2
    18000dcc:	868a                	mv	a3,sp
    18000dce:	4601                	li	a2,0
    18000dd0:	8522                	mv	a0,s0
    18000dd2:	e9bff0ef          	jal	ra,18000c6c <spi_xfer>
		goto err_read_id;
	}

	//print_id(idcode, sizeof(idcode));

	flash = spi_flash_probe_nor(spi,idcode);
    18000dd6:	858a                	mv	a1,sp
    18000dd8:	8522                	mv	a0,s0
    18000dda:	eb5ff0ef          	jal	ra,18000c8e <spi_flash_probe_nor>
	if (!flash)
    18000dde:	c111                	beqz	a0,18000de2 <spi_flash_probe+0x42>
	{
		goto err_manufacturer_probe;
	}

	flash->spi = spi;
    18000de0:	e100                	sd	s0,0(a0)

err_manufacturer_probe:
err_read_id:

	return NULL;
}
    18000de2:	60e2                	ld	ra,24(sp)
    18000de4:	6442                	ld	s0,16(sp)
    18000de6:	6105                	addi	sp,sp,32
    18000de8:	8082                	ret
    18000dea:	60e2                	ld	ra,24(sp)
    18000dec:	6442                	ld	s0,16(sp)
		return NULL;
    18000dee:	4501                	li	a0,0
}
    18000df0:	6105                	addi	sp,sp,32
    18000df2:	8082                	ret

0000000018000df4 <cadence_spi_write_speed>:
#define CQSPI_INDIRECT_WRITE	3
#define CADENCE_QSPI_MAX_HZ		QSPI_CLK
#define CONFIG_CQSPI_REF_CLK	QSPI_CLK
#define CONFIG_CQSPI_DECODER	0
static int cadence_spi_write_speed(unsigned int hz)
{
    18000df4:	1101                	addi	sp,sp,-32
    18000df6:	e04a                	sd	s2,0(sp)
	struct cadence_spi_platdata *plat = &cadence_plat;
	struct cadence_spi_priv *priv = &spi_priv;

	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000df8:	0000f917          	auipc	s2,0xf
    18000dfc:	26890913          	addi	s2,s2,616 # 18010060 <spi_priv>
{
    18000e00:	e426                	sd	s1,8(sp)
    18000e02:	84aa                	mv	s1,a0
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000e04:	00093503          	ld	a0,0(s2)
{
    18000e08:	e822                	sd	s0,16(sp)
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000e0a:	02faf437          	lui	s0,0x2faf
    18000e0e:	8626                	mv	a2,s1
    18000e10:	08040593          	addi	a1,s0,128 # 2faf080 <__stack_size+0x2fae880>
{
    18000e14:	ec06                	sd	ra,24(sp)
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000e16:	51b000ef          	jal	ra,18001b30 <cadence_qspi_apb_config_baudrate_div>
					     CONFIG_CQSPI_REF_CLK, hz);

	/* Reconfigure delay timing if speed is changed. */
	cadence_qspi_apb_delay(priv->regbase, CONFIG_CQSPI_REF_CLK, hz,
    18000e1a:	0000f697          	auipc	a3,0xf
    18000e1e:	29e68693          	addi	a3,a3,670 # 180100b8 <cadence_plat>
    18000e22:	00093503          	ld	a0,0(s2)
    18000e26:	0306a803          	lw	a6,48(a3)
    18000e2a:	56dc                	lw	a5,44(a3)
    18000e2c:	5698                	lw	a4,40(a3)
    18000e2e:	52d4                	lw	a3,36(a3)
    18000e30:	8626                	mv	a2,s1
    18000e32:	08040593          	addi	a1,s0,128
    18000e36:	5c5000ef          	jal	ra,18001bfa <cadence_qspi_apb_delay>
			       plat->tshsl_ns, plat->tsd2d_ns,
			       plat->tchsh_ns, plat->tslch_ns);

	return 0;
}
    18000e3a:	60e2                	ld	ra,24(sp)
    18000e3c:	6442                	ld	s0,16(sp)
    18000e3e:	64a2                	ld	s1,8(sp)
    18000e40:	6902                	ld	s2,0(sp)
    18000e42:	4501                	li	a0,0
    18000e44:	6105                	addi	sp,sp,32
    18000e46:	8082                	ret

0000000018000e48 <cadence_spi4x_setup_slave>:
	return 0;
}

struct spi_slave *cadence_spi4x_setup_slave(unsigned int bus, unsigned int cs,
		unsigned int max_hz, u32 mode, u32 fifo_width)
{
    18000e48:	7159                	addi	sp,sp,-112
	u32 clk_pol;
	u32 clk_pha;

	spi4slave = &vic_spi_slave;
	
	spi4slave->base = (void *)QSPI_BASE_ADDR;
    18000e4a:	118608b7          	lui	a7,0x11860
	clk_pol = (mode & SPI_CPOL) ? 1 : 0;
	clk_pha = (mode & SPI_CPHA) ? 1 : 0;


	plat->regbase = (void *)QSPI_BASE_ADDR;
	plat->ahbbase = (void *)QSPI_BASE_AHB_ADDR;
    18000e4e:	20000e37          	lui	t3,0x20000
{
    18000e52:	fc56                	sd	s5,56(sp)
    18000e54:	8aba                	mv	s5,a4
	spi4slave->base = (void *)QSPI_BASE_ADDR;
    18000e56:	0000f717          	auipc	a4,0xf
    18000e5a:	21172123          	sw	a7,514(a4) # 18010058 <vic_spi_slave+0x10>
	plat->regbase = (void *)QSPI_BASE_ADDR;
    18000e5e:	0000f717          	auipc	a4,0xf
    18000e62:	27173123          	sd	a7,610(a4) # 180100c0 <cadence_plat+0x8>
	plat->ahbbase = (void *)QSPI_BASE_AHB_ADDR;
    18000e66:	0000f717          	auipc	a4,0xf
    18000e6a:	27c73123          	sd	t3,610(a4) # 180100c8 <cadence_plat+0x10>
	plat->max_hz = CADENCE_QSPI_MAX_HZ;


/****default set, may change******/
	plat->tshsl_ns =  200;
	plat->tsd2d_ns =  255;
    18000e6e:	4785                	li	a5,1
	plat->tchsh_ns =  2;
	plat->tslch_ns =  20;
	plat->sram_size = 256;

	plat->block_size = 16;
    18000e70:	4865                	li	a6,25
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000e72:	02faf737          	lui	a4,0x2faf
	plat->tsd2d_ns =  255;
    18000e76:	02179313          	slli	t1,a5,0x21
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000e7a:	08070713          	addi	a4,a4,128 # 2faf080 <__stack_size+0x2fae880>
	plat->tslch_ns =  20;
    18000e7e:	17a2                	slli	a5,a5,0x28
	plat->block_size = 16;
    18000e80:	180e                	slli	a6,a6,0x23
	plat->tslch_ns =  20;
    18000e82:	07d1                	addi	a5,a5,20
	plat->tsd2d_ns =  255;
    18000e84:	0ff30313          	addi	t1,t1,255
	plat->block_size = 16;
    18000e88:	0841                	addi	a6,a6,16
{
    18000e8a:	eca6                	sd	s1,88(sp)
    18000e8c:	f85a                	sd	s6,48(sp)
    18000e8e:	84b6                	mv	s1,a3
    18000e90:	8b2a                	mv	s6,a0
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000e92:	0000f697          	auipc	a3,0xf
    18000e96:	22e6a323          	sw	a4,550(a3) # 180100b8 <cadence_plat>

	priv->regbase = plat->regbase;
	priv->ahbbase = plat->ahbbase;

	/* Disable QSPI */
	cadence_qspi_apb_controller_disable(priv->regbase);
    18000e9a:	11860537          	lui	a0,0x11860
	plat->page_size = 256;
    18000e9e:	10000713          	li	a4,256
    18000ea2:	0000f697          	auipc	a3,0xf
    18000ea6:	22e6a923          	sw	a4,562(a3) # 180100d4 <cadence_plat+0x1c>
{
    18000eaa:	f486                	sd	ra,104(sp)
	plat->tslch_ns =  20;
    18000eac:	0000f717          	auipc	a4,0xf
    18000eb0:	22f73e23          	sd	a5,572(a4) # 180100e8 <cadence_plat+0x30>
	plat->block_size = 16;
    18000eb4:	0000f717          	auipc	a4,0xf
    18000eb8:	23073223          	sd	a6,548(a4) # 180100d8 <cadence_plat+0x20>
	plat->tsd2d_ns =  255;
    18000ebc:	0000f717          	auipc	a4,0xf
    18000ec0:	22673223          	sd	t1,548(a4) # 180100e0 <cadence_plat+0x28>
	priv->regbase = plat->regbase;
    18000ec4:	0000f797          	auipc	a5,0xf
    18000ec8:	1917be23          	sd	a7,412(a5) # 18010060 <spi_priv>
	priv->ahbbase = plat->ahbbase;
    18000ecc:	0000f797          	auipc	a5,0xf
    18000ed0:	19c7be23          	sd	t3,412(a5) # 18010068 <spi_priv+0x8>
{
    18000ed4:	f0a2                	sd	s0,96(sp)
    18000ed6:	e8ca                	sd	s2,80(sp)
    18000ed8:	e4ce                	sd	s3,72(sp)
    18000eda:	e0d2                	sd	s4,64(sp)
    18000edc:	f45e                	sd	s7,40(sp)
    18000ede:	8a2e                	mv	s4,a1
    18000ee0:	8bb2                	mv	s7,a2
    18000ee2:	f062                	sd	s8,32(sp)
    18000ee4:	ec66                	sd	s9,24(sp)
    18000ee6:	e86a                	sd	s10,16(sp)
	priv->regbase = plat->regbase;
    18000ee8:	0000f917          	auipc	s2,0xf
    18000eec:	17890913          	addi	s2,s2,376 # 18010060 <spi_priv>
	cadence_qspi_apb_controller_disable(priv->regbase);
    18000ef0:	3fd000ef          	jal	ra,18001aec <cadence_qspi_apb_controller_disable>

	/* Set SPI mode */
	cadence_qspi_apb_set_clk_mode(priv->regbase, clk_pol, clk_pha);
    18000ef4:	00093503          	ld	a0,0(s2)
	clk_pol = (mode & SPI_CPOL) ? 1 : 0;
    18000ef8:	0014d59b          	srliw	a1,s1,0x1
	cadence_qspi_apb_set_clk_mode(priv->regbase, clk_pol, clk_pha);
    18000efc:	0014f613          	andi	a2,s1,1
    18000f00:	8985                	andi	a1,a1,1
	plat->regbase = (void *)QSPI_BASE_ADDR;
    18000f02:	0000f417          	auipc	s0,0xf
    18000f06:	1b640413          	addi	s0,s0,438 # 180100b8 <cadence_plat>
	cadence_qspi_apb_set_clk_mode(priv->regbase, clk_pol, clk_pha);
    18000f0a:	47b000ef          	jal	ra,18001b84 <cadence_qspi_apb_set_clk_mode>
		cadence_qspi_apb_controller_init(plat);
		priv->qspi_is_init = 1;
	}
#endif

	cadence_qspi_apb_controller_init(plat);
    18000f0e:	8522                	mv	a0,s0
    18000f10:	511000ef          	jal	ra,18001c20 <cadence_qspi_apb_controller_init>

	if (max_hz > plat->max_hz)
    18000f14:	00042983          	lw	s3,0(s0)
    18000f18:	013bf363          	bgeu	s7,s3,18000f1e <cadence_spi4x_setup_slave+0xd6>
    18000f1c:	89de                	mv	s3,s7

	/*
	 * Calibration required for different current SCLK speed, requested
	 * SCLK speed or chip select
	 */
	if (priv->previous_hz != max_hz ||
    18000f1e:	04492783          	lw	a5,68(s2)
    18000f22:	01379663          	bne	a5,s3,18000f2e <cadence_spi4x_setup_slave+0xe6>
    18000f26:	03c92783          	lw	a5,60(s2)
    18000f2a:	13378363          	beq	a5,s3,18001050 <cadence_spi4x_setup_slave+0x208>
	void * base = priv->regbase;
    18000f2e:	00093483          	ld	s1,0(s2)
	cadence_spi_write_speed(500000);
    18000f32:	0007a537          	lui	a0,0x7a
	u8 opcode_rdid = 0x9F;
    18000f36:	f9f00793          	li	a5,-97
	cadence_spi_write_speed(500000);
    18000f3a:	12050513          	addi	a0,a0,288 # 7a120 <__stack_size+0x79920>
	u8 opcode_rdid = 0x9F;
    18000f3e:	00f103a3          	sb	a5,7(sp)
	unsigned int idcode = 0, temp = 0;
    18000f42:	c402                	sw	zero,8(sp)
    18000f44:	c602                	sw	zero,12(sp)
	cadence_spi_write_speed(500000);
    18000f46:	eafff0ef          	jal	ra,18000df4 <cadence_spi_write_speed>
	cadence_qspi_apb_readdata_capture(base, 1, 0);
    18000f4a:	4601                	li	a2,0
    18000f4c:	4585                	li	a1,1
    18000f4e:	8526                	mv	a0,s1
    18000f50:	3a9000ef          	jal	ra,18001af8 <cadence_qspi_apb_readdata_capture>
	cadence_qspi_apb_controller_enable(base);
    18000f54:	8526                	mv	a0,s1
    18000f56:	389000ef          	jal	ra,18001ade <cadence_qspi_apb_controller_enable>
	err = cadence_qspi_apb_command_read(base, 1, &opcode_rdid,
    18000f5a:	0038                	addi	a4,sp,8
    18000f5c:	468d                	li	a3,3
    18000f5e:	00710613          	addi	a2,sp,7
    18000f62:	4585                	li	a1,1
    18000f64:	8526                	mv	a0,s1
    18000f66:	52b000ef          	jal	ra,18001c90 <cadence_qspi_apb_command_read>
    18000f6a:	842a                	mv	s0,a0
	if (err) {
    18000f6c:	c105                	beqz	a0,18000f8c <cadence_spi4x_setup_slave+0x144>
	    priv->qspi_calibrated_hz != max_hz ||
	    priv->qspi_calibrated_cs != cs) {
		err = spi_calibration(max_hz, cs);
		if (err)
			return NULL;
    18000f6e:	4501                	li	a0,0
	spi4slave->slave.bus_width= fifo_width;

	return &spi4slave->slave;

	
}
    18000f70:	70a6                	ld	ra,104(sp)
    18000f72:	7406                	ld	s0,96(sp)
    18000f74:	64e6                	ld	s1,88(sp)
    18000f76:	6946                	ld	s2,80(sp)
    18000f78:	69a6                	ld	s3,72(sp)
    18000f7a:	6a06                	ld	s4,64(sp)
    18000f7c:	7ae2                	ld	s5,56(sp)
    18000f7e:	7b42                	ld	s6,48(sp)
    18000f80:	7ba2                	ld	s7,40(sp)
    18000f82:	7c02                	ld	s8,32(sp)
    18000f84:	6ce2                	ld	s9,24(sp)
    18000f86:	6d42                	ld	s10,16(sp)
    18000f88:	6165                	addi	sp,sp,112
    18000f8a:	8082                	ret
	cadence_spi_write_speed(hz);
    18000f8c:	854e                	mv	a0,s3
    18000f8e:	e67ff0ef          	jal	ra,18000df4 <cadence_spi_write_speed>
	int err = 0, i, range_lo = -1, range_hi = -1;
    18000f92:	5bfd                	li	s7,-1
    18000f94:	5c7d                	li	s8,-1
		if (range_lo == -1 && temp == idcode) {
    18000f96:	5d7d                	li	s10,-1
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000f98:	4cc1                	li	s9,16
    18000f9a:	a039                	j	18000fa8 <cadence_spi4x_setup_slave+0x160>
		if (range_lo != -1 && temp != idcode) {
    18000f9c:	8ba2                	mv	s7,s0
    18000f9e:	0af71e63          	bne	a4,a5,1800105a <cadence_spi4x_setup_slave+0x212>
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000fa2:	2405                	addiw	s0,s0,1
    18000fa4:	05940163          	beq	s0,s9,18000fe6 <cadence_spi4x_setup_slave+0x19e>
		cadence_qspi_apb_controller_disable(base);
    18000fa8:	8526                	mv	a0,s1
    18000faa:	343000ef          	jal	ra,18001aec <cadence_qspi_apb_controller_disable>
		cadence_qspi_apb_readdata_capture(base, 1, i);
    18000fae:	0004061b          	sext.w	a2,s0
    18000fb2:	4585                	li	a1,1
    18000fb4:	8526                	mv	a0,s1
    18000fb6:	343000ef          	jal	ra,18001af8 <cadence_qspi_apb_readdata_capture>
		cadence_qspi_apb_controller_enable(base);
    18000fba:	8526                	mv	a0,s1
    18000fbc:	323000ef          	jal	ra,18001ade <cadence_qspi_apb_controller_enable>
		err = cadence_qspi_apb_command_read(base, 1, &opcode_rdid,
    18000fc0:	0078                	addi	a4,sp,12
    18000fc2:	468d                	li	a3,3
    18000fc4:	00710613          	addi	a2,sp,7
    18000fc8:	4585                	li	a1,1
    18000fca:	8526                	mv	a0,s1
    18000fcc:	4c5000ef          	jal	ra,18001c90 <cadence_qspi_apb_command_read>
		if (err) {
    18000fd0:	fd59                	bnez	a0,18000f6e <cadence_spi4x_setup_slave+0x126>
    18000fd2:	47b2                	lw	a5,12(sp)
    18000fd4:	4722                	lw	a4,8(sp)
		if (range_lo == -1 && temp == idcode) {
    18000fd6:	fdac13e3          	bne	s8,s10,18000f9c <cadence_spi4x_setup_slave+0x154>
    18000fda:	06f70963          	beq	a4,a5,1800104c <cadence_spi4x_setup_slave+0x204>
    18000fde:	8ba2                	mv	s7,s0
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000fe0:	2405                	addiw	s0,s0,1
    18000fe2:	fd9413e3          	bne	s0,s9,18000fa8 <cadence_spi4x_setup_slave+0x160>
	if (range_lo == -1) {
    18000fe6:	57fd                	li	a5,-1
    18000fe8:	02fc0963          	beq	s8,a5,1800101a <cadence_spi4x_setup_slave+0x1d2>
	cadence_qspi_apb_controller_disable(base);
    18000fec:	8526                	mv	a0,s1
    18000fee:	2ff000ef          	jal	ra,18001aec <cadence_qspi_apb_controller_disable>
	cadence_qspi_apb_readdata_capture(base, 1, (range_hi + range_lo) / 2);
    18000ff2:	018b8bbb          	addw	s7,s7,s8
    18000ff6:	01fbd61b          	srliw	a2,s7,0x1f
    18000ffa:	0176063b          	addw	a2,a2,s7
    18000ffe:	4016561b          	sraiw	a2,a2,0x1
    18001002:	4585                	li	a1,1
    18001004:	8526                	mv	a0,s1
    18001006:	2f3000ef          	jal	ra,18001af8 <cadence_qspi_apb_readdata_capture>
	priv->qspi_calibrated_hz = hz;
    1800100a:	0000f797          	auipc	a5,0xf
    1800100e:	0937a923          	sw	s3,146(a5) # 1801009c <spi_priv+0x3c>
	priv->qspi_calibrated_cs = cs;
    18001012:	0000f797          	auipc	a5,0xf
    18001016:	0947a723          	sw	s4,142(a5) # 180100a0 <spi_priv+0x40>
		priv->previous_hz = max_hz;
    1800101a:	0000f797          	auipc	a5,0xf
    1800101e:	0937a523          	sw	s3,138(a5) # 180100a4 <spi_priv+0x44>
	cadence_qspi_apb_controller_enable(priv->regbase);
    18001022:	00093503          	ld	a0,0(s2)
    18001026:	2b9000ef          	jal	ra,18001ade <cadence_qspi_apb_controller_enable>
	return &spi4slave->slave;
    1800102a:	0000f517          	auipc	a0,0xf
    1800102e:	01e50513          	addi	a0,a0,30 # 18010048 <vic_spi_slave>
	spi4slave->slave.bus = bus;
    18001032:	0000f797          	auipc	a5,0xf
    18001036:	0167ab23          	sw	s6,22(a5) # 18010048 <vic_spi_slave>
	spi4slave->slave.cs = cs;
    1800103a:	0000f797          	auipc	a5,0xf
    1800103e:	0147ad23          	sw	s4,26(a5) # 18010054 <vic_spi_slave+0xc>
	spi4slave->slave.bus_width= fifo_width;
    18001042:	0000f797          	auipc	a5,0xf
    18001046:	0157a523          	sw	s5,10(a5) # 1801004c <vic_spi_slave+0x4>
	return &spi4slave->slave;
    1800104a:	b71d                	j	18000f70 <cadence_spi4x_setup_slave+0x128>
		if (range_lo == -1 && temp == idcode) {
    1800104c:	8c22                	mv	s8,s0
    1800104e:	bf91                	j	18000fa2 <cadence_spi4x_setup_slave+0x15a>
	    priv->qspi_calibrated_hz != max_hz ||
    18001050:	04092783          	lw	a5,64(s2)
    18001054:	ed479de3          	bne	a5,s4,18000f2e <cadence_spi4x_setup_slave+0xe6>
    18001058:	b7e9                	j	18001022 <cadence_spi4x_setup_slave+0x1da>
			range_hi = i - 1;
    1800105a:	fff40b9b          	addiw	s7,s0,-1
	if (range_lo == -1) {
    1800105e:	b779                	j	18000fec <cadence_spi4x_setup_slave+0x1a4>

0000000018001060 <cadence_spi_xfer>:


static int cadence_spi_xfer(struct spi_slave *slave, unsigned int bitlen,
			    const void *dout, void *din, unsigned long flags)
{
    18001060:	715d                	addi	sp,sp,-80
    18001062:	e0a2                	sd	s0,64(sp)
    18001064:	fc26                	sd	s1,56(sp)
    18001066:	f84a                	sd	s2,48(sp)
    18001068:	f44e                	sd	s3,40(sp)
    1800106a:	f052                	sd	s4,32(sp)
    1800106c:	e85a                	sd	s6,16(sp)
    1800106e:	e45e                	sd	s7,8(sp)
    18001070:	e062                	sd	s8,0(sp)
	struct cadence_spi_platdata *plat = &cadence_plat;
	struct cadence_spi_priv *priv = &spi_priv;
	void * base = priv->regbase;
    18001072:	0000f917          	auipc	s2,0xf
    18001076:	fee90913          	addi	s2,s2,-18 # 18010060 <spi_priv>
{
    1800107a:	e486                	sd	ra,72(sp)
    1800107c:	ec56                	sd	s5,24(sp)
	u8 *cmd_buf = priv->cmd_buf;
	unsigned int data_bytes = 0;
	int err = 0;
	u32 mode = CQSPI_STIG_WRITE;

	if (flags & SPI_XFER_BEGIN) {
    1800107e:	00177b13          	andi	s6,a4,1
{
    18001082:	843a                	mv	s0,a4
    18001084:	89aa                	mv	s3,a0
    18001086:	84ae                	mv	s1,a1
    18001088:	8bb2                	mv	s7,a2
    1800108a:	8c36                	mv	s8,a3
	void * base = priv->regbase;
    1800108c:	00093a03          	ld	s4,0(s2)
	if (flags & SPI_XFER_BEGIN) {
    18001090:	0a0b1f63          	bnez	s6,1800114e <cadence_spi_xfer+0xee>
		/* copy command to local buffer */
		priv->cmd_len = bitlen / 8;
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
	}

	if (flags == (SPI_XFER_BEGIN | SPI_XFER_END)) 
    18001094:	478d                	li	a5,3
    18001096:	00c9a583          	lw	a1,12(s3)
    1800109a:	00247a93          	andi	s5,s0,2
		data_bytes = bitlen / 8;
	}
	//uart_printf("%s: len=%d [bytes]\n", __func__, data_bytes);

	/* Set Chip select */
	cadence_qspi_apb_chipselect(base, slave->cs,
    1800109e:	4601                	li	a2,0
    180010a0:	8552                	mv	a0,s4
	if (flags == (SPI_XFER_BEGIN | SPI_XFER_END)) 
    180010a2:	08f40563          	beq	s0,a5,1800112c <cadence_spi_xfer+0xcc>
		data_bytes = bitlen / 8;
    180010a6:	0034d49b          	srliw	s1,s1,0x3
	cadence_qspi_apb_chipselect(base, slave->cs,
    180010aa:	307000ef          	jal	ra,18001bb0 <cadence_qspi_apb_chipselect>
				    CONFIG_CQSPI_DECODER);

	if ((flags & SPI_XFER_END) || (flags == 0)) {
    180010ae:	000a9463          	bnez	s5,180010b6 <cadence_spi_xfer+0x56>
	int err = 0;
    180010b2:	4981                	li	s3,0
	if ((flags & SPI_XFER_END) || (flags == 0)) {
    180010b4:	ec39                	bnez	s0,18001112 <cadence_spi_xfer+0xb2>
		if (priv->cmd_len == 0) {
    180010b6:	01092583          	lw	a1,16(s2)
    180010ba:	10058363          	beqz	a1,180011c0 <cadence_spi_xfer+0x160>
			//uart_printf("QSPI: Error, command is empty.\n");
			return -1;
		}

		if (din && data_bytes) {
    180010be:	0c0c0263          	beqz	s8,18001182 <cadence_spi_xfer+0x122>
    180010c2:	c0e1                	beqz	s1,18001182 <cadence_spi_xfer+0x122>
			/* read */
			/* Use STIG if no address. */
			if (!CQSPI_IS_ADDR(priv->cmd_len))
    180010c4:	4785                	li	a5,1
    180010c6:	0ab7f263          	bgeu	a5,a1,1800116a <cadence_spi_xfer+0x10a>
			err = cadence_qspi_apb_command_write(base,
				priv->cmd_len, cmd_buf,
				data_bytes, dout);
		break;
		case CQSPI_INDIRECT_READ:
			err = cadence_qspi_apb_indirect_read_setup(plat,
    180010ca:	0000f617          	auipc	a2,0xf
    180010ce:	faa60613          	addi	a2,a2,-86 # 18010074 <spi_priv+0x14>
    180010d2:	0000f517          	auipc	a0,0xf
    180010d6:	fe650513          	addi	a0,a0,-26 # 180100b8 <cadence_plat>
    180010da:	56d000ef          	jal	ra,18001e46 <cadence_qspi_apb_indirect_read_setup>
    180010de:	89aa                	mv	s3,a0
				priv->cmd_len, cmd_buf);
			if (!err) {
    180010e0:	e911                	bnez	a0,180010f4 <cadence_spi_xfer+0x94>
				err = cadence_qspi_apb_indirect_read_execute
    180010e2:	8662                	mv	a2,s8
    180010e4:	85a6                	mv	a1,s1
    180010e6:	0000f517          	auipc	a0,0xf
    180010ea:	fd250513          	addi	a0,a0,-46 # 180100b8 <cadence_plat>
    180010ee:	601000ef          	jal	ra,18001eee <cadence_qspi_apb_indirect_read_execute>
    180010f2:	89aa                	mv	s3,a0
		default:
			err = -1;
			break;
		}

		if (flags & SPI_XFER_END) {
    180010f4:	000a8f63          	beqz	s5,18001112 <cadence_spi_xfer+0xb2>
			/* clear command buffer */
			sys_memset(cmd_buf, 0, sizeof(priv->cmd_buf));
    180010f8:	02000613          	li	a2,32
    180010fc:	4581                	li	a1,0
    180010fe:	0000f517          	auipc	a0,0xf
    18001102:	f7650513          	addi	a0,a0,-138 # 18010074 <spi_priv+0x14>
    18001106:	b0bff0ef          	jal	ra,18000c10 <sys_memset>
			priv->cmd_len = 0;
    1800110a:	0000f797          	auipc	a5,0xf
    1800110e:	f607a323          	sw	zero,-154(a5) # 18010070 <spi_priv+0x10>
		}
	}

	return err;
}
    18001112:	60a6                	ld	ra,72(sp)
    18001114:	6406                	ld	s0,64(sp)
    18001116:	854e                	mv	a0,s3
    18001118:	74e2                	ld	s1,56(sp)
    1800111a:	7942                	ld	s2,48(sp)
    1800111c:	79a2                	ld	s3,40(sp)
    1800111e:	7a02                	ld	s4,32(sp)
    18001120:	6ae2                	ld	s5,24(sp)
    18001122:	6b42                	ld	s6,16(sp)
    18001124:	6ba2                	ld	s7,8(sp)
    18001126:	6c02                	ld	s8,0(sp)
    18001128:	6161                	addi	sp,sp,80
    1800112a:	8082                	ret
	cadence_qspi_apb_chipselect(base, slave->cs,
    1800112c:	285000ef          	jal	ra,18001bb0 <cadence_qspi_apb_chipselect>
		if (priv->cmd_len == 0) {
    18001130:	01092583          	lw	a1,16(s2)
    18001134:	c5d1                	beqz	a1,180011c0 <cadence_spi_xfer+0x160>
		data_bytes = 0;
    18001136:	4481                	li	s1,0
			err = cadence_qspi_apb_command_write(base,
    18001138:	875e                	mv	a4,s7
    1800113a:	86a6                	mv	a3,s1
    1800113c:	0000f617          	auipc	a2,0xf
    18001140:	f3860613          	addi	a2,a2,-200 # 18010074 <spi_priv+0x14>
    18001144:	8552                	mv	a0,s4
    18001146:	3f7000ef          	jal	ra,18001d3c <cadence_qspi_apb_command_write>
    1800114a:	89aa                	mv	s3,a0
		break;
    1800114c:	b765                	j	180010f4 <cadence_spi_xfer+0x94>
		priv->cmd_len = bitlen / 8;
    1800114e:	0035d61b          	srliw	a2,a1,0x3
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
    18001152:	0000f517          	auipc	a0,0xf
    18001156:	f2250513          	addi	a0,a0,-222 # 18010074 <spi_priv+0x14>
    1800115a:	85de                	mv	a1,s7
		priv->cmd_len = bitlen / 8;
    1800115c:	0000f717          	auipc	a4,0xf
    18001160:	f0c72a23          	sw	a2,-236(a4) # 18010070 <spi_priv+0x10>
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
    18001164:	a21ff0ef          	jal	ra,18000b84 <sys_memcpy>
    18001168:	b735                	j	18001094 <cadence_spi_xfer+0x34>
			err = cadence_qspi_apb_command_read(
    1800116a:	8762                	mv	a4,s8
    1800116c:	86a6                	mv	a3,s1
    1800116e:	0000f617          	auipc	a2,0xf
    18001172:	f0660613          	addi	a2,a2,-250 # 18010074 <spi_priv+0x14>
    18001176:	4585                	li	a1,1
    18001178:	8552                	mv	a0,s4
    1800117a:	317000ef          	jal	ra,18001c90 <cadence_qspi_apb_command_read>
    1800117e:	89aa                	mv	s3,a0
		break;
    18001180:	bf95                	j	180010f4 <cadence_spi_xfer+0x94>
		} else if (dout && !(flags & SPI_XFER_BEGIN)) {
    18001182:	fa0b8be3          	beqz	s7,18001138 <cadence_spi_xfer+0xd8>
    18001186:	fa0b19e3          	bnez	s6,18001138 <cadence_spi_xfer+0xd8>
			if (!CQSPI_IS_ADDR(priv->cmd_len))
    1800118a:	4785                	li	a5,1
    1800118c:	00b7e463          	bltu	a5,a1,18001194 <cadence_spi_xfer+0x134>
    18001190:	4585                	li	a1,1
    18001192:	b75d                	j	18001138 <cadence_spi_xfer+0xd8>
			err = cadence_qspi_apb_indirect_write_setup
    18001194:	0000f617          	auipc	a2,0xf
    18001198:	ee060613          	addi	a2,a2,-288 # 18010074 <spi_priv+0x14>
    1800119c:	0000f517          	auipc	a0,0xf
    180011a0:	f1c50513          	addi	a0,a0,-228 # 180100b8 <cadence_plat>
    180011a4:	6a5000ef          	jal	ra,18002048 <cadence_qspi_apb_indirect_write_setup>
    180011a8:	89aa                	mv	s3,a0
			if (!err) {
    180011aa:	f529                	bnez	a0,180010f4 <cadence_spi_xfer+0x94>
				err = cadence_qspi_apb_indirect_write_execute
    180011ac:	865e                	mv	a2,s7
    180011ae:	85a6                	mv	a1,s1
    180011b0:	0000f517          	auipc	a0,0xf
    180011b4:	f0850513          	addi	a0,a0,-248 # 180100b8 <cadence_plat>
    180011b8:	721000ef          	jal	ra,180020d8 <cadence_qspi_apb_indirect_write_execute>
    180011bc:	89aa                	mv	s3,a0
    180011be:	bf1d                	j	180010f4 <cadence_spi_xfer+0x94>
			return -1;
    180011c0:	59fd                	li	s3,-1
    180011c2:	bf81                	j	18001112 <cadence_spi_xfer+0xb2>

00000000180011c4 <cadence_qspi_init>:
{
	struct spi_operation *func;
    struct cadence_spi_platdata *plat = &cadence_plat;

	/******************* reset ****************/
	_ENABLE_CLOCK_clk_qspi_refclk_;
    180011c4:	118006b7          	lui	a3,0x11800
    180011c8:	22c6a703          	lw	a4,556(a3) # 1180022c <__stack_size+0x117ffa2c>
    180011cc:	800007b7          	lui	a5,0x80000
    180011d0:	fff7c813          	not	a6,a5
    180011d4:	2701                	sext.w	a4,a4
    180011d6:	800008b7          	lui	a7,0x80000
    180011da:	01077733          	and	a4,a4,a6
    180011de:	01176733          	or	a4,a4,a7
    180011e2:	2701                	sext.w	a4,a4
    180011e4:	22e6a623          	sw	a4,556(a3)
    _ENABLE_CLOCK_clk_qspi_apb_;
    180011e8:	2286a703          	lw	a4,552(a3)
    _ENABLE_CLOCK_clk_qspi_ahb_;
    _ASSERT_RESET_rstgen_rstn_qspi_ahb_;
    180011ec:	11840337          	lui	t1,0x11840
{
    180011f0:	862e                	mv	a2,a1
    _ENABLE_CLOCK_clk_qspi_apb_;
    180011f2:	2701                	sext.w	a4,a4
    180011f4:	01077733          	and	a4,a4,a6
    180011f8:	01176733          	or	a4,a4,a7
    180011fc:	2701                	sext.w	a4,a4
    180011fe:	22e6a423          	sw	a4,552(a3)
    _ENABLE_CLOCK_clk_qspi_ahb_;
    18001202:	2246a783          	lw	a5,548(a3)
    _ASSERT_RESET_rstgen_rstn_qspi_ahb_;
    18001206:	11840737          	lui	a4,0x11840
    _ENABLE_CLOCK_clk_qspi_ahb_;
    1800120a:	2781                	sext.w	a5,a5
    1800120c:	0107f7b3          	and	a5,a5,a6
    18001210:	0117e7b3          	or	a5,a5,a7
    18001214:	2781                	sext.w	a5,a5
    18001216:	22f6a223          	sw	a5,548(a3)
    _ASSERT_RESET_rstgen_rstn_qspi_ahb_;
    1800121a:	00832783          	lw	a5,8(t1) # 11840008 <__stack_size+0x1183f808>
    1800121e:	2781                	sext.w	a5,a5
    18001220:	0027e793          	ori	a5,a5,2
    18001224:	00f32423          	sw	a5,8(t1)
    18001228:	4f1c                	lw	a5,24(a4)
    1800122a:	8b89                	andi	a5,a5,2
    1800122c:	fff5                	bnez	a5,18001228 <cadence_qspi_init+0x64>
    _ASSERT_RESET_rstgen_rstn_qspi_core_;
    1800122e:	471c                	lw	a5,8(a4)
    18001230:	118406b7          	lui	a3,0x11840
    18001234:	2781                	sext.w	a5,a5
    18001236:	0047e793          	ori	a5,a5,4
    1800123a:	c71c                	sw	a5,8(a4)
    1800123c:	4e9c                	lw	a5,24(a3)
    1800123e:	8b91                	andi	a5,a5,4
    18001240:	fff5                	bnez	a5,1800123c <cadence_qspi_init+0x78>
    _ASSERT_RESET_rstgen_rstn_qspi_apb_;
    18001242:	469c                	lw	a5,8(a3)
    18001244:	11840737          	lui	a4,0x11840
    18001248:	2781                	sext.w	a5,a5
    1800124a:	0087e793          	ori	a5,a5,8
    1800124e:	c69c                	sw	a5,8(a3)
    18001250:	4f1c                	lw	a5,24(a4)
    18001252:	8ba1                	andi	a5,a5,8
    18001254:	fff5                	bnez	a5,18001250 <cadence_qspi_init+0x8c>
    _CLEAR_RESET_rstgen_rstn_qspi_ahb_;
    18001256:	471c                	lw	a5,8(a4)
    18001258:	118406b7          	lui	a3,0x11840
    1800125c:	2781                	sext.w	a5,a5
    1800125e:	9bf5                	andi	a5,a5,-3
    18001260:	c71c                	sw	a5,8(a4)
    18001262:	4e9c                	lw	a5,24(a3)
    18001264:	8b89                	andi	a5,a5,2
    18001266:	dff5                	beqz	a5,18001262 <cadence_qspi_init+0x9e>
    _CLEAR_RESET_rstgen_rstn_qspi_core_;
    18001268:	469c                	lw	a5,8(a3)
    1800126a:	11840737          	lui	a4,0x11840
    1800126e:	2781                	sext.w	a5,a5
    18001270:	9bed                	andi	a5,a5,-5
    18001272:	c69c                	sw	a5,8(a3)
    18001274:	4f1c                	lw	a5,24(a4)
    18001276:	8b91                	andi	a5,a5,4
    18001278:	dff5                	beqz	a5,18001274 <cadence_qspi_init+0xb0>
    _CLEAR_RESET_rstgen_rstn_qspi_apb_;
    1800127a:	471c                	lw	a5,8(a4)
    1800127c:	118406b7          	lui	a3,0x11840
    18001280:	2781                	sext.w	a5,a5
    18001282:	9bdd                	andi	a5,a5,-9
    18001284:	c71c                	sw	a5,8(a4)
    18001286:	4e9c                	lw	a5,24(a3)
    18001288:	8ba1                	andi	a5,a5,8
    1800128a:	dff5                	beqz	a5,18001286 <cadence_qspi_init+0xc2>
	plat->bit_mode = mode;
    1800128c:	0000f797          	auipc	a5,0xf
    18001290:	e6c7a223          	sw	a2,-412(a5) # 180100f0 <cadence_plat+0x38>
	
	func = &cadence_spi4x_func;
	func->setup_slave = cadence_spi4x_setup_slave;
    18001294:	00000797          	auipc	a5,0x0
    18001298:	bb478793          	addi	a5,a5,-1100 # 18000e48 <cadence_spi4x_setup_slave>
    1800129c:	0000f717          	auipc	a4,0xf
    180012a0:	e0f73623          	sd	a5,-500(a4) # 180100a8 <cadence_spi4x_func>
	func->spi_xfer = cadence_spi_xfer;
    180012a4:	00000797          	auipc	a5,0x0
    180012a8:	dbc78793          	addi	a5,a5,-580 # 18001060 <cadence_spi_xfer>

	spi_register(bus, func);
    180012ac:	0000f597          	auipc	a1,0xf
    180012b0:	dfc58593          	addi	a1,a1,-516 # 180100a8 <cadence_spi4x_func>
	func->spi_xfer = cadence_spi_xfer;
    180012b4:	0000f717          	auipc	a4,0xf
    180012b8:	def73e23          	sd	a5,-516(a4) # 180100b0 <cadence_spi4x_func+0x8>
	spi_register(bus, func);
    180012bc:	ba9d                	j	18000c32 <spi_register>

00000000180012be <spi_flash_read_write>:
		u32 data_len)
{
	unsigned long flags = SPI_XFER_BEGIN;
	int ret;

	if (data_len == 0)
    180012be:	0036189b          	slliw	a7,a2,0x3
    180012c2:	e799                	bnez	a5,180012d0 <spi_flash_read_write+0x12>
		flags |= SPI_XFER_END;

	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180012c4:	862e                	mv	a2,a1
    180012c6:	47a1                	li	a5,8
    180012c8:	470d                	li	a4,3
    180012ca:	4681                	li	a3,0
    180012cc:	85c6                	mv	a1,a7
    180012ce:	ba79                	j	18000c6c <spi_xfer>
{
    180012d0:	7179                	addi	sp,sp,-48
    180012d2:	f022                	sd	s0,32(sp)
    180012d4:	e84a                	sd	s2,16(sp)
    180012d6:	e44e                	sd	s3,8(sp)
    180012d8:	8936                	mv	s2,a3
    180012da:	89ba                	mv	s3,a4
    180012dc:	862e                	mv	a2,a1
    180012de:	843e                	mv	s0,a5
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180012e0:	4705                	li	a4,1
    180012e2:	47a1                	li	a5,8
    180012e4:	4681                	li	a3,0
    180012e6:	85c6                	mv	a1,a7
{
    180012e8:	ec26                	sd	s1,24(sp)
    180012ea:	f406                	sd	ra,40(sp)
    180012ec:	84aa                	mv	s1,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180012ee:	97fff0ef          	jal	ra,18000c6c <spi_xfer>
	if (ret)
    180012f2:	c901                	beqz	a0,18001302 <spi_flash_read_write+0x44>
	{
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
	}

	return ret;
}
    180012f4:	70a2                	ld	ra,40(sp)
    180012f6:	7402                	ld	s0,32(sp)
    180012f8:	64e2                	ld	s1,24(sp)
    180012fa:	6942                	ld	s2,16(sp)
    180012fc:	69a2                	ld	s3,8(sp)
    180012fe:	6145                	addi	sp,sp,48
    18001300:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001302:	0034159b          	slliw	a1,s0,0x3
}
    18001306:	7402                	ld	s0,32(sp)
    18001308:	70a2                	ld	ra,40(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    1800130a:	86ce                	mv	a3,s3
    1800130c:	864a                	mv	a2,s2
}
    1800130e:	69a2                	ld	s3,8(sp)
    18001310:	6942                	ld	s2,16(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001312:	8526                	mv	a0,s1
}
    18001314:	64e2                	ld	s1,24(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001316:	47a1                	li	a5,8
    18001318:	4709                	li	a4,2
}
    1800131a:	6145                	addi	sp,sp,48
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    1800131c:	ba81                	j	18000c6c <spi_xfer>

000000001800131e <spi_flash_cmd>:

int spi_flash_cmd(struct spi_slave *spi, u8 cmd, void *response, u32 len)
{
    1800131e:	1101                	addi	sp,sp,-32
    18001320:	00b107a3          	sb	a1,15(sp)
}

int spi_flash_cmd_read(struct spi_slave *spi, u8 *cmd,
		u32 cmd_len, void *data, u32 data_len)
{
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001324:	87b6                	mv	a5,a3
    18001326:	8732                	mv	a4,a2
    18001328:	00f10593          	addi	a1,sp,15
    1800132c:	4681                	li	a3,0
    1800132e:	4605                	li	a2,1
{
    18001330:	ec06                	sd	ra,24(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001332:	f8dff0ef          	jal	ra,180012be <spi_flash_read_write>
}
    18001336:	60e2                	ld	ra,24(sp)
    18001338:	6105                	addi	sp,sp,32
    1800133a:	8082                	ret

000000001800133c <spi_flash_cmd_read>:
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800133c:	87ba                	mv	a5,a4
    1800133e:	8736                	mv	a4,a3
    18001340:	4681                	li	a3,0
    18001342:	bfb5                	j	180012be <spi_flash_read_write>

0000000018001344 <spi_flash_cmd_write>:
}

int spi_flash_cmd_write(struct spi_slave *spi, u8 *cmd, u32 cmd_len,
		void *data, u32 data_len)
{
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001344:	87ba                	mv	a5,a4
    18001346:	4701                	li	a4,0
    18001348:	bf9d                	j	180012be <spi_flash_read_write>

000000001800134a <spi_flash_cmd_write_enable>:
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800134a:	6108                	ld	a0,0(a0)
}

int spi_flash_cmd_write_enable(struct spi_flash *flash)
{
    1800134c:	1101                	addi	sp,sp,-32
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800134e:	00f10593          	addi	a1,sp,15
    18001352:	4819                	li	a6,6
    18001354:	4781                	li	a5,0
    18001356:	4701                	li	a4,0
    18001358:	4681                	li	a3,0
    1800135a:	4605                	li	a2,1
{
    1800135c:	ec06                	sd	ra,24(sp)
    1800135e:	010107a3          	sb	a6,15(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001362:	f5dff0ef          	jal	ra,180012be <spi_flash_read_write>
	return spi_flash_cmd(flash->spi, CMD_WRITE_ENABLE, (void*)NULL, 0);
}
    18001366:	60e2                	ld	ra,24(sp)
    18001368:	6105                	addi	sp,sp,32
    1800136a:	8082                	ret

000000001800136c <spi_flash_cmd_write_status_enable>:
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800136c:	6108                	ld	a0,0(a0)

int spi_flash_cmd_write_status_enable(struct spi_flash *flash)
{
    1800136e:	1101                	addi	sp,sp,-32
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001370:	00f10593          	addi	a1,sp,15
    18001374:	05000813          	li	a6,80
    18001378:	4781                	li	a5,0
    1800137a:	4701                	li	a4,0
    1800137c:	4681                	li	a3,0
    1800137e:	4605                	li	a2,1
{
    18001380:	ec06                	sd	ra,24(sp)
    18001382:	010107a3          	sb	a6,15(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001386:	f39ff0ef          	jal	ra,180012be <spi_flash_read_write>
	return spi_flash_cmd(flash->spi, CMD_STATUS_ENABLE, (void*)NULL, 0);
}
    1800138a:	60e2                	ld	ra,24(sp)
    1800138c:	6105                	addi	sp,sp,32
    1800138e:	8082                	ret

0000000018001390 <spi_flash_cmd_write_disable>:

int spi_flash_cmd_write_disable(struct spi_slave *spi)
{
    18001390:	1101                	addi	sp,sp,-32
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001392:	00f10593          	addi	a1,sp,15
    18001396:	4811                	li	a6,4
    18001398:	4781                	li	a5,0
    1800139a:	4701                	li	a4,0
    1800139c:	4681                	li	a3,0
    1800139e:	4605                	li	a2,1
{
    180013a0:	ec06                	sd	ra,24(sp)
    180013a2:	010107a3          	sb	a6,15(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    180013a6:	f19ff0ef          	jal	ra,180012be <spi_flash_read_write>
	return spi_flash_cmd(spi, CMD_WRITE_DISABLE, (void*)NULL, 0);
}
    180013aa:	60e2                	ld	ra,24(sp)
    180013ac:	6105                	addi	sp,sp,32
    180013ae:	8082                	ret

00000000180013b0 <spi_flash_cmd_read_status>:
int spi_flash_cmd_read_status(struct spi_flash *flash, u8 *cmd, u32 cmd_len, u8 *status)
{
    180013b0:	1101                	addi	sp,sp,-32
    180013b2:	e822                	sd	s0,16(sp)
	struct spi_slave *spi = flash->spi;
    180013b4:	6100                	ld	s0,0(a0)
	int ret;

	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180013b6:	0036151b          	slliw	a0,a2,0x3
{
    180013ba:	e426                	sd	s1,8(sp)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180013bc:	862e                	mv	a2,a1
{
    180013be:	84b6                	mv	s1,a3
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180013c0:	85aa                	mv	a1,a0
    180013c2:	47a1                	li	a5,8
    180013c4:	4705                	li	a4,1
    180013c6:	4681                	li	a3,0
    180013c8:	8522                	mv	a0,s0
{
    180013ca:	ec06                	sd	ra,24(sp)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180013cc:	8a1ff0ef          	jal	ra,18000c6c <spi_xfer>
	if (ret) {
    180013d0:	c511                	beqz	a0,180013dc <spi_flash_cmd_read_status+0x2c>
	//uart_printf("status = 0x%x\r\n", status[0]);
	if (ret)
		return ret;

	return 0;
}
    180013d2:	60e2                	ld	ra,24(sp)
    180013d4:	6442                	ld	s0,16(sp)
    180013d6:	64a2                	ld	s1,8(sp)
    180013d8:	6105                	addi	sp,sp,32
    180013da:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180013dc:	8522                	mv	a0,s0
}
    180013de:	6442                	ld	s0,16(sp)
    180013e0:	60e2                	ld	ra,24(sp)
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180013e2:	86a6                	mv	a3,s1
}
    180013e4:	64a2                	ld	s1,8(sp)
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180013e6:	47a1                	li	a5,8
    180013e8:	4709                	li	a4,2
    180013ea:	4601                	li	a2,0
    180013ec:	45a1                	li	a1,8
}
    180013ee:	6105                	addi	sp,sp,32
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180013f0:	87dff06f          	j	18000c6c <spi_xfer>

00000000180013f4 <spi_flash_cmd_poll_bit>:

int spi_flash_cmd_poll_bit(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u8 poll_bit)
{
    180013f4:	715d                	addi	sp,sp,-80
    180013f6:	e0a2                	sd	s0,64(sp)
    180013f8:	fc26                	sd	s1,56(sp)
    180013fa:	f84a                	sd	s2,48(sp)
    180013fc:	f44e                	sd	s3,40(sp)
    180013fe:	e486                	sd	ra,72(sp)
    18001400:	84aa                	mv	s1,a0
    18001402:	89ae                	mv	s3,a1
    18001404:	8936                	mv	s2,a3
    18001406:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;
	u32 timebase_1 = 0;
    1800140a:	4401                	li	s0,0
    1800140c:	a811                	j	18001420 <spi_flash_cmd_poll_bit+0x2c>
	do {
		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
        //uart_printf("cmd = 0x%x, status = 0x%x\r\n", cmd, status);
		if (ret)
			return ret;
		if ((status & poll_bit) == 0)
    1800140e:	01f14703          	lbu	a4,31(sp)
			break;
		timebase_1++;//libo
    18001412:	0007841b          	sext.w	s0,a5
		if ((status & poll_bit) == 0)
    18001416:	00e977b3          	and	a5,s2,a4
    1800141a:	c38d                	beqz	a5,1800143c <spi_flash_cmd_poll_bit+0x48>
	} while (timebase_1 < timeout);
    1800141c:	0336f763          	bgeu	a3,s3,1800144a <spi_flash_cmd_poll_bit+0x56>
		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
    18001420:	01f10693          	addi	a3,sp,31
    18001424:	4605                	li	a2,1
    18001426:	00f10593          	addi	a1,sp,15
    1800142a:	8526                	mv	a0,s1
    1800142c:	f85ff0ef          	jal	ra,180013b0 <spi_flash_cmd_read_status>
		timebase_1++;//libo
    18001430:	0014079b          	addiw	a5,s0,1
	} while (timebase_1 < timeout);
    18001434:	02079693          	slli	a3,a5,0x20
    18001438:	9281                	srli	a3,a3,0x20
		if (ret)
    1800143a:	d971                	beqz	a0,1800140e <spi_flash_cmd_poll_bit+0x1a>
		return 0;

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return -1;
}
    1800143c:	60a6                	ld	ra,72(sp)
    1800143e:	6406                	ld	s0,64(sp)
    18001440:	74e2                	ld	s1,56(sp)
    18001442:	7942                	ld	s2,48(sp)
    18001444:	79a2                	ld	s3,40(sp)
    18001446:	6161                	addi	sp,sp,80
    18001448:	8082                	ret
    1800144a:	60a6                	ld	ra,72(sp)
    1800144c:	6406                	ld	s0,64(sp)
    1800144e:	74e2                	ld	s1,56(sp)
    18001450:	7942                	ld	s2,48(sp)
    18001452:	79a2                	ld	s3,40(sp)
	return -1;
    18001454:	557d                	li	a0,-1
}
    18001456:	6161                	addi	sp,sp,80
    18001458:	8082                	ret

000000001800145a <spi_flash_cmd_wait_ready>:

int spi_flash_cmd_wait_ready(struct spi_flash *flash, unsigned long timeout)
{
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800145a:	4685                	li	a3,1
    1800145c:	4615                	li	a2,5
    1800145e:	bf59                	j	180013f4 <spi_flash_cmd_poll_bit>

0000000018001460 <spi_flash_cmd_poll_enable>:
			CMD_READ_STATUS, STATUS_WIP);
}

int spi_flash_cmd_poll_enable(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u32 poll_bit)
{
    18001460:	715d                	addi	sp,sp,-80
    18001462:	e0a2                	sd	s0,64(sp)
    18001464:	fc26                	sd	s1,56(sp)
    18001466:	f84a                	sd	s2,48(sp)
    18001468:	f44e                	sd	s3,40(sp)
    1800146a:	e486                	sd	ra,72(sp)
    1800146c:	84aa                	mv	s1,a0
    1800146e:	89ae                	mv	s3,a1
    18001470:	8936                	mv	s2,a3
    18001472:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;

	u32 timebase_1 = 0;
    18001476:	4401                	li	s0,0
    18001478:	a819                	j	1800148e <spi_flash_cmd_poll_enable+0x2e>

		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
		if (ret)
			return ret;
        //uart_printf("read status = 0x%x\r\n", status);
		if ((status & poll_bit) == 1)
    1800147a:	01f14703          	lbu	a4,31(sp)
			break;
		timebase_1++;
    1800147e:	0007841b          	sext.w	s0,a5
		if ((status & poll_bit) == 1)
    18001482:	00e977b3          	and	a5,s2,a4
    18001486:	02d78363          	beq	a5,a3,180014ac <spi_flash_cmd_poll_enable+0x4c>
	} while (timebase_1 < timeout);
    1800148a:	03367163          	bgeu	a2,s3,180014ac <spi_flash_cmd_poll_enable+0x4c>
		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
    1800148e:	01f10693          	addi	a3,sp,31
    18001492:	4605                	li	a2,1
    18001494:	00f10593          	addi	a1,sp,15
    18001498:	8526                	mv	a0,s1
    1800149a:	f17ff0ef          	jal	ra,180013b0 <spi_flash_cmd_read_status>
		timebase_1++;
    1800149e:	0014079b          	addiw	a5,s0,1
	} while (timebase_1 < timeout);
    180014a2:	02079613          	slli	a2,a5,0x20
		if ((status & poll_bit) == 1)
    180014a6:	4685                	li	a3,1
	} while (timebase_1 < timeout);
    180014a8:	9201                	srli	a2,a2,0x20
		if (ret)
    180014aa:	d961                	beqz	a0,1800147a <spi_flash_cmd_poll_enable+0x1a>

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return 0;
} 
    180014ac:	60a6                	ld	ra,72(sp)
    180014ae:	6406                	ld	s0,64(sp)
    180014b0:	74e2                	ld	s1,56(sp)
    180014b2:	7942                	ld	s2,48(sp)
    180014b4:	79a2                	ld	s3,40(sp)
    180014b6:	6161                	addi	sp,sp,80
    180014b8:	8082                	ret

00000000180014ba <spi_flash_cmd_status_poll_enable>:

int spi_flash_cmd_status_poll_enable(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u32 poll_bit)
{
    180014ba:	715d                	addi	sp,sp,-80
    180014bc:	e0a2                	sd	s0,64(sp)
    180014be:	fc26                	sd	s1,56(sp)
    180014c0:	f84a                	sd	s2,48(sp)
    180014c2:	f44e                	sd	s3,40(sp)
    180014c4:	f052                	sd	s4,32(sp)
    180014c6:	e486                	sd	ra,72(sp)
    180014c8:	84aa                	mv	s1,a0
    180014ca:	8a2e                	mv	s4,a1
    180014cc:	89b6                	mv	s3,a3
    180014ce:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;

	u32 timebase_1 = 0;
    180014d2:	4401                	li	s0,0

		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
		if (ret)
			return ret;
        //uart_printf("read status = 0x%x\r\n", status);
		if ((status & poll_bit) == 0x2)
    180014d4:	4909                	li	s2,2
    180014d6:	a819                	j	180014ec <spi_flash_cmd_status_poll_enable+0x32>
    180014d8:	01f14703          	lbu	a4,31(sp)
			break;
		timebase_1++;
    180014dc:	0007841b          	sext.w	s0,a5
		if ((status & poll_bit) == 0x2)
    180014e0:	00e9f7b3          	and	a5,s3,a4
    180014e4:	03278263          	beq	a5,s2,18001508 <spi_flash_cmd_status_poll_enable+0x4e>
	} while (timebase_1 < timeout);
    180014e8:	0346f063          	bgeu	a3,s4,18001508 <spi_flash_cmd_status_poll_enable+0x4e>
		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
    180014ec:	01f10693          	addi	a3,sp,31
    180014f0:	4605                	li	a2,1
    180014f2:	00f10593          	addi	a1,sp,15
    180014f6:	8526                	mv	a0,s1
    180014f8:	eb9ff0ef          	jal	ra,180013b0 <spi_flash_cmd_read_status>
		timebase_1++;
    180014fc:	0014079b          	addiw	a5,s0,1
	} while (timebase_1 < timeout);
    18001500:	02079693          	slli	a3,a5,0x20
    18001504:	9281                	srli	a3,a3,0x20
		if (ret)
    18001506:	d969                	beqz	a0,180014d8 <spi_flash_cmd_status_poll_enable+0x1e>

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return 0;
}
    18001508:	60a6                	ld	ra,72(sp)
    1800150a:	6406                	ld	s0,64(sp)
    1800150c:	74e2                	ld	s1,56(sp)
    1800150e:	7942                	ld	s2,48(sp)
    18001510:	79a2                	ld	s3,40(sp)
    18001512:	7a02                	ld	s4,32(sp)
    18001514:	6161                	addi	sp,sp,80
    18001516:	8082                	ret

0000000018001518 <spi_flash_cmd_wait_enable>:

int spi_flash_cmd_wait_enable(struct spi_flash *flash, unsigned long timeout)
{
	return spi_flash_cmd_status_poll_enable(flash, timeout,
    18001518:	4689                	li	a3,2
    1800151a:	4615                	li	a2,5
    1800151c:	bf79                	j	180014ba <spi_flash_cmd_status_poll_enable>

000000001800151e <spi_flash_write_status>:
			CMD_READ_STATUS, FLASH_ENABLE);
}
int spi_flash_write_status(struct spi_flash *flash,  u8 *cmd, unsigned int cmd_len,void *data, unsigned int data_len)
{
    1800151e:	7139                	addi	sp,sp,-64
    18001520:	f822                	sd	s0,48(sp)
    18001522:	842a                	mv	s0,a0
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001524:	6108                	ld	a0,0(a0)
{
    18001526:	f426                	sd	s1,40(sp)
    18001528:	f04a                	sd	s2,32(sp)
    1800152a:	ec4e                	sd	s3,24(sp)
    1800152c:	e852                	sd	s4,16(sp)
    1800152e:	84ae                	mv	s1,a1
    18001530:	8932                	mv	s2,a2
    18001532:	89b6                	mv	s3,a3
    18001534:	8a3a                	mv	s4,a4
    18001536:	4819                	li	a6,6
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001538:	4781                	li	a5,0
    1800153a:	4701                	li	a4,0
    1800153c:	4681                	li	a3,0
    1800153e:	4605                	li	a2,1
    18001540:	00f10593          	addi	a1,sp,15
{
    18001544:	fc06                	sd	ra,56(sp)
    18001546:	010107a3          	sb	a6,15(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800154a:	d75ff0ef          	jal	ra,180012be <spi_flash_read_write>
	int ret;

	ret = spi_flash_cmd_write_enable(flash);
	if (ret) {
    1800154e:	c909                	beqz	a0,18001560 <spi_flash_write_status+0x42>
	if (ret < 0) {
		//uart_printf("SF: disable write failed\n");
		return ret;
	}
	return 0;
}
    18001550:	70e2                	ld	ra,56(sp)
    18001552:	7442                	ld	s0,48(sp)
    18001554:	74a2                	ld	s1,40(sp)
    18001556:	7902                	ld	s2,32(sp)
    18001558:	69e2                	ld	s3,24(sp)
    1800155a:	6a42                	ld	s4,16(sp)
    1800155c:	6121                	addi	sp,sp,64
    1800155e:	8082                	ret
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001560:	6008                	ld	a0,0(s0)
    18001562:	87d2                	mv	a5,s4
    18001564:	4701                	li	a4,0
    18001566:	86ce                	mv	a3,s3
    18001568:	864a                	mv	a2,s2
    1800156a:	85a6                	mv	a1,s1
    1800156c:	d53ff0ef          	jal	ra,180012be <spi_flash_read_write>
	if (ret < 0) {
    18001570:	fe0540e3          	bltz	a0,18001550 <spi_flash_write_status+0x32>
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001574:	039385b7          	lui	a1,0x3938
    18001578:	4685                	li	a3,1
    1800157a:	4615                	li	a2,5
    1800157c:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    18001580:	8522                	mv	a0,s0
    18001582:	e73ff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
	if (ret < 0) {
    18001586:	fc0545e3          	bltz	a0,18001550 <spi_flash_write_status+0x32>
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800158a:	6008                	ld	a0,0(s0)
    1800158c:	4781                	li	a5,0
    1800158e:	00f10593          	addi	a1,sp,15
    18001592:	4811                	li	a6,4
    18001594:	4701                	li	a4,0
    18001596:	4681                	li	a3,0
    18001598:	4605                	li	a2,1
    1800159a:	010107a3          	sb	a6,15(sp)
    1800159e:	d21ff0ef          	jal	ra,180012be <spi_flash_read_write>
	if (ret < 0) {
    180015a2:	00152793          	slti	a5,a0,1
}
    180015a6:	70e2                	ld	ra,56(sp)
    180015a8:	7442                	ld	s0,48(sp)
    180015aa:	40f007bb          	negw	a5,a5
    180015ae:	8d7d                	and	a0,a0,a5
    180015b0:	74a2                	ld	s1,40(sp)
    180015b2:	7902                	ld	s2,32(sp)
    180015b4:	69e2                	ld	s3,24(sp)
    180015b6:	6a42                	ld	s4,16(sp)
    180015b8:	2501                	sext.w	a0,a0
    180015ba:	6121                	addi	sp,sp,64
    180015bc:	8082                	ret

00000000180015be <spi_flash_write_status_bit>:
	/* set PB=0 all can write */
	return spi_flash_write_status_bit(flash, 0x00, 0);
}
#else
int spi_flash_write_status_bit(struct spi_flash *flash, u8 status1, u8 status2,  u8 bit1,  u8 bit2)
{
    180015be:	7179                	addi	sp,sp,-48
	u8 status[3];
	int ret = 0;

	status[0] = CMD_WRITE_STATUS;
	status[1] = status1|bit1;
    180015c0:	00d5e833          	or	a6,a1,a3
	status[2] = status2|bit2;
    180015c4:	00e667b3          	or	a5,a2,a4
{
    180015c8:	f022                	sd	s0,32(sp)
    180015ca:	ec26                	sd	s1,24(sp)
    180015cc:	843a                	mv	s0,a4
    180015ce:	84b6                	mv	s1,a3
	status[0] = CMD_WRITE_STATUS;
    180015d0:	4885                	li	a7,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180015d2:	4709                	li	a4,2
    180015d4:	00910693          	addi	a3,sp,9
    180015d8:	4605                	li	a2,1
    180015da:	002c                	addi	a1,sp,8
{
    180015dc:	e84a                	sd	s2,16(sp)
    180015de:	f406                	sd	ra,40(sp)
    180015e0:	892a                	mv	s2,a0
	status[0] = CMD_WRITE_STATUS;
    180015e2:	01110423          	sb	a7,8(sp)
	status[1] = status1|bit1;
    180015e6:	010104a3          	sb	a6,9(sp)
	status[2] = status2|bit2;
    180015ea:	00f10523          	sb	a5,10(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180015ee:	f31ff0ef          	jal	ra,1800151e <spi_flash_write_status>

	if (bit1)
    180015f2:	e889                	bnez	s1,18001604 <spi_flash_write_status_bit+0x46>
	{
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS, ~bit1);
	}
	if (bit2)
    180015f4:	e40d                	bnez	s0,1800161e <spi_flash_write_status_bit+0x60>
	return ret;
   delay(1000);
    

	return ret;
}
    180015f6:	70a2                	ld	ra,40(sp)
    180015f8:	7402                	ld	s0,32(sp)
    180015fa:	64e2                	ld	s1,24(sp)
    180015fc:	6942                	ld	s2,16(sp)
    180015fe:	4501                	li	a0,0
    18001600:	6145                	addi	sp,sp,48
    18001602:	8082                	ret
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS, ~bit1);
    18001604:	fff4c693          	not	a3,s1
    18001608:	039385b7          	lui	a1,0x3938
    1800160c:	0ff6f693          	andi	a3,a3,255
    18001610:	4615                	li	a2,5
    18001612:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    18001616:	854a                	mv	a0,s2
    18001618:	dddff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
	if (bit2)
    1800161c:	dc69                	beqz	s0,180015f6 <spi_flash_write_status_bit+0x38>
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS1, ~bit2);
    1800161e:	fff44693          	not	a3,s0
    18001622:	039385b7          	lui	a1,0x3938
    18001626:	854a                	mv	a0,s2
    18001628:	0ff6f693          	andi	a3,a3,255
    1800162c:	03500613          	li	a2,53
    18001630:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    18001634:	dc1ff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
}
    18001638:	70a2                	ld	ra,40(sp)
    1800163a:	7402                	ld	s0,32(sp)
    1800163c:	64e2                	ld	s1,24(sp)
    1800163e:	6942                	ld	s2,16(sp)
    18001640:	4501                	li	a0,0
    18001642:	6145                	addi	sp,sp,48
    18001644:	8082                	ret

0000000018001646 <spi_flash_protect>:

int spi_flash_protect(struct spi_flash *flash)
{
    18001646:	1101                	addi	sp,sp,-32
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001648:	00910693          	addi	a3,sp,9
    1800164c:	002c                	addi	a1,sp,8
	status[0] = CMD_WRITE_STATUS;
    1800164e:	4785                	li	a5,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001650:	4709                	li	a4,2
    18001652:	4605                	li	a2,1
{
    18001654:	ec06                	sd	ra,24(sp)
	status[0] = CMD_WRITE_STATUS;
    18001656:	00f11423          	sh	a5,8(sp)
	status[2] = status2|bit2;
    1800165a:	00010523          	sb	zero,10(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    1800165e:	ec1ff0ef          	jal	ra,1800151e <spi_flash_write_status>
	/* set PB=0 all can write */
	return spi_flash_write_status_bit(flash, 0x00, 0x00, 0, 0);
}
    18001662:	60e2                	ld	ra,24(sp)
    18001664:	4501                	li	a0,0
    18001666:	6105                	addi	sp,sp,32
    18001668:	8082                	ret

000000001800166a <spi_flash_cmd_erase>:
#endif
int spi_flash_cmd_erase(struct spi_flash *flash, u8 erase_cmd,
		u32 offset, u32 len)
{
    1800166a:	715d                	addi	sp,sp,-80
    1800166c:	e0a2                	sd	s0,64(sp)
    1800166e:	fc26                	sd	s1,56(sp)
    18001670:	f84a                	sd	s2,48(sp)
    18001672:	f052                	sd	s4,32(sp)
    18001674:	e486                	sd	ra,72(sp)
    18001676:	f44e                	sd	s3,40(sp)
    18001678:	ec56                	sd	s5,24(sp)
	int ret;
	u8 cmd[4];
 
    //uart_printf("spi_flash_cmd_erase \r\n");

	switch(erase_cmd){
    1800167a:	05200793          	li	a5,82
{
    1800167e:	8a2e                	mv	s4,a1
    18001680:	84aa                	mv	s1,a0
    18001682:	8432                	mv	s0,a2
    18001684:	8936                	mv	s2,a3
	switch(erase_cmd){
    18001686:	0cf58e63          	beq	a1,a5,18001762 <spi_flash_cmd_erase+0xf8>
    1800168a:	0d800793          	li	a5,216
    1800168e:	0cf58f63          	beq	a1,a5,1800176c <spi_flash_cmd_erase+0x102>
		case CMD_W25_SE:
			erase_size = flash->sector_size;
    18001692:	01852983          	lw	s3,24(a0)
		default:
			erase_size = flash->sector_size;
			break;
	}

	if (offset % erase_size || len % erase_size) {
    18001696:	033477bb          	remuw	a5,s0,s3
    1800169a:	eff1                	bnez	a5,18001776 <spi_flash_cmd_erase+0x10c>
    1800169c:	033977bb          	remuw	a5,s2,s3
    180016a0:	ebf9                	bnez	a5,18001776 <spi_flash_cmd_erase+0x10c>
	status[0] = CMD_WRITE_STATUS;
    180016a2:	4785                	li	a5,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180016a4:	4709                	li	a4,2
    180016a6:	00910693          	addi	a3,sp,9
    180016aa:	4605                	li	a2,1
    180016ac:	002c                	addi	a1,sp,8
    180016ae:	8526                	mv	a0,s1
	status[0] = CMD_WRITE_STATUS;
    180016b0:	00f11423          	sh	a5,8(sp)
	status[2] = status2|bit2;
    180016b4:	00010523          	sb	zero,10(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180016b8:	e67ff0ef          	jal	ra,1800151e <spi_flash_write_status>
	}

   // spi_flash_cmd_write_status_enable(flash);
	spi_flash_protect(flash);

	cmd[0] = erase_cmd;
    180016bc:	01410423          	sb	s4,8(sp)
	return spi_flash_cmd_poll_bit(flash, timeout,
    180016c0:	03938a37          	lui	s4,0x3938
	start = offset;
	end = start + len;
    180016c4:	0124093b          	addw	s2,s0,s2
    180016c8:	4a99                	li	s5,6
	return spi_flash_cmd_poll_bit(flash, timeout,
    180016ca:	700a0a13          	addi	s4,s4,1792 # 3938700 <__stack_size+0x3937f00>
	while (offset < end)
    180016ce:	0b247263          	bgeu	s0,s2,18001772 <spi_flash_cmd_erase+0x108>
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180016d2:	00845793          	srli	a5,s0,0x8
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    180016d6:	6088                	ld	a0,0(s1)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180016d8:	00841813          	slli	a6,s0,0x8
    180016dc:	0ff7f793          	andi	a5,a5,255
    180016e0:	00f86833          	or	a6,a6,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180016e4:	0104589b          	srliw	a7,s0,0x10
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    180016e8:	4781                	li	a5,0
    180016ea:	4701                	li	a4,0
    180016ec:	4681                	li	a3,0
    180016ee:	4605                	li	a2,1
    180016f0:	00710593          	addi	a1,sp,7
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180016f4:	01011523          	sh	a6,10(sp)
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180016f8:	011104a3          	sb	a7,9(sp)
	{
		spi_flash_addr(offset, cmd);
		offset += erase_size;
    180016fc:	015103a3          	sb	s5,7(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001700:	bbfff0ef          	jal	ra,180012be <spi_flash_read_write>
    18001704:	882a                	mv	a6,a0
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001706:	4781                	li	a5,0
    18001708:	4701                	li	a4,0
    1800170a:	4681                	li	a3,0
    1800170c:	4611                	li	a2,4
    1800170e:	002c                	addi	a1,sp,8
		offset += erase_size;
    18001710:	0089843b          	addw	s0,s3,s0

		//uart_printf("SF: erase %x %x %x %x (%x)\n", cmd[0], cmd[1],
		//		cmd[2], cmd[3], offset);

		ret = spi_flash_cmd_write_enable(flash);
		if (ret)
    18001714:	ed0d                	bnez	a0,1800174e <spi_flash_cmd_erase+0xe4>
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001716:	6088                	ld	a0,0(s1)
    18001718:	ba7ff0ef          	jal	ra,180012be <spi_flash_read_write>
    1800171c:	882a                	mv	a6,a0
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800171e:	4685                	li	a3,1
    18001720:	4615                	li	a2,5
    18001722:	85d2                	mv	a1,s4
    18001724:	8526                	mv	a0,s1
			goto out;

		//spi_flash_cmd_wait_enable(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT);

		ret = spi_flash_cmd_write(flash->spi, cmd, sizeof(cmd), NULL, 0);
		if (ret)
    18001726:	02081463          	bnez	a6,1800174e <spi_flash_cmd_erase+0xe4>
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800172a:	ccbff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
    1800172e:	882a                	mv	a6,a0
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001730:	4781                	li	a5,0
    18001732:	4701                	li	a4,0
    18001734:	4681                	li	a3,0
    18001736:	4605                	li	a2,1
    18001738:	00710593          	addi	a1,sp,7
			goto out;

		ret = spi_flash_cmd_wait_ready(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT);
		if (ret)
    1800173c:	e909                	bnez	a0,1800174e <spi_flash_cmd_erase+0xe4>
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800173e:	6088                	ld	a0,0(s1)
    18001740:	4811                	li	a6,4
    18001742:	010103a3          	sb	a6,7(sp)
    18001746:	b79ff0ef          	jal	ra,180012be <spi_flash_read_write>
    1800174a:	882a                	mv	a6,a0
			goto out;

		ret = spi_flash_cmd_write_disable(flash->spi);
		if (ret)
    1800174c:	d149                	beqz	a0,180016ce <spi_flash_cmd_erase+0x64>

	//uart_printf("SF: Successfully erased %d bytes @ %x\n", len , start);

out:
	return ret;
}
    1800174e:	60a6                	ld	ra,72(sp)
    18001750:	6406                	ld	s0,64(sp)
    18001752:	74e2                	ld	s1,56(sp)
    18001754:	7942                	ld	s2,48(sp)
    18001756:	79a2                	ld	s3,40(sp)
    18001758:	7a02                	ld	s4,32(sp)
    1800175a:	6ae2                	ld	s5,24(sp)
    1800175c:	8542                	mv	a0,a6
    1800175e:	6161                	addi	sp,sp,80
    18001760:	8082                	ret
			erase_size = flash->sector_size * 8;
    18001762:	01852983          	lw	s3,24(a0)
    18001766:	0039999b          	slliw	s3,s3,0x3
			break;
    1800176a:	b735                	j	18001696 <spi_flash_cmd_erase+0x2c>
			erase_size = flash->block_size;
    1800176c:	01c52983          	lw	s3,28(a0)
			break;
    18001770:	b71d                	j	18001696 <spi_flash_cmd_erase+0x2c>
		return -1;
    18001772:	4801                	li	a6,0
    18001774:	bfe9                	j	1800174e <spi_flash_cmd_erase+0xe4>
    18001776:	587d                	li	a6,-1
    18001778:	bfd9                	j	1800174e <spi_flash_cmd_erase+0xe4>

000000001800177a <spi_flash_erase_mode>:

/* mode is 4, 32, 64*/
int spi_flash_erase_mode(struct spi_flash *flash, u32 offset, u32 len, u32 mode)
{
    1800177a:	87b6                	mv	a5,a3
	int ret = 0;
	switch (mode)
    1800177c:	02000713          	li	a4,32
{
    18001780:	882a                	mv	a6,a0
    18001782:	86b2                	mv	a3,a2
	switch (mode)
    18001784:	02e78163          	beq	a5,a4,180017a6 <spi_flash_erase_mode+0x2c>
    18001788:	04000713          	li	a4,64
			break;
		case 32:
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE_32, offset, len);
			break;
		case 64:
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE, offset, len);
    1800178c:	862e                	mv	a2,a1
	switch (mode)
    1800178e:	00e79663          	bne	a5,a4,1800179a <spi_flash_erase_mode+0x20>
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE, offset, len);
    18001792:	0d800593          	li	a1,216
    18001796:	8542                	mv	a0,a6
    18001798:	bdc9                	j	1800166a <spi_flash_cmd_erase>
	switch (mode)
    1800179a:	4711                	li	a4,4
    1800179c:	fee79be3          	bne	a5,a4,18001792 <spi_flash_erase_mode+0x18>
			ret = spi_flash_cmd_erase(flash, CMD_W25_SE, offset, len);
    180017a0:	02000593          	li	a1,32
    180017a4:	b5d9                	j	1800166a <spi_flash_cmd_erase>
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE_32, offset, len);
    180017a6:	862e                	mv	a2,a1
    180017a8:	05200593          	li	a1,82
    180017ac:	bd7d                	j	1800166a <spi_flash_cmd_erase>

00000000180017ae <spi_flash_cmd_write_mode>:
	}
	return ret;
}

int spi_flash_cmd_write_mode(struct spi_flash *flash, u32 offset,u32 len, void *buf, u32 mode)
{
    180017ae:	7135                	addi	sp,sp,-160
    180017b0:	e836                	sd	a3,16(sp)
	struct spi_slave *spi = flash->spi;
    180017b2:	6114                	ld	a3,0(a0)
{
    180017b4:	e922                	sd	s0,144(sp)
    180017b6:	e526                	sd	s1,136(sp)
    180017b8:	f8d2                	sd	s4,112(sp)
    180017ba:	f4d6                	sd	s5,104(sp)
    180017bc:	f0da                	sd	s6,96(sp)
    180017be:	ed06                	sd	ra,152(sp)
    180017c0:	8b3a                	mv	s6,a4
    180017c2:	e14a                	sd	s2,128(sp)
    180017c4:	fcce                	sd	s3,120(sp)
    180017c6:	ecde                	sd	s7,88(sp)
    180017c8:	e8e2                	sd	s8,80(sp)
    180017ca:	e4e6                	sd	s9,72(sp)
    180017cc:	e0ea                	sd	s10,64(sp)
    180017ce:	fc6e                	sd	s11,56(sp)
    int write_data = 1;
	unsigned long flags = SPI_XFER_BEGIN;

	page_size = flash->page_size;

	switch (mode){
    180017d0:	4705                	li	a4,1
	struct spi_slave *spi = flash->spi;
    180017d2:	e436                	sd	a3,8(sp)
{
    180017d4:	84aa                	mv	s1,a0
    180017d6:	842e                	mv	s0,a1
    180017d8:	8a32                	mv	s4,a2
	page_size = flash->page_size;
    180017da:	01456a83          	lwu	s5,20(a0)
	switch (mode){
    180017de:	16eb1863          	bne	s6,a4,1800194e <spi_flash_cmd_write_mode+0x1a0>
		case 1:
			cmd[0] = CMD_PAGE_PROGRAM;
    180017e2:	4709                	li	a4,2
    180017e4:	02e10423          	sb	a4,40(sp)
			cmd[0] = CMD_PAGE_PROGRAM;
			break;
	}


	for (actual = 0; actual < len; actual += chunk_len)
    180017e8:	120a0363          	beqz	s4,1800190e <spi_flash_cmd_write_mode+0x160>
	return spi_flash_cmd_status_poll_enable(flash, timeout,
    180017ec:	03938c37          	lui	s8,0x3938
	return spi_flash_cmd_poll_bit(flash, timeout,
    180017f0:	016e3cb7          	lui	s9,0x16e3
	for (actual = 0; actual < len; actual += chunk_len)
    180017f4:	4901                	li	s2,0
    180017f6:	4d19                	li	s10,6
	return spi_flash_cmd_status_poll_enable(flash, timeout,
    180017f8:	700c0c13          	addi	s8,s8,1792 # 3938700 <__stack_size+0x3937f00>
				break;
			}
            
		}
#endif
		if (mode == 4)
    180017fc:	4b91                	li	s7,4
	return spi_flash_cmd_poll_bit(flash, timeout,
    180017fe:	600c8c93          	addi	s9,s9,1536 # 16e3600 <__stack_size+0x16e2e00>
    18001802:	a891                	j	18001856 <spi_flash_cmd_write_mode+0xa8>
		{
			flags = SPI_XFER_BEGIN;
			if (chunk_len == 0)
				flags |= SPI_XFER_END;

			ret = spi_xfer(spi, 4 * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001804:	6522                	ld	a0,8(sp)
    18001806:	47a1                	li	a5,8
    18001808:	470d                	li	a4,3
    1800180a:	4681                	li	a3,0
    1800180c:	1030                	addi	a2,sp,40
    1800180e:	02000593          	li	a1,32
    18001812:	c5aff0ef          	jal	ra,18000c6c <spi_xfer>
    18001816:	87aa                	mv	a5,a0
			if (ret < 0)
    18001818:	0e054b63          	bltz	a0,1800190e <spi_flash_cmd_write_mode+0x160>
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800181c:	4685                	li	a3,1
    1800181e:	4615                	li	a2,5
    18001820:	85e6                	mv	a1,s9
    18001822:	8526                	mv	a0,s1
    18001824:	bd1ff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
    18001828:	87aa                	mv	a5,a0
			
		    }
		}
        //qspi_mode_ctl(SPI4_DATEMODE_0);
		ret = spi_flash_cmd_wait_ready(flash, SPI_FLASH_PROG_TIMEOUT);
		if (ret < 0)
    1800182a:	0e054263          	bltz	a0,1800190e <spi_flash_cmd_write_mode+0x160>
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800182e:	6088                	ld	a0,0(s1)
    18001830:	4781                	li	a5,0
    18001832:	4701                	li	a4,0
    18001834:	4681                	li	a3,0
    18001836:	4605                	li	a2,1
    18001838:	02710593          	addi	a1,sp,39
    1800183c:	037103a3          	sb	s7,39(sp)
    18001840:	a7fff0ef          	jal	ra,180012be <spi_flash_read_write>
    18001844:	87aa                	mv	a5,a0
		{
			//uart_printf("SF: spi_flash_cmd_wait_ready failed\n");
			break;
		}
		ret = spi_flash_cmd_write_disable(flash->spi);
		if (ret < 0)
    18001846:	0c054463          	bltz	a0,1800190e <spi_flash_cmd_write_mode+0x160>
	for (actual = 0; actual < len; actual += chunk_len)
    1800184a:	0139093b          	addw	s2,s2,s3
		{
			//uart_printf("SF: disable write failed\n");
			break;
		}
         
    	offset += chunk_len;
    1800184e:	0089843b          	addw	s0,s3,s0
	for (actual = 0; actual < len; actual += chunk_len)
    18001852:	0b497e63          	bgeu	s2,s4,1800190e <spi_flash_cmd_write_mode+0x160>
		byte_addr = offset % page_size;
    18001856:	02041813          	slli	a6,s0,0x20
    1800185a:	02085813          	srli	a6,a6,0x20
    1800185e:	03587833          	remu	a6,a6,s5
		chunk_len = min(len - actual, page_size - byte_addr);
    18001862:	412a07bb          	subw	a5,s4,s2
    18001866:	1782                	slli	a5,a5,0x20
    18001868:	9381                	srli	a5,a5,0x20
    1800186a:	410a8db3          	sub	s11,s5,a6
    1800186e:	01b7f363          	bgeu	a5,s11,18001874 <spi_flash_cmd_write_mode+0xc6>
    18001872:	8dbe                	mv	s11,a5
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001874:	00845793          	srli	a5,s0,0x8
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001878:	6088                	ld	a0,0(s1)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    1800187a:	0ff7f793          	andi	a5,a5,255
    1800187e:	00841893          	slli	a7,s0,0x8
    18001882:	00f8e8b3          	or	a7,a7,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001886:	0104531b          	srliw	t1,s0,0x10
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800188a:	4781                	li	a5,0
    1800188c:	4701                	li	a4,0
    1800188e:	4681                	li	a3,0
    18001890:	4605                	li	a2,1
    18001892:	02710593          	addi	a1,sp,39
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001896:	026104a3          	sb	t1,41(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    1800189a:	03111523          	sh	a7,42(sp)
    1800189e:	03a103a3          	sb	s10,39(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    180018a2:	a1dff0ef          	jal	ra,180012be <spi_flash_read_write>
    180018a6:	87aa                	mv	a5,a0
		chunk_len = min(len - actual, page_size - byte_addr);
    180018a8:	000d899b          	sext.w	s3,s11
		if (ret < 0) {
    180018ac:	06054163          	bltz	a0,1800190e <spi_flash_cmd_write_mode+0x160>
	return spi_flash_cmd_status_poll_enable(flash, timeout,
    180018b0:	4689                	li	a3,2
    180018b2:	4615                	li	a2,5
    180018b4:	85e2                	mv	a1,s8
    180018b6:	8526                	mv	a0,s1
    180018b8:	c03ff0ef          	jal	ra,180014ba <spi_flash_cmd_status_poll_enable>
		if (mode == 1)
    180018bc:	4785                	li	a5,1
    180018be:	06fb0863          	beq	s6,a5,1800192e <spi_flash_cmd_write_mode+0x180>
		if (mode == 4)
    180018c2:	f57b1de3          	bne	s6,s7,1800181c <spi_flash_cmd_write_mode+0x6e>
			if (chunk_len == 0)
    180018c6:	f20d8fe3          	beqz	s11,18001804 <spi_flash_cmd_write_mode+0x56>
			ret = spi_xfer(spi, 4 * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018ca:	6522                	ld	a0,8(sp)
    180018cc:	47a1                	li	a5,8
    180018ce:	4705                	li	a4,1
    180018d0:	4681                	li	a3,0
    180018d2:	1030                	addi	a2,sp,40
    180018d4:	02000593          	li	a1,32
    180018d8:	b94ff0ef          	jal	ra,18000c6c <spi_xfer>
    180018dc:	87aa                	mv	a5,a0
			if (ret < 0)
    180018de:	02054863          	bltz	a0,1800190e <spi_flash_cmd_write_mode+0x160>
				ret = spi_xfer(spi, chunk_len * 8, (unsigned char*)buf + actual, NULL, SPI_XFER_END, SPI_DATAMODE_8);
    180018e2:	6542                	ld	a0,16(sp)
    180018e4:	02091613          	slli	a2,s2,0x20
    180018e8:	9201                	srli	a2,a2,0x20
    180018ea:	962a                	add	a2,a2,a0
    180018ec:	6522                	ld	a0,8(sp)
    180018ee:	47a1                	li	a5,8
    180018f0:	0039959b          	slliw	a1,s3,0x3
    180018f4:	4709                	li	a4,2
    180018f6:	4681                	li	a3,0
    180018f8:	b74ff0ef          	jal	ra,18000c6c <spi_xfer>
	return spi_flash_cmd_poll_bit(flash, timeout,
    180018fc:	4685                	li	a3,1
    180018fe:	4615                	li	a2,5
    18001900:	85e6                	mv	a1,s9
    18001902:	8526                	mv	a0,s1
    18001904:	af1ff0ef          	jal	ra,180013f4 <spi_flash_cmd_poll_bit>
    18001908:	87aa                	mv	a5,a0
		if (ret < 0)
    1800190a:	f20552e3          	bgez	a0,1800182e <spi_flash_cmd_write_mode+0x80>
	//uart_printf("SF: program %s %d bytes @ %d\n", ret ? "failure" : "success", len, offset);
    }
	return ret;
}
    1800190e:	60ea                	ld	ra,152(sp)
    18001910:	644a                	ld	s0,144(sp)
    18001912:	64aa                	ld	s1,136(sp)
    18001914:	690a                	ld	s2,128(sp)
    18001916:	79e6                	ld	s3,120(sp)
    18001918:	7a46                	ld	s4,112(sp)
    1800191a:	7aa6                	ld	s5,104(sp)
    1800191c:	7b06                	ld	s6,96(sp)
    1800191e:	6be6                	ld	s7,88(sp)
    18001920:	6c46                	ld	s8,80(sp)
    18001922:	6ca6                	ld	s9,72(sp)
    18001924:	6d06                	ld	s10,64(sp)
    18001926:	7de2                	ld	s11,56(sp)
    18001928:	853e                	mv	a0,a5
    1800192a:	610d                	addi	sp,sp,160
    1800192c:	8082                	ret
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    1800192e:	6642                	ld	a2,16(sp)
    18001930:	6088                	ld	a0,0(s1)
            ret = spi_flash_cmd_write(flash->spi, cmd, 4,
    18001932:	02091693          	slli	a3,s2,0x20
    18001936:	9281                	srli	a3,a3,0x20
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001938:	87ce                	mv	a5,s3
    1800193a:	96b2                	add	a3,a3,a2
    1800193c:	4701                	li	a4,0
    1800193e:	4611                	li	a2,4
    18001940:	102c                	addi	a1,sp,40
    18001942:	97dff0ef          	jal	ra,180012be <spi_flash_read_write>
    18001946:	87aa                	mv	a5,a0
			if (ret < 0) {
    18001948:	ec055ae3          	bgez	a0,1800181c <spi_flash_cmd_write_mode+0x6e>
    1800194c:	b7c9                	j	1800190e <spi_flash_cmd_write_mode+0x160>
	switch (mode){
    1800194e:	4711                	li	a4,4
    18001950:	e8eb19e3          	bne	s6,a4,180017e2 <spi_flash_cmd_write_mode+0x34>
			cmd[0] = CMD_PAGE_PROGRAM_QUAD;
    18001954:	03200813          	li	a6,50
			spi_flash_write_status_bit(flash, 0x00, 0x00, 0, STATUS_QE);
    18001958:	4709                	li	a4,2
    1800195a:	4681                	li	a3,0
    1800195c:	4601                	li	a2,0
    1800195e:	4581                	li	a1,0
    18001960:	ec3e                	sd	a5,24(sp)
			cmd[0] = CMD_PAGE_PROGRAM_QUAD;
    18001962:	03010423          	sb	a6,40(sp)
			spi_flash_write_status_bit(flash, 0x00, 0x00, 0, STATUS_QE);
    18001966:	c59ff0ef          	jal	ra,180015be <spi_flash_write_status_bit>
    1800196a:	67e2                	ld	a5,24(sp)
			break;
    1800196c:	bdb5                	j	180017e8 <spi_flash_cmd_write_mode+0x3a>

000000001800196e <spi_flash_read_common>:
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800196e:	6108                	ld	a0,0(a0)
    18001970:	87ba                	mv	a5,a4
    18001972:	8736                	mv	a4,a3
    18001974:	4681                	li	a3,0
    18001976:	b2a1                	j	180012be <spi_flash_read_write>

0000000018001978 <spi_flash_cmd_read_fast>:
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001978:	0085d793          	srli	a5,a1,0x8
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    1800197c:	6108                	ld	a0,0(a0)
	return ret;
}

int spi_flash_cmd_read_fast(struct spi_flash *flash, u32 offset,
		u32 len, void *data, u32 mode)
{
    1800197e:	1101                	addi	sp,sp,-32
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001980:	00859893          	slli	a7,a1,0x8
    18001984:	0ff7f793          	andi	a5,a5,255
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001988:	0105d81b          	srliw	a6,a1,0x10
	cmd[2] = (addr & 0x0000FF00) >> 8;
    1800198c:	00f8e8b3          	or	a7,a7,a5
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001990:	8736                	mv	a4,a3
    18001992:	87b2                	mv	a5,a2
    18001994:	002c                	addi	a1,sp,8
	u8 cmd[5];

	cmd[0] = CMD_READ_ARRAY_FAST;
    18001996:	432d                	li	t1,11
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    18001998:	4615                	li	a2,5
    1800199a:	4681                	li	a3,0
{
    1800199c:	ec06                	sd	ra,24(sp)
	cmd[0] = CMD_READ_ARRAY_FAST;
    1800199e:	00610423          	sb	t1,8(sp)
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180019a2:	010104a3          	sb	a6,9(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180019a6:	01111523          	sh	a7,10(sp)
	spi_flash_addr(offset, cmd);
	cmd[4] = 0x00;
    180019aa:	00010623          	sb	zero,12(sp)
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
    180019ae:	911ff0ef          	jal	ra,180012be <spi_flash_read_write>

	return spi_flash_read_common(flash, cmd, sizeof(cmd), data, len);
}
    180019b2:	60e2                	ld	ra,24(sp)
    180019b4:	6105                	addi	sp,sp,32
    180019b6:	8082                	ret

00000000180019b8 <spi_flash_read_mode>:

int spi_flash_read_mode(struct spi_flash *flash, u32 offset,
		u32 len, void *data, u32 mode)
{
    180019b8:	7139                	addi	sp,sp,-64
    180019ba:	f822                	sd	s0,48(sp)
    180019bc:	f426                	sd	s1,40(sp)
    180019be:	f04a                	sd	s2,32(sp)
    180019c0:	ec4e                	sd	s3,24(sp)
    180019c2:	fc06                	sd	ra,56(sp)
	int ret;
    int write_data = 0;
    u8 status[2] = {2};
    int i = 0;

	switch (mode)
    180019c4:	4789                	li	a5,2
{
    180019c6:	842e                	mv	s0,a1
    180019c8:	84b2                	mv	s1,a2
    180019ca:	89b6                	mv	s3,a3
	struct spi_slave *spi = flash->spi;
    180019cc:	00053903          	ld	s2,0(a0)
	switch (mode)
    180019d0:	06f70963          	beq	a4,a5,18001a42 <spi_flash_read_mode+0x8a>
    180019d4:	4791                	li	a5,4
    180019d6:	06f70b63          	beq	a4,a5,18001a4c <spi_flash_read_mode+0x94>
	{
		case 1:
			cmd[0] = CMD_READ_ARRAY_FAST;
    180019da:	47ad                	li	a5,11
    180019dc:	00f10423          	sb	a5,8(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180019e0:	00845813          	srli	a6,s0,0x8
    180019e4:	0ff87793          	andi	a5,a6,255
    180019e8:	00841813          	slli	a6,s0,0x8
    180019ec:	00f86833          	or	a6,a6,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180019f0:	0104541b          	srliw	s0,s0,0x10
    
	spi_flash_addr(offset, cmd);
	cmd[4] = 0x00;


    ret = spi_xfer(spi, 5*8, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180019f4:	47a1                	li	a5,8
    180019f6:	4705                	li	a4,1
    180019f8:	4681                	li	a3,0
    180019fa:	0030                	addi	a2,sp,8
    180019fc:	02800593          	li	a1,40
    18001a00:	854a                	mv	a0,s2
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001a02:	008104a3          	sb	s0,9(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001a06:	01011523          	sh	a6,10(sp)
	cmd[4] = 0x00;
    18001a0a:	00010623          	sb	zero,12(sp)
    ret = spi_xfer(spi, 5*8, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    18001a0e:	a5eff0ef          	jal	ra,18000c6c <spi_xfer>
    if (ret < 0)
    18001a12:	02054163          	bltz	a0,18001a34 <spi_flash_read_mode+0x7c>
	{
		//uart_printf("xfer failed\n");
		return ret;
	}
	ret = spi_xfer(spi,  len*8,  NULL, data, SPI_XFER_END, SPI_DATAMODE_8);
    18001a16:	47a1                	li	a5,8
    18001a18:	0034959b          	slliw	a1,s1,0x3
    18001a1c:	4709                	li	a4,2
    18001a1e:	86ce                	mv	a3,s3
    18001a20:	4601                	li	a2,0
    18001a22:	854a                	mv	a0,s2
    18001a24:	a48ff0ef          	jal	ra,18000c6c <spi_xfer>
	if (ret < 0)
    18001a28:	00152793          	slti	a5,a0,1
    18001a2c:	40f007bb          	negw	a5,a5
    18001a30:	8d7d                	and	a0,a0,a5
    18001a32:	2501                	sext.w	a0,a0
		//uart_printf("xfer failed\n");
		return ret;
	}

	return 0;
}
    18001a34:	70e2                	ld	ra,56(sp)
    18001a36:	7442                	ld	s0,48(sp)
    18001a38:	74a2                	ld	s1,40(sp)
    18001a3a:	7902                	ld	s2,32(sp)
    18001a3c:	69e2                	ld	s3,24(sp)
    18001a3e:	6121                	addi	sp,sp,64
    18001a40:	8082                	ret
			cmd[0] = CMD_READ_ARRAY_DUAL;
    18001a42:	03b00793          	li	a5,59
    18001a46:	00f10423          	sb	a5,8(sp)
			break;
    18001a4a:	bf59                	j	180019e0 <spi_flash_read_mode+0x28>
			cmd[0] = CMD_READ_ARRAY_QUAD;
    18001a4c:	06b00793          	li	a5,107
			spi_flash_write_status_bit(flash, 0x00, 0x00, 0, STATUS_QE);
    18001a50:	4709                	li	a4,2
    18001a52:	4681                	li	a3,0
    18001a54:	4601                	li	a2,0
    18001a56:	4581                	li	a1,0
			cmd[0] = CMD_READ_ARRAY_QUAD;
    18001a58:	00f10423          	sb	a5,8(sp)
			spi_flash_write_status_bit(flash, 0x00, 0x00, 0, STATUS_QE);
    18001a5c:	b63ff0ef          	jal	ra,180015be <spi_flash_write_status_bit>
			break;
    18001a60:	b741                	j	180019e0 <spi_flash_read_mode+0x28>

0000000018001a62 <cadence_qspi_apb_exec_flash_cmd>:
	return;
}

static int cadence_qspi_apb_exec_flash_cmd(u32 reg_base,
	unsigned int reg)
{
    18001a62:	7179                	addi	sp,sp,-48
    18001a64:	ec26                	sd	s1,24(sp)
	unsigned int retry = CQSPI_REG_RETRY;

	/* Write the CMDCTRL without start execution. */
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);
    18001a66:	0905049b          	addiw	s1,a0,144
    18001a6a:	1482                	slli	s1,s1,0x20
{
    18001a6c:	e84a                	sd	s2,16(sp)
    18001a6e:	f406                	sd	ra,40(sp)
    18001a70:	f022                	sd	s0,32(sp)
    18001a72:	e44e                	sd	s3,8(sp)
    18001a74:	892a                	mv	s2,a0
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);
    18001a76:	9081                	srli	s1,s1,0x20
    18001a78:	c08c                	sw	a1,0(s1)
	/* Start execute */
	reg |= CQSPI_REG_CMDCTRL_EXECUTE_MASK;
    18001a7a:	0015e593          	ori	a1,a1,1
    18001a7e:	c08c                	sw	a1,0(s1)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001a80:	409c                	lw	a5,0(s1)
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);

	while (retry--) {
		reg = readl((u32)reg_base + CQSPI_REG_CMDCTRL);
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001a82:	8b89                	andi	a5,a5,2
    18001a84:	c78d                	beqz	a5,18001aae <cadence_qspi_apb_exec_flash_cmd+0x4c>
			break;
		delay(1000);
    18001a86:	3e800513          	li	a0,1000
	while (retry--) {
    18001a8a:	6409                	lui	s0,0x2
		delay(1000);
    18001a8c:	7fa000ef          	jal	ra,18002286 <udelay>
	while (retry--) {
    18001a90:	70e40413          	addi	s0,s0,1806 # 270e <__stack_size+0x1f0e>
    18001a94:	59fd                	li	s3,-1
    18001a96:	a031                	j	18001aa2 <cadence_qspi_apb_exec_flash_cmd+0x40>
    18001a98:	347d                	addiw	s0,s0,-1
		delay(1000);
    18001a9a:	7ec000ef          	jal	ra,18002286 <udelay>
	while (retry--) {
    18001a9e:	01340863          	beq	s0,s3,18001aae <cadence_qspi_apb_exec_flash_cmd+0x4c>
    18001aa2:	409c                	lw	a5,0(s1)
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001aa4:	8b89                	andi	a5,a5,2
		delay(1000);
    18001aa6:	3e800513          	li	a0,1000
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001aaa:	f7fd                	bnez	a5,18001a98 <cadence_qspi_apb_exec_flash_cmd+0x36>
	}

	if (!retry) {
    18001aac:	c41d                	beqz	s0,18001ada <cadence_qspi_apb_exec_flash_cmd+0x78>
		//uart_printf("QSPI: flash command execution timeout\n");
		return -1;
	}

	/* Polling QSPI idle status. */
	if (!cadence_qspi_wait_idle(reg_base))
    18001aae:	02091513          	slli	a0,s2,0x20
    18001ab2:	6789                	lui	a5,0x2
    18001ab4:	9101                	srli	a0,a0,0x20
    18001ab6:	71078793          	addi	a5,a5,1808 # 2710 <__stack_size+0x1f10>
    18001aba:	a011                	j	18001abe <cadence_qspi_apb_exec_flash_cmd+0x5c>
		if (count >= CQSPI_REG_RETRY)
    18001abc:	c799                	beqz	a5,18001aca <cadence_qspi_apb_exec_flash_cmd+0x68>
    18001abe:	4118                	lw	a4,0(a0)
		if (CQSPI_REG_IS_IDLE((u32)reg_base))
    18001ac0:	02071693          	slli	a3,a4,0x20
    18001ac4:	37fd                	addiw	a5,a5,-1
    18001ac6:	fe06dbe3          	bgez	a3,18001abc <cadence_qspi_apb_exec_flash_cmd+0x5a>
		return -1;

	return 0;
    18001aca:	4501                	li	a0,0
}
    18001acc:	70a2                	ld	ra,40(sp)
    18001ace:	7402                	ld	s0,32(sp)
    18001ad0:	64e2                	ld	s1,24(sp)
    18001ad2:	6942                	ld	s2,16(sp)
    18001ad4:	69a2                	ld	s3,8(sp)
    18001ad6:	6145                	addi	sp,sp,48
    18001ad8:	8082                	ret
		return -1;
    18001ada:	557d                	li	a0,-1
    18001adc:	bfc5                	j	18001acc <cadence_qspi_apb_exec_flash_cmd+0x6a>

0000000018001ade <cadence_qspi_apb_controller_enable>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001ade:	1502                	slli	a0,a0,0x20
    18001ae0:	9101                	srli	a0,a0,0x20
    18001ae2:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001ae4:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ae8:	c11c                	sw	a5,0(a0)
}
    18001aea:	8082                	ret

0000000018001aec <cadence_qspi_apb_controller_disable>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001aec:	1502                	slli	a0,a0,0x20
    18001aee:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001af0:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001af2:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001af4:	c11c                	sw	a5,0(a0)
}
    18001af6:	8082                	ret

0000000018001af8 <cadence_qspi_apb_readdata_capture>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001af8:	02051713          	slli	a4,a0,0x20
    18001afc:	9301                	srli	a4,a4,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001afe:	431c                	lw	a5,0(a4)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b00:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b02:	c31c                	sw	a5,0(a4)
	reg = readl((u32)reg_base + CQSPI_READLCAPTURE);
    18001b04:	2541                	addiw	a0,a0,16
    18001b06:	1502                	slli	a0,a0,0x20
    18001b08:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b0a:	411c                	lw	a5,0(a0)
	if (bypass)
    18001b0c:	cd99                	beqz	a1,18001b2a <cadence_qspi_apb_readdata_capture+0x32>
		reg |= (1 << CQSPI_READLCAPTURE_BYPASS_LSB);
    18001b0e:	0017e793          	ori	a5,a5,1
    18001b12:	2781                	sext.w	a5,a5
		<< CQSPI_READLCAPTURE_DELAY_LSB);
    18001b14:	0016161b          	slliw	a2,a2,0x1
	reg &= ~(CQSPI_READLCAPTURE_DELAY_MASK
    18001b18:	9b85                	andi	a5,a5,-31
		<< CQSPI_READLCAPTURE_DELAY_LSB);
    18001b1a:	8a79                	andi	a2,a2,30
	reg |= ((delay & CQSPI_READLCAPTURE_DELAY_MASK)
    18001b1c:	8e5d                	or	a2,a2,a5
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b1e:	c110                	sw	a2,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b20:	431c                	lw	a5,0(a4)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b22:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b26:	c31c                	sw	a5,0(a4)
}
    18001b28:	8082                	ret
		reg &= ~(1 << CQSPI_READLCAPTURE_BYPASS_LSB);
    18001b2a:	9bf9                	andi	a5,a5,-2
    18001b2c:	2781                	sext.w	a5,a5
    18001b2e:	b7dd                	j	18001b14 <cadence_qspi_apb_readdata_capture+0x1c>

0000000018001b30 <cadence_qspi_apb_config_baudrate_div>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001b30:	1502                	slli	a0,a0,0x20
    18001b32:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b34:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b36:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b38:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b3a:	4114                	lw	a3,0(a0)
	div = ref_clk_hz / sclk_hz;
    18001b3c:	02c5d7bb          	divuw	a5,a1,a2
	reg &= ~(CQSPI_REG_CONFIG_BAUD_MASK << CQSPI_REG_CONFIG_BAUD_LSB);
    18001b40:	ff880737          	lui	a4,0xff880
    18001b44:	177d                	addi	a4,a4,-1
    18001b46:	8f75                	and	a4,a4,a3
	if (div > 32)
    18001b48:	02000693          	li	a3,32
	reg &= ~(CQSPI_REG_CONFIG_BAUD_MASK << CQSPI_REG_CONFIG_BAUD_LSB);
    18001b4c:	2701                	sext.w	a4,a4
	div = ref_clk_hz / sclk_hz;
    18001b4e:	0007881b          	sext.w	a6,a5
	if (div > 32)
    18001b52:	0306e363          	bltu	a3,a6,18001b78 <cadence_qspi_apb_config_baudrate_div+0x48>
	if ((div & 1)) {
    18001b56:	0017f693          	andi	a3,a5,1
    18001b5a:	0017d79b          	srliw	a5,a5,0x1
    18001b5e:	ce91                	beqz	a3,18001b7a <cadence_qspi_apb_config_baudrate_div+0x4a>
	div = (div & CQSPI_REG_CONFIG_BAUD_MASK) << CQSPI_REG_CONFIG_BAUD_LSB;
    18001b60:	007806b7          	lui	a3,0x780
    18001b64:	0137979b          	slliw	a5,a5,0x13
    18001b68:	8ff5                	and	a5,a5,a3
	reg |= div;
    18001b6a:	8fd9                	or	a5,a5,a4
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b6c:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b6e:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b70:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b74:	c11c                	sw	a5,0(a0)
}
    18001b76:	8082                	ret
    18001b78:	47c1                	li	a5,16
		if (ref_clk_hz % sclk_hz)
    18001b7a:	02c5f5bb          	remuw	a1,a1,a2
    18001b7e:	f1ed                	bnez	a1,18001b60 <cadence_qspi_apb_config_baudrate_div+0x30>
			div = (div / 2) - 1;
    18001b80:	37fd                	addiw	a5,a5,-1
    18001b82:	bff9                	j	18001b60 <cadence_qspi_apb_config_baudrate_div+0x30>

0000000018001b84 <cadence_qspi_apb_set_clk_mode>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001b84:	1502                	slli	a0,a0,0x20
    18001b86:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b88:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b8a:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b8c:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b8e:	411c                	lw	a5,0(a0)
	reg |= ((clk_pol & 0x1) << CQSPI_REG_CONFIG_CLK_POL_LSB);
    18001b90:	0015959b          	slliw	a1,a1,0x1
	reg |= ((clk_pha & 0x1) << CQSPI_REG_CONFIG_CLK_PHA_LSB);
    18001b94:	0026161b          	slliw	a2,a2,0x2
    18001b98:	8a11                	andi	a2,a2,4
	reg &= ~(1 <<
    18001b9a:	9bdd                	andi	a5,a5,-9
	reg |= ((clk_pol & 0x1) << CQSPI_REG_CONFIG_CLK_POL_LSB);
    18001b9c:	8989                	andi	a1,a1,2
	reg &= ~(1 <<
    18001b9e:	2781                	sext.w	a5,a5
	reg |= ((clk_pha & 0x1) << CQSPI_REG_CONFIG_CLK_PHA_LSB);
    18001ba0:	8dd1                	or	a1,a1,a2
    18001ba2:	8ddd                	or	a1,a1,a5
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ba4:	c10c                	sw	a1,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001ba6:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001ba8:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001bac:	c11c                	sw	a5,0(a0)
}
    18001bae:	8082                	ret

0000000018001bb0 <cadence_qspi_apb_chipselect>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001bb0:	1502                	slli	a0,a0,0x20
    18001bb2:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001bb4:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001bb6:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001bb8:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001bba:	411c                	lw	a5,0(a0)
	if (decoder_enable) {
    18001bbc:	c60d                	beqz	a2,18001be6 <cadence_qspi_apb_chipselect+0x36>
		reg |= CQSPI_REG_CONFIG_DECODE_MASK;
    18001bbe:	2007e793          	ori	a5,a5,512
    18001bc2:	2781                	sext.w	a5,a5
	reg &= ~(CQSPI_REG_CONFIG_CHIPSELECT_MASK
    18001bc4:	7771                	lui	a4,0xffffc
    18001bc6:	3ff70713          	addi	a4,a4,1023 # ffffffffffffc3ff <_sp+0xffffffffe7fea2a7>
    18001bca:	8ff9                	and	a5,a5,a4
			<< CQSPI_REG_CONFIG_CHIPSELECT_LSB;
    18001bcc:	6711                	lui	a4,0x4
    18001bce:	c0070713          	addi	a4,a4,-1024 # 3c00 <__stack_size+0x3400>
    18001bd2:	00a5959b          	slliw	a1,a1,0xa
    18001bd6:	8df9                	and	a1,a1,a4
	reg |= (chip_select & CQSPI_REG_CONFIG_CHIPSELECT_MASK)
    18001bd8:	8ddd                	or	a1,a1,a5
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001bda:	c10c                	sw	a1,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001bdc:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001bde:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001be2:	c11c                	sw	a5,0(a0)
}
    18001be4:	8082                	ret
		chip_select = 0xF & ~(1 << chip_select);
    18001be6:	4705                	li	a4,1
    18001be8:	00b715bb          	sllw	a1,a4,a1
		reg &= ~CQSPI_REG_CONFIG_DECODE_MASK;
    18001bec:	dff7f793          	andi	a5,a5,-513
		chip_select = 0xF & ~(1 << chip_select);
    18001bf0:	fff5c593          	not	a1,a1
		reg &= ~CQSPI_REG_CONFIG_DECODE_MASK;
    18001bf4:	2781                	sext.w	a5,a5
		chip_select = 0xF & ~(1 << chip_select);
    18001bf6:	89bd                	andi	a1,a1,15
    18001bf8:	b7f1                	j	18001bc4 <cadence_qspi_apb_chipselect+0x14>

0000000018001bfa <cadence_qspi_apb_delay>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001bfa:	02051793          	slli	a5,a0,0x20
    18001bfe:	9381                	srli	a5,a5,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c00:	4398                	lw	a4,0(a5)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c02:	9b79                	andi	a4,a4,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c04:	c398                	sw	a4,0(a5)
	writel(reg, (u32)reg_base + CQSPI_REG_DELAY);
    18001c06:	2531                	addiw	a0,a0,12
    18001c08:	1502                	slli	a0,a0,0x20
    18001c0a:	01010737          	lui	a4,0x1010
    18001c0e:	9101                	srli	a0,a0,0x20
    18001c10:	1017071b          	addiw	a4,a4,257
    18001c14:	c118                	sw	a4,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c16:	4398                	lw	a4,0(a5)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c18:	00176713          	ori	a4,a4,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c1c:	c398                	sw	a4,0(a5)
}
    18001c1e:	8082                	ret

0000000018001c20 <cadence_qspi_apb_controller_init>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001c20:	651c                	ld	a5,8(a0)
    18001c22:	02079613          	slli	a2,a5,0x20
    18001c26:	9201                	srli	a2,a2,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c28:	421c                	lw	a5,0(a2)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c2a:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c2c:	c21c                	sw	a5,0(a2)
	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    18001c2e:	651c                	ld	a5,8(a0)
    18001c30:	2781                	sext.w	a5,a5
    18001c32:	0147859b          	addiw	a1,a5,20
    18001c36:	1582                	slli	a1,a1,0x20
    18001c38:	9181                	srli	a1,a1,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c3a:	0005a883          	lw	a7,0(a1)
	reg |= (plat->page_size << CQSPI_REG_SIZE_PAGE_LSB);
    18001c3e:	4d58                	lw	a4,28(a0)
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c40:	02052803          	lw	a6,32(a0)
	reg &= ~(CQSPI_REG_SIZE_BLOCK_MASK << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c44:	ffc006b7          	lui	a3,0xffc00
    18001c48:	06bd                	addi	a3,a3,15
    18001c4a:	0116f6b3          	and	a3,a3,a7
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c4e:	0108181b          	slliw	a6,a6,0x10
	reg |= (plat->page_size << CQSPI_REG_SIZE_PAGE_LSB);
    18001c52:	0047171b          	slliw	a4,a4,0x4
	reg &= ~(CQSPI_REG_SIZE_BLOCK_MASK << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c56:	2681                	sext.w	a3,a3
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c58:	01076733          	or	a4,a4,a6
    18001c5c:	8f55                	or	a4,a4,a3
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c5e:	c198                	sw	a4,0(a1)
	writel(0,(u32) plat->regbase + CQSPI_REG_REMAP);
    18001c60:	0247871b          	addiw	a4,a5,36
    18001c64:	1702                	slli	a4,a4,0x20
    18001c66:	4581                	li	a1,0
    18001c68:	9301                	srli	a4,a4,0x20
    18001c6a:	c30c                	sw	a1,0(a4)
	writel((plat->sram_size/2), (u32)plat->regbase + CQSPI_REG_SRAMPARTITION);
    18001c6c:	5958                	lw	a4,52(a0)
    18001c6e:	0187869b          	addiw	a3,a5,24
    18001c72:	1682                	slli	a3,a3,0x20
    18001c74:	9281                	srli	a3,a3,0x20
    18001c76:	0017571b          	srliw	a4,a4,0x1
    18001c7a:	c298                	sw	a4,0(a3)
	writel(0, (u32)plat->regbase + CQSPI_REG_IRQMASK);
    18001c7c:	0447879b          	addiw	a5,a5,68
    18001c80:	1782                	slli	a5,a5,0x20
    18001c82:	9381                	srli	a5,a5,0x20
    18001c84:	c38c                	sw	a1,0(a5)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c86:	421c                	lw	a5,0(a2)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c88:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c8c:	c21c                	sw	a5,0(a2)
}
    18001c8e:	8082                	ret

0000000018001c90 <cadence_qspi_apb_command_read>:

/* For command RDID, RDSR. */
int cadence_qspi_apb_command_read(void * reg_base,
	unsigned int cmdlen, const u8 *cmdbuf, unsigned int rxlen,
	u8 *rxbuf)
{
    18001c90:	7139                	addi	sp,sp,-64
    18001c92:	fc06                	sd	ra,56(sp)
    18001c94:	f822                	sd	s0,48(sp)
    18001c96:	f426                	sd	s1,40(sp)
    18001c98:	f04a                	sd	s2,32(sp)
    18001c9a:	ec4e                	sd	s3,24(sp)
    18001c9c:	e852                	sd	s4,16(sp)
	unsigned int reg;
	unsigned int read_len;
	int status;

	if (!cmdlen || rxlen > CQSPI_STIG_DATA_LEN_MAX || rxbuf == NULL) {
    18001c9e:	cdc9                	beqz	a1,18001d38 <cadence_qspi_apb_command_read+0xa8>
    18001ca0:	47a1                	li	a5,8
    18001ca2:	08d7eb63          	bltu	a5,a3,18001d38 <cadence_qspi_apb_command_read+0xa8>
    18001ca6:	cb49                	beqz	a4,18001d38 <cadence_qspi_apb_command_read+0xa8>
    18001ca8:	84ba                	mv	s1,a4
		//uart_printf("QSPI: Invalid input arguments cmdlen %d rxlen %d\n",
		       //cmdlen, rxlen);
		return -1;
	}

	reg = cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001caa:	00064703          	lbu	a4,0(a2)

	reg |= (0x1 << CQSPI_REG_CMDCTRL_RD_EN_LSB);

	/* 0 means 1 byte. */
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cae:	fff6879b          	addiw	a5,a3,-1
    18001cb2:	8936                	mv	s2,a3
		<< CQSPI_REG_CMDCTRL_RD_BYTES_LSB);
    18001cb4:	0147979b          	slliw	a5,a5,0x14
    18001cb8:	007006b7          	lui	a3,0x700
    18001cbc:	8ff5                	and	a5,a5,a3
	reg = cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001cbe:	0187171b          	slliw	a4,a4,0x18
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cc2:	8fd9                	or	a5,a5,a4
    18001cc4:	00800737          	lui	a4,0x800
    18001cc8:	8fd9                	or	a5,a5,a4
    18001cca:	2781                	sext.w	a5,a5
	status = cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001ccc:	0005041b          	sext.w	s0,a0
    18001cd0:	85be                	mv	a1,a5
    18001cd2:	8522                	mv	a0,s0
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cd4:	c63e                	sw	a5,12(sp)
	status = cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001cd6:	d8dff0ef          	jal	ra,18001a62 <cadence_qspi_apb_exec_flash_cmd>
    18001cda:	89aa                	mv	s3,a0
	if (status != 0)
    18001cdc:	c911                	beqz	a0,18001cf0 <cadence_qspi_apb_command_read+0x60>

		read_len = rxlen - read_len;
		sys_memcpy(rxbuf, &reg, read_len);
	}
	return 0;
}
    18001cde:	70e2                	ld	ra,56(sp)
    18001ce0:	7442                	ld	s0,48(sp)
    18001ce2:	854e                	mv	a0,s3
    18001ce4:	74a2                	ld	s1,40(sp)
    18001ce6:	7902                	ld	s2,32(sp)
    18001ce8:	69e2                	ld	s3,24(sp)
    18001cea:	6a42                	ld	s4,16(sp)
    18001cec:	6121                	addi	sp,sp,64
    18001cee:	8082                	ret
	reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATALOWER);
    18001cf0:	0a04079b          	addiw	a5,s0,160
    18001cf4:	1782                	slli	a5,a5,0x20
    18001cf6:	9381                	srli	a5,a5,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001cf8:	439c                	lw	a5,0(a5)
	read_len = (rxlen > 4) ? 4 : rxlen;
    18001cfa:	4711                	li	a4,4
	reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATALOWER);
    18001cfc:	c63e                	sw	a5,12(sp)
	read_len = (rxlen > 4) ? 4 : rxlen;
    18001cfe:	8a4a                	mv	s4,s2
    18001d00:	01277363          	bgeu	a4,s2,18001d06 <cadence_qspi_apb_command_read+0x76>
    18001d04:	4a11                	li	s4,4
	sys_memcpy(rxbuf, &reg, read_len);
    18001d06:	000a061b          	sext.w	a2,s4
    18001d0a:	006c                	addi	a1,sp,12
    18001d0c:	8526                	mv	a0,s1
    18001d0e:	e77fe0ef          	jal	ra,18000b84 <sys_memcpy>
	if (rxlen > 4) {
    18001d12:	4791                	li	a5,4
    18001d14:	fd27f5e3          	bgeu	a5,s2,18001cde <cadence_qspi_apb_command_read+0x4e>
		reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATAUPPER);
    18001d18:	0a44041b          	addiw	s0,s0,164
    18001d1c:	1402                	slli	s0,s0,0x20
    18001d1e:	9001                	srli	s0,s0,0x20
    18001d20:	4000                	lw	s0,0(s0)
	rxbuf += read_len;
    18001d22:	020a1513          	slli	a0,s4,0x20
    18001d26:	9101                	srli	a0,a0,0x20
		sys_memcpy(rxbuf, &reg, read_len);
    18001d28:	4149063b          	subw	a2,s2,s4
    18001d2c:	006c                	addi	a1,sp,12
    18001d2e:	9526                	add	a0,a0,s1
		reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATAUPPER);
    18001d30:	c622                	sw	s0,12(sp)
		sys_memcpy(rxbuf, &reg, read_len);
    18001d32:	e53fe0ef          	jal	ra,18000b84 <sys_memcpy>
    18001d36:	b765                	j	18001cde <cadence_qspi_apb_command_read+0x4e>
		return -1;
    18001d38:	59fd                	li	s3,-1
    18001d3a:	b755                	j	18001cde <cadence_qspi_apb_command_read+0x4e>

0000000018001d3c <cadence_qspi_apb_command_write>:
	unsigned int reg = 0;
	unsigned int addr_value;
	unsigned int wr_data;
	unsigned int wr_len;

	if (!cmdlen || cmdlen > 5 || txlen > 8 || cmdbuf == NULL) {
    18001d3c:	fff5881b          	addiw	a6,a1,-1
    18001d40:	4791                	li	a5,4
    18001d42:	1107e063          	bltu	a5,a6,18001e42 <cadence_qspi_apb_command_write+0x106>
    18001d46:	47a1                	li	a5,8
    18001d48:	0ed7ed63          	bltu	a5,a3,18001e42 <cadence_qspi_apb_command_write+0x106>
    18001d4c:	0e060b63          	beqz	a2,18001e42 <cadence_qspi_apb_command_write+0x106>
{
    18001d50:	7139                	addi	sp,sp,-64
    18001d52:	f822                	sd	s0,48(sp)
    18001d54:	ec4e                	sd	s3,24(sp)
    18001d56:	fc06                	sd	ra,56(sp)
    18001d58:	f426                	sd	s1,40(sp)
    18001d5a:	f04a                	sd	s2,32(sp)
    18001d5c:	e852                	sd	s4,16(sp)
		//uart_printf("QSPI: Invalid input arguments cmdlen %d txlen %d\n",
		       //cmdlen, txlen);
		return -1;
	}

	reg |= cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001d5e:	00064803          	lbu	a6,0(a2)

	if (cmdlen == 4 || cmdlen == 5) {
    18001d62:	ffc5879b          	addiw	a5,a1,-4
    18001d66:	4885                	li	a7,1
	reg |= cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001d68:	0188181b          	slliw	a6,a6,0x18
    18001d6c:	0008041b          	sext.w	s0,a6
	if (cmdlen == 4 || cmdlen == 5) {
    18001d70:	0005099b          	sext.w	s3,a0
    18001d74:	02f8f163          	bgeu	a7,a5,18001d96 <cadence_qspi_apb_command_write+0x5a>
    18001d78:	893a                	mv	s2,a4
    18001d7a:	84b6                	mv	s1,a3
			cmdlen >= 5 ? 4 : 3);

		writel(addr_value, (u32)reg_base + CQSPI_REG_CMDADDRESS);
	}

	if (txlen) {
    18001d7c:	e6b5                	bnez	a3,18001de8 <cadence_qspi_apb_command_write+0xac>
				CQSPI_REG_CMDWRITEDATAUPPER);
		}
	}

	/* Execute the command */
	return cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001d7e:	85a2                	mv	a1,s0
    18001d80:	854e                	mv	a0,s3
    18001d82:	ce1ff0ef          	jal	ra,18001a62 <cadence_qspi_apb_exec_flash_cmd>
}
    18001d86:	70e2                	ld	ra,56(sp)
    18001d88:	7442                	ld	s0,48(sp)
    18001d8a:	74a2                	ld	s1,40(sp)
    18001d8c:	7902                	ld	s2,32(sp)
    18001d8e:	69e2                	ld	s3,24(sp)
    18001d90:	6a42                	ld	s4,16(sp)
    18001d92:	6121                	addi	sp,sp,64
    18001d94:	8082                	ret
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001d96:	00264783          	lbu	a5,2(a2)
    18001d9a:	00164503          	lbu	a0,1(a2)
    18001d9e:	ffe5841b          	addiw	s0,a1,-2
			<< CQSPI_REG_CMDCTRL_ADD_BYTES_LSB;
    18001da2:	0104141b          	slliw	s0,s0,0x10
    18001da6:	00364883          	lbu	a7,3(a2)
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001daa:	01046433          	or	s0,s0,a6
    18001dae:	0105151b          	slliw	a0,a0,0x10
    18001db2:	0087979b          	slliw	a5,a5,0x8
    18001db6:	00080837          	lui	a6,0x80
    18001dba:	8fc9                	or	a5,a5,a0
    18001dbc:	01046433          	or	s0,s0,a6
		addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1],
    18001dc0:	4515                	li	a0,5
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001dc2:	2401                	sext.w	s0,s0
		addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1],
    18001dc4:	0117e7b3          	or	a5,a5,a7
    18001dc8:	00a59863          	bne	a1,a0,18001dd8 <cadence_qspi_apb_command_write+0x9c>
		addr = (addr << 8) | addr_buf[3];
    18001dcc:	00464603          	lbu	a2,4(a2)
    18001dd0:	0087979b          	slliw	a5,a5,0x8
    18001dd4:	8fd1                	or	a5,a5,a2
    18001dd6:	2781                	sext.w	a5,a5
		writel(addr_value, (u32)reg_base + CQSPI_REG_CMDADDRESS);
    18001dd8:	0949861b          	addiw	a2,s3,148
    18001ddc:	1602                	slli	a2,a2,0x20
    18001dde:	9201                	srli	a2,a2,0x20
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001de0:	c21c                	sw	a5,0(a2)
    18001de2:	893a                	mv	s2,a4
    18001de4:	84b6                	mv	s1,a3
	if (txlen) {
    18001de6:	dec1                	beqz	a3,18001d7e <cadence_qspi_apb_command_write+0x42>
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001de8:	fff6879b          	addiw	a5,a3,-1
			<< CQSPI_REG_CMDCTRL_WR_BYTES_LSB;
    18001dec:	00c7979b          	slliw	a5,a5,0xc
    18001df0:	8c5d                	or	s0,s0,a5
    18001df2:	2401                	sext.w	s0,s0
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001df4:	6721                	lui	a4,0x8
		wr_len = txlen > 4 ? 4 : txlen;
    18001df6:	4791                	li	a5,4
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001df8:	8c59                	or	s0,s0,a4
		wr_len = txlen > 4 ? 4 : txlen;
    18001dfa:	8a36                	mv	s4,a3
    18001dfc:	04d7e163          	bltu	a5,a3,18001e3e <cadence_qspi_apb_command_write+0x102>
		sys_memcpy(&wr_data, txbuf, wr_len);
    18001e00:	000a061b          	sext.w	a2,s4
    18001e04:	85ca                	mv	a1,s2
    18001e06:	0068                	addi	a0,sp,12
    18001e08:	d7dfe0ef          	jal	ra,18000b84 <sys_memcpy>
		writel(wr_data, (u32)reg_base +
    18001e0c:	0a89879b          	addiw	a5,s3,168
    18001e10:	1782                	slli	a5,a5,0x20
    18001e12:	9381                	srli	a5,a5,0x20
    18001e14:	4732                	lw	a4,12(sp)
    18001e16:	c398                	sw	a4,0(a5)
		if (txlen > 4) {
    18001e18:	4791                	li	a5,4
    18001e1a:	f697f2e3          	bgeu	a5,s1,18001d7e <cadence_qspi_apb_command_write+0x42>
			txbuf += wr_len;
    18001e1e:	020a1593          	slli	a1,s4,0x20
    18001e22:	9181                	srli	a1,a1,0x20
			sys_memcpy(&wr_data, txbuf, wr_len);
    18001e24:	4144863b          	subw	a2,s1,s4
    18001e28:	95ca                	add	a1,a1,s2
    18001e2a:	0068                	addi	a0,sp,12
    18001e2c:	d59fe0ef          	jal	ra,18000b84 <sys_memcpy>
			writel(wr_data, (u32)reg_base +
    18001e30:	0ac9879b          	addiw	a5,s3,172
    18001e34:	1782                	slli	a5,a5,0x20
    18001e36:	9381                	srli	a5,a5,0x20
    18001e38:	4732                	lw	a4,12(sp)
    18001e3a:	c398                	sw	a4,0(a5)
    18001e3c:	b789                	j	18001d7e <cadence_qspi_apb_command_write+0x42>
		wr_len = txlen > 4 ? 4 : txlen;
    18001e3e:	4a11                	li	s4,4
    18001e40:	b7c1                	j	18001e00 <cadence_qspi_apb_command_write+0xc4>
		return -1;
    18001e42:	557d                	li	a0,-1
}
    18001e44:	8082                	ret

0000000018001e46 <cadence_qspi_apb_indirect_read_setup>:
	 * which always expecting 1 dummy byte, 1 cmd byte and 3/4 addr byte.
	 * With that, the length is in value of 5 or 6. Only FRAM chip from
	 * ramtron using normal read (which won't need dummy byte).
	 * Unlikely NOR flash using normal read due to performance issue.
	 */
	if (cmdlen >= 5)
    18001e46:	4791                	li	a5,4
    18001e48:	08b7ef63          	bltu	a5,a1,18001ee6 <cadence_qspi_apb_indirect_read_setup+0xa0>
    18001e4c:	fff5881b          	addiw	a6,a1,-1
    18001e50:	4581                	li	a1,0
		/* for normal read (only ramtron as of now) */
		addr_bytes = cmdlen - 1;

	/* Setup the indirect trigger address */
	writel(((u32)plat->ahbbase & CQSPI_INDIRECTTRIGGER_ADDR_MASK),
	       (u32)plat->regbase + CQSPI_REG_INDIRECTTRIGGER);
    18001e52:	451c                	lw	a5,8(a0)
    18001e54:	4701                	li	a4,0
    18001e56:	01c7869b          	addiw	a3,a5,28
    18001e5a:	1682                	slli	a3,a3,0x20
    18001e5c:	9281                	srli	a3,a3,0x20
    18001e5e:	c298                	sw	a4,0(a3)

	/* Configure the opcode */
	rd_reg = cmdbuf[0] << CQSPI_REG_RD_INSTR_OPCODE_LSB;
    18001e60:	00064703          	lbu	a4,0(a2)
    if(plat->bit_mode == 4)
    18001e64:	03852883          	lw	a7,56(a0)
    18001e68:	4511                	li	a0,4
	rd_reg = cmdbuf[0] << CQSPI_REG_RD_INSTR_OPCODE_LSB;
    18001e6a:	0007069b          	sext.w	a3,a4
    if(plat->bit_mode == 4)
    18001e6e:	00a89563          	bne	a7,a0,18001e78 <cadence_qspi_apb_indirect_read_setup+0x32>
    {
	    /* Instruction and address at DQ0, data at DQ0-3. */
	    rd_reg |= CQSPI_INST_TYPE_QUAD << CQSPI_REG_RD_INSTR_TYPE_DATA_LSB;
    18001e72:	000206b7          	lui	a3,0x20
    18001e76:	8ed9                	or	a3,a3,a4
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001e78:	00164703          	lbu	a4,1(a2)
    18001e7c:	00264503          	lbu	a0,2(a2)
    18001e80:	00364883          	lbu	a7,3(a2)
    18001e84:	0107171b          	slliw	a4,a4,0x10
    18001e88:	0085151b          	slliw	a0,a0,0x8
    18001e8c:	8f49                	or	a4,a4,a0
	if (addr_width == 4)
    18001e8e:	4511                	li	a0,4
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001e90:	01176733          	or	a4,a4,a7
	if (addr_width == 4)
    18001e94:	00a81863          	bne	a6,a0,18001ea4 <cadence_qspi_apb_indirect_read_setup+0x5e>
		addr = (addr << 8) | addr_buf[3];
    18001e98:	00464603          	lbu	a2,4(a2)
    18001e9c:	0087171b          	slliw	a4,a4,0x8
    18001ea0:	8f51                	or	a4,a4,a2
    18001ea2:	2701                	sext.w	a4,a4
    {
        rd_reg &= ~(CQSPI_INST_TYPE_QUAD << CQSPI_REG_RD_INSTR_TYPE_DATA_LSB);
    }
	/* Get address */
	addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1], addr_bytes);
	writel(addr_value, (u32)plat->regbase + CQSPI_REG_INDIRECTRDSTARTADDR);
    18001ea4:	0687861b          	addiw	a2,a5,104
    18001ea8:	1602                	slli	a2,a2,0x20
    18001eaa:	9201                	srli	a2,a2,0x20
    18001eac:	c218                	sw	a4,0(a2)

	/* The remaining lenght is dummy bytes. */
	dummy_bytes = cmdlen - addr_bytes - 1;
	if (dummy_bytes) {
    18001eae:	c999                	beqz	a1,18001ec4 <cadence_qspi_apb_indirect_read_setup+0x7e>

		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
#if defined(CONFIG_SPL_SPI_XIP) && defined(CONFIG_SPL_BUILD)
		writel(0x0, plat->regbase + CQSPI_REG_MODE_BIT);
#else
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001eb0:	0287861b          	addiw	a2,a5,40
		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
    18001eb4:	00100737          	lui	a4,0x100
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001eb8:	1602                	slli	a2,a2,0x20
		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
    18001eba:	8ed9                	or	a3,a3,a4
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001ebc:	9201                	srli	a2,a2,0x20
    18001ebe:	0ff00713          	li	a4,255
    18001ec2:	c218                	sw	a4,0(a2)
		if (dummy_clk)
			rd_reg |= (dummy_clk & CQSPI_REG_RD_INSTR_DUMMY_MASK)
				<< CQSPI_REG_RD_INSTR_DUMMY_LSB;
	}

	writel(rd_reg, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
    18001ec4:	0047861b          	addiw	a2,a5,4
    18001ec8:	1602                	slli	a2,a2,0x20
    18001eca:	9201                	srli	a2,a2,0x20
    18001ecc:	c214                	sw	a3,0(a2)
	//writel(0x0012006b, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
	//writel(0x041220eb, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
	/* set device size */
	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    18001ece:	27d1                	addiw	a5,a5,20
    18001ed0:	1782                	slli	a5,a5,0x20
    18001ed2:	9381                	srli	a5,a5,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001ed4:	438c                	lw	a1,0(a5)
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    18001ed6:	99c1                	andi	a1,a1,-16
	reg |= (addr_bytes - 1);
    18001ed8:	fff8071b          	addiw	a4,a6,-1
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    18001edc:	2581                	sext.w	a1,a1
	reg |= (addr_bytes - 1);
    18001ede:	8dd9                	or	a1,a1,a4
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ee0:	c38c                	sw	a1,0(a5)
	writel(reg, (u32)plat->regbase + CQSPI_REG_SIZE);
	return 0;
}
    18001ee2:	4501                	li	a0,0
    18001ee4:	8082                	ret
		addr_bytes = cmdlen - 2;
    18001ee6:	ffe5881b          	addiw	a6,a1,-2
    18001eea:	4585                	li	a1,1
    18001eec:	b79d                	j	18001e52 <cadence_qspi_apb_indirect_read_setup+0xc>

0000000018001eee <cadence_qspi_apb_indirect_read_execute>:

int cadence_qspi_apb_indirect_read_execute(struct cadence_spi_platdata *plat,
	unsigned int rxlen, u8 *rxbuf)
{
    18001eee:	7159                	addi	sp,sp,-112
    18001ef0:	f0a2                	sd	s0,96(sp)
	unsigned int reg;

	writel(rxlen, (u32)plat->regbase + CQSPI_REG_INDIRECTRDBYTES);
    18001ef2:	4500                	lw	s0,8(a0)
{
    18001ef4:	f486                	sd	ra,104(sp)
    18001ef6:	eca6                	sd	s1,88(sp)
	writel(rxlen, (u32)plat->regbase + CQSPI_REG_INDIRECTRDBYTES);
    18001ef8:	06c4079b          	addiw	a5,s0,108
    18001efc:	1782                	slli	a5,a5,0x20
{
    18001efe:	e8ca                	sd	s2,80(sp)
    18001f00:	e4ce                	sd	s3,72(sp)
    18001f02:	e0d2                	sd	s4,64(sp)
    18001f04:	fc56                	sd	s5,56(sp)
    18001f06:	f85a                	sd	s6,48(sp)
    18001f08:	f45e                	sd	s7,40(sp)
    18001f0a:	f062                	sd	s8,32(sp)
    18001f0c:	ec66                	sd	s9,24(sp)
	writel(rxlen, (u32)plat->regbase + CQSPI_REG_INDIRECTRDBYTES);
    18001f0e:	9381                	srli	a5,a5,0x20
    18001f10:	c38c                	sw	a1,0(a5)

	/* Start the indirect read transfer */
	writel(CQSPI_REG_INDIRECTRD_START_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
    18001f12:	0604079b          	addiw	a5,s0,96
    18001f16:	1782                	slli	a5,a5,0x20
    18001f18:	9381                	srli	a5,a5,0x20
    18001f1a:	4705                	li	a4,1
    18001f1c:	c398                	sw	a4,0(a5)

	if (qspi_read_sram_fifo_poll(plat->regbase, (void *)rxbuf,
				     (const void *)plat->ahbbase, rxlen))
    18001f1e:	01053a83          	ld	s5,16(a0)
	while (remaining > 0) {
    18001f22:	cde1                	beqz	a1,18001ffa <cadence_qspi_apb_indirect_read_execute+0x10c>
    18001f24:	02c4041b          	addiw	s0,s0,44
    18001f28:	1402                	slli	s0,s0,0x20
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f2a:	6941                	lui	s2,0x10
		while (retry--) {
    18001f2c:	6a09                	lui	s4,0x2
    18001f2e:	89aa                	mv	s3,a0
    18001f30:	84ae                	mv	s1,a1
    18001f32:	8cb2                	mv	s9,a2
    18001f34:	9001                	srli	s0,s0,0x20
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f36:	197d                	addi	s2,s2,-1
		while (retry--) {
    18001f38:	70ea0a13          	addi	s4,s4,1806 # 270e <__stack_size+0x1f0e>
    18001f3c:	5bfd                	li	s7,-1
	while (remaining >= 4) {
    18001f3e:	4b0d                	li	s6,3
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001f40:	401c                	lw	a5,0(s0)
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f42:	00f977b3          	and	a5,s2,a5
    18001f46:	2781                	sext.w	a5,a5
			if (sram_level)
    18001f48:	e78d                	bnez	a5,18001f72 <cadence_qspi_apb_indirect_read_execute+0x84>
			delay(100);
    18001f4a:	06400513          	li	a0,100
    18001f4e:	338000ef          	jal	ra,18002286 <udelay>
		while (retry--) {
    18001f52:	8c52                	mv	s8,s4
    18001f54:	a031                	j	18001f60 <cadence_qspi_apb_indirect_read_execute+0x72>
    18001f56:	3c7d                	addiw	s8,s8,-1
			delay(100);
    18001f58:	32e000ef          	jal	ra,18002286 <udelay>
		while (retry--) {
    18001f5c:	077c0863          	beq	s8,s7,18001fcc <cadence_qspi_apb_indirect_read_execute+0xde>
    18001f60:	401c                	lw	a5,0(s0)
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f62:	00f977b3          	and	a5,s2,a5
    18001f66:	2781                	sext.w	a5,a5
			delay(100);
    18001f68:	06400513          	li	a0,100
			if (sram_level)
    18001f6c:	d7ed                	beqz	a5,18001f56 <cadence_qspi_apb_indirect_read_execute+0x68>
		if (!retry) {
    18001f6e:	0a0c0b63          	beqz	s8,18002024 <cadence_qspi_apb_indirect_read_execute+0x136>
		sram_level *= CQSPI_FIFO_WIDTH;
    18001f72:	0027979b          	slliw	a5,a5,0x2
		sram_level = sram_level > remaining ? remaining : sram_level;
    18001f76:	0007871b          	sext.w	a4,a5
    18001f7a:	00e4f363          	bgeu	s1,a4,18001f80 <cadence_qspi_apb_indirect_read_execute+0x92>
    18001f7e:	87a6                	mv	a5,s1
    18001f80:	02079c13          	slli	s8,a5,0x20
    18001f84:	020c5c13          	srli	s8,s8,0x20
    18001f88:	0007861b          	sext.w	a2,a5
	while (remaining >= 4) {
    18001f8c:	9c66                	add	s8,s8,s9
    18001f8e:	9c9d                	subw	s1,s1,a5
    18001f90:	04cb7363          	bgeu	s6,a2,18001fd6 <cadence_qspi_apb_indirect_read_execute+0xe8>
    18001f94:	37f1                	addiw	a5,a5,-4
    18001f96:	0027d79b          	srliw	a5,a5,0x2
    18001f9a:	02079513          	slli	a0,a5,0x20
    18001f9e:	9101                	srli	a0,a0,0x20
    18001fa0:	0505                	addi	a0,a0,1
    18001fa2:	050a                	slli	a0,a0,0x2
    18001fa4:	9566                	add	a0,a0,s9
    18001fa6:	000aa703          	lw	a4,0(s5)
		*dest_ptr = readl(src_ptr);
    18001faa:	00eca023          	sw	a4,0(s9)
		dest_ptr++;
    18001fae:	0c91                	addi	s9,s9,4
	while (remaining >= 4) {
    18001fb0:	feac9be3          	bne	s9,a0,18001fa6 <cadence_qspi_apb_indirect_read_execute+0xb8>
    18001fb4:	3671                	addiw	a2,a2,-4
    18001fb6:	0027979b          	slliw	a5,a5,0x2
    18001fba:	9e1d                	subw	a2,a2,a5
	if (remaining) {
    18001fbc:	ee11                	bnez	a2,18001fd8 <cadence_qspi_apb_indirect_read_execute+0xea>
		delay(100);
    18001fbe:	06400513          	li	a0,100
    18001fc2:	2c4000ef          	jal	ra,18002286 <udelay>
	while (remaining > 0) {
    18001fc6:	c485                	beqz	s1,18001fee <cadence_qspi_apb_indirect_read_execute+0x100>
    18001fc8:	8ce2                	mv	s9,s8
    18001fca:	bf9d                	j	18001f40 <cadence_qspi_apb_indirect_read_execute+0x52>
		delay(100);
    18001fcc:	06400513          	li	a0,100
    18001fd0:	2b6000ef          	jal	ra,18002286 <udelay>
    18001fd4:	b7b5                	j	18001f40 <cadence_qspi_apb_indirect_read_execute+0x52>
	while (remaining >= 4) {
    18001fd6:	8566                	mv	a0,s9
    18001fd8:	000aa783          	lw	a5,0(s5)
		sys_memcpy(dest_ptr, &temp, remaining);
    18001fdc:	006c                	addi	a1,sp,12
		temp = readl(src_ptr);
    18001fde:	c63e                	sw	a5,12(sp)
		sys_memcpy(dest_ptr, &temp, remaining);
    18001fe0:	ba5fe0ef          	jal	ra,18000b84 <sys_memcpy>
		delay(100);
    18001fe4:	06400513          	li	a0,100
    18001fe8:	29e000ef          	jal	ra,18002286 <udelay>
	while (remaining > 0) {
    18001fec:	fcf1                	bnez	s1,18001fc8 <cadence_qspi_apb_indirect_read_execute+0xda>
    18001fee:	0089b783          	ld	a5,8(s3)
    18001ff2:	0607879b          	addiw	a5,a5,96
    18001ff6:	1782                	slli	a5,a5,0x20
    18001ff8:	9381                	srli	a5,a5,0x20
    18001ffa:	4398                	lw	a4,0(a5)
		goto failrd;

	/* Check flash indirect controller */
	reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTRD);
	if (!(reg & CQSPI_REG_INDIRECTRD_DONE_MASK)) {
    18001ffc:	02077713          	andi	a4,a4,32
    18002000:	c331                	beqz	a4,18002044 <cadence_qspi_apb_indirect_read_execute+0x156>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18002002:	02000713          	li	a4,32
    18002006:	c398                	sw	a4,0(a5)
	}

	/* Clear indirect completion status */
	writel(CQSPI_REG_INDIRECTRD_DONE_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
	return 0;
    18002008:	4501                	li	a0,0
failrd:
	/* Cancel the indirect read */
	writel(CQSPI_REG_INDIRECTRD_CANCEL_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
	return -1;
}
    1800200a:	70a6                	ld	ra,104(sp)
    1800200c:	7406                	ld	s0,96(sp)
    1800200e:	64e6                	ld	s1,88(sp)
    18002010:	6946                	ld	s2,80(sp)
    18002012:	69a6                	ld	s3,72(sp)
    18002014:	6a06                	ld	s4,64(sp)
    18002016:	7ae2                	ld	s5,56(sp)
    18002018:	7b42                	ld	s6,48(sp)
    1800201a:	7ba2                	ld	s7,40(sp)
    1800201c:	7c02                	ld	s8,32(sp)
    1800201e:	6ce2                	ld	s9,24(sp)
    18002020:	6165                	addi	sp,sp,112
    18002022:	8082                	ret
			printk("fifo_poll timeout.\n");
    18002024:	00000517          	auipc	a0,0x0
    18002028:	3dc50513          	addi	a0,a0,988 # 18002400 <spi_flash_table+0x50>
    1800202c:	b35fe0ef          	jal	ra,18000b60 <printk>
			return -1;
    18002030:	0089b783          	ld	a5,8(s3)
    18002034:	0607879b          	addiw	a5,a5,96
    18002038:	1782                	slli	a5,a5,0x20
    1800203a:	9381                	srli	a5,a5,0x20
    1800203c:	4709                	li	a4,2
    1800203e:	c398                	sw	a4,0(a5)
	return -1;
    18002040:	557d                	li	a0,-1
    18002042:	b7e1                	j	1800200a <cadence_qspi_apb_indirect_read_execute+0x11c>
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002044:	4398                	lw	a4,0(a5)
		goto failrd;
    18002046:	bfdd                	j	1800203c <cadence_qspi_apb_indirect_read_execute+0x14e>

0000000018002048 <cadence_qspi_apb_indirect_write_setup>:
/* Opcode + Address (3/4 bytes) */
int cadence_qspi_apb_indirect_write_setup(struct cadence_spi_platdata *plat,
	unsigned int cmdlen, const u8 *cmdbuf)
{
	unsigned int reg;
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    18002048:	4791                	li	a5,4
    1800204a:	08b7e363          	bltu	a5,a1,180020d0 <cadence_qspi_apb_indirect_write_setup+0x88>

	if (cmdlen < 4 || cmdbuf == NULL) {
    1800204e:	08f59363          	bne	a1,a5,180020d4 <cadence_qspi_apb_indirect_write_setup+0x8c>
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    18002052:	468d                	li	a3,3
	if (cmdlen < 4 || cmdbuf == NULL) {
    18002054:	c241                	beqz	a2,180020d4 <cadence_qspi_apb_indirect_write_setup+0x8c>
		       //cmdlen, (unsigned int)cmdbuf);
		return -1;
	}
	/* Setup the indirect trigger address */
	writel(((u32)plat->ahbbase & CQSPI_INDIRECTTRIGGER_ADDR_MASK),
	       (u32)plat->regbase + CQSPI_REG_INDIRECTTRIGGER);
    18002056:	451c                	lw	a5,8(a0)
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18002058:	4581                	li	a1,0
    1800205a:	01c7871b          	addiw	a4,a5,28
    1800205e:	1702                	slli	a4,a4,0x20
    18002060:	9301                	srli	a4,a4,0x20
    18002062:	c30c                	sw	a1,0(a4)

	/* Configure the opcode */
	reg = cmdbuf[0] << CQSPI_REG_WR_INSTR_OPCODE_LSB;
    18002064:	00064703          	lbu	a4,0(a2)
    if(plat->bit_mode == 4)
    18002068:	03852803          	lw	a6,56(a0)
    1800206c:	4511                	li	a0,4
	reg = cmdbuf[0] << CQSPI_REG_WR_INSTR_OPCODE_LSB;
    1800206e:	0007059b          	sext.w	a1,a4
    if(plat->bit_mode == 4)
    18002072:	00a81563          	bne	a6,a0,1800207c <cadence_qspi_apb_indirect_write_setup+0x34>
    {
	    /* Instruction and address at DQ0, data at DQ0-3. */
	    reg |= CQSPI_INST_TYPE_QUAD << CQSPI_REG_WR_INSTR_TYPE_DATA_LSB;
    18002076:	000205b7          	lui	a1,0x20
    1800207a:	8dd9                	or	a1,a1,a4
    }
    else
    {
        reg &= ~(CQSPI_INST_TYPE_QUAD << CQSPI_REG_WR_INSTR_TYPE_DATA_LSB);
    }
	writel(reg, (u32)plat->regbase + CQSPI_REG_WR_INSTR);
    1800207c:	0087871b          	addiw	a4,a5,8
    18002080:	1702                	slli	a4,a4,0x20
    18002082:	9301                	srli	a4,a4,0x20
    18002084:	c30c                	sw	a1,0(a4)
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18002086:	00164703          	lbu	a4,1(a2)
    1800208a:	00264583          	lbu	a1,2(a2)
    1800208e:	00364503          	lbu	a0,3(a2)
    18002092:	0107171b          	slliw	a4,a4,0x10
    18002096:	0085959b          	slliw	a1,a1,0x8
    1800209a:	8f4d                	or	a4,a4,a1
	if (addr_width == 4)
    1800209c:	4591                	li	a1,4
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    1800209e:	8f49                	or	a4,a4,a0
	if (addr_width == 4)
    180020a0:	00b69863          	bne	a3,a1,180020b0 <cadence_qspi_apb_indirect_write_setup+0x68>
		addr = (addr << 8) | addr_buf[3];
    180020a4:	00464603          	lbu	a2,4(a2)
    180020a8:	0087171b          	slliw	a4,a4,0x8
    180020ac:	8f51                	or	a4,a4,a2
    180020ae:	2701                	sext.w	a4,a4
	//writel(0x00020032, (u32)plat->regbase + CQSPI_REG_WR_INSTR);

	/* Setup write address. */
	reg = cadence_qspi_apb_cmd2addr(&cmdbuf[1], addr_bytes);
	writel(reg, (u32)plat->regbase + CQSPI_REG_INDIRECTWRSTARTADDR);
    180020b0:	0787861b          	addiw	a2,a5,120
    180020b4:	1602                	slli	a2,a2,0x20
    180020b6:	9201                	srli	a2,a2,0x20
    180020b8:	c218                	sw	a4,0(a2)

	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    180020ba:	27d1                	addiw	a5,a5,20
    180020bc:	1782                	slli	a5,a5,0x20
    180020be:	9381                	srli	a5,a5,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180020c0:	4398                	lw	a4,0(a5)
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    180020c2:	9b41                	andi	a4,a4,-16
	reg |= (addr_bytes - 1);
    180020c4:	36fd                	addiw	a3,a3,-1
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    180020c6:	2701                	sext.w	a4,a4
	reg |= (addr_bytes - 1);
    180020c8:	8f55                	or	a4,a4,a3
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180020ca:	c398                	sw	a4,0(a5)
	writel(reg, (u32)plat->regbase + CQSPI_REG_SIZE);
	return 0;
    180020cc:	4501                	li	a0,0
    180020ce:	8082                	ret
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    180020d0:	4691                	li	a3,4
    180020d2:	b749                	j	18002054 <cadence_qspi_apb_indirect_write_setup+0xc>
		return -1;
    180020d4:	557d                	li	a0,-1
}
    180020d6:	8082                	ret

00000000180020d8 <cadence_qspi_apb_indirect_write_execute>:
{
	unsigned int reg = 0;
	unsigned int retry;

	/* Configure the indirect read transfer bytes */
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    180020d8:	451c                	lw	a5,8(a0)
{
    180020da:	7119                	addi	sp,sp,-128
    180020dc:	f8a2                	sd	s0,112(sp)
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    180020de:	07c7871b          	addiw	a4,a5,124
    180020e2:	1702                	slli	a4,a4,0x20
{
    180020e4:	fc86                	sd	ra,120(sp)
    180020e6:	f4a6                	sd	s1,104(sp)
    180020e8:	f0ca                	sd	s2,96(sp)
    180020ea:	ecce                	sd	s3,88(sp)
    180020ec:	e8d2                	sd	s4,80(sp)
    180020ee:	e4d6                	sd	s5,72(sp)
    180020f0:	e0da                	sd	s6,64(sp)
    180020f2:	fc5e                	sd	s7,56(sp)
    180020f4:	f862                	sd	s8,48(sp)
    180020f6:	f466                	sd	s9,40(sp)
    180020f8:	f06a                	sd	s10,32(sp)
    180020fa:	ec6e                	sd	s11,24(sp)
    180020fc:	842a                	mv	s0,a0
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    180020fe:	9301                	srli	a4,a4,0x20
    18002100:	c30c                	sw	a1,0(a4)

	/* Start the indirect write transfer */
	writel(CQSPI_REG_INDIRECTWR_START_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    18002102:	0707871b          	addiw	a4,a5,112
    18002106:	1702                	slli	a4,a4,0x20
    18002108:	9301                	srli	a4,a4,0x20
    1800210a:	4685                	li	a3,1
    1800210c:	c314                	sw	a3,0(a4)
	void *dest_addr = plat->ahbbase;
    1800210e:	02c7899b          	addiw	s3,a5,44
    18002112:	1982                	slli	s3,s3,0x20
	int remaining = num_bytes;
    18002114:	0005849b          	sext.w	s1,a1
	void *dest_addr = plat->ahbbase;
    18002118:	01053a03          	ld	s4,16(a0)
	unsigned int page_size = plat->page_size;
    1800211c:	01c52c03          	lw	s8,28(a0)
	while (remaining > 0) {
    18002120:	0209d993          	srli	s3,s3,0x20
    18002124:	08905763          	blez	s1,180021b2 <cadence_qspi_apb_indirect_write_execute+0xda>
		while (retry--) {
    18002128:	6b89                	lui	s7,0x2
    1800212a:	8932                	mv	s2,a2
    1800212c:	70fb8b93          	addi	s7,s7,1807 # 270f <__stack_size+0x1f0f>
			if (sram_level <= sram_threshold_words)
    18002130:	03200b13          	li	s6,50
		while (retry--) {
    18002134:	5afd                	li	s5,-1
		wr_bytes = (remaining > page_size) ?
    18002136:	8d62                	mv	s10,s8
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002138:	4c8d                	li	s9,3
		while (retry--) {
    1800213a:	87de                	mv	a5,s7
    1800213c:	a021                	j	18002144 <cadence_qspi_apb_indirect_write_execute+0x6c>
    1800213e:	37fd                	addiw	a5,a5,-1
    18002140:	01578a63          	beq	a5,s5,18002154 <cadence_qspi_apb_indirect_write_execute+0x7c>
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002144:	0009a703          	lw	a4,0(s3)
			if (sram_level <= sram_threshold_words)
    18002148:	0107571b          	srliw	a4,a4,0x10
    1800214c:	feeb69e3          	bltu	s6,a4,1800213e <cadence_qspi_apb_indirect_write_execute+0x66>
		if (!retry) {
    18002150:	0e078b63          	beqz	a5,18002246 <cadence_qspi_apb_indirect_write_execute+0x16e>
					page_size : remaining;
    18002154:	2481                	sext.w	s1,s1
		wr_bytes = (remaining > page_size) ?
    18002156:	87ea                	mv	a5,s10
    18002158:	0184f363          	bgeu	s1,s8,1800215e <cadence_qspi_apb_indirect_write_execute+0x86>
    1800215c:	87a6                	mv	a5,s1
    1800215e:	00078d9b          	sext.w	s11,a5
	unsigned int temp = 0;
    18002162:	c602                	sw	zero,12(sp)
	int remaining = bytes;
    18002164:	866e                	mv	a2,s11
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002166:	0dbcfe63          	bgeu	s9,s11,18002242 <cadence_qspi_apb_indirect_write_execute+0x16a>
    1800216a:	37f1                	addiw	a5,a5,-4
    1800216c:	0027d79b          	srliw	a5,a5,0x2
    18002170:	02079593          	slli	a1,a5,0x20
    18002174:	9181                	srli	a1,a1,0x20
    18002176:	0585                	addi	a1,a1,1
    18002178:	058a                	slli	a1,a1,0x2
    1800217a:	95ca                	add	a1,a1,s2
    1800217c:	874a                	mv	a4,s2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800217e:	4314                	lw	a3,0(a4)
    18002180:	00da2023          	sw	a3,0(s4)
		src_ptr += CQSPI_FIFO_WIDTH/4;
    18002184:	0711                	addi	a4,a4,4
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002186:	feb71ce3          	bne	a4,a1,1800217e <cadence_qspi_apb_indirect_write_execute+0xa6>
    1800218a:	ffcd861b          	addiw	a2,s11,-4
    1800218e:	0027979b          	slliw	a5,a5,0x2
    18002192:	9e1d                	subw	a2,a2,a5
	if (remaining) {
    18002194:	e245                	bnez	a2,18002234 <cadence_qspi_apb_indirect_write_execute+0x15c>
		src += wr_bytes;
    18002196:	020d9793          	slli	a5,s11,0x20
    1800219a:	9381                	srli	a5,a5,0x20
		remaining -= wr_bytes;
    1800219c:	41b484bb          	subw	s1,s1,s11
		src += wr_bytes;
    180021a0:	993e                	add	s2,s2,a5
	while (remaining > 0) {
    180021a2:	f8904ce3          	bgtz	s1,1800213a <cadence_qspi_apb_indirect_write_execute+0x62>
    180021a6:	441c                	lw	a5,8(s0)
    180021a8:	02c7899b          	addiw	s3,a5,44
    180021ac:	1982                	slli	s3,s3,0x20
    180021ae:	0209d993          	srli	s3,s3,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180021b2:	0009a983          	lw	s3,0(s3)
#if 1
	/* Wait until last write is completed (FIFO empty) */
	retry = CQSPI_REG_RETRY;
	while (retry--) {
		reg = CQSPI_GET_WR_SRAM_LEVEL((u32)plat->regbase);
		if (reg == 0)
    180021b6:	0109d99b          	srliw	s3,s3,0x10
    180021ba:	02098963          	beqz	s3,180021ec <cadence_qspi_apb_indirect_write_execute+0x114>
			break;

		delay(1000);
    180021be:	3e800513          	li	a0,1000
    180021c2:	6489                	lui	s1,0x2
    180021c4:	0c2000ef          	jal	ra,18002286 <udelay>
    180021c8:	70f48493          	addi	s1,s1,1807 # 270f <__stack_size+0x1f0f>
    180021cc:	a021                	j	180021d4 <cadence_qspi_apb_indirect_write_execute+0xfc>
    180021ce:	0b8000ef          	jal	ra,18002286 <udelay>
	while (retry--) {
    180021d2:	c8b5                	beqz	s1,18002246 <cadence_qspi_apb_indirect_write_execute+0x16e>
		reg = CQSPI_GET_WR_SRAM_LEVEL((u32)plat->regbase);
    180021d4:	441c                	lw	a5,8(s0)
    180021d6:	02c7871b          	addiw	a4,a5,44
    180021da:	1702                	slli	a4,a4,0x20
    180021dc:	9301                	srli	a4,a4,0x20
    180021de:	4318                	lw	a4,0(a4)
		if (reg == 0)
    180021e0:	0107571b          	srliw	a4,a4,0x10
		delay(1000);
    180021e4:	3e800513          	li	a0,1000
    180021e8:	34fd                	addiw	s1,s1,-1
		if (reg == 0)
    180021ea:	f375                	bnez	a4,180021ce <cadence_qspi_apb_indirect_write_execute+0xf6>
	}

	/* Check flash indirect controller status */
	retry = CQSPI_REG_RETRY;
	while (retry--) {
		reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    180021ec:	0707879b          	addiw	a5,a5,112
    180021f0:	1782                	slli	a5,a5,0x20
    180021f2:	9381                	srli	a5,a5,0x20
    180021f4:	4398                	lw	a4,0(a5)
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
    180021f6:	02077713          	andi	a4,a4,32
    180021fa:	eb05                	bnez	a4,1800222a <cadence_qspi_apb_indirect_write_execute+0x152>
			break;
		delay(1000);
    180021fc:	3e800513          	li	a0,1000
    18002200:	6489                	lui	s1,0x2
    18002202:	084000ef          	jal	ra,18002286 <udelay>
    18002206:	70f48493          	addi	s1,s1,1807 # 270f <__stack_size+0x1f0f>
    1800220a:	a021                	j	18002212 <cadence_qspi_apb_indirect_write_execute+0x13a>
    1800220c:	07a000ef          	jal	ra,18002286 <udelay>
	while (retry--) {
    18002210:	c89d                	beqz	s1,18002246 <cadence_qspi_apb_indirect_write_execute+0x16e>
		reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    18002212:	641c                	ld	a5,8(s0)
    18002214:	0707879b          	addiw	a5,a5,112
    18002218:	1782                	slli	a5,a5,0x20
    1800221a:	9381                	srli	a5,a5,0x20
    1800221c:	4398                	lw	a4,0(a5)
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
    1800221e:	02077713          	andi	a4,a4,32
		delay(1000);
    18002222:	3e800513          	li	a0,1000
    18002226:	34fd                	addiw	s1,s1,-1
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
    18002228:	d375                	beqz	a4,1800220c <cadence_qspi_apb_indirect_write_execute+0x134>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800222a:	02000713          	li	a4,32
    1800222e:	c398                	sw	a4,0(a5)

	/* Clear indirect completion status */
	writel(CQSPI_REG_INDIRECTWR_DONE_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
#endif
	return 0;
    18002230:	4501                	li	a0,0
    18002232:	a015                	j	18002256 <cadence_qspi_apb_indirect_write_execute+0x17e>
		sys_memcpy(&temp, src_ptr+i, remaining % 4);
    18002234:	0068                	addi	a0,sp,12
    18002236:	94ffe0ef          	jal	ra,18000b84 <sys_memcpy>
    1800223a:	47b2                	lw	a5,12(sp)
    1800223c:	00fa2023          	sw	a5,0(s4)
		for (--i; i >= 0; i--)
    18002240:	bf99                	j	18002196 <cadence_qspi_apb_indirect_write_execute+0xbe>
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002242:	85ca                	mv	a1,s2
    18002244:	bf81                	j	18002194 <cadence_qspi_apb_indirect_write_execute+0xbc>

failwr:
	/* Cancel the indirect write */
	writel(CQSPI_REG_INDIRECTWR_CANCEL_MASK,
    18002246:	441c                	lw	a5,8(s0)
    18002248:	4709                	li	a4,2
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    1800224a:	0707879b          	addiw	a5,a5,112
    1800224e:	1782                	slli	a5,a5,0x20
    18002250:	9381                	srli	a5,a5,0x20
    18002252:	c398                	sw	a4,0(a5)
	return -1;
    18002254:	557d                	li	a0,-1
}
    18002256:	70e6                	ld	ra,120(sp)
    18002258:	7446                	ld	s0,112(sp)
    1800225a:	74a6                	ld	s1,104(sp)
    1800225c:	7906                	ld	s2,96(sp)
    1800225e:	69e6                	ld	s3,88(sp)
    18002260:	6a46                	ld	s4,80(sp)
    18002262:	6aa6                	ld	s5,72(sp)
    18002264:	6b06                	ld	s6,64(sp)
    18002266:	7be2                	ld	s7,56(sp)
    18002268:	7c42                	ld	s8,48(sp)
    1800226a:	7ca2                	ld	s9,40(sp)
    1800226c:	7d02                	ld	s10,32(sp)
    1800226e:	6de2                	ld	s11,24(sp)
    18002270:	6109                	addi	sp,sp,128
    18002272:	8082                	ret

0000000018002274 <usec_to_tick>:
#define TIMER_CLK_HZ		25000000

u64 usec_to_tick(u32 usec)
{
    u64 value;
    value = usec*(TIMER_CLK_HZ/1000000);
    18002274:	0015179b          	slliw	a5,a0,0x1
    18002278:	9fa9                	addw	a5,a5,a0
    1800227a:	0037979b          	slliw	a5,a5,0x3
    1800227e:	9d3d                	addw	a0,a0,a5
    return value;
}
    18002280:	1502                	slli	a0,a0,0x20
    18002282:	9101                	srli	a0,a0,0x20
    18002284:	8082                	ret

0000000018002286 <udelay>:
	asm volatile("ld %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002286:	0200c6b7          	lui	a3,0x200c
    1800228a:	16e1                	addi	a3,a3,-8
    1800228c:	6290                	ld	a2,0(a3)
    value = usec*(TIMER_CLK_HZ/1000000);
    1800228e:	0015171b          	slliw	a4,a0,0x1
    18002292:	9f29                	addw	a4,a4,a0
    18002294:	0037171b          	slliw	a4,a4,0x3
    18002298:	00a707bb          	addw	a5,a4,a0
    1800229c:	1782                	slli	a5,a5,0x20
    1800229e:	9381                	srli	a5,a5,0x20
/* delay x useconds */
void udelay(unsigned long usec)
{
	unsigned long  tmp;

	tmp = readq((volatile void *)CLINT_CTRL_MTIME) + usec_to_tick(usec);	/* get current timestamp */
    180022a0:	97b2                	add	a5,a5,a2
    180022a2:	6298                	ld	a4,0(a3)
    
	while (readq((volatile void *)CLINT_CTRL_MTIME) < tmp);
    180022a4:	fef76fe3          	bltu	a4,a5,180022a2 <udelay+0x1c>
}
    180022a8:	8082                	ret
