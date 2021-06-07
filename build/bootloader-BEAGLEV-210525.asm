
bootloader-BEAGLEV-210525.elf:     file format elf64-littleriscv


Disassembly of section .init:

0000000018000000 <_start>:
	.section .init
	.globl _start

_start:

	la t0, trap_entry
    18000000:	00000297          	auipc	t0,0x0
    18000004:	44428293          	addi	t0,t0,1092 # 18000444 <trap_entry>
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
    1800001e:	14610113          	addi	sp,sp,326 # 18012160 <_sp>
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
    18000034:	4d028293          	addi	t0,t0,1232 # 18002500 <_data_lma>
	la t1, _data
    18000038:	00010317          	auipc	t1,0x10
    1800003c:	fc830313          	addi	t1,t1,-56 # 18010000 <uart_id>
	beq t0, t1, 2f
    18000040:	02628063          	beq	t0,t1,18000060 <_start+0x60>
	la t2, _edata
    18000044:	00010397          	auipc	t2,0x10
    18000048:	fbc38393          	addi	t2,t2,-68 # 18010000 <uart_id>
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
    18000064:	fa030313          	addi	t1,t1,-96 # 18010000 <uart_id>
	la t2, _bss_end
    18000068:	00010397          	auipc	t2,0x10
    1800006c:	09838393          	addi	t2,t2,152 # 18010100 <_bss_end>
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
    1800007e:	1de000ef          	jal	ra,1800025c <BootMain>
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
    1800012e:	e951                	bnez	a0,180001c2 <load_data.constprop.0+0xc2>
        printk("read fail#\r\n");
		return -1;
    }
	
	/*calculate file size*/
	fileSize = (dataBuf[3] << 24) | (dataBuf[2] << 16) | (dataBuf[1] << 8) | (dataBuf[0]) ;
    18000130:	49a2                	lw	s3,8(sp)
	if(fileSize == 0)
    18000132:	08098663          	beqz	s3,180001be <load_data.constprop.0+0xbe>
		return -1;

	endPage = ((fileSize + 255) >> 8);//page align
    18000136:	0ff9899b          	addiw	s3,s3,255
    1800013a:	8baa                	mv	s7,a0
    1800013c:	0089d41b          	srliw	s0,s3,0x8
	/*copy the first page data*/
	sys_memcpy(addr, &dataBuf[4], SPIBOOT_LOAD_ADDR_OFFSET);
    18000140:	0fc00613          	li	a2,252
    18000144:	006c                	addi	a1,sp,12
    18000146:	18080537          	lui	a0,0x18080
	endPage = ((fileSize + 255) >> 8);//page align
    1800014a:	0089d99b          	srliw	s3,s3,0x8
	sys_memcpy(addr, &dataBuf[4], SPIBOOT_LOAD_ADDR_OFFSET);
    1800014e:	0c1000ef          	jal	ra,18000a0e <sys_memcpy>

	offset += pageSize;
    18000152:	015a0a3b          	addw	s4,s4,s5
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
	
	/*read Remaining pages data*/
	for(i=1; i<=endPage; i++)
    18000156:	c439                	beqz	s0,180001a4 <load_data.constprop.0+0xa4>
	{ 		
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    18000158:	e7f807b7          	lui	a5,0xe7f80
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
    1800015c:	18080437          	lui	s0,0x18080
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    18000160:	f047879b          	addiw	a5,a5,-252
        {
            printk("read fail##\r\n");
			return -1;
        }
		offset += pageSize;
		addr +=pageSize;
    18000164:	020a9c13          	slli	s8,s5,0x20
    18000168:	2985                	addiw	s3,s3,1
	for(i=1; i<=endPage; i++)
    1800016a:	4485                	li	s1,1
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
    1800016c:	0fc40413          	addi	s0,s0,252 # 180800fc <_sp+0x6df9c>
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    18000170:	00fa0a3b          	addw	s4,s4,a5
		addr +=pageSize;
    18000174:	020c5c13          	srli	s8,s8,0x20
    18000178:	a021                	j	18000180 <load_data.constprop.0+0x80>
    1800017a:	9462                	add	s0,s0,s8
	for(i=1; i<=endPage; i++)
    1800017c:	02998463          	beq	s3,s1,180001a4 <load_data.constprop.0+0xa4>
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
    18000180:	02093783          	ld	a5,32(s2)
    18000184:	86a2                	mv	a3,s0
    18000186:	008a05bb          	addw	a1,s4,s0
    1800018a:	875a                	mv	a4,s6
    1800018c:	8656                	mv	a2,s5
    1800018e:	854a                	mv	a0,s2
    18000190:	9782                	jalr	a5
	for(i=1; i<=endPage; i++)
    18000192:	2485                	addiw	s1,s1,1
		if(ret != 0)
    18000194:	d17d                	beqz	a0,1800017a <load_data.constprop.0+0x7a>
            printk("read fail##\r\n");
    18000196:	00002517          	auipc	a0,0x2
    1800019a:	1ba50513          	addi	a0,a0,442 # 18002350 <memset+0xce>
    1800019e:	04d000ef          	jal	ra,180009ea <printk>
			return -1;
    180001a2:	5bfd                	li	s7,-1
	}
	return 0;
}
    180001a4:	60f6                	ld	ra,344(sp)
    180001a6:	6456                	ld	s0,336(sp)
    180001a8:	64b6                	ld	s1,328(sp)
    180001aa:	6916                	ld	s2,320(sp)
    180001ac:	79f2                	ld	s3,312(sp)
    180001ae:	7a52                	ld	s4,304(sp)
    180001b0:	7ab2                	ld	s5,296(sp)
    180001b2:	7b12                	ld	s6,288(sp)
    180001b4:	6c52                	ld	s8,272(sp)
    180001b6:	855e                	mv	a0,s7
    180001b8:	6bf2                	ld	s7,280(sp)
    180001ba:	6135                	addi	sp,sp,352
    180001bc:	8082                	ret
		return -1;
    180001be:	5bfd                	li	s7,-1
    180001c0:	b7d5                	j	180001a4 <load_data.constprop.0+0xa4>
        printk("read fail#\r\n");
    180001c2:	00002517          	auipc	a0,0x2
    180001c6:	17e50513          	addi	a0,a0,382 # 18002340 <memset+0xbe>
    180001ca:	021000ef          	jal	ra,180009ea <printk>
		return -1;
    180001ce:	5bfd                	li	s7,-1
    180001d0:	bfd1                	j	180001a4 <load_data.constprop.0+0xa4>

00000000180001d2 <start2run32>:
	(( STARTRUNNING )(start))(0);		
    180001d2:	02051793          	slli	a5,a0,0x20
    180001d6:	9381                	srli	a5,a5,0x20
    180001d8:	4501                	li	a0,0
    180001da:	8782                	jr	a5

00000000180001dc <load_and_run_ddr>:

void load_and_run_ddr(struct spi_flash* spi_flash,int mode)
{
    180001dc:	1141                	addi	sp,sp,-16
    180001de:	e022                	sd	s0,0(sp)
    180001e0:	e406                	sd	ra,8(sp)
	unsigned int addr;
	int ret;

	addr = DEFAULT_DDR_ADDR;

	ret = load_data(spi_flash,addr,DEFAULT_DDR_OFFSET,mode);
    180001e2:	f1fff0ef          	jal	ra,18000100 <load_data.constprop.0>
    180001e6:	842a                	mv	s0,a0
	printk("\r\ncurrent_hartid:%s\r\n",current_hartid());
    180001e8:	f14025f3          	csrr	a1,mhartid
    180001ec:	00002517          	auipc	a0,0x2
    180001f0:	17450513          	addi	a0,a0,372 # 18002360 <memset+0xde>
    180001f4:	2581                	sext.w	a1,a1
    180001f6:	7f4000ef          	jal	ra,180009ea <printk>
	printk("\r\nbootloader version:%s\r\n",VERSION);    
    180001fa:	00002597          	auipc	a1,0x2
    180001fe:	17e58593          	addi	a1,a1,382 # 18002378 <memset+0xf6>
    18000202:	00002517          	auipc	a0,0x2
    18000206:	18650513          	addi	a0,a0,390 # 18002388 <memset+0x106>
    1800020a:	7e0000ef          	jal	ra,180009ea <printk>
	if(!ret)
    1800020e:	e819                	bnez	s0,18000224 <load_and_run_ddr+0x48>
#endif

#ifndef writel
static inline void writel(u32 val, volatile void *addr)
{
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000210:	020007b7          	lui	a5,0x2000
    18000214:	4705                	li	a4,1
    18000216:	0791                	addi	a5,a5,4
    18000218:	c398                	sw	a4,0(a5)
	(( STARTRUNNING )(start))(0);		
    1800021a:	4501                	li	a0,0
    1800021c:	180807b7          	lui	a5,0x18080
    18000220:	9782                	jalr	a5
	}
	else
		printk("\nload ddr bin fail.\n");
 	
	/*never run to here*/
	while(1);
    18000222:	a001                	j	18000222 <load_and_run_ddr+0x46>
		printk("\nload ddr bin fail.\n");
    18000224:	00002517          	auipc	a0,0x2
    18000228:	18450513          	addi	a0,a0,388 # 180023a8 <memset+0x126>
    1800022c:	7be000ef          	jal	ra,180009ea <printk>
    18000230:	bfcd                	j	18000222 <load_and_run_ddr+0x46>

0000000018000232 <boot_from_spi>:
}

