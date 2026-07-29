#include <cstdio> 	/* fprintf() */
#include <cstdlib>	/* exit() */
#include <map>		/* std::map */
#include <stdint.h>	/* uint32_t, int64 */

#include "sm_heap.h"

#include "sm_execinfo.h"

static uint32_t HEAP_END=0;

static std::map<uint32_t,int> HEAP_STATUS;
static uint32_t BLOCKNUM = 1;

static uint32_t current_break = 0;

/**
 * Search the heap for a large enough piece of memory and return its address
 *
 * @param size The number of (TODO what? bytes? words?)
 * @return the address of the start of the block
 */
uint32_t mm_malloc(uint32_t size){

	if(size == 0){
		
		return 0;
	}

	uint32_t heapStart = exec.HEAPSTART;
	
	if(HEAP_END == 0){
		
		HEAP_END = heapStart;
	}
	
	BLOCKNUM++;

	int blockCounter=0;
	
	for(uint32_t i = heapStart; i <= HEAP_END + size; i++) {
		
		// search for large enough space
		if (HEAP_STATUS[i]==0){
		
			blockCounter++;
		}else{
			
			blockCounter = 0;
		}
		
		// if large enough and aligned, prep the space
		uint32_t blockStart = i-size+1;

		if (blockCounter >= size && (blockStart%4==0)) {

			for(uint32_t j = blockStart; j < blockStart + size; j++){
			
				HEAP_STATUS[j] = BLOCKNUM;		//set heap word state variable	
			}

			if(i>HEAP_END){
				
				HEAP_END = i;
			}

			return blockStart;
		}
	}
	// else, no more memory :(
	return 0;
}


/**
 * Deallocate the blocks at the specified address
 *
 * @param addr The location of the allocated memory
 * @return void
 */
void mm_free(uint32_t addr){
	
	int num = HEAP_STATUS[addr];						//store the block # to be cleared
	
	//IF ATTEMPTING TO FREE THE NULL ADDRESS
	if(addr == 0) {
	
		//RETURN FROM PROCESS
		return;
	}

	//IF THE BLOCK TO BE DEALLOCATED IS NOT ALLOCATED 
	if(num == 0){

		//PRINT ERROR AND EXIT	
		fprintf(stderr, "Freeing unallocated memory at %8x!!!\n", addr);
		exit(-1);
	}

	//FOR EVERY ___ FROM THE ADDRESS TO THE END OF THE HEAP
	for(uint32_t i = addr; i <= HEAP_END; i++) {			//iterate through memory resetting any states that match the block number
	
		//IF THE ___ IS PART OF THE ALLOCATION
		if (HEAP_STATUS[i] == num){
			
			//SET STATUS TO NOT ALLOCATED
			HEAP_STATUS[i] = 0;

		//ELSE IF THE END OF THE BLOCK IS FOUND
		}else{

			//EXIT PROCESS
			break;
		}
	}
}

uint32_t mm_sbrk(int32_t value) {

	if(current_break < exec.BREAKSTART) {
	
		current_break = exec.BREAKSTART;
	}

	int64_t temp_break = current_break;
	
	temp_break += value;
	
	if(temp_break >= exec.BREAKSTART && temp_break < exec.HEAPSTART) {	//don't allow potential heap corruption
	
		current_break = temp_break;
	}

	return current_break;
}


