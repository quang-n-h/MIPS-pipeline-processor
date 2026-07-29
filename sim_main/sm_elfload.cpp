#include <sys/types.h>
#include <sys/stat.h>		/* lstat() */
#include <fcntl.h>		/* open() */
#include <unistd.h>	
#include <sys/mman.h>		/* mmap() */
#include <cstdio>

#include "sm_elfload.h"		//INCLUDE FILE HEADER

#include "sm_memory.h"
#include "sm_heap.h"
#include "sm_syscalls.h"
#include "sm_execinfo.h"

#include "elf/elf_reader.h" 	/* parse_elf() */

/**
 * Load the binary into main memory 
 *
 * @param FILE_ARG the directory of the binary file
 * @return exit status, will be negative if failed
 */
int LoadOSMemoryELF (const char * FILE_ARG){

	//VARIABLE TO HOLD FILE DESCRIPTOR OF BINARY
	int elf_fd;

	char * elf_data;

	//OPEN THE BINARY AS READ ONLY AND STORE FILE DESCRIPTOR
	//https://linux.die.net/man/2/open
	elf_fd = open(FILE_ARG, O_RDONLY);
	
	//IF THERE WAS AN ERROR OPENING THE FILE	
	if (elf_fd == -1) {
	
		//RETURN ERROR
		return -1;
	}
	
	//CREATE A STAT STRUCTURE FOR BINARY FILE
	//https://linux.die.net/man/2/lstat
	struct stat file_stat;
	
	//STAT THE BINARY, STORE STATS IN 'file_stat'
	//IF THE 'lstat' FUNCTION FAILED
	if (lstat(FILE_ARG, &file_stat)) {
	
		//CLOSE THE FILE
		close(elf_fd);

		//RETURN ERROR
		return -2;
	}
	
	//CREATE A MAPPING IN MEMORY FOR THE FILE
	//https://linux.die.net/man/2/mmap
	elf_data = (char*)mmap(NULL, file_stat.st_size, PROT_READ, MAP_PRIVATE, elf_fd, 0);

	//IF 'mmap' FAILED
	if (elf_data == MAP_FAILED) {
	
		//CLOSE THE FILE
		close(elf_fd);
	
		//RETURN ERROR
		return -3;
	}
	
	Exe_Format exeFormat;
	
	init_syscalls();
	
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__uname"), &syscalls.UNAME_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__libc_malloc"), &syscalls.LIBC_MALLOC_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__cfree"), &syscalls.CFREE_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__fxstat64"), &syscalls.FXSTAT64_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__mmap"), &syscalls.MMAP_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__libc_write"), &syscalls.LIBC_WRITE_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__munmap"), &syscalls.LIBC_WRITE_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__libc_read"), &syscalls.LIBC_WRITE_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("__libc_open"), &syscalls.LIBC_OPEN_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("_ZN9__gnu_cxx18__exchange_and_addEPVii"), &syscalls.CXX_EX_AND_ADD_ADDRESS));
	exeFormat.function_pointers.insert(std::pair<std::string, unsigned int*>(std::string("_ZN9__gnu_cxx12__atomic_addEPVii"), &syscalls.CXX_ATOMIC_ADD_ADDRESS));
	
	int rv = parse_elf(elf_data, file_stat.st_size, exeFormat);

	if(rv) {
	
		munmap(elf_data, file_stat.st_size);
		close(elf_fd);
	
		printf("\nERROR READING ELF!!!! (%d)\n", rv);
	
		return rv;
	}

	puts("\n-----ELF SUMMARY------\n");
	printf("Num segments %d\n",exeFormat.numSegments);
	printf("entry point %8x\n\n",exeFormat.entryAddr);

	// TODO: clean this
	// for each section
	int maxAddr = 0;

	for(int i =0; i<exeFormat.segmentList.size(); i++){
	
		// read section into memory
		// j = offset from start
		printf("Segment %d ---\n",i);
		printf("startaddr 0x%8x\n",exeFormat.segmentList[i].startAddress);
		printf("length %d\n",exeFormat.segmentList[i].lengthInFile);
		printf("type 0x%8x\n", exeFormat.segmentList[i].type);
		
		int j = 0;
		
		for(int j = 0; j<exeFormat.segmentList[i].lengthInFile; j++){
		
			MAIN_MEMORY[j+exeFormat.segmentList[i].startAddress]
				=elf_data[j+exeFormat.segmentList[i].offsetInFile];
		}
		
		if(j+exeFormat.segmentList[i].startAddress>maxAddr){
		
			maxAddr = j+exeFormat.segmentList[i].startAddress;
		}
	}

	munmap(elf_data, file_stat.st_size);
	close(elf_fd);

	// store exec offsets -----------------------
	exec.GPC_START = exeFormat.entryAddr;

	// set heap beyond the scope of our addressing, and align to a page.
	exec.BREAKSTART = 0x80000000;
	exec.HEAPSTART = 0xC0000000;

	// not sure yet how to get these from ELF
	exec.GSP = 0xf7021fc0;//for noio
	exec.GRA = 0x1006a244;//for noio, but we don't really need it

	exec.GP = exeFormat.globalPointer;
	
	puts("\n-----FINISHED ELF LOAD------\n");

	fill_syscall_redirects();
	
	return 0;
}
