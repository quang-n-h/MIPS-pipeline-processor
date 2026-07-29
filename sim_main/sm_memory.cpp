#include <map>		/* std::map */
#include <stdint.h>	/* uint8_t, uint16_t, uint32_t */
#include <string>	/* std::string */

#include "sm_memory.h"	//INCLUDE FILE HEADER

//MAIN MEMORY MAP; EACH INDEX STORES 8 BITS
std::map<int,uint8_t> MAIN_MEMORY;

/**
 * Read a word (4 bytes) from MAIN_MEMORY and return as a 'uint32_t'
 *
 * @param location The address in memory that the word is located
 * @return the contents of the 4 bytes of memory at the location provided
 */
uint32_t readWord(int location){

	//TEMPORARY VARIABLE TO STORE CONTENTS OF MEMORY
	uint32_t val = 0x00000000;

	//LOAD BYTE AND SHIFT LEFT
	val |= MAIN_MEMORY[location+0];
	val = val << 8;

	//LOAD BYTE AND SHIFT LEFT
	val |= MAIN_MEMORY[location+1];
	val = val<<8;

	//LOAD BYTE AND SHIFT LEFT
	val |= MAIN_MEMORY[location+2];
	val = val << 8;

	//LOAD BYTE
	val |= MAIN_MEMORY[location+3];

	//RETURN WORD
	return val;

}

/**
 * Read a halfword (2 bytes) from MAIN_MEMORY and return as a 'uint16_t'
 *
 * @param location The address in memory that the halfword is located
 * @return the contents of the 2 bytes of memory at the location provided
 */
uint16_t readHalfWord(int location){

	//TEMPORARY VARIABLE TO STORE CONTENTS OF MEMORY
	uint16_t val = 0x0000;

	//LOAD BYTE AND SHIFT LEFT
	val |= MAIN_MEMORY[location+0];
	val = val << 8;

	//LOAD BYTE
	val |= MAIN_MEMORY[location+1];

	//RETURN HALFWORD
	return val;

}

/**
 * Read 1 byte from MAIN_MEMORY and return as a 'uint8_t'
 *
 * @param location The address in memory that the byte is located
 * @return the contents of the byte of memory at the location provided
 */
uint8_t readByte(int location){

	//TEMPORARY VARIABLE TO STORE CONTENTS OF MEMORY
	uint8_t val = 0x00;

	//LOAD BYTE
	val |= MAIN_MEMORY[location+0];

	//RETURN BYTE
	return val;

}

/**
 * Write a word (4 bytes) to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The word that should be written to memory
 * @return void
 */
void writeWord(int location, uint32_t val){	

	//STORE THE FOUR BYTES IN BIG ENDIAN
	MAIN_MEMORY[location + 0] = (val & 0xFF000000) >> 24;
	MAIN_MEMORY[location + 1] = (val & 0x00FF0000) >> 16; 
	MAIN_MEMORY[location + 2] = (val & 0x0000FF00) >> 8; 
	MAIN_MEMORY[location + 3] = (val & 0x000000FF);

}

/**
 * Write a halfword (2 bytes) to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The halfword that should be written to memory
 * @return void
 */
void writeHalfWord(int location, uint16_t val){	

	//STORE THE TWO BYTES IN BIG ENDIAN
	MAIN_MEMORY[location + 0] = (val & 0xFF00) >> 8;
	MAIN_MEMORY[location + 1] = (val & 0x00FF);

}

/**
 * Write 1 byte to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The byte that should be written to memory
 * @return void
 */
void writeByte(int location, uint8_t val){

	//STORE THE BYTE
	MAIN_MEMORY[location] = val;

}

/**
 * TODO: ---
 *
 * @param newValue 
 * @param location 
 * @param bh_word
 * @return void
 */
void loadSingleHEX(std::string newValue, int location, int bh_word){
	
	switch (bh_word) {
		
		case 0:{

			MAIN_MEMORY[location+0] = ((hexCharValue(newValue[1])) + (hexCharValue(newValue[0])<<4));		//msb
			MAIN_MEMORY[location+1] = ((hexCharValue(newValue[3])) + (hexCharValue(newValue[2])<<4));
			MAIN_MEMORY[location+2] = ((hexCharValue(newValue[5])) + (hexCharValue(newValue[4])<<4));
			MAIN_MEMORY[location+3] = ((hexCharValue(newValue[7])) + (hexCharValue(newValue[6])<<4));		//lsb
			
			break;
		}

		case 1:{
			       //store byte
			MAIN_MEMORY[location] = ((hexCharValue(newValue[1])) + (hexCharValue(newValue[0])<<4));
			
			break;
		}

		case 2:{												//store halfword
			
			MAIN_MEMORY[location]   = (hexCharValue(newValue[0]) + hexCharValue(newValue[1])<<4);			//msB
			MAIN_MEMORY[location+1] = (hexCharValue(newValue[3]) + hexCharValue(newValue[2])<<4);			//lsB
			
			break;
		}

		default:{
				
			break;
		}
	}
} 

