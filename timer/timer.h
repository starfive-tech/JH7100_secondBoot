#ifndef __TIMER_H__
#define __TIMER_H__

#include <comdef.h>

void udelay(u64 usec);

#define delay	udelay

#endif /* __TIMER_H__ */
