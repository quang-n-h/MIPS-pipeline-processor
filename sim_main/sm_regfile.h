#ifndef SM_REGFILE_H_
#define SM_REGFILE_H_

#include <stdint.h>		/* uint32_t */

#include "VMIPS_RegFile.h"	/* FOR ACCESS TO THE REGISTER FILE */
#include "VMIPS_EXE.h"		/* FOR ACCESS TO THE HI AND LO REGISTERS */

/**
 * Set the address of the RegFile and EXE Stage
 * 
 * @param *rf The address of the RegFile
 * @return *exe The address of the EXE Stage
 * @return void
 */
void init_register_access(VMIPS_RegFile *rf, VMIPS_EXE *exe);

/**
 * Get the value of a register in either the RegFile or the EXE Stage
 * 
 * @param regno The register number
 * @return the contents of the register specified by 'regno'
 */
uint32_t read_register(uint32_t regno);

/**
 * Set the value of a register in the RegFile
 * 
 * @param regno The register number
 * @param value What the register contents should be set to
 * @return void
 */
void write_register(uint32_t regno, uint32_t value);

#endif /* SM_REGFILE_H_ */
