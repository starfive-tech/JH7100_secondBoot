#include "platform.h"
#include "timer.h"
#include "sys.h"
#include "clkgen_ctrl_macro.h"

#define TIMER_CLK_HZ		25000000

u64 usec_to_tick(u32 usec)
{
    u64 value;
    value = usec*(TIMER_CLK_HZ/1000000);
    return value;
}

/* delay x useconds */
void udelay(unsigned long usec)
{
	unsigned long  tmp;

	tmp = readq((volatile void *)CLINT_CTRL_MTIME) + usec_to_tick(usec);	/* get current timestamp */
    
	while (readq((volatile void *)CLINT_CTRL_MTIME) < tmp);
}

