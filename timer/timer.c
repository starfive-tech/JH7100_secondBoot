/* SPDX-License-Identifier: GPL-2.0-or-later */
/**
  ******************************************************************************
  * @file  timer.c
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