void boot_from_spi(int mode)
{
    18000232:	1141                	addi	sp,sp,-16
	struct spi_flash* spi_flash;
	int ret;
	u32	*addr;
	u32 val;

    cadence_qspi_init(0, mode);
    18000234:	85aa                	mv	a1,a0
{
    18000236:	e022                	sd	s0,0(sp)
    18000238:	842a                	mv	s0,a0
    cadence_qspi_init(0, mode);
    1800023a:	4501                	li	a0,0
{
    1800023c:	e406                	sd	ra,8(sp)
    cadence_qspi_init(0, mode);
    1800023e:	545000ef          	jal	ra,18000f82 <cadence_qspi_init>
	spi_flash = spi_flash_probe(0, 0, 31250000, 0, (u32)SPI_DATAMODE_8);
    18000242:	01dcd637          	lui	a2,0x1dcd
    18000246:	4581                	li	a1,0
    18000248:	4721                	li	a4,8
    1800024a:	4681                	li	a3,0
    1800024c:	65060613          	addi	a2,a2,1616 # 1dcd650 <__stack_size+0x1dcce50>
    18000250:	4501                	li	a0,0
    18000252:	173000ef          	jal	ra,18000bc4 <spi_flash_probe>

	/*init ddr*/
	load_and_run_ddr(spi_flash,mode);
    18000256:	85a2                	mv	a1,s0
    18000258:	f85ff0ef          	jal	ra,180001dc <load_and_run_ddr>

000000001800025c <BootMain>:

}

static void chip_clk_init() 
{
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    1800025c:	118006b7          	lui	a3,0x11800
    18000260:	4298                	lw	a4,0(a3)
    18000262:	fd000637          	lui	a2,0xfd000
    18000266:	167d                	addi	a2,a2,-1
    18000268:	2701                	sext.w	a4,a4
    1800026a:	010005b7          	lui	a1,0x1000
    1800026e:	8f71                	and	a4,a4,a2
//	_SWITCH_CLOCK_clk_nne_bus_SOURCE_clk_cpu_axi_;
}

/*only hartid 0 call this function*/
void BootMain(void)
{	
    18000270:	1141                	addi	sp,sp,-16
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    18000272:	8f4d                	or	a4,a4,a1
{	
    18000274:	e406                	sd	ra,8(sp)
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
    18000276:	2701                	sext.w	a4,a4
    18000278:	c298                	sw	a4,0(a3)
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
    1800027a:	42d8                	lw	a4,4(a3)
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
    1800027c:	030007b7          	lui	a5,0x3000
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
    18000280:	2701                	sext.w	a4,a4
    18000282:	8f71                	and	a4,a4,a2
    18000284:	8f4d                	or	a4,a4,a1
    18000286:	2701                	sext.w	a4,a4
    18000288:	c2d8                	sw	a4,4(a3)
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
    1800028a:	4698                	lw	a4,8(a3)
    1800028c:	2701                	sext.w	a4,a4
    1800028e:	8f71                	and	a4,a4,a2
    18000290:	8f5d                	or	a4,a4,a5
    18000292:	c698                	sw	a4,8(a3)
	_SWITCH_CLOCK_clk_perh0_root_SOURCE_clk_pll0_out_;
    18000294:	4a9c                	lw	a5,16(a3)
    18000296:	ff000737          	lui	a4,0xff000
    1800029a:	177d                	addi	a4,a4,-1
    1800029c:	2781                	sext.w	a5,a5
    1800029e:	8ff9                	and	a5,a5,a4
    180002a0:	8fcd                	or	a5,a5,a1
    180002a2:	2781                	sext.w	a5,a5
    180002a4:	ca9c                	sw	a5,16(a3)

	/*switch to pll mode*/
	chip_clk_init();

//for illegal instruction exception
	_SET_SYSCON_REG_register50_SCFG_funcshare_pad_ctrl_18(0x00c000c0);
    180002a6:	11858637          	lui	a2,0x11858
    180002aa:	0c862783          	lw	a5,200(a2) # 118580c8 <__stack_size+0x118578c8>

	_CLEAR_RESET_rstgen_rstn_usbnoc_axi_;
    180002ae:	118406b7          	lui	a3,0x11840
	_SET_SYSCON_REG_register50_SCFG_funcshare_pad_ctrl_18(0x00c000c0);
    180002b2:	00c007b7          	lui	a5,0xc00
    180002b6:	0c078793          	addi	a5,a5,192 # c000c0 <__stack_size+0xbff8c0>
    180002ba:	0cf62423          	sw	a5,200(a2)
	_CLEAR_RESET_rstgen_rstn_usbnoc_axi_;
    180002be:	42dc                	lw	a5,4(a3)
    180002c0:	11840737          	lui	a4,0x11840
    180002c4:	2781                	sext.w	a5,a5
    180002c6:	fbf7f793          	andi	a5,a5,-65
    180002ca:	c2dc                	sw	a5,4(a3)
    180002cc:	4b5c                	lw	a5,20(a4)
    180002ce:	0407f793          	andi	a5,a5,64
    180002d2:	dfed                	beqz	a5,180002cc <BootMain+0x70>
	_CLEAR_RESET_rstgen_rstn_hifi4noc_axi_;
    180002d4:	435c                	lw	a5,4(a4)
    180002d6:	118406b7          	lui	a3,0x11840
    180002da:	2781                	sext.w	a5,a5
    180002dc:	9bed                	andi	a5,a5,-5
    180002de:	c35c                	sw	a5,4(a4)
    180002e0:	4adc                	lw	a5,20(a3)
    180002e2:	8b91                	andi	a5,a5,4
    180002e4:	dff5                	beqz	a5,180002e0 <BootMain+0x84>

	_ENABLE_CLOCK_clk_x2c_axi_;
    180002e6:	11800637          	lui	a2,0x11800
    180002ea:	15c62783          	lw	a5,348(a2) # 1180015c <__stack_size+0x117ff95c>
    180002ee:	800005b7          	lui	a1,0x80000
	_CLEAR_RESET_rstgen_rstn_x2c_axi_;
    180002f2:	11840737          	lui	a4,0x11840
	_ENABLE_CLOCK_clk_x2c_axi_;
    180002f6:	8fcd                	or	a5,a5,a1
    180002f8:	14f62e23          	sw	a5,348(a2)
	_CLEAR_RESET_rstgen_rstn_x2c_axi_;
    180002fc:	42dc                	lw	a5,4(a3)
    180002fe:	2781                	sext.w	a5,a5
    18000300:	dff7f793          	andi	a5,a5,-513
    18000304:	c2dc                	sw	a5,4(a3)
    18000306:	4b5c                	lw	a5,20(a4)
    18000308:	2007f793          	andi	a5,a5,512
    1800030c:	dfed                	beqz	a5,18000306 <BootMain+0xaa>

	_CLEAR_RESET_rstgen_rstn_dspx2c_axi_;
    1800030e:	435c                	lw	a5,4(a4)
    18000310:	76f1                	lui	a3,0xffffc
    18000312:	16fd                	addi	a3,a3,-1
    18000314:	2781                	sext.w	a5,a5
    18000316:	8ff5                	and	a5,a5,a3
    18000318:	c35c                	sw	a5,4(a4)
    1800031a:	118406b7          	lui	a3,0x11840
    1800031e:	6711                	lui	a4,0x4
    18000320:	4adc                	lw	a5,20(a3)
    18000322:	2781                	sext.w	a5,a5
    18000324:	8ff9                	and	a5,a5,a4
    18000326:	2781                	sext.w	a5,a5
    18000328:	dfe5                	beqz	a5,18000320 <BootMain+0xc4>
	_CLEAR_RESET_rstgen_rstn_dma1p_axi_;
    1800032a:	42dc                	lw	a5,4(a3)
    1800032c:	11840737          	lui	a4,0x11840
    18000330:	2781                	sext.w	a5,a5
    18000332:	eff7f793          	andi	a5,a5,-257
    18000336:	c2dc                	sw	a5,4(a3)
    18000338:	4b5c                	lw	a5,20(a4)
    1800033a:	1007f793          	andi	a5,a5,256
    1800033e:	dfed                	beqz	a5,18000338 <BootMain+0xdc>

	_ENABLE_CLOCK_clk_msi_apb_;
    18000340:	118006b7          	lui	a3,0x11800
    18000344:	2d86a783          	lw	a5,728(a3) # 118002d8 <__stack_size+0x117ffad8>
    18000348:	80000637          	lui	a2,0x80000
    1800034c:	8fd1                	or	a5,a5,a2
    1800034e:	2cf6ac23          	sw	a5,728(a3)
	_CLEAR_RESET_rstgen_rstn_msi_apb_;
    18000352:	475c                	lw	a5,12(a4)
    18000354:	7671                	lui	a2,0xffffc
    18000356:	167d                	addi	a2,a2,-1
    18000358:	2781                	sext.w	a5,a5
    1800035a:	8ff1                	and	a5,a5,a2
    1800035c:	c75c                	sw	a5,12(a4)
    1800035e:	118406b7          	lui	a3,0x11840
    18000362:	6711                	lui	a4,0x4
    18000364:	4edc                	lw	a5,28(a3)
    18000366:	2781                	sext.w	a5,a5
    18000368:	8ff9                	and	a5,a5,a4
    1800036a:	2781                	sext.w	a5,a5
    1800036c:	dfe5                	beqz	a5,18000364 <BootMain+0x108>

	_ASSERT_RESET_rstgen_rstn_x2c_axi_;
    1800036e:	42dc                	lw	a5,4(a3)
    18000370:	11840737          	lui	a4,0x11840
    18000374:	2781                	sext.w	a5,a5
    18000376:	2007e793          	ori	a5,a5,512
    1800037a:	c2dc                	sw	a5,4(a3)
    1800037c:	4b5c                	lw	a5,20(a4)
    1800037e:	2007f793          	andi	a5,a5,512
    18000382:	ffed                	bnez	a5,1800037c <BootMain+0x120>
	_CLEAR_RESET_rstgen_rstn_x2c_axi_;
    18000384:	435c                	lw	a5,4(a4)
    18000386:	118406b7          	lui	a3,0x11840
    1800038a:	2781                	sext.w	a5,a5
    1800038c:	dff7f793          	andi	a5,a5,-513
    18000390:	c35c                	sw	a5,4(a4)
    18000392:	4adc                	lw	a5,20(a3)
    18000394:	2007f793          	andi	a5,a5,512
    18000398:	dfed                	beqz	a5,18000392 <BootMain+0x136>
//end for illegal instruction exception
    _SET_SYSCON_REG_register69_core1_en(1);
    1800039a:	11850637          	lui	a2,0x11850
    1800039e:	11862703          	lw	a4,280(a2) # 11850118 <__stack_size+0x1184f918>
    _SET_SYSCON_REG_register104_SCFG_io_padshare_sel(6);
    180003a2:	118587b7          	lui	a5,0x11858
    _SET_SYSCON_REG_register32_SCFG_funcshare_pad_ctrl_0(0x00c00000);
    180003a6:	00c006b7          	lui	a3,0xc00
    _SET_SYSCON_REG_register69_core1_en(1);
    180003aa:	2701                	sext.w	a4,a4
    180003ac:	00176713          	ori	a4,a4,1
    180003b0:	10e62c23          	sw	a4,280(a2)
    _SET_SYSCON_REG_register104_SCFG_io_padshare_sel(6);
    180003b4:	1a07a703          	lw	a4,416(a5) # 118581a0 <__stack_size+0x118579a0>
    _SET_SYSCON_REG_register33_SCFG_funcshare_pad_ctrl_1(0x00c000c0);
    180003b8:	0c068613          	addi	a2,a3,192 # c000c0 <__stack_size+0xbff8c0>
    _SET_SYSCON_REG_register34_SCFG_funcshare_pad_ctrl_2(0x00c000c0);
    _SET_SYSCON_REG_register35_SCFG_funcshare_pad_ctrl_3(0x00c000c0);
    _SET_SYSCON_REG_register39_SCFG_funcshare_pad_ctrl_7(0x00c300c3);
    _SET_SYSCON_REG_register38_SCFG_funcshare_pad_ctrl_6(0x00c00000);

	uart_init(3);
    180003bc:	450d                	li	a0,3
    _SET_SYSCON_REG_register104_SCFG_io_padshare_sel(6);
    180003be:	2701                	sext.w	a4,a4
    180003c0:	9b61                	andi	a4,a4,-8
    180003c2:	00676713          	ori	a4,a4,6
    180003c6:	1ae7a023          	sw	a4,416(a5)
    _SET_SYSCON_REG_register32_SCFG_funcshare_pad_ctrl_0(0x00c00000);
    180003ca:	0807a703          	lw	a4,128(a5)
    180003ce:	08d7a023          	sw	a3,128(a5)
    _SET_SYSCON_REG_register33_SCFG_funcshare_pad_ctrl_1(0x00c000c0);
    180003d2:	0847a703          	lw	a4,132(a5)
    180003d6:	08c7a223          	sw	a2,132(a5)
    _SET_SYSCON_REG_register34_SCFG_funcshare_pad_ctrl_2(0x00c000c0);
    180003da:	0887a703          	lw	a4,136(a5)
    180003de:	08c7a423          	sw	a2,136(a5)
    _SET_SYSCON_REG_register35_SCFG_funcshare_pad_ctrl_3(0x00c000c0);
    180003e2:	08c7a703          	lw	a4,140(a5)
    180003e6:	08c7a623          	sw	a2,140(a5)
    _SET_SYSCON_REG_register39_SCFG_funcshare_pad_ctrl_7(0x00c300c3);
    180003ea:	09c7a703          	lw	a4,156(a5)
    180003ee:	00c30737          	lui	a4,0xc30
    180003f2:	0c370713          	addi	a4,a4,195 # c300c3 <__stack_size+0xc2f8c3>
    180003f6:	08e7ae23          	sw	a4,156(a5)
    _SET_SYSCON_REG_register38_SCFG_funcshare_pad_ctrl_6(0x00c00000);
    180003fa:	0987a703          	lw	a4,152(a5)
    180003fe:	08d7ac23          	sw	a3,152(a5)
	uart_init(3);
    18000402:	094000ef          	jal	ra,18000496 <uart_init>
    18000406:	180207b7          	lui	a5,0x18020
    1800040a:	18000737          	lui	a4,0x18000
    1800040e:	17f1                	addi	a5,a5,-4
    18000410:	c398                	sw	a4,0(a5)
    18000412:	020007b7          	lui	a5,0x2000
    18000416:	4705                	li	a4,1
    18000418:	0791                	addi	a5,a5,4
    1800041a:	c398                	sw	a4,0(a5)
	
	writel(0x18000000, 0x1801fffc);
	writel(0x1, 0x2000004); 		/*从bootrom中恢复hart1*/
	boot_from_spi(1);
    1800041c:	4505                	li	a0,1
    1800041e:	e15ff0ef          	jal	ra,18000232 <boot_from_spi>

0000000018000422 <handle_trap>:
   #define MCAUSE_CAUSE       0x00000000000003FFUL
#endif


uintptr_t handle_trap(uintptr_t mcause, uintptr_t epc)
{
    18000422:	1141                	addi	sp,sp,-16
    18000424:	e022                	sd	s0,0(sp)
    18000426:	842e                	mv	s0,a1
	}
	else {
		rlSendString("unhandle trap.\n");
	}
#endif
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    18000428:	8622                	mv	a2,s0
{
    1800042a:	85aa                	mv	a1,a0
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    1800042c:	00002517          	auipc	a0,0x2
    18000430:	f9450513          	addi	a0,a0,-108 # 180023c0 <memset+0x13e>
{
    18000434:	e406                	sd	ra,8(sp)
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    18000436:	5b4000ef          	jal	ra,180009ea <printk>
	return epc;
}
    1800043a:	60a2                	ld	ra,8(sp)
    1800043c:	8522                	mv	a0,s0
    1800043e:	6402                	ld	s0,0(sp)
    18000440:	0141                	addi	sp,sp,16
    18000442:	8082                	ret

0000000018000444 <trap_entry>:

void trap_entry(void)
{
  unsigned long mcause = read_csr(mcause);
    18000444:	342025f3          	csrr	a1,mcause
  unsigned long mepc = read_csr(mepc);
    18000448:	34102673          	csrr	a2,mepc
	printk("trap mcause:0x%x epc:0x%x\n",mcause,epc);
    1800044c:	00002517          	auipc	a0,0x2
    18000450:	f7450513          	addi	a0,a0,-140 # 180023c0 <memset+0x13e>
    18000454:	ab59                	j	180009ea <printk>

0000000018000456 <__serial_tstc>:
};

static unsigned int serial_in(int offset)
{
	offset <<= 2;
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000456:	00010797          	auipc	a5,0x10
    1800045a:	baa7e783          	lwu	a5,-1110(a5) # 18010000 <uart_id>
    1800045e:	00379713          	slli	a4,a5,0x3
    18000462:	00002797          	auipc	a5,0x2
    18000466:	fe678793          	addi	a5,a5,-26 # 18002448 <uart_base>
    1800046a:	97ba                	add	a5,a5,a4
    1800046c:	6388                	ld	a0,0(a5)
    1800046e:	0551                	addi	a0,a0,20
#ifndef readl
static inline u32 readl(volatile void *addr)
{
	u32 val;

	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000470:	4108                	lw	a0,0(a0)
}

int __serial_tstc()
{
	return ((serial_in(REG_LSR)) & (1 << 0));
}
    18000472:	8905                	andi	a0,a0,1
    18000474:	8082                	ret

0000000018000476 <serial_tstc>:
    18000476:	00010797          	auipc	a5,0x10
    1800047a:	b8a7e783          	lwu	a5,-1142(a5) # 18010000 <uart_id>
    1800047e:	00379713          	slli	a4,a5,0x3
    18000482:	00002797          	auipc	a5,0x2
    18000486:	fc678793          	addi	a5,a5,-58 # 18002448 <uart_base>
    1800048a:	97ba                	add	a5,a5,a4
    1800048c:	6388                	ld	a0,0(a5)
    1800048e:	0551                	addi	a0,a0,20
    18000490:	4108                	lw	a0,0(a0)
    18000492:	8905                	andi	a0,a0,1
    18000494:	8082                	ret

0000000018000496 <uart_init>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000496:	02051793          	slli	a5,a0,0x20
    1800049a:	01d7d713          	srli	a4,a5,0x1d
    1800049e:	00002797          	auipc	a5,0x2
    180004a2:	faa78793          	addi	a5,a5,-86 # 18002448 <uart_base>
    180004a6:	97ba                	add	a5,a5,a4
    180004a8:	639c                	ld	a5,0(a5)
			
		default:
			return;
	}
#endif
 	uart_id = id;
    180004aa:	00010717          	auipc	a4,0x10
    180004ae:	b4a72b23          	sw	a0,-1194(a4) # 18010000 <uart_id>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180004b2:	00c78713          	addi	a4,a5,12
    180004b6:	4314                	lw	a3,0(a4)
	
	divisor = (UART_CLK / UART_BUADRATE_32MCLK_115200) >> 4;

	lcr_cache = serial_in(REG_LCR);
	serial_out(REG_LCR, (LCR_DLAB | lcr_cache));
    180004b8:	0ff6f613          	zext.b	a2,a3
	writel(value, (volatile void *)(uart_base[uart_id] + offset));
    180004bc:	08066613          	ori	a2,a2,128
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180004c0:	c310                	sw	a2,0(a4)
    180004c2:	03600613          	li	a2,54
    180004c6:	c390                	sw	a2,0(a5)
    180004c8:	4601                	li	a2,0
    180004ca:	00478593          	addi	a1,a5,4
    180004ce:	c190                	sw	a2,0(a1)
    180004d0:	0ff6f693          	zext.b	a3,a3
    180004d4:	c314                	sw	a3,0(a4)
    180004d6:	468d                	li	a3,3
    180004d8:	c314                	sw	a3,0(a4)
    180004da:	01078713          	addi	a4,a5,16
    180004de:	c310                	sw	a2,0(a4)
    180004e0:	08f00713          	li	a4,143
    180004e4:	07a1                	addi	a5,a5,8
    180004e6:	c398                	sw	a4,0(a5)
    180004e8:	c190                	sw	a2,0(a1)
	 * Clear TX and RX FIFO
	 */
	serial_out(REG_FCR, (FCR_FIFO | FCR_MODE1 | /*FCR_FIFO_1*/FCR_FIFO_8 | FCR_RCVRCLR | FCR_XMITCLR));
	
	serial_out(REG_IER, 0);//dis the ser interrupt
}
    180004ea:	8082                	ret

00000000180004ec <_putc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180004ec:	00010797          	auipc	a5,0x10
    180004f0:	b147e783          	lwu	a5,-1260(a5) # 18010000 <uart_id>
    180004f4:	00379713          	slli	a4,a5,0x3
    180004f8:	00002797          	auipc	a5,0x2
    180004fc:	f5078793          	addi	a5,a5,-176 # 18002448 <uart_base>
    18000500:	97ba                	add	a5,a5,a4
    18000502:	6394                	ld	a3,0(a5)
    18000504:	01468713          	addi	a4,a3,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000508:	431c                	lw	a5,0(a4)

int _putc(char c) {
	do
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    1800050a:	0207f793          	andi	a5,a5,32
    1800050e:	dfed                	beqz	a5,18000508 <_putc+0x1c>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000510:	c288                	sw	a0,0(a3)

	serial_out(REG_THR, c);
	return 0;
}
    18000512:	4501                	li	a0,0
    18000514:	8082                	ret

0000000018000516 <rlSendString>:

void rlSendString(char *s)
{
	while (*s){
    18000516:	00054683          	lbu	a3,0(a0)
    1800051a:	ca85                	beqz	a3,1800054a <rlSendString+0x34>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800051c:	00010797          	auipc	a5,0x10
    18000520:	ae47e783          	lwu	a5,-1308(a5) # 18010000 <uart_id>
    18000524:	00379713          	slli	a4,a5,0x3
    18000528:	00002797          	auipc	a5,0x2
    1800052c:	f2078793          	addi	a5,a5,-224 # 18002448 <uart_base>
    18000530:	97ba                	add	a5,a5,a4
    18000532:	6390                	ld	a2,0(a5)
    18000534:	01460713          	addi	a4,a2,20
		_putc(*s++);
    18000538:	0505                	addi	a0,a0,1
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    1800053a:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    1800053c:	0207f793          	andi	a5,a5,32
    18000540:	dfed                	beqz	a5,1800053a <rlSendString+0x24>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000542:	c214                	sw	a3,0(a2)
	while (*s){
    18000544:	00054683          	lbu	a3,0(a0)
    18000548:	fae5                	bnez	a3,18000538 <rlSendString+0x22>
	}
}
    1800054a:	8082                	ret

000000001800054c <CtrlBreak>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800054c:	00010797          	auipc	a5,0x10
    18000550:	ab47e783          	lwu	a5,-1356(a5) # 18010000 <uart_id>
    18000554:	00379713          	slli	a4,a5,0x3
    18000558:	00002797          	auipc	a5,0x2
    1800055c:	ef078793          	addi	a5,a5,-272 # 18002448 <uart_base>
    18000560:	97ba                	add	a5,a5,a4
    18000562:	6394                	ld	a3,0(a5)
{
	int retflag;

	do{
		retflag	= serial_getc();
		if( retflag == 0x03 ){
    18000564:	460d                	li	a2,3
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000566:	01468713          	addi	a4,a3,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    1800056a:	431c                	lw	a5,0(a4)
	return retflag;
}
int serial_getc()
{	
	/* Wait here until the the FIFO is not full */
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    1800056c:	8b85                	andi	a5,a5,1
    1800056e:	dff5                	beqz	a5,1800056a <CtrlBreak+0x1e>
    18000570:	4288                	lw	a0,0(a3)

	return serial_in(REG_RDR);
    18000572:	2501                	sext.w	a0,a0
		if( retflag == 0x03 ){
    18000574:	00c50363          	beq	a0,a2,1800057a <CtrlBreak+0x2e>
	}while( retflag );
    18000578:	f96d                	bnez	a0,1800056a <CtrlBreak+0x1e>
}
    1800057a:	8082                	ret

000000001800057c <serial_getc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800057c:	00010797          	auipc	a5,0x10
    18000580:	a847e783          	lwu	a5,-1404(a5) # 18010000 <uart_id>
    18000584:	00379713          	slli	a4,a5,0x3
    18000588:	00002797          	auipc	a5,0x2
    1800058c:	ec078793          	addi	a5,a5,-320 # 18002448 <uart_base>
    18000590:	97ba                	add	a5,a5,a4
    18000592:	6388                	ld	a0,0(a5)
    18000594:	01450713          	addi	a4,a0,20
    18000598:	431c                	lw	a5,0(a4)
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    1800059a:	8b85                	andi	a5,a5,1
    1800059c:	dff5                	beqz	a5,18000598 <serial_getc+0x1c>
    1800059e:	4108                	lw	a0,0(a0)
}
    180005a0:	2501                	sext.w	a0,a0
    180005a2:	8082                	ret

00000000180005a4 <serial_gets>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180005a4:	00010f17          	auipc	t5,0x10
    180005a8:	a5cf0f13          	addi	t5,t5,-1444 # 18010000 <uart_id>
    180005ac:	000f6783          	lwu	a5,0(t5)
    180005b0:	00002e97          	auipc	t4,0x2
    180005b4:	e98e8e93          	addi	t4,t4,-360 # 18002448 <uart_base>
	unsigned char c;
	unsigned char *pstrorg;
	
	pstrorg = (unsigned char *) pstr;

	while ((c = serial_getc()) != '\r')
    180005b8:	88aa                	mv	a7,a0
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180005ba:	078e                	slli	a5,a5,0x3
    180005bc:	97f6                	add	a5,a5,t4
    180005be:	638c                	ld	a1,0(a5)
	while ((c = serial_getc()) != '\r')
    180005c0:	4335                	li	t1,13
	{
		if (c == '\b'){
    180005c2:	4e21                	li	t3,8
    180005c4:	01458713          	addi	a4,a1,20 # ffffffff80000014 <_sp+0xffffffff67fedeb4>
    180005c8:	431c                	lw	a5,0(a4)
    while (!(serial_in(REG_LSR) & (1 << 0))){};
    180005ca:	8b85                	andi	a5,a5,1
    180005cc:	dff5                	beqz	a5,180005c8 <serial_gets+0x24>
    180005ce:	4190                	lw	a2,0(a1)
	while ((c = serial_getc()) != '\r')
    180005d0:	0ff67693          	zext.b	a3,a2
    180005d4:	0006079b          	sext.w	a5,a2
    180005d8:	06668063          	beq	a3,t1,18000638 <serial_gets+0x94>
		if (c == '\b'){
    180005dc:	03c69a63          	bne	a3,t3,18000610 <serial_gets+0x6c>
			if ((int) *pstrorg < (int) *pstr){
    180005e0:	00054603          	lbu	a2,0(a0)
    180005e4:	0008c783          	lbu	a5,0(a7)
    180005e8:	fef670e3          	bgeu	a2,a5,180005c8 <serial_gets+0x24>
    180005ec:	02000813          	li	a6,32
    180005f0:	00002617          	auipc	a2,0x2
    180005f4:	df060613          	addi	a2,a2,-528 # 180023e0 <memset+0x15e>
		_putc(*s++);
    180005f8:	0605                	addi	a2,a2,1
    180005fa:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    180005fc:	0207f793          	andi	a5,a5,32
    18000600:	dfed                	beqz	a5,180005fa <serial_gets+0x56>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000602:	c194                	sw	a3,0(a1)
	while (*s){
    18000604:	02080863          	beqz	a6,18000634 <serial_gets+0x90>
    18000608:	86c2                	mv	a3,a6
    1800060a:	00164803          	lbu	a6,1(a2)
    1800060e:	b7ed                	j	180005f8 <serial_gets+0x54>
				rlSendString("\b \b");
				pstr--;
			}
		}else{
			*pstr++ = c;
    18000610:	00f88023          	sb	a5,0(a7)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    18000614:	000f6783          	lwu	a5,0(t5)
			*pstr++ = c;
    18000618:	0885                	addi	a7,a7,1
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800061a:	078e                	slli	a5,a5,0x3
    1800061c:	97f6                	add	a5,a5,t4
    1800061e:	638c                	ld	a1,0(a5)
    18000620:	01458713          	addi	a4,a1,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000624:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    18000626:	0207f793          	andi	a5,a5,32
    1800062a:	dfed                	beqz	a5,18000624 <serial_gets+0x80>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800062c:	0ff67613          	zext.b	a2,a2
    18000630:	c190                	sw	a2,0(a1)
	return 0;
    18000632:	bf59                	j	180005c8 <serial_gets+0x24>
				pstr--;
    18000634:	18fd                	addi	a7,a7,-1
    18000636:	bf49                	j	180005c8 <serial_gets+0x24>
			_putc(c);
		}
	}

	*pstr = '\0';
    18000638:	00088023          	sb	zero,0(a7)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800063c:	000f6783          	lwu	a5,0(t5)
	writel(value, (volatile void *)(uart_base[uart_id] + offset));
    18000640:	45a9                	li	a1,10
    18000642:	00002617          	auipc	a2,0x2
    18000646:	da660613          	addi	a2,a2,-602 # 180023e8 <memset+0x166>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    1800064a:	078e                	slli	a5,a5,0x3
    1800064c:	9ebe                	add	t4,t4,a5
    1800064e:	000eb503          	ld	a0,0(t4)
    18000652:	01450713          	addi	a4,a0,20
		_putc(*s++);
    18000656:	0605                	addi	a2,a2,1
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000658:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    1800065a:	0207f793          	andi	a5,a5,32
    1800065e:	dfed                	beqz	a5,18000658 <serial_gets+0xb4>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18000660:	c114                	sw	a3,0(a0)
	while (*s){
    18000662:	c589                	beqz	a1,1800066c <serial_gets+0xc8>
    18000664:	86ae                	mv	a3,a1
    18000666:	00164583          	lbu	a1,1(a2)
    1800066a:	b7f5                	j	18000656 <serial_gets+0xb2>

	rlSendString("\r\n");
		
}
    1800066c:	8082                	ret

000000001800066e <_puts>:
    1800066e:	00054683          	lbu	a3,0(a0)
    18000672:	ca85                	beqz	a3,180006a2 <_puts+0x34>
    18000674:	00010797          	auipc	a5,0x10
    18000678:	98c7e783          	lwu	a5,-1652(a5) # 18010000 <uart_id>
    1800067c:	00379713          	slli	a4,a5,0x3
    18000680:	00002797          	auipc	a5,0x2
    18000684:	dc878793          	addi	a5,a5,-568 # 18002448 <uart_base>
    18000688:	97ba                	add	a5,a5,a4
    1800068a:	6390                	ld	a2,0(a5)
    1800068c:	01460713          	addi	a4,a2,20
    18000690:	0505                	addi	a0,a0,1
    18000692:	431c                	lw	a5,0(a4)
    18000694:	0207f793          	andi	a5,a5,32
    18000698:	dfed                	beqz	a5,18000692 <_puts+0x24>
    1800069a:	c214                	sw	a3,0(a2)
    1800069c:	00054683          	lbu	a3,0(a0)
    180006a0:	fae5                	bnez	a3,18000690 <_puts+0x22>
    180006a2:	8082                	ret

00000000180006a4 <print_ubyte_hex>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006a4:	00010717          	auipc	a4,0x10
    180006a8:	95c76703          	lwu	a4,-1700(a4) # 18010000 <uart_id>
	static const char digits[16] = "0123456789ABCDEF";
	char tmp[2];
	int dig=0;

	dig = ((bval&0xf0)>>4);
	tmp[0] = digits[dig];
    180006ac:	00002797          	auipc	a5,0x2
    180006b0:	d9c78793          	addi	a5,a5,-612 # 18002448 <uart_base>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006b4:	070e                	slli	a4,a4,0x3
    180006b6:	973e                	add	a4,a4,a5
	tmp[0] = digits[dig];
    180006b8:	00455613          	srli	a2,a0,0x4
	dig = (bval&0x0f);
	tmp[1] = digits[dig];
    180006bc:	893d                	andi	a0,a0,15
	tmp[0] = digits[dig];
    180006be:	963e                	add	a2,a2,a5
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006c0:	6314                	ld	a3,0(a4)
	tmp[1] = digits[dig];
    180006c2:	97aa                	add	a5,a5,a0
	tmp[0] = digits[dig];
    180006c4:	02064583          	lbu	a1,32(a2)
	tmp[1] = digits[dig];
    180006c8:	0207c603          	lbu	a2,32(a5)
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006cc:	01468713          	addi	a4,a3,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180006d0:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    180006d2:	0207f793          	andi	a5,a5,32
    180006d6:	dfed                	beqz	a5,180006d0 <print_ubyte_hex+0x2c>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180006d8:	c28c                	sw	a1,0(a3)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180006da:	431c                	lw	a5,0(a4)
    180006dc:	0207f793          	andi	a5,a5,32
    180006e0:	dfed                	beqz	a5,180006da <print_ubyte_hex+0x36>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180006e2:	c290                	sw	a2,0(a3)
	_putc(tmp[0]);
	_putc(tmp[1]);
}
    180006e4:	8082                	ret

00000000180006e6 <serial_nowait_getc>:
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180006e6:	00010797          	auipc	a5,0x10
    180006ea:	91a7e783          	lwu	a5,-1766(a5) # 18010000 <uart_id>
    180006ee:	00379713          	slli	a4,a5,0x3
    180006f2:	00002797          	auipc	a5,0x2
    180006f6:	d5678793          	addi	a5,a5,-682 # 18002448 <uart_base>
    180006fa:	97ba                	add	a5,a5,a4
    180006fc:	6398                	ld	a4,0(a5)
    180006fe:	01470793          	addi	a5,a4,20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18000702:	439c                	lw	a5,0(a5)
int serial_nowait_getc()
{
	unsigned int status;

	status = serial_in(REG_LSR);
	if (!(status & (1 << 0))) {
    18000704:	8b85                	andi	a5,a5,1
    18000706:	4501                	li	a0,0
    18000708:	c781                	beqz	a5,18000710 <serial_nowait_getc+0x2a>
    1800070a:	4318                	lw	a4,0(a4)
		status = 0;//NO_POLL_CHAR;
		goto out;
	}
	status = serial_in(REG_RDR);
out:
	return status;
    1800070c:	0007051b          	sext.w	a0,a4
}
    18000710:	8082                	ret

0000000018000712 <vnprintf>:
int vnprintf(char* out, size_t n, const char* s, va_list vl)
{
  bool format = false;
  bool longarg = false;
  size_t pos = 0;
  for( ; *s; s++)
    18000712:	00064783          	lbu	a5,0(a2)
{
    18000716:	832a                	mv	t1,a0
  for( ; *s; s++)
    18000718:	24078c63          	beqz	a5,18000970 <vnprintf+0x25e>
{
    1800071c:	7179                	addi	sp,sp,-48
    1800071e:	f422                	sd	s0,40(sp)
    18000720:	f026                	sd	s1,32(sp)
    18000722:	ec4a                	sd	s2,24(sp)
    18000724:	e84e                	sd	s3,16(sp)
    18000726:	e452                	sd	s4,8(sp)
    18000728:	e056                	sd	s5,0(sp)
  size_t pos = 0;
    1800072a:	4701                	li	a4,0
  bool longarg = false;
    1800072c:	4901                	li	s2,0
  bool format = false;
    1800072e:	4801                	li	a6,0
        }
        default:
          break;
      }
    }
    else if(*s == '%')
    18000730:	02500293          	li	t0,37
    18000734:	4fd5                	li	t6,21
    18000736:	00002e97          	auipc	t4,0x2
    1800073a:	cbae8e93          	addi	t4,t4,-838 # 180023f0 <memset+0x16e>
          for (long nn = num; nn /= 10; digits++)
    1800073e:	4529                	li	a0,10
            if (++pos < n) out[pos-1] = '-';
    18000740:	02d00493          	li	s1,45
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    18000744:	4f25                	li	t5,9
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000746:	5e71                	li	t3,-4
          if (++pos < n) out[pos-1] = 'x';
    18000748:	07800413          	li	s0,120
          if (++pos < n) out[pos-1] = '0';
    1800074c:	03000393          	li	t2,48
    if(format)
    18000750:	18080863          	beqz	a6,180008e0 <vnprintf+0x1ce>
      switch(*s)
    18000754:	f9d7879b          	addiw	a5,a5,-99
    18000758:	0ff7f793          	zext.b	a5,a5
    1800075c:	00ffe863          	bltu	t6,a5,1800076c <vnprintf+0x5a>
    18000760:	078a                	slli	a5,a5,0x2
    18000762:	97f6                	add	a5,a5,t4
    18000764:	439c                	lw	a5,0(a5)
    18000766:	97f6                	add	a5,a5,t4
    18000768:	8782                	jr	a5
      format = true;
    1800076a:	4805                	li	a6,1
  for( ; *s; s++)
    1800076c:	00164783          	lbu	a5,1(a2)
    18000770:	0605                	addi	a2,a2,1
    18000772:	fff9                	bnez	a5,18000750 <vnprintf+0x3e>
  }
  if (pos < n)
    out[pos] = 0;
  else if (n)
    out[n-1] = 0;
  return pos;
    18000774:	0007051b          	sext.w	a0,a4
  if (pos < n)
    18000778:	18b76b63          	bltu	a4,a1,1800090e <vnprintf+0x1fc>
  else if (n)
    1800077c:	c589                	beqz	a1,18000786 <vnprintf+0x74>
    out[n-1] = 0;
    1800077e:	00b30733          	add	a4,t1,a1
    18000782:	fe070fa3          	sb	zero,-1(a4)
}
    18000786:	7422                	ld	s0,40(sp)
    18000788:	7482                	ld	s1,32(sp)
    1800078a:	6962                	ld	s2,24(sp)
    1800078c:	69c2                	ld	s3,16(sp)
    1800078e:	6a22                	ld	s4,8(sp)
    18000790:	6a82                	ld	s5,0(sp)
    18000792:	6145                	addi	sp,sp,48
    18000794:	8082                	ret
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000796:	00868793          	addi	a5,a3,8
    1800079a:	1a091d63          	bnez	s2,18000954 <vnprintf+0x242>
    1800079e:	0006aa03          	lw	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180007a2:	4a9d                	li	s5,7
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    180007a4:	86be                	mv	a3,a5
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180007a6:	002a9813          	slli	a6,s5,0x2
    180007aa:	87ba                	mv	a5,a4
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    180007ac:	0785                	addi	a5,a5,1
    180007ae:	02b7f063          	bgeu	a5,a1,180007ce <vnprintf+0xbc>
            int d = (num >> (4*i)) & 0xF;
    180007b2:	410a58b3          	sra	a7,s4,a6
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    180007b6:	00f8f993          	andi	s3,a7,15
    180007ba:	05798913          	addi	s2,s3,87
    180007be:	013f4463          	blt	t5,s3,180007c6 <vnprintf+0xb4>
    180007c2:	03098913          	addi	s2,s3,48
    180007c6:	00f308b3          	add	a7,t1,a5
    180007ca:	ff288fa3          	sb	s2,-1(a7)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    180007ce:	3871                	addiw	a6,a6,-4
    180007d0:	fdc81ee3          	bne	a6,t3,180007ac <vnprintf+0x9a>
  for( ; *s; s++)
    180007d4:	00164783          	lbu	a5,1(a2)
    180007d8:	0705                	addi	a4,a4,1
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
    180007da:	9756                	add	a4,a4,s5
          longarg = false;
    180007dc:	4901                	li	s2,0
          format = false;
    180007de:	4801                	li	a6,0
  for( ; *s; s++)
    180007e0:	0605                	addi	a2,a2,1
    180007e2:	f7bd                	bnez	a5,18000750 <vnprintf+0x3e>
    180007e4:	bf41                	j	18000774 <vnprintf+0x62>
          const char* s2 = va_arg(vl, const char*);
    180007e6:	0006b803          	ld	a6,0(a3)
    180007ea:	00868913          	addi	s2,a3,8
          while (*s2) {
    180007ee:	00084683          	lbu	a3,0(a6)
    180007f2:	18068a63          	beqz	a3,18000986 <vnprintf+0x274>
    180007f6:	87ba                	mv	a5,a4
            if (++pos < n)
    180007f8:	0785                	addi	a5,a5,1
    180007fa:	00b7f663          	bgeu	a5,a1,18000806 <vnprintf+0xf4>
              out[pos-1] = *s2;
    180007fe:	00f308b3          	add	a7,t1,a5
    18000802:	fed88fa3          	sb	a3,-1(a7)
          while (*s2) {
    18000806:	40e786b3          	sub	a3,a5,a4
    1800080a:	96c2                	add	a3,a3,a6
    1800080c:	0006c683          	lbu	a3,0(a3)
    18000810:	f6e5                	bnez	a3,180007f8 <vnprintf+0xe6>
            if (++pos < n)
    18000812:	873e                	mv	a4,a5
  for( ; *s; s++)
    18000814:	00164783          	lbu	a5,1(a2)
          const char* s2 = va_arg(vl, const char*);
    18000818:	86ca                	mv	a3,s2
          format = false;
    1800081a:	4801                	li	a6,0
          longarg = false;
    1800081c:	4901                	li	s2,0
  for( ; *s; s++)
    1800081e:	0605                	addi	a2,a2,1
    18000820:	fb85                	bnez	a5,18000750 <vnprintf+0x3e>
    18000822:	bf89                	j	18000774 <vnprintf+0x62>
          if (++pos < n) out[pos-1] = '0';
    18000824:	00170793          	addi	a5,a4,1
    18000828:	00b7f663          	bgeu	a5,a1,18000834 <vnprintf+0x122>
    1800082c:	00e30833          	add	a6,t1,a4
    18000830:	00780023          	sb	t2,0(a6)
          if (++pos < n) out[pos-1] = 'x';
    18000834:	0709                	addi	a4,a4,2
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000836:	00868813          	addi	a6,a3,8
          if (++pos < n) out[pos-1] = 'x';
    1800083a:	00b77563          	bgeu	a4,a1,18000844 <vnprintf+0x132>
    1800083e:	979a                	add	a5,a5,t1
    18000840:	00878023          	sb	s0,0(a5)
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000844:	0006ba03          	ld	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000848:	4abd                	li	s5,15
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    1800084a:	86c2                	mv	a3,a6
    1800084c:	bfa9                	j	180007a6 <vnprintf+0x94>
    1800084e:	00868993          	addi	s3,a3,8
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000852:	0e090263          	beqz	s2,18000936 <vnprintf+0x224>
    18000856:	0006b803          	ld	a6,0(a3)
          if (num < 0) {
    1800085a:	0e084263          	bltz	a6,1800093e <vnprintf+0x22c>
          for (long nn = num; nn /= 10; digits++)
    1800085e:	02a847b3          	div	a5,a6,a0
    18000862:	10078f63          	beqz	a5,18000980 <vnprintf+0x26e>
          long digits = 1;
    18000866:	4685                	li	a3,1
          for (long nn = num; nn /= 10; digits++)
    18000868:	02a7c7b3          	div	a5,a5,a0
    1800086c:	0685                	addi	a3,a3,1
    1800086e:	ffed                	bnez	a5,18000868 <vnprintf+0x156>
          for (int i = digits-1; i >= 0; i--) {
    18000870:	fff6879b          	addiw	a5,a3,-1
          pos += digits;
    18000874:	88b6                	mv	a7,a3
          for (int i = digits-1; i >= 0; i--) {
    18000876:	0207c863          	bltz	a5,180008a6 <vnprintf+0x194>
    1800087a:	00170a13          	addi	s4,a4,1
            if (pos + i + 1 < n) out[pos + i] = '0' + (num % 10);
    1800087e:	00fa06b3          	add	a3,s4,a5
    18000882:	00b6fb63          	bgeu	a3,a1,18000898 <vnprintf+0x186>
    18000886:	02a866b3          	rem	a3,a6,a0
    1800088a:	00f70933          	add	s2,a4,a5
    1800088e:	991a                	add	s2,s2,t1
    18000890:	0306869b          	addiw	a3,a3,48
    18000894:	00d90023          	sb	a3,0(s2)
          for (int i = digits-1; i >= 0; i--) {
    18000898:	17fd                	addi	a5,a5,-1
    1800089a:	0007869b          	sext.w	a3,a5
            num /= 10;
    1800089e:	02a84833          	div	a6,a6,a0
          for (int i = digits-1; i >= 0; i--) {
    180008a2:	fc06dee3          	bgez	a3,1800087e <vnprintf+0x16c>
  for( ; *s; s++)
    180008a6:	00164783          	lbu	a5,1(a2)
          pos += digits;
    180008aa:	9746                	add	a4,a4,a7
          break;
    180008ac:	86ce                	mv	a3,s3
          longarg = false;
    180008ae:	4901                	li	s2,0
          format = false;
    180008b0:	4801                	li	a6,0
  for( ; *s; s++)
    180008b2:	0605                	addi	a2,a2,1
    180008b4:	e8079ee3          	bnez	a5,18000750 <vnprintf+0x3e>
    180008b8:	bd75                	j	18000774 <vnprintf+0x62>
          if (++pos < n) out[pos-1] = (char)va_arg(vl,int);
    180008ba:	00170793          	addi	a5,a4,1
    180008be:	06b7f363          	bgeu	a5,a1,18000924 <vnprintf+0x212>
    180008c2:	0006a803          	lw	a6,0(a3)
    180008c6:	971a                	add	a4,a4,t1
    180008c8:	06a1                	addi	a3,a3,8
    180008ca:	01070023          	sb	a6,0(a4)
    180008ce:	873e                	mv	a4,a5
  for( ; *s; s++)
    180008d0:	00164783          	lbu	a5,1(a2)
          longarg = false;
    180008d4:	4901                	li	s2,0
          format = false;
    180008d6:	4801                	li	a6,0
  for( ; *s; s++)
    180008d8:	0605                	addi	a2,a2,1
    180008da:	e6079be3          	bnez	a5,18000750 <vnprintf+0x3e>
    180008de:	bd59                	j	18000774 <vnprintf+0x62>
    else if(*s == '%')
    180008e0:	e85785e3          	beq	a5,t0,1800076a <vnprintf+0x58>
      if (++pos < n) out[pos-1] = *s;
    180008e4:	00170893          	addi	a7,a4,1
    180008e8:	00b8fc63          	bgeu	a7,a1,18000900 <vnprintf+0x1ee>
    180008ec:	971a                	add	a4,a4,t1
    180008ee:	00f70023          	sb	a5,0(a4)
  for( ; *s; s++)
    180008f2:	00164783          	lbu	a5,1(a2)
      if (++pos < n) out[pos-1] = *s;
    180008f6:	8746                	mv	a4,a7
  for( ; *s; s++)
    180008f8:	0605                	addi	a2,a2,1
    180008fa:	e4079be3          	bnez	a5,18000750 <vnprintf+0x3e>
    180008fe:	bd9d                	j	18000774 <vnprintf+0x62>
    18000900:	00164783          	lbu	a5,1(a2)
    18000904:	8746                	mv	a4,a7
    18000906:	0605                	addi	a2,a2,1
    18000908:	e40794e3          	bnez	a5,18000750 <vnprintf+0x3e>
    1800090c:	b5a5                	j	18000774 <vnprintf+0x62>
    out[pos] = 0;
    1800090e:	971a                	add	a4,a4,t1
    18000910:	00070023          	sb	zero,0(a4)
}
    18000914:	7422                	ld	s0,40(sp)
    18000916:	7482                	ld	s1,32(sp)
    18000918:	6962                	ld	s2,24(sp)
    1800091a:	69c2                	ld	s3,16(sp)
    1800091c:	6a22                	ld	s4,8(sp)
    1800091e:	6a82                	ld	s5,0(sp)
    18000920:	6145                	addi	sp,sp,48
    18000922:	8082                	ret
    18000924:	873e                	mv	a4,a5
  for( ; *s; s++)
    18000926:	00164783          	lbu	a5,1(a2)
          longarg = false;
    1800092a:	4901                	li	s2,0
          format = false;
    1800092c:	4801                	li	a6,0
  for( ; *s; s++)
    1800092e:	0605                	addi	a2,a2,1
    18000930:	e20790e3          	bnez	a5,18000750 <vnprintf+0x3e>
    18000934:	b581                	j	18000774 <vnprintf+0x62>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000936:	0006a803          	lw	a6,0(a3)
          if (num < 0) {
    1800093a:	f20852e3          	bgez	a6,1800085e <vnprintf+0x14c>
            if (++pos < n) out[pos-1] = '-';
    1800093e:	00170793          	addi	a5,a4,1
            num = -num;
    18000942:	41000833          	neg	a6,a6
            if (++pos < n) out[pos-1] = '-';
    18000946:	02b7f363          	bgeu	a5,a1,1800096c <vnprintf+0x25a>
    1800094a:	971a                	add	a4,a4,t1
    1800094c:	00970023          	sb	s1,0(a4)
    18000950:	873e                	mv	a4,a5
    18000952:	b731                	j	1800085e <vnprintf+0x14c>
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    18000954:	0006ba03          	ld	s4,0(a3)
          for(int i = 2*(longarg ? sizeof(long) : sizeof(int))-1; i >= 0; i--) {
    18000958:	4abd                	li	s5,15
          long num = longarg ? va_arg(vl, long) : va_arg(vl, int);
    1800095a:	86be                	mv	a3,a5
    1800095c:	b5a9                	j	180007a6 <vnprintf+0x94>
  for( ; *s; s++)
    1800095e:	00164783          	lbu	a5,1(a2)
    if(format)
    18000962:	8942                	mv	s2,a6
  for( ; *s; s++)
    18000964:	0605                	addi	a2,a2,1
    18000966:	de0795e3          	bnez	a5,18000750 <vnprintf+0x3e>
    1800096a:	b529                	j	18000774 <vnprintf+0x62>
    1800096c:	873e                	mv	a4,a5
    1800096e:	bdc5                	j	1800085e <vnprintf+0x14c>
  size_t pos = 0;
    18000970:	4701                	li	a4,0
  for( ; *s; s++)
    18000972:	4501                	li	a0,0
  if (pos < n)
    18000974:	00b77d63          	bgeu	a4,a1,1800098e <vnprintf+0x27c>
    out[pos] = 0;
    18000978:	971a                	add	a4,a4,t1
    1800097a:	00070023          	sb	zero,0(a4)
    1800097e:	8082                	ret
          for (long nn = num; nn /= 10; digits++)
    18000980:	4885                	li	a7,1
          for (int i = digits-1; i >= 0; i--) {
    18000982:	4781                	li	a5,0
    18000984:	bddd                	j	1800087a <vnprintf+0x168>
          const char* s2 = va_arg(vl, const char*);
    18000986:	86ca                	mv	a3,s2
          format = false;
    18000988:	4801                	li	a6,0
          longarg = false;
    1800098a:	4901                	li	s2,0
    1800098c:	b3c5                	j	1800076c <vnprintf+0x5a>
  else if (n)
    1800098e:	c591                	beqz	a1,1800099a <vnprintf+0x288>
    out[n-1] = 0;
    18000990:	00b30733          	add	a4,t1,a1
    18000994:	fe070fa3          	sb	zero,-1(a4)
    18000998:	8082                	ret
}
    1800099a:	8082                	ret

000000001800099c <vprintk>:

static void vprintk(const char* s, va_list vl)
{
    1800099c:	716d                	addi	sp,sp,-272
    1800099e:	862a                	mv	a2,a0
    180009a0:	86ae                	mv	a3,a1
  char out[256]; 
  int res = vnprintf(out, sizeof(out), s, vl);
    180009a2:	850a                	mv	a0,sp
    180009a4:	10000593          	li	a1,256
{
    180009a8:	e606                	sd	ra,264(sp)
  int res = vnprintf(out, sizeof(out), s, vl);
    180009aa:	d69ff0ef          	jal	ra,18000712 <vnprintf>
	while (*s){
    180009ae:	00014603          	lbu	a2,0(sp)
    180009b2:	ca0d                	beqz	a2,180009e4 <vprintk+0x48>
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180009b4:	0000f797          	auipc	a5,0xf
    180009b8:	64c7e783          	lwu	a5,1612(a5) # 18010000 <uart_id>
    180009bc:	00379713          	slli	a4,a5,0x3
    180009c0:	00002797          	auipc	a5,0x2
    180009c4:	a8878793          	addi	a5,a5,-1400 # 18002448 <uart_base>
    180009c8:	97ba                	add	a5,a5,a4
    180009ca:	638c                	ld	a1,0(a5)
	writel(value, (volatile void *)(uart_base[uart_id] + offset));
    180009cc:	868a                	mv	a3,sp
	return readl((volatile void *)(uart_base[uart_id] + offset));
    180009ce:	01458713          	addi	a4,a1,20
		_putc(*s++);
    180009d2:	0685                	addi	a3,a3,1
    180009d4:	431c                	lw	a5,0(a4)
	{}while((serial_in(REG_LSR) & LSR_THRE) == 0);
    180009d6:	0207f793          	andi	a5,a5,32
    180009da:	dfed                	beqz	a5,180009d4 <vprintk+0x38>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180009dc:	c190                	sw	a2,0(a1)
	while (*s){
    180009de:	0006c603          	lbu	a2,0(a3)
    180009e2:	fa65                	bnez	a2,180009d2 <vprintk+0x36>
  _puts(out);
}
    180009e4:	60b2                	ld	ra,264(sp)
    180009e6:	6151                	addi	sp,sp,272
    180009e8:	8082                	ret

00000000180009ea <printk>:

void printk(const char* s, ...)
{
    180009ea:	711d                	addi	sp,sp,-96
  va_list vl;
  va_start(vl, s);
    180009ec:	02810313          	addi	t1,sp,40
{
    180009f0:	f42e                	sd	a1,40(sp)

  vprintk(s, vl);
    180009f2:	859a                	mv	a1,t1
{
    180009f4:	ec06                	sd	ra,24(sp)
    180009f6:	f832                	sd	a2,48(sp)
    180009f8:	fc36                	sd	a3,56(sp)
    180009fa:	e0ba                	sd	a4,64(sp)
    180009fc:	e4be                	sd	a5,72(sp)
    180009fe:	e8c2                	sd	a6,80(sp)
    18000a00:	ecc6                	sd	a7,88(sp)
  va_start(vl, s);
    18000a02:	e41a                	sd	t1,8(sp)
  vprintk(s, vl);
    18000a04:	f99ff0ef          	jal	ra,1800099c <vprintk>

  va_end(vl);
}
    18000a08:	60e2                	ld	ra,24(sp)
    18000a0a:	6125                	addi	sp,sp,96
    18000a0c:	8082                	ret

0000000018000a0e <sys_memcpy>:
void * sys_memcpy(void *p_des,const void * p_src,unsigned long size)
{
	char *tmp = p_des;
	const char *s = p_src;

	while (size--)
    18000a0e:	ca19                	beqz	a2,18000a24 <sys_memcpy+0x16>
    18000a10:	962a                	add	a2,a2,a0
	char *tmp = p_des;
    18000a12:	87aa                	mv	a5,a0
		*tmp++ = *s++;
    18000a14:	0005c703          	lbu	a4,0(a1)
    18000a18:	0785                	addi	a5,a5,1
    18000a1a:	0585                	addi	a1,a1,1
    18000a1c:	fee78fa3          	sb	a4,-1(a5)
	while (size--)
    18000a20:	fec79ae3          	bne	a5,a2,18000a14 <sys_memcpy+0x6>

	return p_des;
}
    18000a24:	8082                	ret

0000000018000a26 <sys_memcmp>:
 int sys_memcmp(const void * cs,const void * ct,unsigned int count)
{
    18000a26:	87aa                	mv	a5,a0
	const unsigned char *su1, *su2;
	int res = 0;

	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000a28:	c215                	beqz	a2,18000a4c <sys_memcmp+0x26>
    18000a2a:	1602                	slli	a2,a2,0x20
    18000a2c:	9201                	srli	a2,a2,0x20
    18000a2e:	00c506b3          	add	a3,a0,a2
    18000a32:	a019                	j	18000a38 <sys_memcmp+0x12>
    18000a34:	00d78b63          	beq	a5,a3,18000a4a <sys_memcmp+0x24>
		if ((res = *su1 - *su2) != 0)
    18000a38:	0007c503          	lbu	a0,0(a5)
    18000a3c:	0005c703          	lbu	a4,0(a1)
	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000a40:	0785                	addi	a5,a5,1
    18000a42:	0585                	addi	a1,a1,1
		if ((res = *su1 - *su2) != 0)
    18000a44:	9d19                	subw	a0,a0,a4
    18000a46:	d57d                	beqz	a0,18000a34 <sys_memcmp+0xe>
			break;
	return res;
}
    18000a48:	8082                	ret
    18000a4a:	8082                	ret
	for( su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
    18000a4c:	4501                	li	a0,0
}
    18000a4e:	8082                	ret

0000000018000a50 <_memcpy>:
void * _memcpy(void * dest,const void *src,unsigned int count)
{
	char *tmp = (char *) dest;
	const char *s = (char *) src;

	while (count--)
    18000a50:	ce11                	beqz	a2,18000a6c <_memcpy+0x1c>
    18000a52:	1602                	slli	a2,a2,0x20
    18000a54:	9201                	srli	a2,a2,0x20
    18000a56:	00c506b3          	add	a3,a0,a2
	char *tmp = (char *) dest;
    18000a5a:	87aa                	mv	a5,a0
		*tmp++ = *s++;
    18000a5c:	0005c703          	lbu	a4,0(a1)
    18000a60:	0785                	addi	a5,a5,1
    18000a62:	0585                	addi	a1,a1,1
    18000a64:	fee78fa3          	sb	a4,-1(a5)
	while (count--)
    18000a68:	fef69ae3          	bne	a3,a5,18000a5c <_memcpy+0xc>
	return dest;
}
    18000a6c:	8082                	ret

0000000018000a6e <sys_memcpy_32>:
RETURN VALUE:
===========================================================================*/
void sys_memcpy_32(void *p_des,const void * p_src,unsigned long size)
{
	unsigned long i;
	for (i=0;i<size;i++)
    18000a6e:	ca19                	beqz	a2,18000a84 <sys_memcpy_32+0x16>
    18000a70:	060e                	slli	a2,a2,0x3
    18000a72:	00c58733          	add	a4,a1,a2
		*((unsigned long*)p_des+i) = *((unsigned long*)p_src+i);
    18000a76:	619c                	ld	a5,0(a1)
	for (i=0;i<size;i++)
    18000a78:	05a1                	addi	a1,a1,8
    18000a7a:	0521                	addi	a0,a0,8
		*((unsigned long*)p_des+i) = *((unsigned long*)p_src+i);
    18000a7c:	fef53c23          	sd	a5,-8(a0)
	for (i=0;i<size;i++)
    18000a80:	fee59be3          	bne	a1,a4,18000a76 <sys_memcpy_32+0x8>
}
    18000a84:	8082                	ret

0000000018000a86 <sys_memset>:
RETURN VALUE:
===========================================================================*/
void sys_memset(void *p_des,unsigned char c,unsigned long size)
{
	unsigned long i;
	for (i=0;i<size;i++)
    18000a86:	c219                	beqz	a2,18000a8c <sys_memset+0x6>
		*((char*)p_des+i) = c;
    18000a88:	7fa0106f          	j	18002282 <memset>
}
    18000a8c:	8082                	ret

0000000018000a8e <sys_memset32>:
RETURN VALUE:
===========================================================================*/
void sys_memset32(void *p_des,int c,unsigned long size)
{
	unsigned long i;
	for(i=0; i< size; i++)
    18000a8e:	00361793          	slli	a5,a2,0x3
    18000a92:	97aa                	add	a5,a5,a0
    18000a94:	c609                	beqz	a2,18000a9e <sys_memset32+0x10>
		((unsigned long*)p_des)[i] = c;
    18000a96:	e10c                	sd	a1,0(a0)
	for(i=0; i< size; i++)
    18000a98:	0521                	addi	a0,a0,8
    18000a9a:	fef51ee3          	bne	a0,a5,18000a96 <sys_memset32+0x8>
}
    18000a9e:	8082                	ret

0000000018000aa0 <spi_register>:
#define SPI_CONTROLLER_NUM	1
struct spi_operation *operations[SPI_CONTROLLER_NUM];

int spi_register(unsigned int bus, struct spi_operation *operation)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000aa0:	e511                	bnez	a0,18000aac <spi_register+0xc>
		return -1;

	operations[bus] = operation;
    18000aa2:	0000f797          	auipc	a5,0xf
    18000aa6:	56b7b323          	sd	a1,1382(a5) # 18010008 <operations>

	return 0;
    18000aaa:	8082                	ret
		return -1;
    18000aac:	557d                	li	a0,-1
}
    18000aae:	8082                	ret

0000000018000ab0 <spi_unregister>:

int spi_unregister(unsigned int bus)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000ab0:	e511                	bnez	a0,18000abc <spi_unregister+0xc>
		return -1;

	operations[bus] = 0;
    18000ab2:	0000f797          	auipc	a5,0xf
    18000ab6:	5407bb23          	sd	zero,1366(a5) # 18010008 <operations>

	return 0;
    18000aba:	8082                	ret
		return -1;
    18000abc:	557d                	li	a0,-1
}
    18000abe:	8082                	ret

0000000018000ac0 <spi_setup_slave>:

struct spi_slave *spi_setup_slave(unsigned int bus, unsigned int cs,
		unsigned int max_hz, unsigned int mode, unsigned int bus_width)
{
	if(bus> SPI_CONTROLLER_NUM-1)
    18000ac0:	e901                	bnez	a0,18000ad0 <spi_setup_slave+0x10>
		return NULL;

	if(operations[bus]->setup_slave)
    18000ac2:	0000f797          	auipc	a5,0xf
    18000ac6:	5467b783          	ld	a5,1350(a5) # 18010008 <operations>
    18000aca:	639c                	ld	a5,0(a5)
    18000acc:	c391                	beqz	a5,18000ad0 <spi_setup_slave+0x10>
	{
		return operations[bus]->setup_slave(bus,cs,max_hz,mode,bus_width);
    18000ace:	8782                	jr	a5
	}
	return NULL;
}
    18000ad0:	4501                	li	a0,0
    18000ad2:	8082                	ret

0000000018000ad4 <spi_xfer>:
		void *din, unsigned long flags,int bit_mode)
{
	unsigned int bus = slave->bus;
	int ret = -1;

	if(bus> SPI_CONTROLLER_NUM-1)
    18000ad4:	00052803          	lw	a6,0(a0)
    18000ad8:	00081b63          	bnez	a6,18000aee <spi_xfer+0x1a>
		return -1;

	if(operations[bus]->spi_xfer)
    18000adc:	0000f817          	auipc	a6,0xf
    18000ae0:	52c83803          	ld	a6,1324(a6) # 18010008 <operations>
    18000ae4:	00883803          	ld	a6,8(a6)
    18000ae8:	00080363          	beqz	a6,18000aee <spi_xfer+0x1a>
		ret = operations[bus]->spi_xfer(slave, bitlen, dout, din, flags, bit_mode);
    18000aec:	8802                	jr	a6

	return ret;
}
    18000aee:	557d                	li	a0,-1
    18000af0:	8082                	ret

0000000018000af2 <spi_flash_probe_nor>:
	struct spi_flash_params *params;
	struct spi_flash *flash;
	u32 id = 0;
	static int i = 0;

	id = ((idcode[2] << 16) | (idcode[1] << 8) | idcode[0]);
    18000af2:	0025c783          	lbu	a5,2(a1)
    18000af6:	0015c703          	lbu	a4,1(a1)
    18000afa:	0005c683          	lbu	a3,0(a1)
    18000afe:	0107979b          	slliw	a5,a5,0x10
    18000b02:	0087171b          	slliw	a4,a4,0x8
    18000b06:	8fd9                	or	a5,a5,a4
    18000b08:	8fd5                	or	a5,a5,a3
    18000b0a:	0007871b          	sext.w	a4,a5
    18000b0e:	87ba                	mv	a5,a4
    if(id == 0x0)
    18000b10:	c355                	beqz	a4,18000bb4 <spi_flash_probe_nor+0xc2>
    {
        return NULL;
    }
	params = spi_flash_table;
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000b12:	0000f717          	auipc	a4,0xf
    18000b16:	4e072f23          	sw	zero,1278(a4) # 18010010 <i.0>
	{
		if ((spi_flash_table[i].id & 0xFFFFFF) == id)
    18000b1a:	00200737          	lui	a4,0x200
    18000b1e:	20170713          	addi	a4,a4,513 # 200201 <__stack_size+0x1ffa01>
    18000b22:	08e78b63          	beq	a5,a4,18000bb8 <spi_flash_probe_nor+0xc6>
    18000b26:	4785                	li	a5,1
    18000b28:	0000f717          	auipc	a4,0xf
    18000b2c:	4ef72423          	sw	a5,1256(a4) # 18010010 <i.0>
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000b30:	00002617          	auipc	a2,0x2
    18000b34:	94860613          	addi	a2,a2,-1720 # 18002478 <digits.0+0x10>
    18000b38:	4685                	li	a3,1
		{
			break;
		}
	}

	flash = &g_spi_flash[spi->bus];
    18000b3a:	00056783          	lwu	a5,0(a0)
		//uart_printf("SF: Failed to allocate memory\r\n");
		return NULL;
	}

	flash->name = spi_flash_table[i].name;
	if(spi_flash_table[i].flags == NOR)
    18000b3e:	00169713          	slli	a4,a3,0x1
    18000b42:	9736                	add	a4,a4,a3
	flash = &g_spi_flash[spi->bus];
    18000b44:	00379513          	slli	a0,a5,0x3
    18000b48:	8d1d                	sub	a0,a0,a5
	if(spi_flash_table[i].flags == NOR)
    18000b4a:	070e                	slli	a4,a4,0x3
    18000b4c:	00002797          	auipc	a5,0x2
    18000b50:	94c78793          	addi	a5,a5,-1716 # 18002498 <spi_flash_table>
    18000b54:	973e                	add	a4,a4,a5
    18000b56:	4b54                	lw	a3,20(a4)
	flash = &g_spi_flash[spi->bus];
    18000b58:	00351793          	slli	a5,a0,0x3
    18000b5c:	0000f517          	auipc	a0,0xf
    18000b60:	4bc50513          	addi	a0,a0,1212 # 18010018 <g_spi_flash>
    18000b64:	953e                	add	a0,a0,a5
	flash->name = spi_flash_table[i].name;
    18000b66:	e510                	sd	a2,8(a0)
	if(spi_flash_table[i].flags == NOR)
    18000b68:	e6b9                	bnez	a3,18000bb6 <spi_flash_probe_nor+0xc4>
	{
		/* Assuming power-of-two page size initially. */
		flash->write = spi_flash_cmd_write_mode;
		flash->erase = spi_flash_erase_mode;
		flash->read = spi_flash_read_mode;
		flash->page_size = 1 << spi_flash_table[i].l2_page_size;
    18000b6a:	00c74583          	lbu	a1,12(a4)
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000b6e:	00e75683          	lhu	a3,14(a4)
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000b72:	01075783          	lhu	a5,16(a4)
		flash->size = flash->page_size * spi_flash_table[i].pages_per_sector
						* spi_flash_table[i].sectors_per_block
						* spi_flash_table[i].nr_blocks;
    18000b76:	01275603          	lhu	a2,18(a4)
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000b7a:	00b6973b          	sllw	a4,a3,a1
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000b7e:	02e787bb          	mulw	a5,a5,a4
		flash->page_size = 1 << spi_flash_table[i].l2_page_size;
    18000b82:	4685                	li	a3,1
    18000b84:	00b696bb          	sllw	a3,a3,a1
    18000b88:	c954                	sw	a3,20(a0)
		flash->write = spi_flash_cmd_write_mode;
    18000b8a:	00001597          	auipc	a1,0x1
    18000b8e:	b3258593          	addi	a1,a1,-1230 # 180016bc <spi_flash_cmd_write_mode>
    18000b92:	f50c                	sd	a1,40(a0)
		flash->erase = spi_flash_erase_mode;
    18000b94:	00001597          	auipc	a1,0x1
    18000b98:	afe58593          	addi	a1,a1,-1282 # 18001692 <spi_flash_erase_mode>
    18000b9c:	f90c                	sd	a1,48(a0)
		flash->read = spi_flash_read_mode;
    18000b9e:	00001597          	auipc	a1,0x1
    18000ba2:	e0058593          	addi	a1,a1,-512 # 1800199e <spi_flash_read_mode>
    18000ba6:	f10c                	sd	a1,32(a0)
						* spi_flash_table[i].nr_blocks;
    18000ba8:	02f606bb          	mulw	a3,a2,a5
		flash->sector_size = flash->page_size * spi_flash_table[i].pages_per_sector;
    18000bac:	cd18                	sw	a4,24(a0)
		flash->block_size = flash->sector_size * spi_flash_table[i].sectors_per_block;
    18000bae:	cd5c                	sw	a5,28(a0)
		flash->size = flash->page_size * spi_flash_table[i].pages_per_sector
    18000bb0:	c914                	sw	a3,16(a0)
    18000bb2:	8082                	ret
        return NULL;
    18000bb4:	4501                	li	a0,0
	}

	//uart_printf("spi probe complete\r\n");

	return flash;
}
    18000bb6:	8082                	ret
	for (i = 0; spi_flash_table[i].name != NULL; i++)
    18000bb8:	00002617          	auipc	a2,0x2
    18000bbc:	8d060613          	addi	a2,a2,-1840 # 18002488 <digits.0+0x20>
    18000bc0:	4681                	li	a3,0
    18000bc2:	bfa5                	j	18000b3a <spi_flash_probe_nor+0x48>

0000000018000bc4 <spi_flash_probe>:

static struct spi_flash aic_flash;

struct spi_flash *spi_flash_probe(unsigned int bus, unsigned int cs,
		unsigned int max_hz, unsigned int mode, unsigned int bus_width)
{
    18000bc4:	1101                	addi	sp,sp,-32
    18000bc6:	ec06                	sd	ra,24(sp)
    18000bc8:	e822                	sd	s0,16(sp)
	struct spi_slave *spi;
	struct spi_flash *flash = &aic_flash;
	int ret = 0;
	u8 idcode[IDCODE_LEN];

	spi = spi_setup_slave(bus, cs, max_hz, mode, bus_width);
    18000bca:	ef7ff0ef          	jal	ra,18000ac0 <spi_setup_slave>
	if (!spi) {
    18000bce:	c121                	beqz	a0,18000c0e <spi_flash_probe+0x4a>
	buf[0] = cmd;
    18000bd0:	f9f00813          	li	a6,-97
	unsigned char buf[4] = {0};// = {(u8)cmd, 0x00, 0x00, 0x00};
    18000bd4:	c402                	sw	zero,8(sp)
	ret1 = spi_xfer(spi, 1*8, &buf[0], NULL, SPI_XFER_BEGIN, 8);
    18000bd6:	47a1                	li	a5,8
    18000bd8:	4705                	li	a4,1
    18000bda:	4681                	li	a3,0
    18000bdc:	0030                	addi	a2,sp,8
    18000bde:	45a1                	li	a1,8
    18000be0:	842a                	mv	s0,a0
	buf[0] = cmd;
    18000be2:	01010423          	sb	a6,8(sp)
	ret1 = spi_xfer(spi, 1*8, &buf[0], NULL, SPI_XFER_BEGIN, 8);
    18000be6:	eefff0ef          	jal	ra,18000ad4 <spi_xfer>
	ret2 = spi_xfer(spi, len*8, NULL, response, SPI_XFER_END, 8);
    18000bea:	45e1                	li	a1,24
    18000bec:	47a1                	li	a5,8
    18000bee:	4709                	li	a4,2
    18000bf0:	868a                	mv	a3,sp
    18000bf2:	4601                	li	a2,0
    18000bf4:	8522                	mv	a0,s0
    18000bf6:	edfff0ef          	jal	ra,18000ad4 <spi_xfer>
		goto err_read_id;
	}

	//print_id(idcode, sizeof(idcode));

	flash = spi_flash_probe_nor(spi,idcode);
    18000bfa:	858a                	mv	a1,sp
    18000bfc:	8522                	mv	a0,s0
    18000bfe:	ef5ff0ef          	jal	ra,18000af2 <spi_flash_probe_nor>
	if (!flash)
    18000c02:	c111                	beqz	a0,18000c06 <spi_flash_probe+0x42>
	{
		goto err_manufacturer_probe;
	}

	flash->spi = spi;
    18000c04:	e100                	sd	s0,0(a0)

err_manufacturer_probe:
err_read_id:

	return NULL;
}
    18000c06:	60e2                	ld	ra,24(sp)
    18000c08:	6442                	ld	s0,16(sp)
    18000c0a:	6105                	addi	sp,sp,32
    18000c0c:	8082                	ret
    18000c0e:	60e2                	ld	ra,24(sp)
    18000c10:	6442                	ld	s0,16(sp)
		return NULL;
    18000c12:	4501                	li	a0,0
}
    18000c14:	6105                	addi	sp,sp,32
    18000c16:	8082                	ret

0000000018000c18 <cadence_spi_xfer>:
}


static int cadence_spi_xfer(struct spi_slave *slave, unsigned int bitlen,
			    const void *dout, void *din, unsigned long flags)
{
    18000c18:	715d                	addi	sp,sp,-80
    18000c1a:	e0a2                	sd	s0,64(sp)
    18000c1c:	fc26                	sd	s1,56(sp)
    18000c1e:	f84a                	sd	s2,48(sp)
    18000c20:	f44e                	sd	s3,40(sp)
    18000c22:	ec56                	sd	s5,24(sp)
    18000c24:	e85a                	sd	s6,16(sp)
    18000c26:	e45e                	sd	s7,8(sp)
    18000c28:	e062                	sd	s8,0(sp)
	struct cadence_spi_platdata *plat = &cadence_plat;
	struct cadence_spi_priv *priv = &spi_priv;
	void * base = priv->regbase;
    18000c2a:	0000fb17          	auipc	s6,0xf
    18000c2e:	426b0b13          	addi	s6,s6,1062 # 18010050 <spi_priv>
{
    18000c32:	e486                	sd	ra,72(sp)
    18000c34:	f052                	sd	s4,32(sp)
	u8 *cmd_buf = priv->cmd_buf;
	unsigned int data_bytes = 0;
	int err = 0;
	u32 mode = CQSPI_STIG_WRITE;

	if (flags & SPI_XFER_BEGIN) {
    18000c36:	00177c13          	andi	s8,a4,1
	void * base = priv->regbase;
    18000c3a:	000b3b83          	ld	s7,0(s6)
{
    18000c3e:	843a                	mv	s0,a4
    18000c40:	892a                	mv	s2,a0
    18000c42:	84ae                	mv	s1,a1
    18000c44:	89b2                	mv	s3,a2
    18000c46:	8ab6                	mv	s5,a3
	if (flags & SPI_XFER_BEGIN) {
    18000c48:	0a0c1f63          	bnez	s8,18000d06 <cadence_spi_xfer+0xee>
		/* copy command to local buffer */
		priv->cmd_len = bitlen / 8;
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
	}

	if (flags == (SPI_XFER_BEGIN | SPI_XFER_END)) 
    18000c4c:	478d                	li	a5,3
		data_bytes = bitlen / 8;
	}
	//uart_printf("%s: len=%d [bytes]\n", __func__, data_bytes);

	/* Set Chip select */
	cadence_qspi_apb_chipselect(base, slave->cs,
    18000c4e:	00c92583          	lw	a1,12(s2)
				    CONFIG_CQSPI_DECODER);

	if ((flags & SPI_XFER_END) || (flags == 0)) {
    18000c52:	00247a13          	andi	s4,s0,2
	cadence_qspi_apb_chipselect(base, slave->cs,
    18000c56:	4601                	li	a2,0
    18000c58:	855e                	mv	a0,s7
	if (flags == (SPI_XFER_BEGIN | SPI_XFER_END)) 
    18000c5a:	08f40563          	beq	s0,a5,18000ce4 <cadence_spi_xfer+0xcc>
		data_bytes = bitlen / 8;
    18000c5e:	0034d49b          	srliw	s1,s1,0x3
	cadence_qspi_apb_chipselect(base, slave->cs,
    18000c62:	74f000ef          	jal	ra,18001bb0 <cadence_qspi_apb_chipselect>
	if ((flags & SPI_XFER_END) || (flags == 0)) {
    18000c66:	000a1463          	bnez	s4,18000c6e <cadence_spi_xfer+0x56>
	int err = 0;
    18000c6a:	4901                	li	s2,0
	if ((flags & SPI_XFER_END) || (flags == 0)) {
    18000c6c:	ec39                	bnez	s0,18000cca <cadence_spi_xfer+0xb2>
		if (priv->cmd_len == 0) {
    18000c6e:	010b2583          	lw	a1,16(s6)
    18000c72:	10058163          	beqz	a1,18000d74 <cadence_spi_xfer+0x15c>
			//uart_printf("QSPI: Error, command is empty.\n");
			return -1;
		}

		if (din && data_bytes) {
    18000c76:	0c0a8263          	beqz	s5,18000d3a <cadence_spi_xfer+0x122>
    18000c7a:	c0e1                	beqz	s1,18000d3a <cadence_spi_xfer+0x122>
			/* read */
			/* Use STIG if no address. */
			if (!CQSPI_IS_ADDR(priv->cmd_len))
    18000c7c:	4785                	li	a5,1
    18000c7e:	0af58263          	beq	a1,a5,18000d22 <cadence_spi_xfer+0x10a>
			err = cadence_qspi_apb_command_write(base,
				priv->cmd_len, cmd_buf,
				data_bytes, dout);
		break;
		case CQSPI_INDIRECT_READ:
			err = cadence_qspi_apb_indirect_read_setup(plat,
    18000c82:	0000f617          	auipc	a2,0xf
    18000c86:	3e260613          	addi	a2,a2,994 # 18010064 <spi_priv+0x14>
    18000c8a:	0000f517          	auipc	a0,0xf
    18000c8e:	40e50513          	addi	a0,a0,1038 # 18010098 <cadence_plat>
    18000c92:	1b2010ef          	jal	ra,18001e44 <cadence_qspi_apb_indirect_read_setup>
    18000c96:	892a                	mv	s2,a0
				priv->cmd_len, cmd_buf);
			if (!err) {
    18000c98:	e911                	bnez	a0,18000cac <cadence_spi_xfer+0x94>
				err = cadence_qspi_apb_indirect_read_execute
    18000c9a:	8656                	mv	a2,s5
    18000c9c:	85a6                	mv	a1,s1
    18000c9e:	0000f517          	auipc	a0,0xf
    18000ca2:	3fa50513          	addi	a0,a0,1018 # 18010098 <cadence_plat>
    18000ca6:	248010ef          	jal	ra,18001eee <cadence_qspi_apb_indirect_read_execute>
    18000caa:	892a                	mv	s2,a0
		default:
			err = -1;
			break;
		}

		if (flags & SPI_XFER_END) {
    18000cac:	000a0f63          	beqz	s4,18000cca <cadence_spi_xfer+0xb2>
			/* clear command buffer */
			sys_memset(cmd_buf, 0, sizeof(priv->cmd_buf));
    18000cb0:	02000613          	li	a2,32
    18000cb4:	4581                	li	a1,0
    18000cb6:	0000f517          	auipc	a0,0xf
    18000cba:	3ae50513          	addi	a0,a0,942 # 18010064 <spi_priv+0x14>
    18000cbe:	dc9ff0ef          	jal	ra,18000a86 <sys_memset>
			priv->cmd_len = 0;
    18000cc2:	0000f797          	auipc	a5,0xf
    18000cc6:	3807af23          	sw	zero,926(a5) # 18010060 <spi_priv+0x10>
		}
	}

	return err;
}
    18000cca:	60a6                	ld	ra,72(sp)
    18000ccc:	6406                	ld	s0,64(sp)
    18000cce:	74e2                	ld	s1,56(sp)
    18000cd0:	79a2                	ld	s3,40(sp)
    18000cd2:	7a02                	ld	s4,32(sp)
    18000cd4:	6ae2                	ld	s5,24(sp)
    18000cd6:	6b42                	ld	s6,16(sp)
    18000cd8:	6ba2                	ld	s7,8(sp)
    18000cda:	6c02                	ld	s8,0(sp)
    18000cdc:	854a                	mv	a0,s2
    18000cde:	7942                	ld	s2,48(sp)
    18000ce0:	6161                	addi	sp,sp,80
    18000ce2:	8082                	ret
	cadence_qspi_apb_chipselect(base, slave->cs,
    18000ce4:	6cd000ef          	jal	ra,18001bb0 <cadence_qspi_apb_chipselect>
		if (priv->cmd_len == 0) {
    18000ce8:	010b2583          	lw	a1,16(s6)
    18000cec:	c5c1                	beqz	a1,18000d74 <cadence_spi_xfer+0x15c>
		data_bytes = 0;
    18000cee:	4481                	li	s1,0
			err = cadence_qspi_apb_command_write(base,
    18000cf0:	874e                	mv	a4,s3
    18000cf2:	86a6                	mv	a3,s1
    18000cf4:	0000f617          	auipc	a2,0xf
    18000cf8:	37060613          	addi	a2,a2,880 # 18010064 <spi_priv+0x14>
    18000cfc:	855e                	mv	a0,s7
    18000cfe:	03a010ef          	jal	ra,18001d38 <cadence_qspi_apb_command_write>
    18000d02:	892a                	mv	s2,a0
		break;
    18000d04:	b765                	j	18000cac <cadence_spi_xfer+0x94>
		priv->cmd_len = bitlen / 8;
    18000d06:	0035d79b          	srliw	a5,a1,0x3
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
    18000d0a:	0035d61b          	srliw	a2,a1,0x3
    18000d0e:	0000f517          	auipc	a0,0xf
    18000d12:	35650513          	addi	a0,a0,854 # 18010064 <spi_priv+0x14>
    18000d16:	85ce                	mv	a1,s3
		priv->cmd_len = bitlen / 8;
    18000d18:	00fb2823          	sw	a5,16(s6)
		sys_memcpy(cmd_buf, dout, priv->cmd_len);
    18000d1c:	cf3ff0ef          	jal	ra,18000a0e <sys_memcpy>
    18000d20:	b735                	j	18000c4c <cadence_spi_xfer+0x34>
			err = cadence_qspi_apb_command_read(
    18000d22:	8756                	mv	a4,s5
    18000d24:	86a6                	mv	a3,s1
    18000d26:	0000f617          	auipc	a2,0xf
    18000d2a:	33e60613          	addi	a2,a2,830 # 18010064 <spi_priv+0x14>
    18000d2e:	4585                	li	a1,1
    18000d30:	855e                	mv	a0,s7
    18000d32:	75d000ef          	jal	ra,18001c8e <cadence_qspi_apb_command_read>
    18000d36:	892a                	mv	s2,a0
		break;
    18000d38:	bf95                	j	18000cac <cadence_spi_xfer+0x94>
		} else if (dout && !(flags & SPI_XFER_BEGIN)) {
    18000d3a:	fa098be3          	beqz	s3,18000cf0 <cadence_spi_xfer+0xd8>
    18000d3e:	fa0c19e3          	bnez	s8,18000cf0 <cadence_spi_xfer+0xd8>
			if (!CQSPI_IS_ADDR(priv->cmd_len))
    18000d42:	4785                	li	a5,1
    18000d44:	faf586e3          	beq	a1,a5,18000cf0 <cadence_spi_xfer+0xd8>
			err = cadence_qspi_apb_indirect_write_setup
    18000d48:	0000f617          	auipc	a2,0xf
    18000d4c:	31c60613          	addi	a2,a2,796 # 18010064 <spi_priv+0x14>
    18000d50:	0000f517          	auipc	a0,0xf
    18000d54:	34850513          	addi	a0,a0,840 # 18010098 <cadence_plat>
    18000d58:	2f4010ef          	jal	ra,1800204c <cadence_qspi_apb_indirect_write_setup>
    18000d5c:	892a                	mv	s2,a0
			if (!err) {
    18000d5e:	f539                	bnez	a0,18000cac <cadence_spi_xfer+0x94>
				err = cadence_qspi_apb_indirect_write_execute
    18000d60:	864e                	mv	a2,s3
    18000d62:	85a6                	mv	a1,s1
    18000d64:	0000f517          	auipc	a0,0xf
    18000d68:	33450513          	addi	a0,a0,820 # 18010098 <cadence_plat>
    18000d6c:	376010ef          	jal	ra,180020e2 <cadence_qspi_apb_indirect_write_execute>
    18000d70:	892a                	mv	s2,a0
    18000d72:	bf2d                	j	18000cac <cadence_spi_xfer+0x94>
			return -1;
    18000d74:	597d                	li	s2,-1
    18000d76:	bf91                	j	18000cca <cadence_spi_xfer+0xb2>

0000000018000d78 <cadence_spi_write_speed.isra.0>:
static int cadence_spi_write_speed(unsigned int hz)
    18000d78:	1101                	addi	sp,sp,-32
    18000d7a:	e822                	sd	s0,16(sp)
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000d7c:	0000f417          	auipc	s0,0xf
    18000d80:	2d440413          	addi	s0,s0,724 # 18010050 <spi_priv>
static int cadence_spi_write_speed(unsigned int hz)
    18000d84:	e426                	sd	s1,8(sp)
    18000d86:	84aa                	mv	s1,a0
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000d88:	6008                	ld	a0,0(s0)
static int cadence_spi_write_speed(unsigned int hz)
    18000d8a:	e04a                	sd	s2,0(sp)
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000d8c:	0ee6b937          	lui	s2,0xee6b
    18000d90:	8626                	mv	a2,s1
    18000d92:	28090593          	addi	a1,s2,640 # ee6b280 <__stack_size+0xee6aa80>
static int cadence_spi_write_speed(unsigned int hz)
    18000d96:	ec06                	sd	ra,24(sp)
	cadence_qspi_apb_config_baudrate_div(priv->regbase,
    18000d98:	5a9000ef          	jal	ra,18001b40 <cadence_qspi_apb_config_baudrate_div>
	cadence_qspi_apb_delay(priv->regbase, CONFIG_CQSPI_REF_CLK, hz,
    18000d9c:	07842803          	lw	a6,120(s0)
    18000da0:	587c                	lw	a5,116(s0)
    18000da2:	5838                	lw	a4,112(s0)
    18000da4:	5474                	lw	a3,108(s0)
    18000da6:	6008                	ld	a0,0(s0)
}
    18000da8:	6442                	ld	s0,16(sp)
    18000daa:	60e2                	ld	ra,24(sp)
	cadence_qspi_apb_delay(priv->regbase, CONFIG_CQSPI_REF_CLK, hz,
    18000dac:	8626                	mv	a2,s1
    18000dae:	28090593          	addi	a1,s2,640
}
    18000db2:	64a2                	ld	s1,8(sp)
    18000db4:	6902                	ld	s2,0(sp)
    18000db6:	6105                	addi	sp,sp,32
	cadence_qspi_apb_delay(priv->regbase, CONFIG_CQSPI_REF_CLK, hz,
    18000db8:	6430006f          	j	18001bfa <cadence_qspi_apb_delay>

0000000018000dbc <cadence_spi4x_setup_slave>:
{
    18000dbc:	7159                	addi	sp,sp,-112
    18000dbe:	f062                	sd	s8,32(sp)
	plat->tsd2d_ns =  255;
    18000dc0:	4785                	li	a5,1
	plat->block_size = 16;
    18000dc2:	4865                	li	a6,25
{
    18000dc4:	8c3a                	mv	s8,a4
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000dc6:	05f5e737          	lui	a4,0x5f5e
{
    18000dca:	eca6                	sd	s1,88(sp)
	plat->tsd2d_ns =  255;
    18000dcc:	02179313          	slli	t1,a5,0x21
	spi4slave->base = (void *)QSPI_BASE_ADDR;
    18000dd0:	0000f497          	auipc	s1,0xf
    18000dd4:	28048493          	addi	s1,s1,640 # 18010050 <spi_priv>
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000dd8:	10070713          	addi	a4,a4,256 # 5f5e100 <__stack_size+0x5f5d900>
	plat->tslch_ns =  20;
    18000ddc:	17a2                	slli	a5,a5,0x28
	plat->block_size = 16;
    18000dde:	180e                	slli	a6,a6,0x23
	spi4slave->base = (void *)QSPI_BASE_ADDR;
    18000de0:	118608b7          	lui	a7,0x11860
	plat->ahbbase = (void *)QSPI_BASE_AHB_ADDR;
    18000de4:	20000e37          	lui	t3,0x20000
	plat->tsd2d_ns =  255;
    18000de8:	0ff30313          	addi	t1,t1,255
	plat->tslch_ns =  20;
    18000dec:	07d1                	addi	a5,a5,20
	plat->block_size = 16;
    18000dee:	0841                	addi	a6,a6,16
{
    18000df0:	ec66                	sd	s9,24(sp)
	plat->max_hz = CADENCE_QSPI_MAX_HZ;
    18000df2:	c4b8                	sw	a4,72(s1)
{
    18000df4:	8caa                	mv	s9,a0
	plat->page_size = 256;
    18000df6:	10000713          	li	a4,256
	cadence_qspi_apb_controller_disable(priv->regbase);
    18000dfa:	11860537          	lui	a0,0x11860
{
    18000dfe:	f486                	sd	ra,104(sp)
	spi4slave->base = (void *)QSPI_BASE_ADDR;
    18000e00:	0914ac23          	sw	a7,152(s1)
	plat->regbase = (void *)QSPI_BASE_ADDR;
    18000e04:	0514b823          	sd	a7,80(s1)
	plat->ahbbase = (void *)QSPI_BASE_AHB_ADDR;
    18000e08:	05c4bc23          	sd	t3,88(s1)
	plat->page_size = 256;
    18000e0c:	d0f8                	sw	a4,100(s1)
	plat->block_size = 16;
    18000e0e:	0704b423          	sd	a6,104(s1)
	plat->tsd2d_ns =  255;
    18000e12:	0664b823          	sd	t1,112(s1)
	plat->tslch_ns =  20;
    18000e16:	fcbc                	sd	a5,120(s1)
	priv->regbase = plat->regbase;
    18000e18:	0114b023          	sd	a7,0(s1)
	priv->ahbbase = plat->ahbbase;
    18000e1c:	01c4b423          	sd	t3,8(s1)
{
    18000e20:	f0a2                	sd	s0,96(sp)
    18000e22:	e8ca                	sd	s2,80(sp)
    18000e24:	8436                	mv	s0,a3
    18000e26:	e4ce                	sd	s3,72(sp)
    18000e28:	f85a                	sd	s6,48(sp)
    18000e2a:	8932                	mv	s2,a2
    18000e2c:	8b2e                	mv	s6,a1
    18000e2e:	e0d2                	sd	s4,64(sp)
    18000e30:	fc56                	sd	s5,56(sp)
    18000e32:	f45e                	sd	s7,40(sp)
    18000e34:	e86a                	sd	s10,16(sp)
	cadence_qspi_apb_controller_disable(priv->regbase);
    18000e36:	4c7000ef          	jal	ra,18001afc <cadence_qspi_apb_controller_disable>
	cadence_qspi_apb_set_clk_mode(priv->regbase, clk_pol, clk_pha);
    18000e3a:	6088                	ld	a0,0(s1)
	clk_pol = (mode & SPI_CPOL) ? 1 : 0;
    18000e3c:	0014559b          	srliw	a1,s0,0x1
	cadence_qspi_apb_set_clk_mode(priv->regbase, clk_pol, clk_pha);
    18000e40:	00147613          	andi	a2,s0,1
    18000e44:	8985                	andi	a1,a1,1
    18000e46:	53f000ef          	jal	ra,18001b84 <cadence_qspi_apb_set_clk_mode>
	cadence_qspi_apb_controller_init(plat);
    18000e4a:	0000f517          	auipc	a0,0xf
    18000e4e:	24e50513          	addi	a0,a0,590 # 18010098 <cadence_plat>
    18000e52:	5cf000ef          	jal	ra,18001c20 <cadence_qspi_apb_controller_init>
	if (max_hz > plat->max_hz)
    18000e56:	0484a983          	lw	s3,72(s1)
    18000e5a:	01397363          	bgeu	s2,s3,18000e60 <cadence_spi4x_setup_slave+0xa4>
    18000e5e:	89ca                	mv	s3,s2
	if (priv->previous_hz != max_hz ||
    18000e60:	40fc                	lw	a5,68(s1)
    18000e62:	01379563          	bne	a5,s3,18000e6c <cadence_spi4x_setup_slave+0xb0>
    18000e66:	5cdc                	lw	a5,60(s1)
    18000e68:	11378663          	beq	a5,s3,18000f74 <cadence_spi4x_setup_slave+0x1b8>
	void * base = priv->regbase;
    18000e6c:	0004b903          	ld	s2,0(s1)
	cadence_spi_write_speed(500000);
    18000e70:	0007a537          	lui	a0,0x7a
	u8 opcode_rdid = 0x9F;
    18000e74:	f9f00793          	li	a5,-97
	cadence_spi_write_speed(500000);
    18000e78:	12050513          	addi	a0,a0,288 # 7a120 <__stack_size+0x79920>
	u8 opcode_rdid = 0x9F;
    18000e7c:	00f103a3          	sb	a5,7(sp)
	unsigned int idcode = 0, temp = 0;
    18000e80:	c402                	sw	zero,8(sp)
    18000e82:	c602                	sw	zero,12(sp)
	cadence_spi_write_speed(500000);
    18000e84:	ef5ff0ef          	jal	ra,18000d78 <cadence_spi_write_speed.isra.0>
	cadence_qspi_apb_readdata_capture(base, 1, 0);
    18000e88:	4601                	li	a2,0
    18000e8a:	4585                	li	a1,1
    18000e8c:	854a                	mv	a0,s2
    18000e8e:	47b000ef          	jal	ra,18001b08 <cadence_qspi_apb_readdata_capture>
	cadence_qspi_apb_controller_enable(base);
    18000e92:	854a                	mv	a0,s2
    18000e94:	45b000ef          	jal	ra,18001aee <cadence_qspi_apb_controller_enable>
	err = cadence_qspi_apb_command_read(base, 1, &opcode_rdid,
    18000e98:	0038                	addi	a4,sp,8
    18000e9a:	468d                	li	a3,3
    18000e9c:	00710613          	addi	a2,sp,7
    18000ea0:	4585                	li	a1,1
    18000ea2:	854a                	mv	a0,s2
    18000ea4:	5eb000ef          	jal	ra,18001c8e <cadence_qspi_apb_command_read>
    18000ea8:	842a                	mv	s0,a0
	if (err) {
    18000eaa:	c105                	beqz	a0,18000eca <cadence_spi4x_setup_slave+0x10e>
			return NULL;
    18000eac:	4501                	li	a0,0
}
    18000eae:	70a6                	ld	ra,104(sp)
    18000eb0:	7406                	ld	s0,96(sp)
    18000eb2:	64e6                	ld	s1,88(sp)
    18000eb4:	6946                	ld	s2,80(sp)
    18000eb6:	69a6                	ld	s3,72(sp)
    18000eb8:	6a06                	ld	s4,64(sp)
    18000eba:	7ae2                	ld	s5,56(sp)
    18000ebc:	7b42                	ld	s6,48(sp)
    18000ebe:	7ba2                	ld	s7,40(sp)
    18000ec0:	7c02                	ld	s8,32(sp)
    18000ec2:	6ce2                	ld	s9,24(sp)
    18000ec4:	6d42                	ld	s10,16(sp)
    18000ec6:	6165                	addi	sp,sp,112
    18000ec8:	8082                	ret
	cadence_spi_write_speed(hz);
    18000eca:	854e                	mv	a0,s3
    18000ecc:	eadff0ef          	jal	ra,18000d78 <cadence_spi_write_speed.isra.0>
	int err = 0, i, range_lo = -1, range_hi = -1;
    18000ed0:	5afd                	li	s5,-1
    18000ed2:	5a7d                	li	s4,-1
		if (range_lo == -1 && temp == idcode) {
    18000ed4:	5bfd                	li	s7,-1
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000ed6:	4d41                	li	s10,16
    18000ed8:	a039                	j	18000ee6 <cadence_spi4x_setup_slave+0x12a>
    18000eda:	8aa2                	mv	s5,s0
		if (range_lo != -1 && temp != idcode) {
    18000edc:	0af71063          	bne	a4,a5,18000f7c <cadence_spi4x_setup_slave+0x1c0>
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000ee0:	2405                	addiw	s0,s0,1
    18000ee2:	05a40163          	beq	s0,s10,18000f24 <cadence_spi4x_setup_slave+0x168>
		cadence_qspi_apb_controller_disable(base);
    18000ee6:	854a                	mv	a0,s2
    18000ee8:	415000ef          	jal	ra,18001afc <cadence_qspi_apb_controller_disable>
		cadence_qspi_apb_readdata_capture(base, 1, i);
    18000eec:	0004061b          	sext.w	a2,s0
    18000ef0:	4585                	li	a1,1
    18000ef2:	854a                	mv	a0,s2
    18000ef4:	415000ef          	jal	ra,18001b08 <cadence_qspi_apb_readdata_capture>
		cadence_qspi_apb_controller_enable(base);
    18000ef8:	854a                	mv	a0,s2
    18000efa:	3f5000ef          	jal	ra,18001aee <cadence_qspi_apb_controller_enable>
		err = cadence_qspi_apb_command_read(base, 1, &opcode_rdid,
    18000efe:	0078                	addi	a4,sp,12
    18000f00:	468d                	li	a3,3
    18000f02:	00710613          	addi	a2,sp,7
    18000f06:	4585                	li	a1,1
    18000f08:	854a                	mv	a0,s2
    18000f0a:	585000ef          	jal	ra,18001c8e <cadence_qspi_apb_command_read>
		if (err) {
    18000f0e:	fd59                	bnez	a0,18000eac <cadence_spi4x_setup_slave+0xf0>
		if (range_lo == -1 && temp == idcode) {
    18000f10:	47b2                	lw	a5,12(sp)
    18000f12:	4722                	lw	a4,8(sp)
    18000f14:	fd7a13e3          	bne	s4,s7,18000eda <cadence_spi4x_setup_slave+0x11e>
    18000f18:	04f70c63          	beq	a4,a5,18000f70 <cadence_spi4x_setup_slave+0x1b4>
    18000f1c:	8aa2                	mv	s5,s0
	for (i = 0; i < CQSPI_READ_CAPTURE_MAX_DELAY; i++) {
    18000f1e:	2405                	addiw	s0,s0,1
    18000f20:	fda413e3          	bne	s0,s10,18000ee6 <cadence_spi4x_setup_slave+0x12a>
	if (range_lo == -1) {
    18000f24:	57fd                	li	a5,-1
    18000f26:	02fa0563          	beq	s4,a5,18000f50 <cadence_spi4x_setup_slave+0x194>
	cadence_qspi_apb_controller_disable(base);
    18000f2a:	854a                	mv	a0,s2
    18000f2c:	3d1000ef          	jal	ra,18001afc <cadence_qspi_apb_controller_disable>
	cadence_qspi_apb_readdata_capture(base, 1, (range_hi + range_lo) / 2);
    18000f30:	014a8a3b          	addw	s4,s5,s4
    18000f34:	01fa561b          	srliw	a2,s4,0x1f
    18000f38:	0146063b          	addw	a2,a2,s4
    18000f3c:	4016561b          	sraiw	a2,a2,0x1
    18000f40:	4585                	li	a1,1
    18000f42:	854a                	mv	a0,s2
    18000f44:	3c5000ef          	jal	ra,18001b08 <cadence_qspi_apb_readdata_capture>
	priv->qspi_calibrated_hz = hz;
    18000f48:	0334ae23          	sw	s3,60(s1)
	priv->qspi_calibrated_cs = cs;
    18000f4c:	0564a023          	sw	s6,64(s1)
		priv->previous_hz = max_hz;
    18000f50:	0534a223          	sw	s3,68(s1)
	cadence_qspi_apb_controller_enable(priv->regbase);
    18000f54:	6088                	ld	a0,0(s1)
    18000f56:	399000ef          	jal	ra,18001aee <cadence_qspi_apb_controller_enable>
	return &spi4slave->slave;
    18000f5a:	0000f517          	auipc	a0,0xf
    18000f5e:	17e50513          	addi	a0,a0,382 # 180100d8 <vic_spi_slave>
	spi4slave->slave.bus = bus;
    18000f62:	0994a423          	sw	s9,136(s1)
	spi4slave->slave.cs = cs;
    18000f66:	0964aa23          	sw	s6,148(s1)
	spi4slave->slave.bus_width= fifo_width;
    18000f6a:	0984a623          	sw	s8,140(s1)
	return &spi4slave->slave;
    18000f6e:	b781                	j	18000eae <cadence_spi4x_setup_slave+0xf2>
    18000f70:	8a22                	mv	s4,s0
    18000f72:	b7bd                	j	18000ee0 <cadence_spi4x_setup_slave+0x124>
	    priv->qspi_calibrated_hz != max_hz ||
    18000f74:	40bc                	lw	a5,64(s1)
    18000f76:	ef679be3          	bne	a5,s6,18000e6c <cadence_spi4x_setup_slave+0xb0>
    18000f7a:	bfe9                	j	18000f54 <cadence_spi4x_setup_slave+0x198>
			range_hi = i - 1;
    18000f7c:	fff40a9b          	addiw	s5,s0,-1
	if (range_lo == -1) {
    18000f80:	b76d                	j	18000f2a <cadence_spi4x_setup_slave+0x16e>

0000000018000f82 <cadence_qspi_init>:
    _ASSERT_RESET_rstgen_rstn_qspi_apb_;
    _CLEAR_RESET_rstgen_rstn_qspi_ahb_;
    _CLEAR_RESET_rstgen_rstn_qspi_core_;
    _CLEAR_RESET_rstgen_rstn_qspi_apb_;
#endif
	plat->bit_mode = mode;
    18000f82:	0000f797          	auipc	a5,0xf
    18000f86:	0ce78793          	addi	a5,a5,206 # 18010050 <spi_priv>
{
    18000f8a:	872e                	mv	a4,a1
	plat->bit_mode = mode;
    18000f8c:	08e7a023          	sw	a4,128(a5)
	
	func = &cadence_spi4x_func;
	func->setup_slave = cadence_spi4x_setup_slave;
    18000f90:	00000717          	auipc	a4,0x0
    18000f94:	e2c70713          	addi	a4,a4,-468 # 18000dbc <cadence_spi4x_setup_slave>
    18000f98:	f3d8                	sd	a4,160(a5)
	func->spi_xfer = cadence_spi_xfer;

	spi_register(bus, func);
    18000f9a:	0000f597          	auipc	a1,0xf
    18000f9e:	15658593          	addi	a1,a1,342 # 180100f0 <cadence_spi4x_func>
	func->spi_xfer = cadence_spi_xfer;
    18000fa2:	00000717          	auipc	a4,0x0
    18000fa6:	c7670713          	addi	a4,a4,-906 # 18000c18 <cadence_spi_xfer>
    18000faa:	f7d8                	sd	a4,168(a5)
	spi_register(bus, func);
    18000fac:	bcd5                	j	18000aa0 <spi_register>

0000000018000fae <spi_flash_read_write>:
	int ret;

	if (data_len == 0)
		flags |= SPI_XFER_END;

	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18000fae:	0036181b          	slliw	a6,a2,0x3
{
    18000fb2:	862e                	mv	a2,a1
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18000fb4:	0008059b          	sext.w	a1,a6
	if (data_len == 0)
    18000fb8:	e789                	bnez	a5,18000fc2 <spi_flash_read_write+0x14>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18000fba:	47a1                	li	a5,8
    18000fbc:	470d                	li	a4,3
    18000fbe:	4681                	li	a3,0
    18000fc0:	be11                	j	18000ad4 <spi_xfer>
{
    18000fc2:	7179                	addi	sp,sp,-48
    18000fc4:	f022                	sd	s0,32(sp)
    18000fc6:	e84a                	sd	s2,16(sp)
    18000fc8:	e44e                	sd	s3,8(sp)
    18000fca:	843e                	mv	s0,a5
    18000fcc:	8936                	mv	s2,a3
    18000fce:	89ba                	mv	s3,a4
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18000fd0:	47a1                	li	a5,8
    18000fd2:	4705                	li	a4,1
    18000fd4:	4681                	li	a3,0
{
    18000fd6:	ec26                	sd	s1,24(sp)
    18000fd8:	f406                	sd	ra,40(sp)
    18000fda:	84aa                	mv	s1,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18000fdc:	af9ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    18000fe0:	c901                	beqz	a0,18000ff0 <spi_flash_read_write+0x42>
	{
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
	}

	return ret;
}
    18000fe2:	70a2                	ld	ra,40(sp)
    18000fe4:	7402                	ld	s0,32(sp)
    18000fe6:	64e2                	ld	s1,24(sp)
    18000fe8:	6942                	ld	s2,16(sp)
    18000fea:	69a2                	ld	s3,8(sp)
    18000fec:	6145                	addi	sp,sp,48
    18000fee:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18000ff0:	0034159b          	slliw	a1,s0,0x3
}
    18000ff4:	7402                	ld	s0,32(sp)
    18000ff6:	70a2                	ld	ra,40(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18000ff8:	86ce                	mv	a3,s3
    18000ffa:	864a                	mv	a2,s2
}
    18000ffc:	69a2                	ld	s3,8(sp)
    18000ffe:	6942                	ld	s2,16(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001000:	8526                	mv	a0,s1
}
    18001002:	64e2                	ld	s1,24(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001004:	47a1                	li	a5,8
    18001006:	4709                	li	a4,2
}
    18001008:	6145                	addi	sp,sp,48
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    1800100a:	b4e9                	j	18000ad4 <spi_xfer>

000000001800100c <spi_flash_cmd>:

int spi_flash_cmd(struct spi_slave *spi, u8 cmd, void *response, u32 len)
{
    1800100c:	7179                	addi	sp,sp,-48
    1800100e:	f406                	sd	ra,40(sp)
    18001010:	f022                	sd	s0,32(sp)
    18001012:	ec26                	sd	s1,24(sp)
    18001014:	e84a                	sd	s2,16(sp)
    18001016:	00b107a3          	sb	a1,15(sp)
	if (data_len == 0)
    1800101a:	ee91                	bnez	a3,18001036 <spi_flash_cmd+0x2a>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800101c:	47a1                	li	a5,8
    1800101e:	470d                	li	a4,3
    18001020:	00f10613          	addi	a2,sp,15
    18001024:	45a1                	li	a1,8
    18001026:	aafff0ef          	jal	ra,18000ad4 <spi_xfer>
	return spi_flash_cmd_read(spi, &cmd, 1, response, len);
}
    1800102a:	70a2                	ld	ra,40(sp)
    1800102c:	7402                	ld	s0,32(sp)
    1800102e:	64e2                	ld	s1,24(sp)
    18001030:	6942                	ld	s2,16(sp)
    18001032:	6145                	addi	sp,sp,48
    18001034:	8082                	ret
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001036:	8436                	mv	s0,a3
    18001038:	8932                	mv	s2,a2
    1800103a:	47a1                	li	a5,8
    1800103c:	4705                	li	a4,1
    1800103e:	4681                	li	a3,0
    18001040:	00f10613          	addi	a2,sp,15
    18001044:	45a1                	li	a1,8
    18001046:	84aa                	mv	s1,a0
    18001048:	a8dff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    1800104c:	fd79                	bnez	a0,1800102a <spi_flash_cmd+0x1e>
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    1800104e:	0034159b          	slliw	a1,s0,0x3
    18001052:	86ca                	mv	a3,s2
    18001054:	8526                	mv	a0,s1
    18001056:	47a1                	li	a5,8
    18001058:	4709                	li	a4,2
    1800105a:	4601                	li	a2,0
    1800105c:	a79ff0ef          	jal	ra,18000ad4 <spi_xfer>
}
    18001060:	70a2                	ld	ra,40(sp)
    18001062:	7402                	ld	s0,32(sp)
    18001064:	64e2                	ld	s1,24(sp)
    18001066:	6942                	ld	s2,16(sp)
    18001068:	6145                	addi	sp,sp,48
    1800106a:	8082                	ret

000000001800106c <spi_flash_cmd_read>:
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800106c:	0036179b          	slliw	a5,a2,0x3

int spi_flash_cmd_read(struct spi_slave *spi, u8 *cmd,
		u32 cmd_len, void *data, u32 data_len)
{
    18001070:	862e                	mv	a2,a1
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001072:	0007859b          	sext.w	a1,a5
	if (data_len == 0)
    18001076:	e709                	bnez	a4,18001080 <spi_flash_cmd_read+0x14>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001078:	47a1                	li	a5,8
    1800107a:	470d                	li	a4,3
    1800107c:	4681                	li	a3,0
    1800107e:	bc99                	j	18000ad4 <spi_xfer>
{
    18001080:	1101                	addi	sp,sp,-32
    18001082:	e822                	sd	s0,16(sp)
    18001084:	e04a                	sd	s2,0(sp)
    18001086:	843a                	mv	s0,a4
    18001088:	8936                	mv	s2,a3
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800108a:	47a1                	li	a5,8
    1800108c:	4705                	li	a4,1
    1800108e:	4681                	li	a3,0
{
    18001090:	e426                	sd	s1,8(sp)
    18001092:	ec06                	sd	ra,24(sp)
    18001094:	84aa                	mv	s1,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001096:	a3fff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    1800109a:	c519                	beqz	a0,180010a8 <spi_flash_cmd_read+0x3c>
	return spi_flash_read_write(spi, cmd, cmd_len, NULL, data, data_len);
}
    1800109c:	60e2                	ld	ra,24(sp)
    1800109e:	6442                	ld	s0,16(sp)
    180010a0:	64a2                	ld	s1,8(sp)
    180010a2:	6902                	ld	s2,0(sp)
    180010a4:	6105                	addi	sp,sp,32
    180010a6:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180010a8:	0034159b          	slliw	a1,s0,0x3
}
    180010ac:	6442                	ld	s0,16(sp)
    180010ae:	60e2                	ld	ra,24(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180010b0:	86ca                	mv	a3,s2
    180010b2:	8526                	mv	a0,s1
}
    180010b4:	6902                	ld	s2,0(sp)
    180010b6:	64a2                	ld	s1,8(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180010b8:	47a1                	li	a5,8
    180010ba:	4709                	li	a4,2
    180010bc:	4601                	li	a2,0
}
    180010be:	6105                	addi	sp,sp,32
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180010c0:	bc11                	j	18000ad4 <spi_xfer>

00000000180010c2 <spi_flash_cmd_write>:
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180010c2:	0036179b          	slliw	a5,a2,0x3

int spi_flash_cmd_write(struct spi_slave *spi, u8 *cmd, u32 cmd_len,
		void *data, u32 data_len)
{
    180010c6:	862e                	mv	a2,a1
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180010c8:	0007859b          	sext.w	a1,a5
	if (data_len == 0)
    180010cc:	e709                	bnez	a4,180010d6 <spi_flash_cmd_write+0x14>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180010ce:	47a1                	li	a5,8
    180010d0:	470d                	li	a4,3
    180010d2:	4681                	li	a3,0
    180010d4:	b401                	j	18000ad4 <spi_xfer>
{
    180010d6:	1101                	addi	sp,sp,-32
    180010d8:	e822                	sd	s0,16(sp)
    180010da:	e04a                	sd	s2,0(sp)
    180010dc:	843a                	mv	s0,a4
    180010de:	8936                	mv	s2,a3
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180010e0:	47a1                	li	a5,8
    180010e2:	4705                	li	a4,1
    180010e4:	4681                	li	a3,0
{
    180010e6:	e426                	sd	s1,8(sp)
    180010e8:	ec06                	sd	ra,24(sp)
    180010ea:	84aa                	mv	s1,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180010ec:	9e9ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    180010f0:	c519                	beqz	a0,180010fe <spi_flash_cmd_write+0x3c>
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
}
    180010f2:	60e2                	ld	ra,24(sp)
    180010f4:	6442                	ld	s0,16(sp)
    180010f6:	64a2                	ld	s1,8(sp)
    180010f8:	6902                	ld	s2,0(sp)
    180010fa:	6105                	addi	sp,sp,32
    180010fc:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180010fe:	0034159b          	slliw	a1,s0,0x3
}
    18001102:	6442                	ld	s0,16(sp)
    18001104:	60e2                	ld	ra,24(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001106:	864a                	mv	a2,s2
    18001108:	8526                	mv	a0,s1
}
    1800110a:	6902                	ld	s2,0(sp)
    1800110c:	64a2                	ld	s1,8(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    1800110e:	47a1                	li	a5,8
    18001110:	4709                	li	a4,2
    18001112:	4681                	li	a3,0
}
    18001114:	6105                	addi	sp,sp,32
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001116:	ba7d                	j	18000ad4 <spi_xfer>

0000000018001118 <spi_flash_cmd_write_enable>:
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001118:	6108                	ld	a0,0(a0)

int spi_flash_cmd_write_enable(struct spi_flash *flash)
{
    1800111a:	1101                	addi	sp,sp,-32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800111c:	00f10613          	addi	a2,sp,15
    18001120:	4819                	li	a6,6
    18001122:	47a1                	li	a5,8
    18001124:	470d                	li	a4,3
    18001126:	4681                	li	a3,0
    18001128:	45a1                	li	a1,8
{
    1800112a:	ec06                	sd	ra,24(sp)
    1800112c:	010107a3          	sb	a6,15(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001130:	9a5ff0ef          	jal	ra,18000ad4 <spi_xfer>
	return spi_flash_cmd(flash->spi, CMD_WRITE_ENABLE, (void*)NULL, 0);
}
    18001134:	60e2                	ld	ra,24(sp)
    18001136:	6105                	addi	sp,sp,32
    18001138:	8082                	ret

000000001800113a <spi_flash_cmd_write_status_enable>:
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800113a:	6108                	ld	a0,0(a0)

int spi_flash_cmd_write_status_enable(struct spi_flash *flash)
{
    1800113c:	1101                	addi	sp,sp,-32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800113e:	00f10613          	addi	a2,sp,15
    18001142:	05000813          	li	a6,80
    18001146:	47a1                	li	a5,8
    18001148:	470d                	li	a4,3
    1800114a:	4681                	li	a3,0
    1800114c:	45a1                	li	a1,8
{
    1800114e:	ec06                	sd	ra,24(sp)
    18001150:	010107a3          	sb	a6,15(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001154:	981ff0ef          	jal	ra,18000ad4 <spi_xfer>
	return spi_flash_cmd(flash->spi, CMD_STATUS_ENABLE, (void*)NULL, 0);
}
    18001158:	60e2                	ld	ra,24(sp)
    1800115a:	6105                	addi	sp,sp,32
    1800115c:	8082                	ret

000000001800115e <spi_flash_cmd_write_disable>:

int spi_flash_cmd_write_disable(struct spi_slave *spi)
{
    1800115e:	1101                	addi	sp,sp,-32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001160:	00f10613          	addi	a2,sp,15
    18001164:	4811                	li	a6,4
    18001166:	47a1                	li	a5,8
    18001168:	470d                	li	a4,3
    1800116a:	4681                	li	a3,0
    1800116c:	45a1                	li	a1,8
{
    1800116e:	ec06                	sd	ra,24(sp)
    18001170:	010107a3          	sb	a6,15(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001174:	961ff0ef          	jal	ra,18000ad4 <spi_xfer>
	return spi_flash_cmd(spi, CMD_WRITE_DISABLE, (void*)NULL, 0);
}
    18001178:	60e2                	ld	ra,24(sp)
    1800117a:	6105                	addi	sp,sp,32
    1800117c:	8082                	ret

000000001800117e <spi_flash_cmd_read_status>:
int spi_flash_cmd_read_status(struct spi_flash *flash, u8 *cmd, u32 cmd_len, u8 *status)
{
    1800117e:	1101                	addi	sp,sp,-32
    18001180:	e426                	sd	s1,8(sp)
	struct spi_slave *spi = flash->spi;
    18001182:	6104                	ld	s1,0(a0)
{
    18001184:	8532                	mv	a0,a2
    18001186:	e822                	sd	s0,16(sp)
    18001188:	862e                	mv	a2,a1
    1800118a:	8436                	mv	s0,a3
	int ret;

	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    1800118c:	0035159b          	slliw	a1,a0,0x3
    18001190:	47a1                	li	a5,8
    18001192:	4705                	li	a4,1
    18001194:	4681                	li	a3,0
    18001196:	8526                	mv	a0,s1
{
    18001198:	ec06                	sd	ra,24(sp)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    1800119a:	93bff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret) {
    1800119e:	c511                	beqz	a0,180011aa <spi_flash_cmd_read_status+0x2c>
	//uart_printf("status = 0x%x\r\n", status[0]);
	if (ret)
		return ret;

	return 0;
}
    180011a0:	60e2                	ld	ra,24(sp)
    180011a2:	6442                	ld	s0,16(sp)
    180011a4:	64a2                	ld	s1,8(sp)
    180011a6:	6105                	addi	sp,sp,32
    180011a8:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180011aa:	86a2                	mv	a3,s0
}
    180011ac:	6442                	ld	s0,16(sp)
    180011ae:	60e2                	ld	ra,24(sp)
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180011b0:	8526                	mv	a0,s1
}
    180011b2:	64a2                	ld	s1,8(sp)
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180011b4:	47a1                	li	a5,8
    180011b6:	4709                	li	a4,2
    180011b8:	4601                	li	a2,0
    180011ba:	45a1                	li	a1,8
}
    180011bc:	6105                	addi	sp,sp,32
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180011be:	ba19                	j	18000ad4 <spi_xfer>

00000000180011c0 <spi_flash_cmd_poll_bit>:

int spi_flash_cmd_poll_bit(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u8 poll_bit)
{
    180011c0:	715d                	addi	sp,sp,-80
    180011c2:	e0a2                	sd	s0,64(sp)
    180011c4:	f84a                	sd	s2,48(sp)
    180011c6:	f44e                	sd	s3,40(sp)
    180011c8:	f052                	sd	s4,32(sp)
    180011ca:	e486                	sd	ra,72(sp)
    180011cc:	fc26                	sd	s1,56(sp)
    180011ce:	892a                	mv	s2,a0
    180011d0:	8a2e                	mv	s4,a1
    180011d2:	89b6                	mv	s3,a3
    180011d4:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;
	u32 timebase_1 = 0;
    180011d8:	4401                	li	s0,0
	struct spi_slave *spi = flash->spi;
    180011da:	00093483          	ld	s1,0(s2)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180011de:	47a1                	li	a5,8
    180011e0:	4705                	li	a4,1
    180011e2:	4681                	li	a3,0
    180011e4:	00f10613          	addi	a2,sp,15
    180011e8:	45a1                	li	a1,8
    180011ea:	8526                	mv	a0,s1
    180011ec:	8e9ff0ef          	jal	ra,18000ad4 <spi_xfer>
    180011f0:	882a                	mv	a6,a0
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180011f2:	47a1                	li	a5,8
    180011f4:	4709                	li	a4,2
    180011f6:	01f10693          	addi	a3,sp,31
    180011fa:	4601                	li	a2,0
    180011fc:	45a1                	li	a1,8
    180011fe:	8526                	mv	a0,s1
	if (ret) {
    18001200:	00080b63          	beqz	a6,18001216 <spi_flash_cmd_poll_bit+0x56>
		return 0;

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return -1;
}
    18001204:	60a6                	ld	ra,72(sp)
    18001206:	6406                	ld	s0,64(sp)
    18001208:	74e2                	ld	s1,56(sp)
    1800120a:	7942                	ld	s2,48(sp)
    1800120c:	79a2                	ld	s3,40(sp)
    1800120e:	7a02                	ld	s4,32(sp)
    18001210:	8542                	mv	a0,a6
    18001212:	6161                	addi	sp,sp,80
    18001214:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001216:	8bfff0ef          	jal	ra,18000ad4 <spi_xfer>
		timebase_1++;//libo
    1800121a:	0014071b          	addiw	a4,s0,1
	} while (timebase_1 < timeout);
    1800121e:	02071613          	slli	a2,a4,0x20
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001222:	882a                	mv	a6,a0
	} while (timebase_1 < timeout);
    18001224:	9201                	srli	a2,a2,0x20
	if (ret)
    18001226:	fd79                	bnez	a0,18001204 <spi_flash_cmd_poll_bit+0x44>
		if ((status & poll_bit) == 0)
    18001228:	01f14783          	lbu	a5,31(sp)
		timebase_1++;//libo
    1800122c:	0007041b          	sext.w	s0,a4
		if ((status & poll_bit) == 0)
    18001230:	00f9f7b3          	and	a5,s3,a5
    18001234:	dbe1                	beqz	a5,18001204 <spi_flash_cmd_poll_bit+0x44>
	} while (timebase_1 < timeout);
    18001236:	fb4662e3          	bltu	a2,s4,180011da <spi_flash_cmd_poll_bit+0x1a>
	return -1;
    1800123a:	587d                	li	a6,-1
    1800123c:	b7e1                	j	18001204 <spi_flash_cmd_poll_bit+0x44>

000000001800123e <spi_flash_cmd_wait_ready>:

int spi_flash_cmd_wait_ready(struct spi_flash *flash, unsigned long timeout)
{
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800123e:	4685                	li	a3,1
    18001240:	4615                	li	a2,5
    18001242:	bfbd                	j	180011c0 <spi_flash_cmd_poll_bit>

0000000018001244 <spi_flash_cmd_poll_enable>:
			CMD_READ_STATUS, STATUS_WIP);
}

int spi_flash_cmd_poll_enable(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u32 poll_bit)
{
    18001244:	715d                	addi	sp,sp,-80
    18001246:	e0a2                	sd	s0,64(sp)
    18001248:	f84a                	sd	s2,48(sp)
    1800124a:	f44e                	sd	s3,40(sp)
    1800124c:	f052                	sd	s4,32(sp)
    1800124e:	e486                	sd	ra,72(sp)
    18001250:	fc26                	sd	s1,56(sp)
    18001252:	892a                	mv	s2,a0
    18001254:	8a2e                	mv	s4,a1
    18001256:	89b6                	mv	s3,a3
    18001258:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;

	u32 timebase_1 = 0;
    1800125c:	4401                	li	s0,0
	struct spi_slave *spi = flash->spi;
    1800125e:	00093483          	ld	s1,0(s2)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    18001262:	47a1                	li	a5,8
    18001264:	4705                	li	a4,1
    18001266:	4681                	li	a3,0
    18001268:	00f10613          	addi	a2,sp,15
    1800126c:	45a1                	li	a1,8
    1800126e:	8526                	mv	a0,s1
    18001270:	865ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001274:	882a                	mv	a6,a0
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001276:	47a1                	li	a5,8
    18001278:	4709                	li	a4,2
    1800127a:	01f10693          	addi	a3,sp,31
    1800127e:	4601                	li	a2,0
    18001280:	45a1                	li	a1,8
    18001282:	8526                	mv	a0,s1
	if (ret) {
    18001284:	00080b63          	beqz	a6,1800129a <spi_flash_cmd_poll_enable+0x56>
	} while (timebase_1 < timeout);

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return 0;
} 
    18001288:	60a6                	ld	ra,72(sp)
    1800128a:	6406                	ld	s0,64(sp)
    1800128c:	74e2                	ld	s1,56(sp)
    1800128e:	7942                	ld	s2,48(sp)
    18001290:	79a2                	ld	s3,40(sp)
    18001292:	7a02                	ld	s4,32(sp)
    18001294:	8542                	mv	a0,a6
    18001296:	6161                	addi	sp,sp,80
    18001298:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    1800129a:	83bff0ef          	jal	ra,18000ad4 <spi_xfer>
		timebase_1++;
    1800129e:	0014071b          	addiw	a4,s0,1
	} while (timebase_1 < timeout);
    180012a2:	02071693          	slli	a3,a4,0x20
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180012a6:	882a                	mv	a6,a0
		if ((status & poll_bit) == 1)
    180012a8:	4605                	li	a2,1
	} while (timebase_1 < timeout);
    180012aa:	9281                	srli	a3,a3,0x20
	if (ret)
    180012ac:	fd71                	bnez	a0,18001288 <spi_flash_cmd_poll_enable+0x44>
		if ((status & poll_bit) == 1)
    180012ae:	01f14783          	lbu	a5,31(sp)
		timebase_1++;
    180012b2:	0007041b          	sext.w	s0,a4
		if ((status & poll_bit) == 1)
    180012b6:	00f9f7b3          	and	a5,s3,a5
    180012ba:	fcc787e3          	beq	a5,a2,18001288 <spi_flash_cmd_poll_enable+0x44>
	} while (timebase_1 < timeout);
    180012be:	fb46e0e3          	bltu	a3,s4,1800125e <spi_flash_cmd_poll_enable+0x1a>
    180012c2:	b7d9                	j	18001288 <spi_flash_cmd_poll_enable+0x44>

00000000180012c4 <spi_flash_cmd_status_poll_enable>:

int spi_flash_cmd_status_poll_enable(struct spi_flash *flash, unsigned long timeout,
		u8 cmd, u32 poll_bit)
{
    180012c4:	715d                	addi	sp,sp,-80
    180012c6:	e0a2                	sd	s0,64(sp)
    180012c8:	f84a                	sd	s2,48(sp)
    180012ca:	f44e                	sd	s3,40(sp)
    180012cc:	f052                	sd	s4,32(sp)
    180012ce:	e486                	sd	ra,72(sp)
    180012d0:	fc26                	sd	s1,56(sp)
    180012d2:	892a                	mv	s2,a0
    180012d4:	8a2e                	mv	s4,a1
    180012d6:	89b6                	mv	s3,a3
    180012d8:	00c107a3          	sb	a2,15(sp)
	int ret;
	u8 status;
    u32 status_tmp = 0;

	u32 timebase_1 = 0;
    180012dc:	4401                	li	s0,0
	struct spi_slave *spi = flash->spi;
    180012de:	00093483          	ld	s1,0(s2)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180012e2:	47a1                	li	a5,8
    180012e4:	4705                	li	a4,1
    180012e6:	4681                	li	a3,0
    180012e8:	00f10613          	addi	a2,sp,15
    180012ec:	45a1                	li	a1,8
    180012ee:	8526                	mv	a0,s1
    180012f0:	fe4ff0ef          	jal	ra,18000ad4 <spi_xfer>
    180012f4:	882a                	mv	a6,a0
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180012f6:	47a1                	li	a5,8
    180012f8:	4709                	li	a4,2
    180012fa:	01f10693          	addi	a3,sp,31
    180012fe:	4601                	li	a2,0
    18001300:	45a1                	li	a1,8
    18001302:	8526                	mv	a0,s1
	if (ret) {
    18001304:	00080b63          	beqz	a6,1800131a <spi_flash_cmd_status_poll_enable+0x56>
	} while (timebase_1 < timeout);

	/* Timed out */
	//uart_printf("SF: time out!\r\n");
	return 0;
}
    18001308:	60a6                	ld	ra,72(sp)
    1800130a:	6406                	ld	s0,64(sp)
    1800130c:	74e2                	ld	s1,56(sp)
    1800130e:	7942                	ld	s2,48(sp)
    18001310:	79a2                	ld	s3,40(sp)
    18001312:	7a02                	ld	s4,32(sp)
    18001314:	8542                	mv	a0,a6
    18001316:	6161                	addi	sp,sp,80
    18001318:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    1800131a:	fbaff0ef          	jal	ra,18000ad4 <spi_xfer>
		timebase_1++;
    1800131e:	0014071b          	addiw	a4,s0,1
	} while (timebase_1 < timeout);
    18001322:	02071693          	slli	a3,a4,0x20
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001326:	882a                	mv	a6,a0
		if ((status & poll_bit) == 0x2)
    18001328:	4609                	li	a2,2
	} while (timebase_1 < timeout);
    1800132a:	9281                	srli	a3,a3,0x20
	if (ret)
    1800132c:	fd71                	bnez	a0,18001308 <spi_flash_cmd_status_poll_enable+0x44>
		if ((status & poll_bit) == 0x2)
    1800132e:	01f14783          	lbu	a5,31(sp)
		timebase_1++;
    18001332:	0007041b          	sext.w	s0,a4
		if ((status & poll_bit) == 0x2)
    18001336:	00f9f7b3          	and	a5,s3,a5
    1800133a:	fcc787e3          	beq	a5,a2,18001308 <spi_flash_cmd_status_poll_enable+0x44>
	} while (timebase_1 < timeout);
    1800133e:	fb46e0e3          	bltu	a3,s4,180012de <spi_flash_cmd_status_poll_enable+0x1a>
    18001342:	b7d9                	j	18001308 <spi_flash_cmd_status_poll_enable+0x44>

0000000018001344 <spi_flash_cmd_wait_enable>:

int spi_flash_cmd_wait_enable(struct spi_flash *flash, unsigned long timeout)
{
    18001344:	7139                	addi	sp,sp,-64
    18001346:	4795                	li	a5,5
    18001348:	f822                	sd	s0,48(sp)
    1800134a:	f04a                	sd	s2,32(sp)
    1800134c:	ec4e                	sd	s3,24(sp)
    1800134e:	fc06                	sd	ra,56(sp)
    18001350:	f426                	sd	s1,40(sp)
    18001352:	892a                	mv	s2,a0
    18001354:	89ae                	mv	s3,a1
    18001356:	00f10723          	sb	a5,14(sp)
	u32 timebase_1 = 0;
    1800135a:	4401                	li	s0,0
	struct spi_slave *spi = flash->spi;
    1800135c:	00093483          	ld	s1,0(s2)
	ret = spi_xfer(spi, 8*cmd_len, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    18001360:	47a1                	li	a5,8
    18001362:	4705                	li	a4,1
    18001364:	4681                	li	a3,0
    18001366:	00e10613          	addi	a2,sp,14
    1800136a:	45a1                	li	a1,8
    1800136c:	8526                	mv	a0,s1
    1800136e:	f66ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001372:	882a                	mv	a6,a0
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001374:	47a1                	li	a5,8
    18001376:	4709                	li	a4,2
    18001378:	00f10693          	addi	a3,sp,15
    1800137c:	4601                	li	a2,0
    1800137e:	45a1                	li	a1,8
    18001380:	8526                	mv	a0,s1
	if (ret) {
    18001382:	00080a63          	beqz	a6,18001396 <spi_flash_cmd_wait_enable+0x52>
	return spi_flash_cmd_status_poll_enable(flash, timeout,
			CMD_READ_STATUS, FLASH_ENABLE);
}
    18001386:	70e2                	ld	ra,56(sp)
    18001388:	7442                	ld	s0,48(sp)
    1800138a:	74a2                	ld	s1,40(sp)
    1800138c:	7902                	ld	s2,32(sp)
    1800138e:	69e2                	ld	s3,24(sp)
    18001390:	8542                	mv	a0,a6
    18001392:	6121                	addi	sp,sp,64
    18001394:	8082                	ret
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    18001396:	f3eff0ef          	jal	ra,18000ad4 <spi_xfer>
		timebase_1++;
    1800139a:	0014071b          	addiw	a4,s0,1
	} while (timebase_1 < timeout);
    1800139e:	02071693          	slli	a3,a4,0x20
	ret = spi_xfer(spi, 8*1, NULL, status, SPI_XFER_END, SPI_DATAMODE_8);
    180013a2:	882a                	mv	a6,a0
	} while (timebase_1 < timeout);
    180013a4:	9281                	srli	a3,a3,0x20
	if (ret)
    180013a6:	f165                	bnez	a0,18001386 <spi_flash_cmd_wait_enable+0x42>
		if ((status & poll_bit) == 0x2)
    180013a8:	00f14783          	lbu	a5,15(sp)
		timebase_1++;
    180013ac:	0007041b          	sext.w	s0,a4
		if ((status & poll_bit) == 0x2)
    180013b0:	8b89                	andi	a5,a5,2
    180013b2:	fbf1                	bnez	a5,18001386 <spi_flash_cmd_wait_enable+0x42>
	} while (timebase_1 < timeout);
    180013b4:	fb36e4e3          	bltu	a3,s3,1800135c <spi_flash_cmd_wait_enable+0x18>
}
    180013b8:	70e2                	ld	ra,56(sp)
    180013ba:	7442                	ld	s0,48(sp)
    180013bc:	74a2                	ld	s1,40(sp)
    180013be:	7902                	ld	s2,32(sp)
    180013c0:	69e2                	ld	s3,24(sp)
    180013c2:	8542                	mv	a0,a6
    180013c4:	6121                	addi	sp,sp,64
    180013c6:	8082                	ret

00000000180013c8 <spi_flash_write_status>:
int spi_flash_write_status(struct spi_flash *flash,  u8 *cmd, unsigned int cmd_len,void *data, unsigned int data_len)
{
    180013c8:	7139                	addi	sp,sp,-64
    180013ca:	f822                	sd	s0,48(sp)
    180013cc:	842a                	mv	s0,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180013ce:	6108                	ld	a0,0(a0)
{
    180013d0:	f426                	sd	s1,40(sp)
    180013d2:	f04a                	sd	s2,32(sp)
    180013d4:	ec4e                	sd	s3,24(sp)
    180013d6:	e852                	sd	s4,16(sp)
    180013d8:	84ae                	mv	s1,a1
    180013da:	8932                	mv	s2,a2
    180013dc:	89b6                	mv	s3,a3
    180013de:	8a3a                	mv	s4,a4
    180013e0:	4819                	li	a6,6
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180013e2:	47a1                	li	a5,8
    180013e4:	470d                	li	a4,3
    180013e6:	4681                	li	a3,0
    180013e8:	00f10613          	addi	a2,sp,15
    180013ec:	45a1                	li	a1,8
{
    180013ee:	fc06                	sd	ra,56(sp)
    180013f0:	010107a3          	sb	a6,15(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180013f4:	ee0ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    180013f8:	e921                	bnez	a0,18001448 <spi_flash_write_status+0x80>
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    180013fa:	6008                	ld	a0,0(s0)
    180013fc:	87d2                	mv	a5,s4
    180013fe:	4701                	li	a4,0
    18001400:	86ce                	mv	a3,s3
    18001402:	864a                	mv	a2,s2
    18001404:	85a6                	mv	a1,s1
    18001406:	ba9ff0ef          	jal	ra,18000fae <spi_flash_read_write>
	//	uart_printf("SF: Unable to claim SPI bus\n");
		return ret;
	}

	ret = spi_flash_cmd_write(flash->spi, cmd, cmd_len, data, data_len);
	if (ret < 0) {
    1800140a:	02054f63          	bltz	a0,18001448 <spi_flash_write_status+0x80>
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800140e:	039385b7          	lui	a1,0x3938
    18001412:	4685                	li	a3,1
    18001414:	4615                	li	a2,5
    18001416:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    1800141a:	8522                	mv	a0,s0
    1800141c:	da5ff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
		//uart_printf("SF: write failed\n");
		return ret;
	}
	ret = spi_flash_cmd_wait_ready(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT);
	if (ret < 0) {
    18001420:	02054463          	bltz	a0,18001448 <spi_flash_write_status+0x80>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001424:	6008                	ld	a0,0(s0)
    18001426:	47a1                	li	a5,8
    18001428:	4811                	li	a6,4
    1800142a:	470d                	li	a4,3
    1800142c:	4681                	li	a3,0
    1800142e:	00f10613          	addi	a2,sp,15
    18001432:	45a1                	li	a1,8
    18001434:	010107a3          	sb	a6,15(sp)
    18001438:	e9cff0ef          	jal	ra,18000ad4 <spi_xfer>
		//uart_printf("SF: wait ready failed\n");
		return ret;
	}
	ret = spi_flash_cmd_write_disable(flash->spi);
	if (ret < 0) {
    1800143c:	00152793          	slti	a5,a0,1
    18001440:	40f007bb          	negw	a5,a5
    18001444:	8d7d                	and	a0,a0,a5
    18001446:	2501                	sext.w	a0,a0
		//uart_printf("SF: disable write failed\n");
		return ret;
	}
	return 0;
}
    18001448:	70e2                	ld	ra,56(sp)
    1800144a:	7442                	ld	s0,48(sp)
    1800144c:	74a2                	ld	s1,40(sp)
    1800144e:	7902                	ld	s2,32(sp)
    18001450:	69e2                	ld	s3,24(sp)
    18001452:	6a42                	ld	s4,16(sp)
    18001454:	6121                	addi	sp,sp,64
    18001456:	8082                	ret

0000000018001458 <spi_flash_write_status_bit>:
	/* set PB=0 all can write */
	return spi_flash_write_status_bit(flash, 0x00, 0);
}
#else
int spi_flash_write_status_bit(struct spi_flash *flash, u8 status1, u8 status2,  u8 bit1,  u8 bit2)
{
    18001458:	7179                	addi	sp,sp,-48
	u8 status[3];
	int ret = 0;

	status[0] = CMD_WRITE_STATUS;
	status[1] = status1|bit1;
    1800145a:	00d5e833          	or	a6,a1,a3
	status[2] = status2|bit2;
    1800145e:	00e667b3          	or	a5,a2,a4
{
    18001462:	f022                	sd	s0,32(sp)
    18001464:	ec26                	sd	s1,24(sp)
    18001466:	843a                	mv	s0,a4
    18001468:	84b6                	mv	s1,a3
	status[0] = CMD_WRITE_STATUS;
    1800146a:	4885                	li	a7,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    1800146c:	4709                	li	a4,2
    1800146e:	00910693          	addi	a3,sp,9
    18001472:	4605                	li	a2,1
    18001474:	002c                	addi	a1,sp,8
{
    18001476:	e84a                	sd	s2,16(sp)
    18001478:	f406                	sd	ra,40(sp)
    1800147a:	892a                	mv	s2,a0
	status[0] = CMD_WRITE_STATUS;
    1800147c:	01110423          	sb	a7,8(sp)
	status[1] = status1|bit1;
    18001480:	010104a3          	sb	a6,9(sp)
	status[2] = status2|bit2;
    18001484:	00f10523          	sb	a5,10(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001488:	f41ff0ef          	jal	ra,180013c8 <spi_flash_write_status>

	if (bit1)
    1800148c:	e889                	bnez	s1,1800149e <spi_flash_write_status_bit+0x46>
	{
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS, ~bit1);
	}
	if (bit2)
    1800148e:	e40d                	bnez	s0,180014b8 <spi_flash_write_status_bit+0x60>
	return ret;
   delay(1000);
    

	return ret;
}
    18001490:	70a2                	ld	ra,40(sp)
    18001492:	7402                	ld	s0,32(sp)
    18001494:	64e2                	ld	s1,24(sp)
    18001496:	6942                	ld	s2,16(sp)
    18001498:	4501                	li	a0,0
    1800149a:	6145                	addi	sp,sp,48
    1800149c:	8082                	ret
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS, ~bit1);
    1800149e:	fff4c693          	not	a3,s1
    180014a2:	039385b7          	lui	a1,0x3938
    180014a6:	0ff6f693          	zext.b	a3,a3
    180014aa:	4615                	li	a2,5
    180014ac:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    180014b0:	854a                	mv	a0,s2
    180014b2:	d0fff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
	if (bit2)
    180014b6:	dc69                	beqz	s0,18001490 <spi_flash_write_status_bit+0x38>
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS1, ~bit2);
    180014b8:	fff44693          	not	a3,s0
    180014bc:	039385b7          	lui	a1,0x3938
    180014c0:	854a                	mv	a0,s2
    180014c2:	0ff6f693          	zext.b	a3,a3
    180014c6:	03500613          	li	a2,53
    180014ca:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    180014ce:	cf3ff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
}
    180014d2:	70a2                	ld	ra,40(sp)
    180014d4:	7402                	ld	s0,32(sp)
    180014d6:	64e2                	ld	s1,24(sp)
    180014d8:	6942                	ld	s2,16(sp)
    180014da:	4501                	li	a0,0
    180014dc:	6145                	addi	sp,sp,48
    180014de:	8082                	ret

00000000180014e0 <spi_flash_protect>:

int spi_flash_protect(struct spi_flash *flash)
{
    180014e0:	7179                	addi	sp,sp,-48
    180014e2:	f022                	sd	s0,32(sp)
    180014e4:	842a                	mv	s0,a0
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180014e6:	6108                	ld	a0,0(a0)
	status[0] = CMD_WRITE_STATUS;
    180014e8:	4805                	li	a6,1
    180014ea:	01011423          	sh	a6,8(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180014ee:	47a1                	li	a5,8
    180014f0:	4819                	li	a6,6
    180014f2:	470d                	li	a4,3
    180014f4:	4681                	li	a3,0
    180014f6:	00710613          	addi	a2,sp,7
    180014fa:	45a1                	li	a1,8
{
    180014fc:	f406                	sd	ra,40(sp)
    180014fe:	ec26                	sd	s1,24(sp)
	status[2] = status2|bit2;
    18001500:	00010523          	sb	zero,10(sp)
	return spi_flash_cmd(flash->spi, CMD_WRITE_ENABLE, (void*)NULL, 0);
    18001504:	010103a3          	sb	a6,7(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001508:	dccff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    1800150c:	e521                	bnez	a0,18001554 <spi_flash_protect+0x74>
	ret = spi_flash_cmd_write(flash->spi, cmd, cmd_len, data, data_len);
    1800150e:	6004                	ld	s1,0(s0)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001510:	47a1                	li	a5,8
    18001512:	4705                	li	a4,1
    18001514:	4681                	li	a3,0
    18001516:	0030                	addi	a2,sp,8
    18001518:	45a1                	li	a1,8
    1800151a:	8526                	mv	a0,s1
    1800151c:	db8ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    18001520:	c121                	beqz	a0,18001560 <spi_flash_protect+0x80>
	if (ret < 0) {
    18001522:	02054963          	bltz	a0,18001554 <spi_flash_protect+0x74>
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001526:	039385b7          	lui	a1,0x3938
    1800152a:	4685                	li	a3,1
    1800152c:	4615                	li	a2,5
    1800152e:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    18001532:	8522                	mv	a0,s0
    18001534:	c8dff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
	if (ret < 0) {
    18001538:	00054e63          	bltz	a0,18001554 <spi_flash_protect+0x74>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800153c:	6008                	ld	a0,0(s0)
    1800153e:	4811                	li	a6,4
    18001540:	47a1                	li	a5,8
    18001542:	470d                	li	a4,3
    18001544:	4681                	li	a3,0
    18001546:	00710613          	addi	a2,sp,7
    1800154a:	45a1                	li	a1,8
    1800154c:	010103a3          	sb	a6,7(sp)
    18001550:	d84ff0ef          	jal	ra,18000ad4 <spi_xfer>
	/* set PB=0 all can write */
	return spi_flash_write_status_bit(flash, 0x00, 0x00, 0, 0);
}
    18001554:	70a2                	ld	ra,40(sp)
    18001556:	7402                	ld	s0,32(sp)
    18001558:	64e2                	ld	s1,24(sp)
    1800155a:	4501                	li	a0,0
    1800155c:	6145                	addi	sp,sp,48
    1800155e:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001560:	47a1                	li	a5,8
    18001562:	4709                	li	a4,2
    18001564:	4681                	li	a3,0
    18001566:	00910613          	addi	a2,sp,9
    1800156a:	45c1                	li	a1,16
    1800156c:	8526                	mv	a0,s1
    1800156e:	d66ff0ef          	jal	ra,18000ad4 <spi_xfer>
	return ret;
    18001572:	bf45                	j	18001522 <spi_flash_protect+0x42>

0000000018001574 <spi_flash_cmd_erase>:
#endif
int spi_flash_cmd_erase(struct spi_flash *flash, u8 erase_cmd,
		u32 offset, u32 len)
{
    18001574:	715d                	addi	sp,sp,-80
    18001576:	e0a2                	sd	s0,64(sp)
    18001578:	fc26                	sd	s1,56(sp)
    1800157a:	f84a                	sd	s2,48(sp)
    1800157c:	f052                	sd	s4,32(sp)
    1800157e:	e486                	sd	ra,72(sp)
    18001580:	f44e                	sd	s3,40(sp)
    18001582:	ec56                	sd	s5,24(sp)
    18001584:	e85a                	sd	s6,16(sp)
	int ret;
	u8 cmd[4];
 
    //uart_printf("spi_flash_cmd_erase \r\n");

	switch(erase_cmd){
    18001586:	05200793          	li	a5,82
{
    1800158a:	8a2e                	mv	s4,a1
    1800158c:	84aa                	mv	s1,a0
    1800158e:	8432                	mv	s0,a2
    18001590:	8936                	mv	s2,a3
	switch(erase_cmd){
    18001592:	0ef58963          	beq	a1,a5,18001684 <spi_flash_cmd_erase+0x110>
    18001596:	0d800793          	li	a5,216
    1800159a:	0ef58263          	beq	a1,a5,1800167e <spi_flash_cmd_erase+0x10a>
		case CMD_W25_SE:
			erase_size = flash->sector_size;
    1800159e:	01852983          	lw	s3,24(a0)
		default:
			erase_size = flash->sector_size;
			break;
	}

	if (offset % erase_size || len % erase_size) {
    180015a2:	033477bb          	remuw	a5,s0,s3
    180015a6:	e7e5                	bnez	a5,1800168e <spi_flash_cmd_erase+0x11a>
    180015a8:	033977bb          	remuw	a5,s2,s3
    180015ac:	e3ed                	bnez	a5,1800168e <spi_flash_cmd_erase+0x11a>
	status[0] = CMD_WRITE_STATUS;
    180015ae:	4785                	li	a5,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180015b0:	4709                	li	a4,2
    180015b2:	00910693          	addi	a3,sp,9
    180015b6:	4605                	li	a2,1
    180015b8:	002c                	addi	a1,sp,8
    180015ba:	8526                	mv	a0,s1
	status[0] = CMD_WRITE_STATUS;
    180015bc:	00f11423          	sh	a5,8(sp)
	status[2] = status2|bit2;
    180015c0:	00010523          	sb	zero,10(sp)
   // spi_flash_cmd_write_status_enable(flash);
	spi_flash_protect(flash);

	cmd[0] = erase_cmd;
	start = offset;
	end = start + len;
    180015c4:	0124093b          	addw	s2,s0,s2
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    180015c8:	e01ff0ef          	jal	ra,180013c8 <spi_flash_write_status>
	cmd[0] = erase_cmd;
    180015cc:	01410423          	sb	s4,8(sp)
	while (offset < end)
    180015d0:	0b247563          	bgeu	s0,s2,1800167a <spi_flash_cmd_erase+0x106>
	return spi_flash_cmd_poll_bit(flash, timeout,
    180015d4:	03938a37          	lui	s4,0x3938
    180015d8:	4a99                	li	s5,6
    180015da:	700a0a13          	addi	s4,s4,1792 # 3938700 <__stack_size+0x3937f00>
    180015de:	4b11                	li	s6,4
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180015e0:	0104179b          	slliw	a5,s0,0x10
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180015e4:	6088                	ld	a0,0(s1)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180015e6:	0107d79b          	srliw	a5,a5,0x10
    180015ea:	0084181b          	slliw	a6,s0,0x8
    180015ee:	0087d79b          	srliw	a5,a5,0x8
    180015f2:	00f86833          	or	a6,a6,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180015f6:	0104589b          	srliw	a7,s0,0x10
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180015fa:	47a1                	li	a5,8
    180015fc:	470d                	li	a4,3
    180015fe:	4681                	li	a3,0
    18001600:	00710613          	addi	a2,sp,7
    18001604:	45a1                	li	a1,8
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001606:	01011523          	sh	a6,10(sp)
	cmd[1] = (addr & 0x00FF0000) >> 16;
    1800160a:	011104a3          	sb	a7,9(sp)
	{
		spi_flash_addr(offset, cmd);
		offset += erase_size;
    1800160e:	015103a3          	sb	s5,7(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001612:	cc2ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001616:	47a1                	li	a5,8
    18001618:	470d                	li	a4,3
    1800161a:	4681                	li	a3,0
    1800161c:	0030                	addi	a2,sp,8
    1800161e:	02000593          	li	a1,32
    18001622:	882a                	mv	a6,a0
		offset += erase_size;
    18001624:	0089843b          	addw	s0,s3,s0
	if (ret)
    18001628:	cd01                	beqz	a0,18001640 <spi_flash_cmd_erase+0xcc>

	//uart_printf("SF: Successfully erased %d bytes @ %x\n", len , start);

out:
	return ret;
}
    1800162a:	60a6                	ld	ra,72(sp)
    1800162c:	6406                	ld	s0,64(sp)
    1800162e:	74e2                	ld	s1,56(sp)
    18001630:	7942                	ld	s2,48(sp)
    18001632:	79a2                	ld	s3,40(sp)
    18001634:	7a02                	ld	s4,32(sp)
    18001636:	6ae2                	ld	s5,24(sp)
    18001638:	6b42                	ld	s6,16(sp)
    1800163a:	8542                	mv	a0,a6
    1800163c:	6161                	addi	sp,sp,80
    1800163e:	8082                	ret
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001640:	6088                	ld	a0,0(s1)
    18001642:	c92ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001646:	882a                	mv	a6,a0
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001648:	4685                	li	a3,1
    1800164a:	4615                	li	a2,5
    1800164c:	85d2                	mv	a1,s4
    1800164e:	8526                	mv	a0,s1
	if (ret)
    18001650:	fc081de3          	bnez	a6,1800162a <spi_flash_cmd_erase+0xb6>
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001654:	b6dff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001658:	47a1                	li	a5,8
    1800165a:	470d                	li	a4,3
    1800165c:	4681                	li	a3,0
    1800165e:	00710613          	addi	a2,sp,7
    18001662:	45a1                	li	a1,8
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001664:	882a                	mv	a6,a0
		if (ret)
    18001666:	f171                	bnez	a0,1800162a <spi_flash_cmd_erase+0xb6>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001668:	6088                	ld	a0,0(s1)
    1800166a:	016103a3          	sb	s6,7(sp)
    1800166e:	c66ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001672:	882a                	mv	a6,a0
	if (ret)
    18001674:	f95d                	bnez	a0,1800162a <spi_flash_cmd_erase+0xb6>
	while (offset < end)
    18001676:	f72465e3          	bltu	s0,s2,180015e0 <spi_flash_cmd_erase+0x6c>
		return -1;
    1800167a:	4801                	li	a6,0
    1800167c:	b77d                	j	1800162a <spi_flash_cmd_erase+0xb6>
			erase_size = flash->block_size;
    1800167e:	01c52983          	lw	s3,28(a0)
			break;
    18001682:	b705                	j	180015a2 <spi_flash_cmd_erase+0x2e>
			erase_size = flash->sector_size * 8;
    18001684:	01852983          	lw	s3,24(a0)
    18001688:	0039999b          	slliw	s3,s3,0x3
			break;
    1800168c:	bf19                	j	180015a2 <spi_flash_cmd_erase+0x2e>
		return -1;
    1800168e:	587d                	li	a6,-1
    18001690:	bf69                	j	1800162a <spi_flash_cmd_erase+0xb6>

0000000018001692 <spi_flash_erase_mode>:

/* mode is 4, 32, 64*/
int spi_flash_erase_mode(struct spi_flash *flash, u32 offset, u32 len, u32 mode)
{
    18001692:	87b6                	mv	a5,a3
	int ret = 0;
	switch (mode)
    18001694:	4711                	li	a4,4
{
    18001696:	86b2                	mv	a3,a2
	switch (mode)
    18001698:	00e78a63          	beq	a5,a4,180016ac <spi_flash_erase_mode+0x1a>
    1800169c:	02000713          	li	a4,32
    180016a0:	00e78a63          	beq	a5,a4,180016b4 <spi_flash_erase_mode+0x22>
			break;
		case 32:
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE_32, offset, len);
			break;
		case 64:
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE, offset, len);
    180016a4:	862e                	mv	a2,a1
    180016a6:	0d800593          	li	a1,216
    180016aa:	b5e9                	j	18001574 <spi_flash_cmd_erase>
			ret = spi_flash_cmd_erase(flash, CMD_W25_SE, offset, len);
    180016ac:	862e                	mv	a2,a1
    180016ae:	02000593          	li	a1,32
    180016b2:	b5c9                	j	18001574 <spi_flash_cmd_erase>
			ret = spi_flash_cmd_erase(flash, CMD_W25_BE_32, offset, len);
    180016b4:	862e                	mv	a2,a1
    180016b6:	05200593          	li	a1,82
    180016ba:	bd6d                	j	18001574 <spi_flash_cmd_erase>

00000000180016bc <spi_flash_cmd_write_mode>:
	}
	return ret;
}

int spi_flash_cmd_write_mode(struct spi_flash *flash, u32 offset,u32 len, void *buf, u32 mode)
{
    180016bc:	7135                	addi	sp,sp,-160
    180016be:	e922                	sd	s0,144(sp)
    180016c0:	e14a                	sd	s2,128(sp)
    180016c2:	f4d6                	sd	s5,104(sp)
    180016c4:	f0da                	sd	s6,96(sp)
    180016c6:	ecde                	sd	s7,88(sp)
    180016c8:	fc6e                	sd	s11,56(sp)
    180016ca:	8b3a                	mv	s6,a4
    180016cc:	ed06                	sd	ra,152(sp)
    180016ce:	e526                	sd	s1,136(sp)
    180016d0:	fcce                	sd	s3,120(sp)
    180016d2:	f8d2                	sd	s4,112(sp)
    180016d4:	e8e2                	sd	s8,80(sp)
    180016d6:	e4e6                	sd	s9,72(sp)
    180016d8:	e0ea                	sd	s10,64(sp)
    int write_data = 1;
	unsigned long flags = SPI_XFER_BEGIN;

	page_size = flash->page_size;

	switch (mode){
    180016da:	4711                	li	a4,4
{
    180016dc:	e436                	sd	a3,8(sp)
	struct spi_slave *spi = flash->spi;
    180016de:	00053d83          	ld	s11,0(a0)
	page_size = flash->page_size;
    180016e2:	01456b83          	lwu	s7,20(a0)
{
    180016e6:	842a                	mv	s0,a0
    180016e8:	892e                	mv	s2,a1
    180016ea:	8ab2                	mv	s5,a2
	switch (mode){
    180016ec:	16eb0f63          	beq	s6,a4,1800186a <spi_flash_cmd_write_mode+0x1ae>
		case 1:
			cmd[0] = CMD_PAGE_PROGRAM;
    180016f0:	4709                	li	a4,2
    180016f2:	02e10423          	sb	a4,40(sp)
			cmd[0] = CMD_PAGE_PROGRAM;
			break;
	}


	for (actual = 0; actual < len; actual += chunk_len)
    180016f6:	100a8063          	beqz	s5,180017f6 <spi_flash_cmd_write_mode+0x13a>
    180016fa:	039387b7          	lui	a5,0x3938
    180016fe:	70078793          	addi	a5,a5,1792 # 3938700 <__stack_size+0x3937f00>
	return spi_flash_cmd_poll_bit(flash, timeout,
    18001702:	016e3c37          	lui	s8,0x16e3
	for (actual = 0; actual < len; actual += chunk_len)
    18001706:	4981                	li	s3,0
    18001708:	4c99                	li	s9,6
    1800170a:	e03e                	sd	a5,0(sp)
	return spi_flash_cmd_poll_bit(flash, timeout,
    1800170c:	600c0c13          	addi	s8,s8,1536 # 16e3600 <__stack_size+0x16e2e00>
	{
		write_addr = offset;
		byte_addr = offset % page_size;
    18001710:	02091493          	slli	s1,s2,0x20
    18001714:	9081                	srli	s1,s1,0x20
    18001716:	0374f4b3          	remu	s1,s1,s7
		chunk_len = min(len - actual, page_size - byte_addr);
    1800171a:	413a87bb          	subw	a5,s5,s3
    1800171e:	1782                	slli	a5,a5,0x20
    18001720:	9381                	srli	a5,a5,0x20
    18001722:	409b84b3          	sub	s1,s7,s1
    18001726:	0097f363          	bgeu	a5,s1,1800172c <spi_flash_cmd_write_mode+0x70>
    1800172a:	84be                	mv	s1,a5
	cmd[2] = (addr & 0x0000FF00) >> 8;
    1800172c:	0109181b          	slliw	a6,s2,0x10
    18001730:	0108581b          	srliw	a6,a6,0x10
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001734:	6008                	ld	a0,0(s0)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001736:	0088579b          	srliw	a5,a6,0x8
    1800173a:	0089181b          	slliw	a6,s2,0x8
    1800173e:	00f86833          	or	a6,a6,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001742:	0109589b          	srliw	a7,s2,0x10
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001746:	47a1                	li	a5,8
    18001748:	470d                	li	a4,3
    1800174a:	4681                	li	a3,0
    1800174c:	1010                	addi	a2,sp,32
    1800174e:	45a1                	li	a1,8
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001750:	031104a3          	sb	a7,41(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001754:	03011523          	sh	a6,42(sp)
    18001758:	03910023          	sb	s9,32(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800175c:	b78ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001760:	87aa                	mv	a5,a0
		chunk_len = min(len - actual, page_size - byte_addr);
    18001762:	00048a1b          	sext.w	s4,s1
	if (ret)
    18001766:	c119                	beqz	a0,1800176c <spi_flash_cmd_write_mode+0xb0>

		spi_flash_addr(write_addr, cmd);

		ret = spi_flash_cmd_write_enable(flash);
		if (ret < 0) {
    18001768:	08054763          	bltz	a0,180017f6 <spi_flash_cmd_write_mode+0x13a>
	return spi_flash_cmd_status_poll_enable(flash, timeout,
    1800176c:	4795                	li	a5,5
	for (actual = 0; actual < len; actual += chunk_len)
    1800176e:	6d02                	ld	s10,0(sp)
    18001770:	00f10fa3          	sb	a5,31(sp)
    18001774:	a039                	j	18001782 <spi_flash_cmd_write_mode+0xc6>
		if ((status & poll_bit) == 0x2)
    18001776:	02014783          	lbu	a5,32(sp)
    1800177a:	8b89                	andi	a5,a5,2
    1800177c:	ef81                	bnez	a5,18001794 <spi_flash_cmd_write_mode+0xd8>
	} while (timebase_1 < timeout);
    1800177e:	000d0b63          	beqz	s10,18001794 <spi_flash_cmd_write_mode+0xd8>
		ret = spi_flash_cmd_read_status(flash, &cmd, 1, &status);
    18001782:	1014                	addi	a3,sp,32
    18001784:	4605                	li	a2,1
    18001786:	01f10593          	addi	a1,sp,31
    1800178a:	8522                	mv	a0,s0
    1800178c:	9f3ff0ef          	jal	ra,1800117e <spi_flash_cmd_read_status>
	} while (timebase_1 < timeout);
    18001790:	3d7d                	addiw	s10,s10,-1
		if (ret)
    18001792:	d175                	beqz	a0,18001776 <spi_flash_cmd_write_mode+0xba>
			//uart_printf("SF: enabling write failed\n");
			break;
		}
		spi_flash_cmd_wait_enable(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT);
#if 1
		if (mode == 1)
    18001794:	4785                	li	a5,1
    18001796:	0afb0a63          	beq	s6,a5,1800184a <spi_flash_cmd_write_mode+0x18e>
				break;
			}
            
		}
#endif
		if (mode == 4)
    1800179a:	4791                	li	a5,4
    1800179c:	00fb1f63          	bne	s6,a5,180017ba <spi_flash_cmd_write_mode+0xfe>
		{
			flags = SPI_XFER_BEGIN;
			if (chunk_len == 0)
    180017a0:	e8bd                	bnez	s1,18001816 <spi_flash_cmd_write_mode+0x15a>
				flags |= SPI_XFER_END;

			ret = spi_xfer(spi, 4 * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180017a2:	47a1                	li	a5,8
    180017a4:	470d                	li	a4,3
    180017a6:	4681                	li	a3,0
    180017a8:	1030                	addi	a2,sp,40
    180017aa:	02000593          	li	a1,32
    180017ae:	856e                	mv	a0,s11
    180017b0:	b24ff0ef          	jal	ra,18000ad4 <spi_xfer>
    180017b4:	87aa                	mv	a5,a0
			if (ret < 0)
    180017b6:	04054063          	bltz	a0,180017f6 <spi_flash_cmd_write_mode+0x13a>
	return spi_flash_cmd_poll_bit(flash, timeout,
    180017ba:	4685                	li	a3,1
    180017bc:	4615                	li	a2,5
    180017be:	85e2                	mv	a1,s8
    180017c0:	8522                	mv	a0,s0
    180017c2:	9ffff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
    180017c6:	87aa                	mv	a5,a0
			
		    }
		}
        //qspi_mode_ctl(SPI4_DATEMODE_0);
		ret = spi_flash_cmd_wait_ready(flash, SPI_FLASH_PROG_TIMEOUT);
		if (ret < 0)
    180017c8:	02054763          	bltz	a0,180017f6 <spi_flash_cmd_write_mode+0x13a>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180017cc:	6008                	ld	a0,0(s0)
    180017ce:	47a1                	li	a5,8
    180017d0:	4811                	li	a6,4
    180017d2:	470d                	li	a4,3
    180017d4:	4681                	li	a3,0
    180017d6:	1010                	addi	a2,sp,32
    180017d8:	45a1                	li	a1,8
    180017da:	03010023          	sb	a6,32(sp)
    180017de:	af6ff0ef          	jal	ra,18000ad4 <spi_xfer>
    180017e2:	87aa                	mv	a5,a0
	if (ret)
    180017e4:	c119                	beqz	a0,180017ea <spi_flash_cmd_write_mode+0x12e>
		{
			//uart_printf("SF: spi_flash_cmd_wait_ready failed\n");
			break;
		}
		ret = spi_flash_cmd_write_disable(flash->spi);
		if (ret < 0)
    180017e6:	00054863          	bltz	a0,180017f6 <spi_flash_cmd_write_mode+0x13a>
	for (actual = 0; actual < len; actual += chunk_len)
    180017ea:	013a09bb          	addw	s3,s4,s3
		{
			//uart_printf("SF: disable write failed\n");
			break;
		}
         
    	offset += chunk_len;
    180017ee:	012a093b          	addw	s2,s4,s2
	for (actual = 0; actual < len; actual += chunk_len)
    180017f2:	f159efe3          	bltu	s3,s5,18001710 <spi_flash_cmd_write_mode+0x54>
	//uart_printf("SF: program %s %d bytes @ %d\n", ret ? "failure" : "success", len, offset);
    }
	return ret;
}
    180017f6:	60ea                	ld	ra,152(sp)
    180017f8:	644a                	ld	s0,144(sp)
    180017fa:	64aa                	ld	s1,136(sp)
    180017fc:	690a                	ld	s2,128(sp)
    180017fe:	79e6                	ld	s3,120(sp)
    18001800:	7a46                	ld	s4,112(sp)
    18001802:	7aa6                	ld	s5,104(sp)
    18001804:	7b06                	ld	s6,96(sp)
    18001806:	6be6                	ld	s7,88(sp)
    18001808:	6c46                	ld	s8,80(sp)
    1800180a:	6ca6                	ld	s9,72(sp)
    1800180c:	6d06                	ld	s10,64(sp)
    1800180e:	7de2                	ld	s11,56(sp)
    18001810:	853e                	mv	a0,a5
    18001812:	610d                	addi	sp,sp,160
    18001814:	8082                	ret
			ret = spi_xfer(spi, 4 * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001816:	47a1                	li	a5,8
    18001818:	4705                	li	a4,1
    1800181a:	4681                	li	a3,0
    1800181c:	1030                	addi	a2,sp,40
    1800181e:	02000593          	li	a1,32
    18001822:	856e                	mv	a0,s11
    18001824:	ab0ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001828:	87aa                	mv	a5,a0
			if (ret < 0)
    1800182a:	fc0546e3          	bltz	a0,180017f6 <spi_flash_cmd_write_mode+0x13a>
				ret = spi_xfer(spi, chunk_len * 8, (unsigned char*)buf + actual, NULL, SPI_XFER_END, SPI_DATAMODE_8);
    1800182e:	6522                	ld	a0,8(sp)
    18001830:	02099613          	slli	a2,s3,0x20
    18001834:	9201                	srli	a2,a2,0x20
    18001836:	962a                	add	a2,a2,a0
    18001838:	003a159b          	slliw	a1,s4,0x3
    1800183c:	47a1                	li	a5,8
    1800183e:	4709                	li	a4,2
    18001840:	4681                	li	a3,0
    18001842:	856e                	mv	a0,s11
    18001844:	a90ff0ef          	jal	ra,18000ad4 <spi_xfer>
    18001848:	bf8d                	j	180017ba <spi_flash_cmd_write_mode+0xfe>
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    1800184a:	6622                	ld	a2,8(sp)
    1800184c:	6008                	ld	a0,0(s0)
            ret = spi_flash_cmd_write(flash->spi, cmd, 4,
    1800184e:	02099693          	slli	a3,s3,0x20
    18001852:	9281                	srli	a3,a3,0x20
	return spi_flash_read_write(spi, cmd, cmd_len, data, NULL, data_len);
    18001854:	87d2                	mv	a5,s4
    18001856:	96b2                	add	a3,a3,a2
    18001858:	4701                	li	a4,0
    1800185a:	4611                	li	a2,4
    1800185c:	102c                	addi	a1,sp,40
    1800185e:	f50ff0ef          	jal	ra,18000fae <spi_flash_read_write>
    18001862:	87aa                	mv	a5,a0
			if (ret < 0) {
    18001864:	f4055be3          	bgez	a0,180017ba <spi_flash_cmd_write_mode+0xfe>
    18001868:	b779                	j	180017f6 <spi_flash_cmd_write_mode+0x13a>
			cmd[0] = CMD_PAGE_PROGRAM_QUAD;
    1800186a:	03200813          	li	a6,50
    1800186e:	03010423          	sb	a6,40(sp)
	status[0] = CMD_WRITE_STATUS;
    18001872:	4805                	li	a6,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001874:	02110693          	addi	a3,sp,33
    18001878:	4605                	li	a2,1
    1800187a:	100c                	addi	a1,sp,32
    1800187c:	4709                	li	a4,2
	status[0] = CMD_WRITE_STATUS;
    1800187e:	03011023          	sh	a6,32(sp)
	status[2] = status2|bit2;
    18001882:	4809                	li	a6,2
    18001884:	e03e                	sd	a5,0(sp)
    18001886:	03010123          	sb	a6,34(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    1800188a:	b3fff0ef          	jal	ra,180013c8 <spi_flash_write_status>
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS1, ~bit2);
    1800188e:	039385b7          	lui	a1,0x3938
    18001892:	0fd00693          	li	a3,253
    18001896:	03500613          	li	a2,53
    1800189a:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    1800189e:	8522                	mv	a0,s0
    180018a0:	921ff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
    180018a4:	6782                	ld	a5,0(sp)
	return ret;
    180018a6:	bd81                	j	180016f6 <spi_flash_cmd_write_mode+0x3a>

00000000180018a8 <spi_flash_read_common>:

int spi_flash_read_common(struct spi_flash *flash, u8 *cmd,
		u32 cmd_len, void *data, u32 data_len)
{
    180018a8:	1101                	addi	sp,sp,-32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018aa:	0036179b          	slliw	a5,a2,0x3
{
    180018ae:	e04a                	sd	s2,0(sp)
    180018b0:	ec06                	sd	ra,24(sp)
    180018b2:	e822                	sd	s0,16(sp)
    180018b4:	e426                	sd	s1,8(sp)
    180018b6:	862e                	mv	a2,a1
	struct spi_slave *spi = flash->spi;
    180018b8:	00053903          	ld	s2,0(a0)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018bc:	0007859b          	sext.w	a1,a5
	if (data_len == 0)
    180018c0:	ef01                	bnez	a4,180018d8 <spi_flash_read_common+0x30>
	int ret;

	ret = spi_flash_cmd_read(spi, cmd, cmd_len, data, data_len);

	return ret;
}
    180018c2:	6442                	ld	s0,16(sp)
    180018c4:	60e2                	ld	ra,24(sp)
    180018c6:	64a2                	ld	s1,8(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018c8:	854a                	mv	a0,s2
}
    180018ca:	6902                	ld	s2,0(sp)
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018cc:	47a1                	li	a5,8
    180018ce:	470d                	li	a4,3
    180018d0:	4681                	li	a3,0
}
    180018d2:	6105                	addi	sp,sp,32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    180018d4:	a00ff06f          	j	18000ad4 <spi_xfer>
    180018d8:	843a                	mv	s0,a4
    180018da:	84b6                	mv	s1,a3
    180018dc:	47a1                	li	a5,8
    180018de:	4705                	li	a4,1
    180018e0:	4681                	li	a3,0
    180018e2:	854a                	mv	a0,s2
    180018e4:	9f0ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    180018e8:	c519                	beqz	a0,180018f6 <spi_flash_read_common+0x4e>
}
    180018ea:	60e2                	ld	ra,24(sp)
    180018ec:	6442                	ld	s0,16(sp)
    180018ee:	64a2                	ld	s1,8(sp)
    180018f0:	6902                	ld	s2,0(sp)
    180018f2:	6105                	addi	sp,sp,32
    180018f4:	8082                	ret
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180018f6:	0034159b          	slliw	a1,s0,0x3
}
    180018fa:	6442                	ld	s0,16(sp)
    180018fc:	60e2                	ld	ra,24(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    180018fe:	86a6                	mv	a3,s1
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001900:	854a                	mv	a0,s2
}
    18001902:	64a2                	ld	s1,8(sp)
    18001904:	6902                	ld	s2,0(sp)
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001906:	47a1                	li	a5,8
    18001908:	4709                	li	a4,2
    1800190a:	4601                	li	a2,0
}
    1800190c:	6105                	addi	sp,sp,32
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800190e:	9c6ff06f          	j	18000ad4 <spi_xfer>

0000000018001912 <spi_flash_cmd_read_fast>:
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001912:	0105971b          	slliw	a4,a1,0x10
    18001916:	0107571b          	srliw	a4,a4,0x10
    1800191a:	0085979b          	slliw	a5,a1,0x8
    1800191e:	0087571b          	srliw	a4,a4,0x8

int spi_flash_cmd_read_fast(struct spi_flash *flash, u32 offset,
		u32 len, void *data, u32 mode)
{
    18001922:	7179                	addi	sp,sp,-48
	cmd[2] = (addr & 0x0000FF00) >> 8;
    18001924:	8fd9                	or	a5,a5,a4
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001926:	0105d59b          	srliw	a1,a1,0x10
	u8 cmd[5];

	cmd[0] = CMD_READ_ARRAY_FAST;
    1800192a:	472d                	li	a4,11
{
    1800192c:	e84a                	sd	s2,16(sp)
    1800192e:	f406                	sd	ra,40(sp)
    18001930:	f022                	sd	s0,32(sp)
    18001932:	ec26                	sd	s1,24(sp)
	cmd[0] = CMD_READ_ARRAY_FAST;
    18001934:	00e10423          	sb	a4,8(sp)
	cmd[1] = (addr & 0x00FF0000) >> 16;
    18001938:	00b104a3          	sb	a1,9(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    1800193c:	00f11523          	sh	a5,10(sp)
	spi_flash_addr(offset, cmd);
	cmd[4] = 0x00;
    18001940:	00010623          	sb	zero,12(sp)
	struct spi_slave *spi = flash->spi;
    18001944:	00053903          	ld	s2,0(a0)
	if (data_len == 0)
    18001948:	e205                	bnez	a2,18001968 <spi_flash_cmd_read_fast+0x56>
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    1800194a:	47a1                	li	a5,8
    1800194c:	470d                	li	a4,3
    1800194e:	4681                	li	a3,0
    18001950:	0030                	addi	a2,sp,8
    18001952:	02800593          	li	a1,40
    18001956:	854a                	mv	a0,s2
    18001958:	97cff0ef          	jal	ra,18000ad4 <spi_xfer>

	return spi_flash_read_common(flash, cmd, sizeof(cmd), data, len);
}
    1800195c:	70a2                	ld	ra,40(sp)
    1800195e:	7402                	ld	s0,32(sp)
    18001960:	64e2                	ld	s1,24(sp)
    18001962:	6942                	ld	s2,16(sp)
    18001964:	6145                	addi	sp,sp,48
    18001966:	8082                	ret
	ret = spi_xfer(spi, cmd_len * 8, cmd, NULL, flags, SPI_DATAMODE_8);
    18001968:	8432                	mv	s0,a2
    1800196a:	84b6                	mv	s1,a3
    1800196c:	47a1                	li	a5,8
    1800196e:	4705                	li	a4,1
    18001970:	4681                	li	a3,0
    18001972:	0030                	addi	a2,sp,8
    18001974:	02800593          	li	a1,40
    18001978:	854a                	mv	a0,s2
    1800197a:	95aff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret)
    1800197e:	fd79                	bnez	a0,1800195c <spi_flash_cmd_read_fast+0x4a>
		ret = spi_xfer(spi, data_len * 8, data_out, data_in, SPI_XFER_END, SPI_DATAMODE_8);
    18001980:	0034159b          	slliw	a1,s0,0x3
    18001984:	86a6                	mv	a3,s1
    18001986:	854a                	mv	a0,s2
    18001988:	47a1                	li	a5,8
    1800198a:	4709                	li	a4,2
    1800198c:	4601                	li	a2,0
    1800198e:	946ff0ef          	jal	ra,18000ad4 <spi_xfer>
}
    18001992:	70a2                	ld	ra,40(sp)
    18001994:	7402                	ld	s0,32(sp)
    18001996:	64e2                	ld	s1,24(sp)
    18001998:	6942                	ld	s2,16(sp)
    1800199a:	6145                	addi	sp,sp,48
    1800199c:	8082                	ret

000000001800199e <spi_flash_read_mode>:

int spi_flash_read_mode(struct spi_flash *flash, u32 offset,
		u32 len, void *data, u32 mode)
{
    1800199e:	7139                	addi	sp,sp,-64
    180019a0:	f822                	sd	s0,48(sp)
    180019a2:	f426                	sd	s1,40(sp)
    180019a4:	ec4e                	sd	s3,24(sp)
    180019a6:	e852                	sd	s4,16(sp)
    180019a8:	fc06                	sd	ra,56(sp)
    180019aa:	f04a                	sd	s2,32(sp)
	int ret;
    int write_data = 0;
    u8 status[2] = {2};
    int i = 0;

	switch (mode)
    180019ac:	4789                	li	a5,2
	struct spi_slave *spi = flash->spi;
    180019ae:	00053a03          	ld	s4,0(a0)
{
    180019b2:	842e                	mv	s0,a1
    180019b4:	84b2                	mv	s1,a2
    180019b6:	89b6                	mv	s3,a3
	switch (mode)
    180019b8:	06f70c63          	beq	a4,a5,18001a30 <spi_flash_read_mode+0x92>
    180019bc:	4691                	li	a3,4
    180019be:	06d70e63          	beq	a4,a3,18001a3a <spi_flash_read_mode+0x9c>
	{
		case 1:
			cmd[0] = CMD_READ_ARRAY_FAST;
    180019c2:	47ad                	li	a5,11
    180019c4:	00f10423          	sb	a5,8(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180019c8:	0104181b          	slliw	a6,s0,0x10
    180019cc:	0108581b          	srliw	a6,a6,0x10
    180019d0:	0088579b          	srliw	a5,a6,0x8
    180019d4:	0084181b          	slliw	a6,s0,0x8
    180019d8:	00f86833          	or	a6,a6,a5
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180019dc:	0104541b          	srliw	s0,s0,0x10
    
	spi_flash_addr(offset, cmd);
	cmd[4] = 0x00;


    ret = spi_xfer(spi, 5*8, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180019e0:	47a1                	li	a5,8
    180019e2:	4705                	li	a4,1
    180019e4:	4681                	li	a3,0
    180019e6:	0030                	addi	a2,sp,8
    180019e8:	02800593          	li	a1,40
    180019ec:	8552                	mv	a0,s4
	cmd[1] = (addr & 0x00FF0000) >> 16;
    180019ee:	008104a3          	sb	s0,9(sp)
	cmd[2] = (addr & 0x0000FF00) >> 8;
    180019f2:	01011523          	sh	a6,10(sp)
	cmd[4] = 0x00;
    180019f6:	00010623          	sb	zero,12(sp)
    ret = spi_xfer(spi, 5*8, cmd, NULL, SPI_XFER_BEGIN, SPI_DATAMODE_8);
    180019fa:	8daff0ef          	jal	ra,18000ad4 <spi_xfer>
    if (ret < 0)
    180019fe:	02054163          	bltz	a0,18001a20 <spi_flash_read_mode+0x82>
	{
		//uart_printf("xfer failed\n");
		return ret;
	}
	ret = spi_xfer(spi,  len*8,  NULL, data, SPI_XFER_END, SPI_DATAMODE_8);
    18001a02:	47a1                	li	a5,8
    18001a04:	0034959b          	slliw	a1,s1,0x3
    18001a08:	4709                	li	a4,2
    18001a0a:	86ce                	mv	a3,s3
    18001a0c:	4601                	li	a2,0
    18001a0e:	8552                	mv	a0,s4
    18001a10:	8c4ff0ef          	jal	ra,18000ad4 <spi_xfer>
	if (ret < 0)
    18001a14:	00152793          	slti	a5,a0,1
    18001a18:	40f007bb          	negw	a5,a5
    18001a1c:	8d7d                	and	a0,a0,a5
    18001a1e:	2501                	sext.w	a0,a0
		//uart_printf("xfer failed\n");
		return ret;
	}

	return 0;
}
    18001a20:	70e2                	ld	ra,56(sp)
    18001a22:	7442                	ld	s0,48(sp)
    18001a24:	74a2                	ld	s1,40(sp)
    18001a26:	7902                	ld	s2,32(sp)
    18001a28:	69e2                	ld	s3,24(sp)
    18001a2a:	6a42                	ld	s4,16(sp)
    18001a2c:	6121                	addi	sp,sp,64
    18001a2e:	8082                	ret
			cmd[0] = CMD_READ_ARRAY_DUAL;
    18001a30:	03b00793          	li	a5,59
    18001a34:	00f10423          	sb	a5,8(sp)
			break;
    18001a38:	bf41                	j	180019c8 <spi_flash_read_mode+0x2a>
			cmd[0] = CMD_READ_ARRAY_QUAD;
    18001a3a:	06b00813          	li	a6,107
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001a3e:	00110693          	addi	a3,sp,1
    18001a42:	858a                	mv	a1,sp
			cmd[0] = CMD_READ_ARRAY_QUAD;
    18001a44:	01010423          	sb	a6,8(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001a48:	4605                	li	a2,1
	status[0] = CMD_WRITE_STATUS;
    18001a4a:	4805                	li	a6,1
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001a4c:	4709                	li	a4,2
    18001a4e:	892a                	mv	s2,a0
	status[0] = CMD_WRITE_STATUS;
    18001a50:	01011023          	sh	a6,0(sp)
	status[2] = status2|bit2;
    18001a54:	00f10123          	sb	a5,2(sp)
	spi_flash_write_status(flash, &status[0], 1, &status[1], 2);
    18001a58:	971ff0ef          	jal	ra,180013c8 <spi_flash_write_status>
		ret &= spi_flash_cmd_poll_bit(flash, SPI_FLASH_PAGE_ERASE_TIMEOUT, CMD_READ_STATUS1, ~bit2);
    18001a5c:	039385b7          	lui	a1,0x3938
    18001a60:	0fd00693          	li	a3,253
    18001a64:	03500613          	li	a2,53
    18001a68:	70058593          	addi	a1,a1,1792 # 3938700 <__stack_size+0x3937f00>
    18001a6c:	854a                	mv	a0,s2
    18001a6e:	f52ff0ef          	jal	ra,180011c0 <spi_flash_cmd_poll_bit>
	return ret;
    18001a72:	bf99                	j	180019c8 <spi_flash_read_mode+0x2a>

0000000018001a74 <cadence_qspi_apb_exec_flash_cmd>:
	return;
}

static int cadence_qspi_apb_exec_flash_cmd(u32 reg_base,
	unsigned int reg)
{
    18001a74:	7179                	addi	sp,sp,-48
    18001a76:	ec26                	sd	s1,24(sp)
	unsigned int retry = CQSPI_REG_RETRY;

	/* Write the CMDCTRL without start execution. */
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);
    18001a78:	0905049b          	addiw	s1,a0,144
    18001a7c:	1482                	slli	s1,s1,0x20
{
    18001a7e:	e84a                	sd	s2,16(sp)
    18001a80:	f406                	sd	ra,40(sp)
    18001a82:	f022                	sd	s0,32(sp)
    18001a84:	e44e                	sd	s3,8(sp)
    18001a86:	892a                	mv	s2,a0
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);
    18001a88:	9081                	srli	s1,s1,0x20
    18001a8a:	c08c                	sw	a1,0(s1)
	/* Start execute */
	reg |= CQSPI_REG_CMDCTRL_EXECUTE_MASK;
    18001a8c:	0015e593          	ori	a1,a1,1
    18001a90:	c08c                	sw	a1,0(s1)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001a92:	409c                	lw	a5,0(s1)
	writel(reg, (u32)reg_base + CQSPI_REG_CMDCTRL);

	while (retry--) {
		reg = readl((u32)reg_base + CQSPI_REG_CMDCTRL);
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001a94:	8b89                	andi	a5,a5,2
    18001a96:	c78d                	beqz	a5,18001ac0 <cadence_qspi_apb_exec_flash_cmd+0x4c>
			break;
		delay(1000);
    18001a98:	3e800513          	li	a0,1000
	while (retry--) {
    18001a9c:	6409                	lui	s0,0x2
		delay(1000);
    18001a9e:	7c2000ef          	jal	ra,18002260 <udelay>
	while (retry--) {
    18001aa2:	70e40413          	addi	s0,s0,1806 # 270e <__stack_size+0x1f0e>
    18001aa6:	59fd                	li	s3,-1
    18001aa8:	a031                	j	18001ab4 <cadence_qspi_apb_exec_flash_cmd+0x40>
    18001aaa:	347d                	addiw	s0,s0,-1
		delay(1000);
    18001aac:	7b4000ef          	jal	ra,18002260 <udelay>
	while (retry--) {
    18001ab0:	01340863          	beq	s0,s3,18001ac0 <cadence_qspi_apb_exec_flash_cmd+0x4c>
    18001ab4:	409c                	lw	a5,0(s1)
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001ab6:	8b89                	andi	a5,a5,2
		delay(1000);
    18001ab8:	3e800513          	li	a0,1000
		if ((reg & CQSPI_REG_CMDCTRL_INPROGRESS_MASK) == 0)
    18001abc:	f7fd                	bnez	a5,18001aaa <cadence_qspi_apb_exec_flash_cmd+0x36>
	}

	if (!retry) {
    18001abe:	c415                	beqz	s0,18001aea <cadence_qspi_apb_exec_flash_cmd+0x76>
		//uart_printf("QSPI: flash command execution timeout\n");
		return -1;
	}

	/* Polling QSPI idle status. */
	if (!cadence_qspi_wait_idle(reg_base))
    18001ac0:	02091693          	slli	a3,s2,0x20
    18001ac4:	6709                	lui	a4,0x2
    18001ac6:	9281                	srli	a3,a3,0x20
    18001ac8:	71070713          	addi	a4,a4,1808 # 2710 <__stack_size+0x1f10>
    18001acc:	a011                	j	18001ad0 <cadence_qspi_apb_exec_flash_cmd+0x5c>
		if (count >= CQSPI_REG_RETRY)
    18001ace:	c711                	beqz	a4,18001ada <cadence_qspi_apb_exec_flash_cmd+0x66>
    18001ad0:	429c                	lw	a5,0(a3)
		if (CQSPI_REG_IS_IDLE((u32)reg_base))
    18001ad2:	2781                	sext.w	a5,a5
		if (count >= CQSPI_REG_RETRY)
    18001ad4:	377d                	addiw	a4,a4,-1
		if (CQSPI_REG_IS_IDLE((u32)reg_base))
    18001ad6:	fe07dce3          	bgez	a5,18001ace <cadence_qspi_apb_exec_flash_cmd+0x5a>
		return -1;

	return 0;
    18001ada:	4501                	li	a0,0
}
    18001adc:	70a2                	ld	ra,40(sp)
    18001ade:	7402                	ld	s0,32(sp)
    18001ae0:	64e2                	ld	s1,24(sp)
    18001ae2:	6942                	ld	s2,16(sp)
    18001ae4:	69a2                	ld	s3,8(sp)
    18001ae6:	6145                	addi	sp,sp,48
    18001ae8:	8082                	ret
		return -1;
    18001aea:	557d                	li	a0,-1
    18001aec:	bfc5                	j	18001adc <cadence_qspi_apb_exec_flash_cmd+0x68>

0000000018001aee <cadence_qspi_apb_controller_enable>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001aee:	1502                	slli	a0,a0,0x20
    18001af0:	9101                	srli	a0,a0,0x20
    18001af2:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001af4:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001af8:	c11c                	sw	a5,0(a0)
}
    18001afa:	8082                	ret

0000000018001afc <cadence_qspi_apb_controller_disable>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001afc:	1502                	slli	a0,a0,0x20
    18001afe:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b00:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b02:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b04:	c11c                	sw	a5,0(a0)
}
    18001b06:	8082                	ret

0000000018001b08 <cadence_qspi_apb_readdata_capture>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001b08:	02051713          	slli	a4,a0,0x20
    18001b0c:	9301                	srli	a4,a4,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b0e:	431c                	lw	a5,0(a4)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b10:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b12:	c31c                	sw	a5,0(a4)
	reg = readl((u32)reg_base + CQSPI_READLCAPTURE);
    18001b14:	2541                	addiw	a0,a0,16
    18001b16:	1502                	slli	a0,a0,0x20
    18001b18:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b1a:	411c                	lw	a5,0(a0)
	if (bypass)
    18001b1c:	cd99                	beqz	a1,18001b3a <cadence_qspi_apb_readdata_capture+0x32>
		reg |= (1 << CQSPI_READLCAPTURE_BYPASS_LSB);
    18001b1e:	0017e793          	ori	a5,a5,1
    18001b22:	2781                	sext.w	a5,a5
		<< CQSPI_READLCAPTURE_DELAY_LSB);
    18001b24:	0016161b          	slliw	a2,a2,0x1
	reg &= ~(CQSPI_READLCAPTURE_DELAY_MASK
    18001b28:	9b85                	andi	a5,a5,-31
		<< CQSPI_READLCAPTURE_DELAY_LSB);
    18001b2a:	8a79                	andi	a2,a2,30
	reg |= ((delay & CQSPI_READLCAPTURE_DELAY_MASK)
    18001b2c:	8e5d                	or	a2,a2,a5
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b2e:	c110                	sw	a2,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b30:	431c                	lw	a5,0(a4)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b32:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b36:	c31c                	sw	a5,0(a4)
}
    18001b38:	8082                	ret
		reg &= ~(1 << CQSPI_READLCAPTURE_BYPASS_LSB);
    18001b3a:	9bf9                	andi	a5,a5,-2
    18001b3c:	2781                	sext.w	a5,a5
    18001b3e:	b7dd                	j	18001b24 <cadence_qspi_apb_readdata_capture+0x1c>

0000000018001b40 <cadence_qspi_apb_config_baudrate_div>:
	reg = readl((u32)reg_base + CQSPI_REG_CONFIG);
    18001b40:	1502                	slli	a0,a0,0x20
    18001b42:	9101                	srli	a0,a0,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b44:	411c                	lw	a5,0(a0)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b46:	9bf9                	andi	a5,a5,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b48:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b4a:	4114                	lw	a3,0(a0)
	div = DIV_ROUND_UP(ref_clk_hz, sclk_hz * 2) - 1;
    18001b4c:	0016161b          	slliw	a2,a2,0x1
    18001b50:	35fd                	addiw	a1,a1,-1
    18001b52:	00c587bb          	addw	a5,a1,a2
    18001b56:	02c7d7bb          	divuw	a5,a5,a2
	reg &= ~(CQSPI_REG_CONFIG_BAUD_MASK << CQSPI_REG_CONFIG_BAUD_LSB);
    18001b5a:	ff880737          	lui	a4,0xff880
    18001b5e:	177d                	addi	a4,a4,-1
    18001b60:	8f75                	and	a4,a4,a3
	div = (div & CQSPI_REG_CONFIG_BAUD_MASK) << CQSPI_REG_CONFIG_BAUD_LSB;
    18001b62:	46bd                	li	a3,15
	reg &= ~(CQSPI_REG_CONFIG_BAUD_MASK << CQSPI_REG_CONFIG_BAUD_LSB);
    18001b64:	2701                	sext.w	a4,a4
	div = DIV_ROUND_UP(ref_clk_hz, sclk_hz * 2) - 1;
    18001b66:	fff7861b          	addiw	a2,a5,-1
    18001b6a:	87b2                	mv	a5,a2
	div = (div & CQSPI_REG_CONFIG_BAUD_MASK) << CQSPI_REG_CONFIG_BAUD_LSB;
    18001b6c:	00c6f363          	bgeu	a3,a2,18001b72 <cadence_qspi_apb_config_baudrate_div+0x32>
    18001b70:	47bd                	li	a5,15
    18001b72:	0137979b          	slliw	a5,a5,0x13
	reg |= div;
    18001b76:	8fd9                	or	a5,a5,a4
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b78:	c11c                	sw	a5,0(a0)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001b7a:	411c                	lw	a5,0(a0)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001b7c:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001b80:	c11c                	sw	a5,0(a0)
}
    18001b82:	8082                	ret

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
    18001bc6:	3ff70713          	addi	a4,a4,1023 # ffffffffffffc3ff <_sp+0xffffffffe7fea29f>
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
    18001c28:	4218                	lw	a4,0(a2)
	reg &= ~CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c2a:	9b79                	andi	a4,a4,-2
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c2c:	c218                	sw	a4,0(a2)
	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    18001c2e:	0147859b          	addiw	a1,a5,20
    18001c32:	1582                	slli	a1,a1,0x20
    18001c34:	2781                	sext.w	a5,a5
    18001c36:	9181                	srli	a1,a1,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c38:	0005a883          	lw	a7,0(a1)
	reg |= (plat->page_size << CQSPI_REG_SIZE_PAGE_LSB);
    18001c3c:	4d58                	lw	a4,28(a0)
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c3e:	02052803          	lw	a6,32(a0)
	reg &= ~(CQSPI_REG_SIZE_BLOCK_MASK << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c42:	ffc006b7          	lui	a3,0xffc00
    18001c46:	06bd                	addi	a3,a3,15
    18001c48:	0116f6b3          	and	a3,a3,a7
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c4c:	0108181b          	slliw	a6,a6,0x10
	reg |= (plat->page_size << CQSPI_REG_SIZE_PAGE_LSB);
    18001c50:	0047171b          	slliw	a4,a4,0x4
	reg &= ~(CQSPI_REG_SIZE_BLOCK_MASK << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c54:	2681                	sext.w	a3,a3
	reg |= (plat->block_size << CQSPI_REG_SIZE_BLOCK_LSB);
    18001c56:	01076733          	or	a4,a4,a6
    18001c5a:	8f55                	or	a4,a4,a3
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c5c:	c198                	sw	a4,0(a1)
	writel(0,(u32) plat->regbase + CQSPI_REG_REMAP);
    18001c5e:	0247871b          	addiw	a4,a5,36
    18001c62:	1702                	slli	a4,a4,0x20
    18001c64:	4581                	li	a1,0
    18001c66:	9301                	srli	a4,a4,0x20
    18001c68:	c30c                	sw	a1,0(a4)
	writel((plat->sram_size/2), (u32)plat->regbase + CQSPI_REG_SRAMPARTITION);
    18001c6a:	5958                	lw	a4,52(a0)
    18001c6c:	0187869b          	addiw	a3,a5,24
    18001c70:	1682                	slli	a3,a3,0x20
    18001c72:	9281                	srli	a3,a3,0x20
    18001c74:	0017571b          	srliw	a4,a4,0x1
    18001c78:	c298                	sw	a4,0(a3)
	writel(0, (u32)plat->regbase + CQSPI_REG_IRQMASK);
    18001c7a:	0447879b          	addiw	a5,a5,68
    18001c7e:	1782                	slli	a5,a5,0x20
    18001c80:	9381                	srli	a5,a5,0x20
    18001c82:	c38c                	sw	a1,0(a5)
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001c84:	421c                	lw	a5,0(a2)
	reg |= CQSPI_REG_CONFIG_ENABLE_MASK;
    18001c86:	0017e793          	ori	a5,a5,1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001c8a:	c21c                	sw	a5,0(a2)
}
    18001c8c:	8082                	ret

0000000018001c8e <cadence_qspi_apb_command_read>:

/* For command RDID, RDSR. */
int cadence_qspi_apb_command_read(void * reg_base,
	unsigned int cmdlen, const u8 *cmdbuf, unsigned int rxlen,
	u8 *rxbuf)
{
    18001c8e:	7139                	addi	sp,sp,-64
    18001c90:	fc06                	sd	ra,56(sp)
    18001c92:	f822                	sd	s0,48(sp)
    18001c94:	f426                	sd	s1,40(sp)
    18001c96:	f04a                	sd	s2,32(sp)
    18001c98:	ec4e                	sd	s3,24(sp)
    18001c9a:	e852                	sd	s4,16(sp)
	unsigned int reg;
	unsigned int read_len;
	int status;

	if (!cmdlen || rxlen > CQSPI_STIG_DATA_LEN_MAX || rxbuf == NULL) {
    18001c9c:	cdc1                	beqz	a1,18001d34 <cadence_qspi_apb_command_read+0xa6>
    18001c9e:	47a1                	li	a5,8
    18001ca0:	84b6                	mv	s1,a3
    18001ca2:	08d7e963          	bltu	a5,a3,18001d34 <cadence_qspi_apb_command_read+0xa6>
    18001ca6:	89ba                	mv	s3,a4
    18001ca8:	c751                	beqz	a4,18001d34 <cadence_qspi_apb_command_read+0xa6>
		//uart_printf("QSPI: Invalid input arguments cmdlen %d rxlen %d\n",
		       //cmdlen, rxlen);
		return -1;
	}

	reg = cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001caa:	00064783          	lbu	a5,0(a2)

	reg |= (0x1 << CQSPI_REG_CMDCTRL_RD_EN_LSB);

	/* 0 means 1 byte. */
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cae:	fff6859b          	addiw	a1,a3,-1
		<< CQSPI_REG_CMDCTRL_RD_BYTES_LSB);
    18001cb2:	00700737          	lui	a4,0x700
    18001cb6:	0145959b          	slliw	a1,a1,0x14
    18001cba:	8df9                	and	a1,a1,a4
	reg = cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001cbc:	0187979b          	slliw	a5,a5,0x18
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cc0:	8ddd                	or	a1,a1,a5
    18001cc2:	008007b7          	lui	a5,0x800
    18001cc6:	8ddd                	or	a1,a1,a5
	status = cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001cc8:	0005041b          	sext.w	s0,a0
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001ccc:	2581                	sext.w	a1,a1
	status = cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001cce:	8522                	mv	a0,s0
	reg |= (((rxlen - 1) & CQSPI_REG_CMDCTRL_RD_BYTES_MASK)
    18001cd0:	c62e                	sw	a1,12(sp)
	status = cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001cd2:	da3ff0ef          	jal	ra,18001a74 <cadence_qspi_apb_exec_flash_cmd>
    18001cd6:	892a                	mv	s2,a0
	if (status != 0)
    18001cd8:	c911                	beqz	a0,18001cec <cadence_qspi_apb_command_read+0x5e>

		read_len = rxlen - read_len;
		sys_memcpy(rxbuf, &reg, read_len);
	}
	return 0;
}
    18001cda:	70e2                	ld	ra,56(sp)
    18001cdc:	7442                	ld	s0,48(sp)
    18001cde:	74a2                	ld	s1,40(sp)
    18001ce0:	69e2                	ld	s3,24(sp)
    18001ce2:	6a42                	ld	s4,16(sp)
    18001ce4:	854a                	mv	a0,s2
    18001ce6:	7902                	ld	s2,32(sp)
    18001ce8:	6121                	addi	sp,sp,64
    18001cea:	8082                	ret
	reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATALOWER);
    18001cec:	0a04079b          	addiw	a5,s0,160
    18001cf0:	1782                	slli	a5,a5,0x20
    18001cf2:	9381                	srli	a5,a5,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001cf4:	439c                	lw	a5,0(a5)
	read_len = (rxlen > 4) ? 4 : rxlen;
    18001cf6:	4711                	li	a4,4
	reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATALOWER);
    18001cf8:	c63e                	sw	a5,12(sp)
	read_len = (rxlen > 4) ? 4 : rxlen;
    18001cfa:	8a26                	mv	s4,s1
    18001cfc:	00977363          	bgeu	a4,s1,18001d02 <cadence_qspi_apb_command_read+0x74>
    18001d00:	4a11                	li	s4,4
	sys_memcpy(rxbuf, &reg, read_len);
    18001d02:	000a061b          	sext.w	a2,s4
    18001d06:	006c                	addi	a1,sp,12
    18001d08:	854e                	mv	a0,s3
    18001d0a:	d05fe0ef          	jal	ra,18000a0e <sys_memcpy>
	if (rxlen > 4) {
    18001d0e:	4791                	li	a5,4
    18001d10:	fc97f5e3          	bgeu	a5,s1,18001cda <cadence_qspi_apb_command_read+0x4c>
		reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATAUPPER);
    18001d14:	0a44041b          	addiw	s0,s0,164
    18001d18:	1402                	slli	s0,s0,0x20
    18001d1a:	9001                	srli	s0,s0,0x20
    18001d1c:	4000                	lw	s0,0(s0)
	rxbuf += read_len;
    18001d1e:	020a1513          	slli	a0,s4,0x20
    18001d22:	9101                	srli	a0,a0,0x20
		sys_memcpy(rxbuf, &reg, read_len);
    18001d24:	4144863b          	subw	a2,s1,s4
    18001d28:	006c                	addi	a1,sp,12
    18001d2a:	954e                	add	a0,a0,s3
		reg = readl((u32)reg_base + CQSPI_REG_CMDREADDATAUPPER);
    18001d2c:	c622                	sw	s0,12(sp)
		sys_memcpy(rxbuf, &reg, read_len);
    18001d2e:	ce1fe0ef          	jal	ra,18000a0e <sys_memcpy>
    18001d32:	b765                	j	18001cda <cadence_qspi_apb_command_read+0x4c>
		return -1;
    18001d34:	597d                	li	s2,-1
    18001d36:	b755                	j	18001cda <cadence_qspi_apb_command_read+0x4c>

0000000018001d38 <cadence_qspi_apb_command_write>:
	unsigned int reg = 0;
	unsigned int addr_value;
	unsigned int wr_data;
	unsigned int wr_len;

	if (!cmdlen || cmdlen > 5 || txlen > 8 || cmdbuf == NULL) {
    18001d38:	fff5881b          	addiw	a6,a1,-1
    18001d3c:	4791                	li	a5,4
    18001d3e:	1107e163          	bltu	a5,a6,18001e40 <cadence_qspi_apb_command_write+0x108>
{
    18001d42:	7139                	addi	sp,sp,-64
    18001d44:	f04a                	sd	s2,32(sp)
    18001d46:	fc06                	sd	ra,56(sp)
    18001d48:	f822                	sd	s0,48(sp)
    18001d4a:	f426                	sd	s1,40(sp)
    18001d4c:	ec4e                	sd	s3,24(sp)
    18001d4e:	e852                	sd	s4,16(sp)
	if (!cmdlen || cmdlen > 5 || txlen > 8 || cmdbuf == NULL) {
    18001d50:	47a1                	li	a5,8
    18001d52:	8936                	mv	s2,a3
    18001d54:	0ed7e463          	bltu	a5,a3,18001e3c <cadence_qspi_apb_command_write+0x104>
    18001d58:	c275                	beqz	a2,18001e3c <cadence_qspi_apb_command_write+0x104>
		//uart_printf("QSPI: Invalid input arguments cmdlen %d txlen %d\n",
		       //cmdlen, txlen);
		return -1;
	}

	reg |= cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001d5a:	00064803          	lbu	a6,0(a2)
    18001d5e:	89ba                	mv	s3,a4

	if (cmdlen == 4 || cmdlen == 5) {
    18001d60:	ffc5879b          	addiw	a5,a1,-4
	reg |= cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001d64:	0188181b          	slliw	a6,a6,0x18
	if (cmdlen == 4 || cmdlen == 5) {
    18001d68:	4705                	li	a4,1
	reg |= cmdbuf[0] << CQSPI_REG_CMDCTRL_OPCODE_LSB;
    18001d6a:	0008049b          	sext.w	s1,a6
			<< CQSPI_REG_CMDCTRL_ADD_BYTES_LSB;
		/* Get address */
		addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1],
			cmdlen >= 5 ? 4 : 3);

		writel(addr_value, (u32)reg_base + CQSPI_REG_CMDADDRESS);
    18001d6e:	0005041b          	sext.w	s0,a0
	if (cmdlen == 4 || cmdlen == 5) {
    18001d72:	02f77063          	bgeu	a4,a5,18001d92 <cadence_qspi_apb_command_write+0x5a>
	}

	if (txlen) {
    18001d76:	06091663          	bnez	s2,18001de2 <cadence_qspi_apb_command_write+0xaa>
				CQSPI_REG_CMDWRITEDATAUPPER);
		}
	}

	/* Execute the command */
	return cadence_qspi_apb_exec_flash_cmd(reg_base, reg);
    18001d7a:	85a6                	mv	a1,s1
    18001d7c:	8522                	mv	a0,s0
    18001d7e:	cf7ff0ef          	jal	ra,18001a74 <cadence_qspi_apb_exec_flash_cmd>
}
    18001d82:	70e2                	ld	ra,56(sp)
    18001d84:	7442                	ld	s0,48(sp)
    18001d86:	74a2                	ld	s1,40(sp)
    18001d88:	7902                	ld	s2,32(sp)
    18001d8a:	69e2                	ld	s3,24(sp)
    18001d8c:	6a42                	ld	s4,16(sp)
    18001d8e:	6121                	addi	sp,sp,64
    18001d90:	8082                	ret
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001d92:	00164783          	lbu	a5,1(a2)
    18001d96:	00264703          	lbu	a4,2(a2)
    18001d9a:	00364683          	lbu	a3,3(a2)
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001d9e:	ffe5849b          	addiw	s1,a1,-2
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001da2:	0087171b          	slliw	a4,a4,0x8
			<< CQSPI_REG_CMDCTRL_ADD_BYTES_LSB;
    18001da6:	0104949b          	slliw	s1,s1,0x10
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001daa:	0107979b          	slliw	a5,a5,0x10
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001dae:	0104e4b3          	or	s1,s1,a6
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001db2:	8fd9                	or	a5,a5,a4
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001db4:	00080837          	lui	a6,0x80
    18001db8:	0104e4b3          	or	s1,s1,a6
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001dbc:	8fd5                	or	a5,a5,a3
		addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1],
    18001dbe:	4715                	li	a4,5
		reg |= ((cmdlen - 2) & CQSPI_REG_CMDCTRL_ADD_BYTES_MASK)
    18001dc0:	2481                	sext.w	s1,s1
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001dc2:	2781                	sext.w	a5,a5
		addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1],
    18001dc4:	00e59863          	bne	a1,a4,18001dd4 <cadence_qspi_apb_command_write+0x9c>
		addr = (addr << 8) | addr_buf[3];
    18001dc8:	00464703          	lbu	a4,4(a2)
    18001dcc:	0087979b          	slliw	a5,a5,0x8
    18001dd0:	8fd9                	or	a5,a5,a4
    18001dd2:	2781                	sext.w	a5,a5
		writel(addr_value, (u32)reg_base + CQSPI_REG_CMDADDRESS);
    18001dd4:	0944071b          	addiw	a4,s0,148
    18001dd8:	1702                	slli	a4,a4,0x20
    18001dda:	9301                	srli	a4,a4,0x20
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ddc:	c31c                	sw	a5,0(a4)
	if (txlen) {
    18001dde:	f8090ee3          	beqz	s2,18001d7a <cadence_qspi_apb_command_write+0x42>
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001de2:	fff9079b          	addiw	a5,s2,-1
			<< CQSPI_REG_CMDCTRL_WR_BYTES_LSB;
    18001de6:	00c7979b          	slliw	a5,a5,0xc
    18001dea:	8cdd                	or	s1,s1,a5
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001dec:	67a1                	lui	a5,0x8
    18001dee:	8cdd                	or	s1,s1,a5
		wr_len = txlen > 4 ? 4 : txlen;
    18001df0:	4791                	li	a5,4
		reg |= ((txlen - 1) & CQSPI_REG_CMDCTRL_WR_BYTES_MASK)
    18001df2:	2481                	sext.w	s1,s1
		wr_len = txlen > 4 ? 4 : txlen;
    18001df4:	8a4a                	mv	s4,s2
    18001df6:	0527e163          	bltu	a5,s2,18001e38 <cadence_qspi_apb_command_write+0x100>
		sys_memcpy(&wr_data, txbuf, wr_len);
    18001dfa:	000a061b          	sext.w	a2,s4
    18001dfe:	85ce                	mv	a1,s3
    18001e00:	0068                	addi	a0,sp,12
    18001e02:	c0dfe0ef          	jal	ra,18000a0e <sys_memcpy>
		writel(wr_data, (u32)reg_base +
    18001e06:	0a84079b          	addiw	a5,s0,168
    18001e0a:	1782                	slli	a5,a5,0x20
    18001e0c:	4732                	lw	a4,12(sp)
    18001e0e:	9381                	srli	a5,a5,0x20
    18001e10:	c398                	sw	a4,0(a5)
		if (txlen > 4) {
    18001e12:	4791                	li	a5,4
    18001e14:	f727f3e3          	bgeu	a5,s2,18001d7a <cadence_qspi_apb_command_write+0x42>
			txbuf += wr_len;
    18001e18:	020a1593          	slli	a1,s4,0x20
    18001e1c:	9181                	srli	a1,a1,0x20
			sys_memcpy(&wr_data, txbuf, wr_len);
    18001e1e:	4149063b          	subw	a2,s2,s4
    18001e22:	95ce                	add	a1,a1,s3
    18001e24:	0068                	addi	a0,sp,12
    18001e26:	be9fe0ef          	jal	ra,18000a0e <sys_memcpy>
			writel(wr_data, (u32)reg_base +
    18001e2a:	0ac4079b          	addiw	a5,s0,172
    18001e2e:	1782                	slli	a5,a5,0x20
    18001e30:	4732                	lw	a4,12(sp)
    18001e32:	9381                	srli	a5,a5,0x20
    18001e34:	c398                	sw	a4,0(a5)
}
    18001e36:	b791                	j	18001d7a <cadence_qspi_apb_command_write+0x42>
		wr_len = txlen > 4 ? 4 : txlen;
    18001e38:	4a11                	li	s4,4
    18001e3a:	b7c1                	j	18001dfa <cadence_qspi_apb_command_write+0xc2>
		return -1;
    18001e3c:	557d                	li	a0,-1
    18001e3e:	b791                	j	18001d82 <cadence_qspi_apb_command_write+0x4a>
    18001e40:	557d                	li	a0,-1
}
    18001e42:	8082                	ret

0000000018001e44 <cadence_qspi_apb_indirect_read_setup>:
	 * which always expecting 1 dummy byte, 1 cmd byte and 3/4 addr byte.
	 * With that, the length is in value of 5 or 6. Only FRAM chip from
	 * ramtron using normal read (which won't need dummy byte).
	 * Unlikely NOR flash using normal read due to performance issue.
	 */
	if (cmdlen >= 5)
    18001e44:	4791                	li	a5,4
    18001e46:	0ab7e163          	bltu	a5,a1,18001ee8 <cadence_qspi_apb_indirect_read_setup+0xa4>
		/* to cater fast read where cmd + addr + dummy */
		addr_bytes = cmdlen - 2;
	else
		/* for normal read (only ramtron as of now) */
		addr_bytes = cmdlen - 1;
    18001e4a:	35fd                	addiw	a1,a1,-1
    18001e4c:	4801                	li	a6,0

	/* Setup the indirect trigger address */
	writel(((u32)plat->ahbbase & CQSPI_INDIRECTTRIGGER_ADDR_MASK),
	       (u32)plat->regbase + CQSPI_REG_INDIRECTTRIGGER);
    18001e4e:	4518                	lw	a4,8(a0)
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001e50:	4681                	li	a3,0
    18001e52:	01c7079b          	addiw	a5,a4,28
    18001e56:	1782                	slli	a5,a5,0x20
    18001e58:	9381                	srli	a5,a5,0x20
    18001e5a:	c394                	sw	a3,0(a5)

	/* Configure the opcode */
	rd_reg = cmdbuf[0] << CQSPI_REG_RD_INSTR_OPCODE_LSB;
    18001e5c:	00064783          	lbu	a5,0(a2)
    if(plat->bit_mode == 4)
    18001e60:	03852883          	lw	a7,56(a0)
    18001e64:	4691                	li	a3,4
	rd_reg = cmdbuf[0] << CQSPI_REG_RD_INSTR_OPCODE_LSB;
    18001e66:	0007851b          	sext.w	a0,a5
    if(plat->bit_mode == 4)
    18001e6a:	00d89763          	bne	a7,a3,18001e78 <cadence_qspi_apb_indirect_read_setup+0x34>
    {
	    /* Instruction and address at DQ0, data at DQ0-3. */
	    rd_reg |= CQSPI_INST_TYPE_QUAD << CQSPI_REG_RD_INSTR_TYPE_DATA_LSB;
    18001e6e:	00020537          	lui	a0,0x20
    18001e72:	8fc9                	or	a5,a5,a0
    18001e74:	0007851b          	sext.w	a0,a5
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001e78:	00164783          	lbu	a5,1(a2)
    18001e7c:	00264683          	lbu	a3,2(a2)
    18001e80:	00364883          	lbu	a7,3(a2)
    18001e84:	0107979b          	slliw	a5,a5,0x10
    18001e88:	0086969b          	slliw	a3,a3,0x8
    18001e8c:	8fd5                	or	a5,a5,a3
    18001e8e:	0117e7b3          	or	a5,a5,a7
	if (addr_width == 4)
    18001e92:	4691                	li	a3,4
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    18001e94:	2781                	sext.w	a5,a5
	if (addr_width == 4)
    18001e96:	00d59863          	bne	a1,a3,18001ea6 <cadence_qspi_apb_indirect_read_setup+0x62>
		addr = (addr << 8) | addr_buf[3];
    18001e9a:	00464683          	lbu	a3,4(a2)
    18001e9e:	0087979b          	slliw	a5,a5,0x8
    18001ea2:	8fd5                	or	a5,a5,a3
    18001ea4:	2781                	sext.w	a5,a5
    {
        rd_reg &= ~(CQSPI_INST_TYPE_QUAD << CQSPI_REG_RD_INSTR_TYPE_DATA_LSB);
    }
	/* Get address */
	addr_value = cadence_qspi_apb_cmd2addr(&cmdbuf[1], addr_bytes);
	writel(addr_value, (u32)plat->regbase + CQSPI_REG_INDIRECTRDSTARTADDR);
    18001ea6:	0687069b          	addiw	a3,a4,104
    18001eaa:	1682                	slli	a3,a3,0x20
    18001eac:	9281                	srli	a3,a3,0x20
    18001eae:	c29c                	sw	a5,0(a3)

	/* The remaining lenght is dummy bytes. */
	dummy_bytes = cmdlen - addr_bytes - 1;
	if (dummy_bytes) {
    18001eb0:	00080c63          	beqz	a6,18001ec8 <cadence_qspi_apb_indirect_read_setup+0x84>

		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
#if defined(CONFIG_SPL_SPI_XIP) && defined(CONFIG_SPL_BUILD)
		writel(0x0, plat->regbase + CQSPI_REG_MODE_BIT);
#else
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001eb4:	0287079b          	addiw	a5,a4,40
		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
    18001eb8:	001006b7          	lui	a3,0x100
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001ebc:	1782                	slli	a5,a5,0x20
		rd_reg |= (1 << CQSPI_REG_RD_INSTR_MODE_EN_LSB);
    18001ebe:	8d55                	or	a0,a0,a3
		writel(0xFF, (u32)plat->regbase + CQSPI_REG_MODE_BIT);
    18001ec0:	9381                	srli	a5,a5,0x20
    18001ec2:	0ff00693          	li	a3,255
    18001ec6:	c394                	sw	a3,0(a5)
		if (dummy_clk)
			rd_reg |= (dummy_clk & CQSPI_REG_RD_INSTR_DUMMY_MASK)
				<< CQSPI_REG_RD_INSTR_DUMMY_LSB;
	}

	writel(rd_reg, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
    18001ec8:	0047079b          	addiw	a5,a4,4
    18001ecc:	1782                	slli	a5,a5,0x20
    18001ece:	9381                	srli	a5,a5,0x20
    18001ed0:	c388                	sw	a0,0(a5)
	//writel(0x0012006b, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
	//writel(0x041220eb, (u32)plat->regbase + CQSPI_REG_RD_INSTR);
	/* set device size */
	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    18001ed2:	2751                	addiw	a4,a4,20
    18001ed4:	1702                	slli	a4,a4,0x20
    18001ed6:	9301                	srli	a4,a4,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001ed8:	431c                	lw	a5,0(a4)
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    18001eda:	9bc1                	andi	a5,a5,-16
	reg |= (addr_bytes - 1);
    18001edc:	35fd                	addiw	a1,a1,-1
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    18001ede:	2781                	sext.w	a5,a5
	reg |= (addr_bytes - 1);
    18001ee0:	8fcd                	or	a5,a5,a1
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ee2:	c31c                	sw	a5,0(a4)
	writel(reg, (u32)plat->regbase + CQSPI_REG_SIZE);
	return 0;
}
    18001ee4:	4501                	li	a0,0
    18001ee6:	8082                	ret
		addr_bytes = cmdlen - 2;
    18001ee8:	35f9                	addiw	a1,a1,-2
    18001eea:	4805                	li	a6,1
    18001eec:	b78d                	j	18001e4e <cadence_qspi_apb_indirect_read_setup+0xa>

0000000018001eee <cadence_qspi_apb_indirect_read_execute>:
int cadence_qspi_apb_indirect_read_execute(struct cadence_spi_platdata *plat,
	unsigned int rxlen, u8 *rxbuf)
{
	unsigned int reg;

	writel(rxlen, (u32)plat->regbase + CQSPI_REG_INDIRECTRDBYTES);
    18001eee:	4518                	lw	a4,8(a0)
{
    18001ef0:	7159                	addi	sp,sp,-112
    18001ef2:	f486                	sd	ra,104(sp)
	writel(rxlen, (u32)plat->regbase + CQSPI_REG_INDIRECTRDBYTES);
    18001ef4:	06c7079b          	addiw	a5,a4,108
    18001ef8:	1782                	slli	a5,a5,0x20
{
    18001efa:	f0a2                	sd	s0,96(sp)
    18001efc:	eca6                	sd	s1,88(sp)
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
    18001f12:	0607079b          	addiw	a5,a4,96
    18001f16:	1782                	slli	a5,a5,0x20
    18001f18:	9381                	srli	a5,a5,0x20
    18001f1a:	4685                	li	a3,1
    18001f1c:	c394                	sw	a3,0(a5)

	if (qspi_read_sram_fifo_poll(plat->regbase, (void *)rxbuf,
				     (const void *)plat->ahbbase, rxlen))
    18001f1e:	01053983          	ld	s3,16(a0) # 20010 <__stack_size+0x1f810>
	while (remaining > 0) {
    18001f22:	c5f9                	beqz	a1,18001ff0 <cadence_qspi_apb_indirect_read_execute+0x102>
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f24:	02c7071b          	addiw	a4,a4,44
    18001f28:	02071413          	slli	s0,a4,0x20
    18001f2c:	64c1                	lui	s1,0x10
		while (retry--) {
    18001f2e:	6a89                	lui	s5,0x2
    18001f30:	8baa                	mv	s7,a0
    18001f32:	8a2e                	mv	s4,a1
    18001f34:	8cb2                	mv	s9,a2
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f36:	9001                	srli	s0,s0,0x20
    18001f38:	14fd                	addi	s1,s1,-1
		while (retry--) {
    18001f3a:	70ea8a93          	addi	s5,s5,1806 # 270e <__stack_size+0x1f0e>
    18001f3e:	597d                	li	s2,-1
	while (remaining >= 4) {
    18001f40:	4b0d                	li	s6,3
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18001f42:	401c                	lw	a5,0(s0)
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f44:	8fe5                	and	a5,a5,s1
    18001f46:	2781                	sext.w	a5,a5
			if (sram_level)
    18001f48:	e785                	bnez	a5,18001f70 <cadence_qspi_apb_indirect_read_execute+0x82>
			delay(100);
    18001f4a:	06400513          	li	a0,100
    18001f4e:	312000ef          	jal	ra,18002260 <udelay>
		while (retry--) {
    18001f52:	8c56                	mv	s8,s5
    18001f54:	a031                	j	18001f60 <cadence_qspi_apb_indirect_read_execute+0x72>
    18001f56:	3c7d                	addiw	s8,s8,-1
			delay(100);
    18001f58:	308000ef          	jal	ra,18002260 <udelay>
		while (retry--) {
    18001f5c:	0b2c0f63          	beq	s8,s2,1800201a <cadence_qspi_apb_indirect_read_execute+0x12c>
    18001f60:	401c                	lw	a5,0(s0)
			sram_level = CQSPI_GET_RD_SRAM_LEVEL((u32)reg_base);
    18001f62:	8fe5                	and	a5,a5,s1
    18001f64:	2781                	sext.w	a5,a5
			delay(100);
    18001f66:	06400513          	li	a0,100
			if (sram_level)
    18001f6a:	d7f5                	beqz	a5,18001f56 <cadence_qspi_apb_indirect_read_execute+0x68>
		if (!retry) {
    18001f6c:	0a0c0e63          	beqz	s8,18002028 <cadence_qspi_apb_indirect_read_execute+0x13a>
		sram_level *= CQSPI_FIFO_WIDTH;
    18001f70:	0027979b          	slliw	a5,a5,0x2
		sram_level = sram_level > remaining ? remaining : sram_level;
    18001f74:	0007871b          	sext.w	a4,a5
    18001f78:	00ea7363          	bgeu	s4,a4,18001f7e <cadence_qspi_apb_indirect_read_execute+0x90>
    18001f7c:	87d2                	mv	a5,s4
		dest += sram_level;
    18001f7e:	02079c13          	slli	s8,a5,0x20
    18001f82:	020c5c13          	srli	s8,s8,0x20
		sram_level = sram_level > remaining ? remaining : sram_level;
    18001f86:	0007861b          	sext.w	a2,a5
		dest += sram_level;
    18001f8a:	9c66                	add	s8,s8,s9
		remaining -= sram_level;
    18001f8c:	40fa0a3b          	subw	s4,s4,a5
	while (remaining >= 4) {
    18001f90:	02cb7d63          	bgeu	s6,a2,18001fca <cadence_qspi_apb_indirect_read_execute+0xdc>
    18001f94:	37f1                	addiw	a5,a5,-4
    18001f96:	0027d79b          	srliw	a5,a5,0x2
    18001f9a:	0017851b          	addiw	a0,a5,1
    18001f9e:	050a                	slli	a0,a0,0x2
    18001fa0:	9566                	add	a0,a0,s9
    18001fa2:	0009a703          	lw	a4,0(s3)
		*dest_ptr = readl(src_ptr);
    18001fa6:	00eca023          	sw	a4,0(s9)
		dest_ptr++;
    18001faa:	0c91                	addi	s9,s9,4
	while (remaining >= 4) {
    18001fac:	feac9be3          	bne	s9,a0,18001fa2 <cadence_qspi_apb_indirect_read_execute+0xb4>
    18001fb0:	3671                	addiw	a2,a2,-4
		remaining -= 4;
    18001fb2:	0027979b          	slliw	a5,a5,0x2
    18001fb6:	9e1d                	subw	a2,a2,a5
	if (remaining) {
    18001fb8:	ea11                	bnez	a2,18001fcc <cadence_qspi_apb_indirect_read_execute+0xde>
		delay(100);
    18001fba:	06400513          	li	a0,100
    18001fbe:	2a2000ef          	jal	ra,18002260 <udelay>
	while (remaining > 0) {
    18001fc2:	020a0163          	beqz	s4,18001fe4 <cadence_qspi_apb_indirect_read_execute+0xf6>
		delay(100);
    18001fc6:	8ce2                	mv	s9,s8
    18001fc8:	bfad                	j	18001f42 <cadence_qspi_apb_indirect_read_execute+0x54>
	while (remaining >= 4) {
    18001fca:	8566                	mv	a0,s9
    18001fcc:	0009a783          	lw	a5,0(s3)
		sys_memcpy(dest_ptr, &temp, remaining);
    18001fd0:	006c                	addi	a1,sp,12
		temp = readl(src_ptr);
    18001fd2:	c63e                	sw	a5,12(sp)
		sys_memcpy(dest_ptr, &temp, remaining);
    18001fd4:	a3bfe0ef          	jal	ra,18000a0e <sys_memcpy>
		delay(100);
    18001fd8:	06400513          	li	a0,100
    18001fdc:	284000ef          	jal	ra,18002260 <udelay>
	while (remaining > 0) {
    18001fe0:	fe0a13e3          	bnez	s4,18001fc6 <cadence_qspi_apb_indirect_read_execute+0xd8>
		goto failrd;

	/* Check flash indirect controller */
	reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTRD);
    18001fe4:	008bb783          	ld	a5,8(s7)
    18001fe8:	0607879b          	addiw	a5,a5,96
    18001fec:	1782                	slli	a5,a5,0x20
    18001fee:	9381                	srli	a5,a5,0x20
    18001ff0:	4398                	lw	a4,0(a5)
	if (!(reg & CQSPI_REG_INDIRECTRD_DONE_MASK)) {
    18001ff2:	02077713          	andi	a4,a4,32
    18001ff6:	cb29                	beqz	a4,18002048 <cadence_qspi_apb_indirect_read_execute+0x15a>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18001ff8:	02000713          	li	a4,32
    18001ffc:	c398                	sw	a4,0(a5)
	}

	/* Clear indirect completion status */
	writel(CQSPI_REG_INDIRECTRD_DONE_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
	return 0;
    18001ffe:	4501                	li	a0,0
failrd:
	/* Cancel the indirect read */
	writel(CQSPI_REG_INDIRECTRD_CANCEL_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
	return -1;
}
    18002000:	70a6                	ld	ra,104(sp)
    18002002:	7406                	ld	s0,96(sp)
    18002004:	64e6                	ld	s1,88(sp)
    18002006:	6946                	ld	s2,80(sp)
    18002008:	69a6                	ld	s3,72(sp)
    1800200a:	6a06                	ld	s4,64(sp)
    1800200c:	7ae2                	ld	s5,56(sp)
    1800200e:	7b42                	ld	s6,48(sp)
    18002010:	7ba2                	ld	s7,40(sp)
    18002012:	7c02                	ld	s8,32(sp)
    18002014:	6ce2                	ld	s9,24(sp)
    18002016:	6165                	addi	sp,sp,112
    18002018:	8082                	ret
		delay(100);
    1800201a:	06400513          	li	a0,100
    1800201e:	8c66                	mv	s8,s9
    18002020:	240000ef          	jal	ra,18002260 <udelay>
    18002024:	8ce2                	mv	s9,s8
    18002026:	bf31                	j	18001f42 <cadence_qspi_apb_indirect_read_execute+0x54>
			printk("fifo_poll timeout.\n");
    18002028:	00000517          	auipc	a0,0x0
    1800202c:	4a050513          	addi	a0,a0,1184 # 180024c8 <spi_flash_table+0x30>
    18002030:	9bbfe0ef          	jal	ra,180009ea <printk>
	       (u32)plat->regbase + CQSPI_REG_INDIRECTRD);
    18002034:	008bb783          	ld	a5,8(s7)
    18002038:	0607879b          	addiw	a5,a5,96
    1800203c:	1782                	slli	a5,a5,0x20
    1800203e:	9381                	srli	a5,a5,0x20
    18002040:	4709                	li	a4,2
    18002042:	c398                	sw	a4,0(a5)
	return -1;
    18002044:	557d                	li	a0,-1
    18002046:	bf6d                	j	18002000 <cadence_qspi_apb_indirect_read_execute+0x112>
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002048:	4398                	lw	a4,0(a5)
		goto failrd;
    1800204a:	bfdd                	j	18002040 <cadence_qspi_apb_indirect_read_execute+0x152>

000000001800204c <cadence_qspi_apb_indirect_write_setup>:
/* Opcode + Address (3/4 bytes) */
int cadence_qspi_apb_indirect_write_setup(struct cadence_spi_platdata *plat,
	unsigned int cmdlen, const u8 *cmdbuf)
{
	unsigned int reg;
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    1800204c:	4791                	li	a5,4
    1800204e:	08b7e663          	bltu	a5,a1,180020da <cadence_qspi_apb_indirect_write_setup+0x8e>

	if (cmdlen < 4 || cmdbuf == NULL) {
    18002052:	08f59663          	bne	a1,a5,180020de <cadence_qspi_apb_indirect_write_setup+0x92>
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    18002056:	468d                	li	a3,3
	if (cmdlen < 4 || cmdbuf == NULL) {
    18002058:	c259                	beqz	a2,180020de <cadence_qspi_apb_indirect_write_setup+0x92>
		       //cmdlen, (unsigned int)cmdbuf);
		return -1;
	}
	/* Setup the indirect trigger address */
	writel(((u32)plat->ahbbase & CQSPI_INDIRECTTRIGGER_ADDR_MASK),
	       (u32)plat->regbase + CQSPI_REG_INDIRECTTRIGGER);
    1800205a:	4518                	lw	a4,8(a0)
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    1800205c:	4581                	li	a1,0
    1800205e:	01c7079b          	addiw	a5,a4,28
    18002062:	1782                	slli	a5,a5,0x20
    18002064:	9381                	srli	a5,a5,0x20
    18002066:	c38c                	sw	a1,0(a5)

	/* Configure the opcode */
	reg = cmdbuf[0] << CQSPI_REG_WR_INSTR_OPCODE_LSB;
    18002068:	00064783          	lbu	a5,0(a2)
    if(plat->bit_mode == 4)
    1800206c:	03852803          	lw	a6,56(a0)
    18002070:	4511                	li	a0,4
	reg = cmdbuf[0] << CQSPI_REG_WR_INSTR_OPCODE_LSB;
    18002072:	0007859b          	sext.w	a1,a5
    if(plat->bit_mode == 4)
    18002076:	00a81763          	bne	a6,a0,18002084 <cadence_qspi_apb_indirect_write_setup+0x38>
    {
	    /* Instruction and address at DQ0, data at DQ0-3. */
	    reg |= CQSPI_INST_TYPE_QUAD << CQSPI_REG_WR_INSTR_TYPE_DATA_LSB;
    1800207a:	000205b7          	lui	a1,0x20
    1800207e:	8fcd                	or	a5,a5,a1
    18002080:	0007859b          	sext.w	a1,a5
    }
    else
    {
        reg &= ~(CQSPI_INST_TYPE_QUAD << CQSPI_REG_WR_INSTR_TYPE_DATA_LSB);
    }
	writel(reg, (u32)plat->regbase + CQSPI_REG_WR_INSTR);
    18002084:	0087079b          	addiw	a5,a4,8
    18002088:	1782                	slli	a5,a5,0x20
    1800208a:	9381                	srli	a5,a5,0x20
    1800208c:	c38c                	sw	a1,0(a5)
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    1800208e:	00164783          	lbu	a5,1(a2)
    18002092:	00264583          	lbu	a1,2(a2)
    18002096:	00364503          	lbu	a0,3(a2)
    1800209a:	0107979b          	slliw	a5,a5,0x10
    1800209e:	0085959b          	slliw	a1,a1,0x8
    180020a2:	8fcd                	or	a5,a5,a1
    180020a4:	8fc9                	or	a5,a5,a0
	if (addr_width == 4)
    180020a6:	4591                	li	a1,4
	addr = (addr_buf[0] << 16) | (addr_buf[1] << 8) | addr_buf[2];
    180020a8:	2781                	sext.w	a5,a5
	if (addr_width == 4)
    180020aa:	00b69863          	bne	a3,a1,180020ba <cadence_qspi_apb_indirect_write_setup+0x6e>
		addr = (addr << 8) | addr_buf[3];
    180020ae:	00464603          	lbu	a2,4(a2)
    180020b2:	0087979b          	slliw	a5,a5,0x8
    180020b6:	8fd1                	or	a5,a5,a2
    180020b8:	2781                	sext.w	a5,a5
	//writel(0x00020032, (u32)plat->regbase + CQSPI_REG_WR_INSTR);

	/* Setup write address. */
	reg = cadence_qspi_apb_cmd2addr(&cmdbuf[1], addr_bytes);
	writel(reg, (u32)plat->regbase + CQSPI_REG_INDIRECTWRSTARTADDR);
    180020ba:	0787061b          	addiw	a2,a4,120
    180020be:	1602                	slli	a2,a2,0x20
    180020c0:	9201                	srli	a2,a2,0x20
    180020c2:	c21c                	sw	a5,0(a2)

	reg = readl((u32)plat->regbase + CQSPI_REG_SIZE);
    180020c4:	2751                	addiw	a4,a4,20
    180020c6:	1702                	slli	a4,a4,0x20
    180020c8:	9301                	srli	a4,a4,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180020ca:	431c                	lw	a5,0(a4)
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    180020cc:	9bc1                	andi	a5,a5,-16
	reg |= (addr_bytes - 1);
    180020ce:	36fd                	addiw	a3,a3,-1
	reg &= ~CQSPI_REG_SIZE_ADDRESS_MASK;
    180020d0:	2781                	sext.w	a5,a5
	reg |= (addr_bytes - 1);
    180020d2:	8fd5                	or	a5,a5,a3
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    180020d4:	c31c                	sw	a5,0(a4)
	writel(reg, (u32)plat->regbase + CQSPI_REG_SIZE);
	return 0;
    180020d6:	4501                	li	a0,0
    180020d8:	8082                	ret
	unsigned int addr_bytes = cmdlen > 4 ? 4 : 3;
    180020da:	4691                	li	a3,4
    180020dc:	bfb5                	j	18002058 <cadence_qspi_apb_indirect_write_setup+0xc>
		return -1;
    180020de:	557d                	li	a0,-1
}
    180020e0:	8082                	ret

00000000180020e2 <cadence_qspi_apb_indirect_write_execute>:
{
	unsigned int reg = 0;
	unsigned int retry;

	/* Configure the indirect read transfer bytes */
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    180020e2:	651c                	ld	a5,8(a0)
{
    180020e4:	7119                	addi	sp,sp,-128
    180020e6:	ecce                	sd	s3,88(sp)
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    180020e8:	07c7869b          	addiw	a3,a5,124
    180020ec:	1682                	slli	a3,a3,0x20
{
    180020ee:	e0da                	sd	s6,64(sp)
    180020f0:	fc86                	sd	ra,120(sp)
    180020f2:	f8a2                	sd	s0,112(sp)
    180020f4:	f4a6                	sd	s1,104(sp)
    180020f6:	f0ca                	sd	s2,96(sp)
    180020f8:	e8d2                	sd	s4,80(sp)
    180020fa:	e4d6                	sd	s5,72(sp)
    180020fc:	fc5e                	sd	s7,56(sp)
    180020fe:	f862                	sd	s8,48(sp)
    18002100:	f466                	sd	s9,40(sp)
    18002102:	f06a                	sd	s10,32(sp)
    18002104:	ec6e                	sd	s11,24(sp)
    18002106:	89aa                	mv	s3,a0
    18002108:	8b32                	mv	s6,a2
	writel(txlen, (u32)plat->regbase + CQSPI_REG_INDIRECTWRBYTES);
    1800210a:	0007871b          	sext.w	a4,a5
    1800210e:	9281                	srli	a3,a3,0x20
    18002110:	c28c                	sw	a1,0(a3)

	/* Start the indirect write transfer */
	writel(CQSPI_REG_INDIRECTWR_START_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    18002112:	0707069b          	addiw	a3,a4,112
    18002116:	1682                	slli	a3,a3,0x20
    18002118:	9281                	srli	a3,a3,0x20
    1800211a:	4605                	li	a2,1
    1800211c:	c290                	sw	a2,0(a3)
	void *dest_addr = plat->ahbbase;
    1800211e:	01053a83          	ld	s5,16(a0)
	unsigned int page_size = plat->page_size;
    18002122:	01c52c03          	lw	s8,28(a0)
	while (remaining > 0) {
    18002126:	08b05663          	blez	a1,180021b2 <cadence_qspi_apb_indirect_write_execute+0xd0>
    1800212a:	02c7071b          	addiw	a4,a4,44
    1800212e:	02071413          	slli	s0,a4,0x20
		while (retry--) {
    18002132:	6b89                	lui	s7,0x2
    18002134:	0005869b          	sext.w	a3,a1
    18002138:	9001                	srli	s0,s0,0x20
    1800213a:	70fb8b93          	addi	s7,s7,1807 # 270f <__stack_size+0x1f0f>
			if (sram_level <= sram_threshold_words)
    1800213e:	03200493          	li	s1,50
		while (retry--) {
    18002142:	597d                	li	s2,-1
		wr_bytes = (remaining > page_size) ?
    18002144:	8d62                	mv	s10,s8
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002146:	4c8d                	li	s9,3
		while (retry--) {
    18002148:	875e                	mv	a4,s7
    1800214a:	a021                	j	18002152 <cadence_qspi_apb_indirect_write_execute+0x70>
    1800214c:	377d                	addiw	a4,a4,-1
    1800214e:	01270863          	beq	a4,s2,1800215e <cadence_qspi_apb_indirect_write_execute+0x7c>
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002152:	401c                	lw	a5,0(s0)
			if (sram_level <= sram_threshold_words)
    18002154:	0107d79b          	srliw	a5,a5,0x10
    18002158:	fef4eae3          	bltu	s1,a5,1800214c <cadence_qspi_apb_indirect_write_execute+0x6a>
		if (!retry) {
    1800215c:	c369                	beqz	a4,1800221e <cadence_qspi_apb_indirect_write_execute+0x13c>
					page_size : remaining;
    1800215e:	00068d9b          	sext.w	s11,a3
		wr_bytes = (remaining > page_size) ?
    18002162:	87ea                	mv	a5,s10
    18002164:	0186f363          	bgeu	a3,s8,1800216a <cadence_qspi_apb_indirect_write_execute+0x88>
    18002168:	87ee                	mv	a5,s11
    1800216a:	00078a1b          	sext.w	s4,a5
	unsigned int temp = 0;
    1800216e:	c602                	sw	zero,12(sp)
	int remaining = bytes;
    18002170:	8652                	mv	a2,s4
	while (remaining >= CQSPI_FIFO_WIDTH) {
    18002172:	0b4cf463          	bgeu	s9,s4,1800221a <cadence_qspi_apb_indirect_write_execute+0x138>
    18002176:	37f1                	addiw	a5,a5,-4
    18002178:	0027d51b          	srliw	a0,a5,0x2
    1800217c:	0015059b          	addiw	a1,a0,1
    18002180:	058a                	slli	a1,a1,0x2
    18002182:	95da                	add	a1,a1,s6
    18002184:	87da                	mv	a5,s6
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18002186:	4398                	lw	a4,0(a5)
    18002188:	00eaa023          	sw	a4,0(s5)
		src_ptr += CQSPI_FIFO_WIDTH/4;
    1800218c:	0791                	addi	a5,a5,4
	while (remaining >= CQSPI_FIFO_WIDTH) {
    1800218e:	feb79ce3          	bne	a5,a1,18002186 <cadence_qspi_apb_indirect_write_execute+0xa4>
    18002192:	ffca061b          	addiw	a2,s4,-4
		remaining -= CQSPI_FIFO_WIDTH;
    18002196:	0025151b          	slliw	a0,a0,0x2
    1800219a:	9e09                	subw	a2,a2,a0
	if (remaining) {
    1800219c:	ea25                	bnez	a2,1800220c <cadence_qspi_apb_indirect_write_execute+0x12a>
		src += wr_bytes;
    1800219e:	020a1793          	slli	a5,s4,0x20
    180021a2:	9381                	srli	a5,a5,0x20
		remaining -= wr_bytes;
    180021a4:	414d86bb          	subw	a3,s11,s4
		src += wr_bytes;
    180021a8:	9b3e                	add	s6,s6,a5
	while (remaining > 0) {
    180021aa:	f8d04fe3          	bgtz	a3,18002148 <cadence_qspi_apb_indirect_write_execute+0x66>
		goto failwr;
#if 1
	/* Wait until last write is completed (FIFO empty) */
	retry = CQSPI_REG_RETRY;
	while (retry--) {
		reg = CQSPI_GET_WR_SRAM_LEVEL((u32)plat->regbase);
    180021ae:	0089b783          	ld	a5,8(s3)
	while (remaining >= CQSPI_FIFO_WIDTH) {
    180021b2:	6409                	lui	s0,0x2
    180021b4:	71040413          	addi	s0,s0,1808 # 2710 <__stack_size+0x1f10>
    180021b8:	a031                	j	180021c4 <cadence_qspi_apb_indirect_write_execute+0xe2>
		if (reg == 0)
			break;

		delay(1000);
    180021ba:	0a6000ef          	jal	ra,18002260 <udelay>
	while (retry--) {
    180021be:	c025                	beqz	s0,1800221e <cadence_qspi_apb_indirect_write_execute+0x13c>
		reg = CQSPI_GET_WR_SRAM_LEVEL((u32)plat->regbase);
    180021c0:	0089b783          	ld	a5,8(s3)
    180021c4:	02c7871b          	addiw	a4,a5,44
    180021c8:	1702                	slli	a4,a4,0x20
    180021ca:	9301                	srli	a4,a4,0x20
	asm volatile("lw %0, 0(%1)" : "=r" (val) : "r" (addr));
    180021cc:	4318                	lw	a4,0(a4)
		if (reg == 0)
    180021ce:	0107571b          	srliw	a4,a4,0x10
		delay(1000);
    180021d2:	3e800513          	li	a0,1000
	while (retry--) {
    180021d6:	347d                	addiw	s0,s0,-1
		if (reg == 0)
    180021d8:	f36d                	bnez	a4,180021ba <cadence_qspi_apb_indirect_write_execute+0xd8>
    180021da:	6409                	lui	s0,0x2
    180021dc:	71040413          	addi	s0,s0,1808 # 2710 <__stack_size+0x1f10>
    180021e0:	a031                	j	180021ec <cadence_qspi_apb_indirect_write_execute+0x10a>
	retry = CQSPI_REG_RETRY;
	while (retry--) {
		reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTWR);
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
			break;
		delay(1000);
    180021e2:	07e000ef          	jal	ra,18002260 <udelay>
	while (retry--) {
    180021e6:	cc05                	beqz	s0,1800221e <cadence_qspi_apb_indirect_write_execute+0x13c>
		reg = readl((u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    180021e8:	0089b783          	ld	a5,8(s3)
    180021ec:	0707879b          	addiw	a5,a5,112
    180021f0:	1782                	slli	a5,a5,0x20
    180021f2:	9381                	srli	a5,a5,0x20
    180021f4:	4398                	lw	a4,0(a5)
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
    180021f6:	02077713          	andi	a4,a4,32
		delay(1000);
    180021fa:	3e800513          	li	a0,1000
	while (retry--) {
    180021fe:	347d                	addiw	s0,s0,-1
		if (reg & CQSPI_REG_INDIRECTWR_DONE_MASK)
    18002200:	d36d                	beqz	a4,180021e2 <cadence_qspi_apb_indirect_write_execute+0x100>
	asm volatile("sw %0, 0(%1)" : : "r" (val), "r" (addr));
    18002202:	02000713          	li	a4,32
    18002206:	c398                	sw	a4,0(a5)

	/* Clear indirect completion status */
	writel(CQSPI_REG_INDIRECTWR_DONE_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
#endif
	return 0;
    18002208:	4501                	li	a0,0
    1800220a:	a01d                	j	18002230 <cadence_qspi_apb_indirect_write_execute+0x14e>
		sys_memcpy(&temp, src_ptr+i, remaining % 4);
    1800220c:	0068                	addi	a0,sp,12
    1800220e:	801fe0ef          	jal	ra,18000a0e <sys_memcpy>
    18002212:	47b2                	lw	a5,12(sp)
    18002214:	00faa023          	sw	a5,0(s5)
		for (--i; i >= 0; i--)
    18002218:	b759                	j	1800219e <cadence_qspi_apb_indirect_write_execute+0xbc>
	while (remaining >= CQSPI_FIFO_WIDTH) {
    1800221a:	85da                	mv	a1,s6
    1800221c:	b741                	j	1800219c <cadence_qspi_apb_indirect_write_execute+0xba>

failwr:
	/* Cancel the indirect write */
	writel(CQSPI_REG_INDIRECTWR_CANCEL_MASK,
	       (u32)plat->regbase + CQSPI_REG_INDIRECTWR);
    1800221e:	0089b783          	ld	a5,8(s3)
    18002222:	4709                	li	a4,2
    18002224:	0707879b          	addiw	a5,a5,112
    18002228:	1782                	slli	a5,a5,0x20
    1800222a:	9381                	srli	a5,a5,0x20
    1800222c:	c398                	sw	a4,0(a5)
	return -1;
    1800222e:	557d                	li	a0,-1
}
    18002230:	70e6                	ld	ra,120(sp)
    18002232:	7446                	ld	s0,112(sp)
    18002234:	74a6                	ld	s1,104(sp)
    18002236:	7906                	ld	s2,96(sp)
    18002238:	69e6                	ld	s3,88(sp)
    1800223a:	6a46                	ld	s4,80(sp)
    1800223c:	6aa6                	ld	s5,72(sp)
    1800223e:	6b06                	ld	s6,64(sp)
    18002240:	7be2                	ld	s7,56(sp)
    18002242:	7c42                	ld	s8,48(sp)
    18002244:	7ca2                	ld	s9,40(sp)
    18002246:	7d02                	ld	s10,32(sp)
    18002248:	6de2                	ld	s11,24(sp)
    1800224a:	6109                	addi	sp,sp,128
    1800224c:	8082                	ret

000000001800224e <usec_to_tick>:
#define TIMER_CLK_HZ		25000000

u64 usec_to_tick(u32 usec)
{
    u64 value;
    value = usec*(TIMER_CLK_HZ/1000000);
    1800224e:	0015179b          	slliw	a5,a0,0x1
    18002252:	9fa9                	addw	a5,a5,a0
    18002254:	0037979b          	slliw	a5,a5,0x3
    18002258:	9d3d                	addw	a0,a0,a5
    return value;
}
    1800225a:	1502                	slli	a0,a0,0x20
    1800225c:	9101                	srli	a0,a0,0x20
    1800225e:	8082                	ret

0000000018002260 <udelay>:
	asm volatile("ld %0, 0(%1)" : "=r" (val) : "r" (addr));
    18002260:	0200c6b7          	lui	a3,0x200c
    18002264:	16e1                	addi	a3,a3,-8
    18002266:	6298                	ld	a4,0(a3)
    value = usec*(TIMER_CLK_HZ/1000000);
    18002268:	0015179b          	slliw	a5,a0,0x1
    1800226c:	9fa9                	addw	a5,a5,a0
    1800226e:	0037979b          	slliw	a5,a5,0x3
    18002272:	9fa9                	addw	a5,a5,a0
    18002274:	1782                	slli	a5,a5,0x20
    18002276:	9381                	srli	a5,a5,0x20
/* delay x useconds */
void udelay(unsigned long usec)
{
	unsigned long  tmp;

	tmp = readq((volatile void *)CLINT_CTRL_MTIME) + usec_to_tick(usec);	/* get current timestamp */
    18002278:	97ba                	add	a5,a5,a4
    1800227a:	6298                	ld	a4,0(a3)
    
	while (readq((volatile void *)CLINT_CTRL_MTIME) < tmp);
    1800227c:	fef76fe3          	bltu	a4,a5,1800227a <udelay+0x1a>
}
    18002280:	8082                	ret

0000000018002282 <memset>:
    18002282:	433d                	li	t1,15
    18002284:	872a                	mv	a4,a0
    18002286:	02c37163          	bgeu	t1,a2,180022a8 <memset+0x26>
    1800228a:	00f77793          	andi	a5,a4,15
    1800228e:	e3c1                	bnez	a5,1800230e <memset+0x8c>
    18002290:	e1bd                	bnez	a1,180022f6 <memset+0x74>
    18002292:	ff067693          	andi	a3,a2,-16
    18002296:	8a3d                	andi	a2,a2,15
    18002298:	96ba                	add	a3,a3,a4
    1800229a:	e30c                	sd	a1,0(a4)
    1800229c:	e70c                	sd	a1,8(a4)
    1800229e:	0741                	addi	a4,a4,16
    180022a0:	fed76de3          	bltu	a4,a3,1800229a <memset+0x18>
    180022a4:	e211                	bnez	a2,180022a8 <memset+0x26>
    180022a6:	8082                	ret
    180022a8:	40c306b3          	sub	a3,t1,a2
    180022ac:	068a                	slli	a3,a3,0x2
    180022ae:	00000297          	auipc	t0,0x0
    180022b2:	9696                	add	a3,a3,t0
    180022b4:	00a68067          	jr	10(a3) # 200c00a <__stack_size+0x200b80a>
    180022b8:	00b70723          	sb	a1,14(a4) # 70000e <__stack_size+0x6ff80e>
    180022bc:	00b706a3          	sb	a1,13(a4)
    180022c0:	00b70623          	sb	a1,12(a4)
    180022c4:	00b705a3          	sb	a1,11(a4)
    180022c8:	00b70523          	sb	a1,10(a4)
    180022cc:	00b704a3          	sb	a1,9(a4)
    180022d0:	00b70423          	sb	a1,8(a4)
    180022d4:	00b703a3          	sb	a1,7(a4)
    180022d8:	00b70323          	sb	a1,6(a4)
    180022dc:	00b702a3          	sb	a1,5(a4)
    180022e0:	00b70223          	sb	a1,4(a4)
    180022e4:	00b701a3          	sb	a1,3(a4)
    180022e8:	00b70123          	sb	a1,2(a4)
    180022ec:	00b700a3          	sb	a1,1(a4)
    180022f0:	00b70023          	sb	a1,0(a4)
    180022f4:	8082                	ret
    180022f6:	0ff5f593          	zext.b	a1,a1
    180022fa:	00859693          	slli	a3,a1,0x8
    180022fe:	8dd5                	or	a1,a1,a3
    18002300:	01059693          	slli	a3,a1,0x10
    18002304:	8dd5                	or	a1,a1,a3
    18002306:	02059693          	slli	a3,a1,0x20
    1800230a:	8dd5                	or	a1,a1,a3
    1800230c:	b759                	j	18002292 <memset+0x10>
    1800230e:	00279693          	slli	a3,a5,0x2
    18002312:	00000297          	auipc	t0,0x0
    18002316:	9696                	add	a3,a3,t0
    18002318:	8286                	mv	t0,ra
    1800231a:	fa2680e7          	jalr	-94(a3)
    1800231e:	8096                	mv	ra,t0
    18002320:	17c1                	addi	a5,a5,-16
    18002322:	8f1d                	sub	a4,a4,a5
    18002324:	963e                	add	a2,a2,a5
    18002326:	f8c371e3          	bgeu	t1,a2,180022a8 <memset+0x26>
    1800232a:	b79d                	j	18002290 <memset+0xe>
