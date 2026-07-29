#include "sm_syscalls.h"
#include "sm_memory.h"

#include <cstdio> 	/* printf() */
#include <stdlib.h>

#include <sys/utsname.h>
#include <stddef.h>

struct syscall_addresses syscalls; 

bool EMULATE_LLSC = 1;

void init_syscalls() {

	syscalls.CFREE_ADDRESS = 0xFFFFFFF0;
	syscalls.EXIT_ADDRESS = 0xFFFFFFF0;
	syscalls.FXSTAT64_ADDRESS = 0xFFFFFFF0;
	syscalls.GETEGID_ADDRESS = 0xFFFFFFF0;
	syscalls.GETEUID_ADDRESS = 0xFFFFFFF0;
	syscalls.GETGID_ADDRESS = 0xFFFFFFF0;
	syscalls.GETPID_ADDRESS = 0xFFFFFFF0;
	syscalls.GETUID_ADDRESS = 0xFFFFFFF0;
	syscalls.LIBC_MALLOC_ADDRESS = 0xFFFFFFF0;
	syscalls.LIBC_OPEN_ADDRESS = 0xFFFFFFF0;
	syscalls.LIBC_READ_ADDRESS = 0xFFFFFFF0;
	syscalls.LIBC_WRITE_ADDRESS = 0xFFFFFFF0;
	syscalls.MMAP_ADDRESS = 0xFFFFFFF0;
	syscalls.MUNMAP_ADDRESS = 0xFFFFFFF0;
	syscalls.UNAME_ADDRESS = 0xFFFFFFF0;
	syscalls.CXX_EX_AND_ADD_ADDRESS = 0xFFFFFFE0;
	syscalls.CXX_ATOMIC_ADD_ADDRESS = 0xFFFFFFE0;

}

void fill_syscall(uint32_t address, uint16_t call) {

	printf("Writing syscall %hd at address %x\n", call, address);

	writeWord(address + 0x0, 0x24020000 | call);		//li $2, call
	writeWord(address + 0x4, 0xc);				//syscall
	writeWord(address + 0x8, 0x03e00008);			//jr $31
	writeWord(address + 0xc, 0x0);				//nop
}

void fill_ex_and_add(uint32_t address) {

	printf("Writing Exchange and Add at address %x\n", address);

	writeWord(address + 0x00, 0x8c820000);	//lw	v0,0(a0)
	writeWord(address + 0x04, 0x00000000);	//nop
	writeWord(address + 0x08, 0x00a21821);	//addu	v1,a1,v0
	writeWord(address + 0x0c, 0xac830000);	//sw	v1,0(a0)
	writeWord(address + 0x10, 0x03e00008);	//jr	ra
	writeWord(address + 0x14, 0x24030001);	//li	v1,1
}

void fill_atomic_add(uint32_t address) {

	printf("Writing Atomic Add at address %x\n", address);

	writeWord(address + 0x00, 0x8c820000);	//lw	v0,0(a0)
	writeWord(address + 0x04, 0x00000000);	//nop
	writeWord(address + 0x08, 0x00a21021);	//addu	v1,a1,v0
	writeWord(address + 0x0c, 0xac820000);	//sw	v1,0(a0)
	writeWord(address + 0x10, 0x03e00008);	//jr	ra
	writeWord(address + 0x14, 0x24020001);	//li	v0,1
}

void fill_syscall_redirects() {

	fill_syscall(syscalls.CFREE_ADDRESS, 4091);
	fill_syscall(syscalls.EXIT_ADDRESS, 4001);
	fill_syscall(syscalls.FXSTAT64_ADDRESS, 4028);
	fill_syscall(syscalls.LIBC_MALLOC_ADDRESS, 4555);
	fill_syscall(syscalls.LIBC_OPEN_ADDRESS, 4005);
	fill_syscall(syscalls.LIBC_READ_ADDRESS, 4003);
	fill_syscall(syscalls.LIBC_WRITE_ADDRESS, 4004);
	fill_syscall(syscalls.MMAP_ADDRESS, 4090);
	fill_syscall(syscalls.MUNMAP_ADDRESS, 4091);
	fill_syscall(syscalls.UNAME_ADDRESS, 4122);
	
	fill_ex_and_add(syscalls.CXX_EX_AND_ADD_ADDRESS);
	fill_atomic_add(syscalls.CXX_ATOMIC_ADD_ADDRESS);

}

