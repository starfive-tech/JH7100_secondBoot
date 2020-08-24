#include "sys.h"
#include "spi_flash.h"
#include "spi.h"
#include "encoding.h"
#include "clkgen_ctrl_macro.h"


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
	spi_flash = spi_flash_probe(0, 0, 50000000, 0, (u32)SPI_DATAMODE_8);

	/*init ddr*/
	load_and_run_ddr(spi_flash,mode);

}

static void chip_clk_init() 
{
	_SWITCH_CLOCK_clk_cpundbus_root_SOURCE_clk_pll0_out_;
	_SWITCH_CLOCK_clk_dla_root_SOURCE_clk_pll1_out_;
	_SWITCH_CLOCK_clk_dsp_root_SOURCE_clk_pll2_out_;
	_SWITCH_CLOCK_clk_perh0_root_SOURCE_clk_pll0_out_;
}

/*only hartid 0 call this function*/
void BootMain(void)
{	
	int boot_mode = 0;

	/*switch to pll mode*/
	chip_clk_init();

	uart_init(3);
	
	writel(0x18000000, 0x1801fffc);
	writel(0x1, 0x2000004); 		/*从bootrom中恢复hart1*/
	boot_from_spi(1);
	
	/*never run to heare*/
}
