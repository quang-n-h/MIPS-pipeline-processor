#ifndef SM_HEAP_H
#define SM_HEAP_H

#include <stdint.h>	/* uint32_t, int32_t */

// heap functions
uint32_t mm_malloc(uint32_t size);
void mm_free(uint32_t addr);

extern uint32_t mm_sbrk(int32_t value);

#endif
