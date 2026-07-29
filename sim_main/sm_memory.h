#ifndef SM_MEMORY_H
#define SM_MEMORY_H

#include <map>		/* std::map */
#include <stdint.h>	/* uint8_t, uint16_t, uint32_t */
#include <string>	/* std::string */

//MAIN MEMORY MAP; EACH INDEX STORES 8 BITS (SINGLE DIGIT OF HEX)
extern std::map<int,uint8_t> MAIN_MEMORY;

/**
 * Read a word (4 bytes) from MAIN_MEMORY and return as a 'uint32_t'
 *
 * @param location The address in memory that the word is located
 * @return the contents of the 4 bytes of memory at the location provided
 */
uint32_t readWord(int location);

/**
 * Read a halfword (2 bytes) from MAIN_MEMORY and return as a 'uint16_t'
 *
 * @param location The address in memory that the halfword is located
 * @return the contents of the 2 bytes of memory at the location provided
 */
uint16_t readHalfWord(int location);

/**
 * Read 1 byte from MAIN_MEMORY and return as a 'uint8_t'
 *
 * @param location The address in memory that the byte is located
 * @return the contents of the byte of memory at the location provided
 */
uint8_t readByte(int location);

/**
 * Write a word (4 bytes) to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The word that should be written to memory
 * @return void
 */
void writeByte(int location, uint8_t val);

/**
 * Write a halfword (2 bytes) to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The halfword that should be written to memory
 * @return void
 */
void writeHalfWord(int location, uint16_t val);

/**
 * Write 1 byte to MAIN_MEMORY
 *
 * @param location The address in memory that should be written to
 * @param val The byte that should be written to memory
 * @return void
 */
void writeWord(int location, uint32_t val);

/**
 * Convert single hex char to 4-bit integer
 *
 * @param ch The character to convert
 * @return the 4-bit integer
 */
inline int hexCharValue(const char ch){

	//IF THE CHARACTER IS BETWEEN '0' AND '9' 
	if (ch >= '0' && ch <= '9'){
	
		//RETURN DISTANCE FROM '0'
		return ch - '0';
	}

	//IF THE CHARACTER IS BETWEEN 'A' AND 'F'
 	if (ch >= 'a' && ch <= 'f'){
		
		//RETURN DISTANCE FROM 'A' PLUS TEN
		return ch - 'a' + 10;
	}
  
	//DEFAULT RETURN 0
	return 0;
}

void loadSingleHEX(std::string newValue, int location, int bh_word);

#endif
