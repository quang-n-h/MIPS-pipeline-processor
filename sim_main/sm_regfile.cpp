#include <cstdio>	/* fprintf() */
#include <stdint.h>	/* uint32_t */
#include <verilated.h>	/* VMIPS_RegFile, VMIPS_EXE */

#include "sm_regfile.h"	//INCLUDE FILE HEADER

//THESE TWO VARIABLES STORE THE ADDRESS OF THE REGFILE AND EXE STAGE
//BOTH ARE USED TO ACCESS 'verilator public' REGISTERS
static VMIPS_RegFile* _RegFile = NULL;
static VMIPS_EXE* _EXE = NULL;

/**
 * Set the address of the RegFile and EXE Stage
 * 
 * @param *rf The address of the RegFile
 * @return *exe The address of the EXE Stage
 * @return void
 */
void init_register_access(VMIPS_RegFile *rf, VMIPS_EXE *exe) {

	_RegFile = rf;
	_EXE = exe;
}

/**
 * Get the value of a register in either the RegFile or the EXE Stage
 * 
 * @param regno The register number
 * @return the contents of the register specified by 'regno'
 */
uint32_t read_register(uint32_t regno) {

	//IF THE REGFILE OR THE EXE HAS NOT BEEN SET UP
	if(!(_RegFile && _EXE)){

		//PRINT ERROR AND TERMINATE
		fprintf(stderr, "ERROR: Register access not initialized!\n");
		return -1;
	}

	//IF THE REQUESTED REGISTER IS 0
	if(regno == 0){

		//REGISTER 0 IS ALWAYS 0
		return 0;
	}

	//IF THE REQUESTED REGISTER IS BETWEEN 1 AND 31
	if(regno < 32){

		//RETURN CONTENTS OF REGISTER IN REGFILE
		return _RegFile->Reg[regno];
	}

	//IF THE REQUESTED REGISTER IS 'HI'
	if(regno == 32){

		//RETURN CONTENTS OF 'HI'
		return _EXE->HI;
	}

	//RETURN CONTENTS OF 'LO'
	return _EXE->LO;
}

/**
 * Set the value of a register in the RegFile
 * 
 * @param regno The register number
 * @param value What the register contents should be set to
 * @return void
 */
void write_register(uint32_t regno, uint32_t value) {

	//IF THE REGFILE OR THE EXE HAS NOT BEEN SET UP
	if(!(_RegFile && _EXE)) {

		//PRINT ERROR AND TERMINATE
		fprintf(stderr, "ERROR: Register access not initialized!\n");
		return;
	}

	//IF THE REQUESTED REGISTER IS BETWEEN 1 AND 31
	if((regno >= 1) && (regno <= 31)){

		//WRITE 'value' TO REGISTER
		_RegFile->Reg[regno] = value;

	}
}
