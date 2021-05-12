/**
  ******************************************************************************
  * @file  bootmain.c
  * @author  StarFive Technology
  * @version  V1.0
  * @date  06/25/2020
  * @brief
  ******************************************************************************
  * @copy
  *
  * THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
  * WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE
  * TIME. AS A RESULT, STARFIVE SHALL NOT BE HELD LIABLE FOR ANY
  * DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING
  * FROM THE CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE
  * CODING INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
  *
  * COPYRIGHT 2020 Shanghai StarFive Technology Co., Ltd.
  */

#include "sys.h"
#include "spi_flash.h"
#include "spi.h"
#include "encoding.h"
#include <clkgen_ctrl_macro.h>
#include <syscon_sysmain_ctrl_macro.h>
#include <ezGPIO_fullMux_ctrl_macro.h>
#include <rstgen_ctrl_macro.h>
#include <syscon_iopad_ctrl_macro.h>

typedef void ( *STARTRUNNING )( unsigned int par1 );

/*
To run a procedure from the address:start
	start:	start address of runing in armmode, not do address align checking
*/
void start2run32(unsigned int start)
{
	(( STARTRUNNING )(start))(0);		
}

#define     SPIBOOT_LOAD_ADDR_OFFSET    252


/*read data from flash to the destination address
 *
 *spi_flash: flash device informations
 *des_addr: store the data read from flash
 *page_offset:Offset of data stored in flash 
 *mode:flash work mode
*/

static int load_data(struct spi_flash* spi_flash,unsigned int des_addr,unsigned int page_offset,int mode)
{
	u8 dataBuf[260];
	u32 startPage,endPage;
	u32 pageSize;
	u32 fileSize;
	u8 *addr;
	int ret;
	int i;
	u32 offset;

	pageSize = spi_flash->page_size;
	addr = (u8 *)des_addr;
	offset = page_offset*pageSize;
	
	/*read first page,get the file size*/
	ret = spi_flash->read(spi_flash,offset,pageSize,dataBuf,mode);
	if(ret != 0)
    {
        printk("read fail#\r\n");
		return -1;
    }
	
	/*calculate file size*/
	fileSize = (dataBuf[3] << 24) | (dataBuf[2] << 16) | (dataBuf[1] << 8) | (dataBuf[0]) ;
	if(fileSize == 0)
		return -1;

	endPage = ((fileSize + 255) >> 8);//page align
	/*copy the first page data*/
	sys_memcpy(addr, &dataBuf[4], SPIBOOT_LOAD_ADDR_OFFSET);

	offset += pageSize;
	addr += SPIBOOT_LOAD_ADDR_OFFSET;
	
	/*read Remaining pages data*/
	for(i=1; i<=endPage; i++)
	{ 		
		ret = spi_flash->read(spi_flash,offset,pageSize, addr, mode);
		if(ret != 0)
        {
            printk("read fail##\r\n");
			return -1;
        }
		offset += pageSize;
		addr +=pageSize;
	}
	return 0;
}

void load_and_run_ddr(struct spi_flash* spi_flash,int mode)
{
	unsigned int addr;
	int ret;

	addr = DEFAULT_DDR_ADDR;

	ret = load_data(spi_flash,addr,DEFAULT_DDR_OFFSET,mode);
	printk("bootloader version:%s\n\n",VERSION);    
	if(!ret)
	{
		writel(0x1, 0x2000004); 
		start2run32(addr);
	}
	else
		printk("\nload ddr bin fail.\n");
		
	/*never run to here*/
	while(1);
}

void boot_from_spi(int mode)
{
	struct spi_flash* spi_flash;
	int ret;
	u32	*addr;
	u32 val;

    cadence_qspi_init(0, mode);
	spi_flash = spi_flash_probe(0, 0, 31250000, 0, (u32)SPI_DATAMODE_8);

	/*init ddr*/
	load_and_run_ddr(spi_flash,mode);

}

static void chip_clk_init() 
{
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
	_SWITCH_CLOCK_clk_perh0_root_SOURCE_clk_pll0_out_;
	
	// slow down nne bus can fix nne50 & vp6 ram scan issue,
	// as well as vin_subsys reg scan issue.
//	_SWITCH_CLOCK_clk_nne_bus_SOURCE_clk_cpu_axi_;
}

/*only hartid 0 call this function*/
void BootMain(void)
{	
	int boot_mode = 0;

	/*switch to pll mode*/
	chip_clk_init();

//for illegal instruction exception
	_SET_SYSCON_REG_register50_SCFG_funcshare_pad_ctrl_18(0x00c000c0);

	_CLEAR_RESET_rstgen_rstn_usbnoc_axi_;
	_CLEAR_RESET_rstgen_rstn_hifi4noc_axi_;

	_ENABLE_CLOCK_clk_x2c_axi_;
	_CLEAR_RESET_rstgen_rstn_x2c_axi_;

	_CLEAR_RESET_rstgen_rstn_dspx2c_axi_;
	_CLEAR_RESET_rstgen_rstn_dma1p_axi_;

	_ENABLE_CLOCK_clk_msi_apb_;
	_CLEAR_RESET_rstgen_rstn_msi_apb_;

	_ASSERT_RESET_rstgen_rstn_x2c_axi_;
	_CLEAR_RESET_rstgen_rstn_x2c_axi_;
//end for illegal instruction exception
    _SET_SYSCON_REG_register69_core1_en(1);
    _SET_SYSCON_REG_register104_SCFG_io_padshare_sel(6);
    _SET_SYSCON_REG_register32_SCFG_funcshare_pad_ctrl_0(0x00c00000);
    _SET_SYSCON_REG_register33_SCFG_funcshare_pad_ctrl_1(0x00c000c0);
    _SET_SYSCON_REG_register34_SCFG_funcshare_pad_ctrl_2(0x00c000c0);
    _SET_SYSCON_REG_register35_SCFG_funcshare_pad_ctrl_3(0x00c000c0);
    _SET_SYSCON_REG_register39_SCFG_funcshare_pad_ctrl_7(0x00c300c3);
    _SET_SYSCON_REG_register38_SCFG_funcshare_pad_ctrl_6(0x00c00000);

	uart_init(3);
	
	writel(0x18000000, 0x1801fffc);
	writel(0x1, 0x2000004); 		/*从bootrom中恢复hart1*/
	boot_from_spi(1);
	
	/*never run to heare*/
}