// implementation of fxstat64 system call
// who knows what it's loading into memory?
// Not Joe.
void fxstat64(int sp)
{
	loadSingleHEX("00000009",sp +32,0);
	loadSingleHEX("00000000",sp +48,0);
	loadSingleHEX("00000002",sp +52,0);
	loadSingleHEX("00002190",sp +56,0);
	loadSingleHEX("00000001",sp +60,0);
	loadSingleHEX("00001fb3",sp +64,0);
	loadSingleHEX("00000005",sp +68,0);
	loadSingleHEX("00008800",sp +72,0);
	loadSingleHEX("00000000",sp +88,0);
	loadSingleHEX("00000000",sp +92,0);
	loadSingleHEX("00000400",sp +120,0);
	loadSingleHEX("00000000",sp +128,0);
	loadSingleHEX("00000000",sp +132,0);	
}

void write_instruction(uint32_t *address, uint32_t instruction) {

	writeWord(*address, instruction);
	printf("Writing 0x%08x to 0x%08x", instruction, *address);
	(*address)+=4;

	for(int i = 0; i < 7; i++) {
	
		writeWord(*address, 0x0);
		(*address)+=4;
	}
	
	printf("\n");
}

void write_load_immediate(uint32_t *address, uint32_t regno, uint32_t value) {
	
	write_instruction(address, 0x3C000000 |
			(regno << 16) |
			((value >> 16) & 0xFFFF));
	
	write_instruction(address, 0x34000000 |
			(regno << 21) |
			(regno << 16) |
			(value & 0xFFFF));
}

void write_initialization_vector(uint32_t sp, uint32_t gp, uint32_t start) {
	
	printf("Initializing sp=0x%08x; gp=0x%08x; start=0x%08x\n", sp, gp, start);
	
	uint32_t current_address = 0xBFC00000;
	
	write_load_immediate(&current_address, 29, sp);
	
	if(gp != 0xFFFFFFFF) {
	
		write_load_immediate(&current_address, 28, gp);
	}
	
	write_load_immediate(&current_address, 31, start);
	write_instruction(&current_address, 0x3E00008);	//jr ra
	write_instruction(&current_address, 0x0);	//nop [branch delay]
}

void copy_string_to_sim(uint32_t base_addr, const char * str) {
	
	while(*str) {
		writeByte(base_addr, *str);
		str++;
		base_addr++;
	}
	writeByte(base_addr, '\0');
}

// uname syscall implementation (for 2.4 kernel)
void sm_uname(int sp){

	/* insert into stack...
	 * "SescLinux"
	 * "sesc"
	 * "2.4.18"
	 * "#1 SMP Tue Jun 4 16:05:29 CDT 2002"
	 * "mips"
	 */

	printf("running sm_uname\n");

	loadSingleHEX("6d697073",sp +348,0);
	loadSingleHEX("32000000",sp +316,0);
	loadSingleHEX("20323030",sp +312,0);
	loadSingleHEX("20434454",sp +308,0);
	loadSingleHEX("353a3239",sp +304,0);
	loadSingleHEX("31363a30",sp +300,0);
	loadSingleHEX("6e203420",sp +296,0);
	loadSingleHEX("65204a75",sp +292,0);
	loadSingleHEX("50205475",sp +288,0);
	loadSingleHEX("3120534d",sp +284,0);
	loadSingleHEX("00000023",sp +280,0);
	loadSingleHEX("342e3138",sp +220,0);
	loadSingleHEX("0000322e",sp +216,0);
	loadSingleHEX("63000000",sp +156,0);
	loadSingleHEX("00736573",sp +152,0);
	loadSingleHEX("78000000",sp +96,0); 
	loadSingleHEX("4c696e75",sp +92,0);
	loadSingleHEX("53657363",sp +88,0);

	printf("exiting sm_uname\n");

}
