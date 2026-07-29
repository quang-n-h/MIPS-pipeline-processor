/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
|        WRAPPER PROGRAM: Emulating OS for MIPS I Processor (MIPS32 ABI)                         |
|           This program automates the process of generating a binary                            |
|           and loading the hex dump of that program into a verilog processor                    |
|           memory map.  This wrapper also acts as the clock generator for                       |
|           the processor.                                                                       |
|        Written by Dan Snyder                                                                   |
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 * Made actually usable (and reasonable) by Joe Israelevitz
 *
 * Polish by Isaac Richter
 *
 * Looked at and dismissed as unsalvagable by B.C.
 * Yet worked on anyway
 */

/* THIS PROGRAM HANDLES
 * 1. Memory Management
 * 2. Syscalls
 * 3. Debug Information Display
 */

#include <cstdio>		/* printf(), fprintf() */
#include <cstdlib>		/* atoi(), strtol() */
#include <ctime>		/* time_t, time() */
#include <fstream>		/* std::ofstream, std::ifstream */
#include <getopt.h>		/* getopt() */
#include <iostream>
#include <signal.h>		/* kill() */
#include <string>		/* std::string */
#include <sstream>		/* std::stringstream */
#include <sys/stat.h>		/* stat, fstat() */
#include <sys/syscall.h>
#include <vector>		/* std::vector */

//ACCESS TO VERILATOR ITEMS
#include <verilated.h>		/* Verilator Libraries */
#include "VMIPS.h"		/* For Access To Verilog Parent Module */
#include "VMIPS_MIPS.h"		/* For Access To Verilog Submodules */
#include "VMIPS_ID.h"		/* For Access To The Register File */
#include "VMIPS_IF.h"		/* For Access To The Program Counter */

//EXTERNAL FUNCTIONALITY
#include "sm_memory.h"		/* Methods For Accessing Main Memory */	
#include "sm_heap.h"		/* Methods For Dynamic Memory Allocation */
#include "sm_syscalls.h"
#define DEFINE_GLOBALS
#include "sm_execinfo.h"
#include "sm_elfload.h"		/* Methods For Loading ELF Files Into Memory */
#include "sm_regfile.h"		/* Methods For Accessing The Register File */

//USED TO KEEP TRACK OF PROGRESS
static unsigned int MAINTIME = 0; 	/* The Number Of 'CLOCK' Transitions */
static int INSTR_COUNT = 0; 		/* The Number Of Instructions Executed */

//NUMBER OF CYCLES COMPLETED IN THE SIMULATION
int CLOCK_COUNTER = 0;

//SIMULATION OPTIONS - CAN BE SET COMMAND LINE
std::string FILE_ARG; 	//path to input elf files
int duration = 1;

//MONITORING OUTPUT PARAMETERS - CAN BE SET COMMAND LINE
bool MONITOR_REGS = 1;		/* Should Register Contents Be Printed At Each Cycle? */
int SINGLE_STEP_QUIT = 0;
int BREAKPOINT = -1;

extern char *optarg;
char* argv0;

/**
 * Prints to the terminal the definition of each command line argument option
 *
 * @return void
 */
void printargdef(){

	fprintf(stderr, "usage: %s [APP_NAME] <DURATION>\n", argv0);
	fprintf(stderr, "OR\n");
	fprintf(stderr, "usage: %s [-f file_path] <arguments>\n", argv0);
	fprintf(stderr, "-r [0/1]: monitor regs no/yes [default=1]\n");
	fprintf(stderr, "-d {0,9}+: duration between halts [default=0]\n");
	fprintf(stderr, "-b {value}: where we unconditionally drop into single-instruction mode\n");
	fprintf(stderr, "            may be specified in hex as 0x12345678\n");
	fprintf(stderr, "-q [0/1]: quit when breaking into single-step mode [default=0]\n");
	fprintf(stderr, "-h : show usage\n");
}

/**
 * Take in the command line arguments and set the corresponding variables accordingly
 *
 * @param argc The number of command line arguments
 * @param argv The command line arguments
 * @return void
 */
void readcommandline(int argc, char *argv[]){

	int c;
	argv0 = argv[0];
	int numopts=0;
	bool file = 0;

	//WHILE VALID COMMAND LINE ARGUMENTS REMAIN
	while ((c = getopt (argc, argv, "f:r:h:d:b:q:")) != -1){

		numopts++;

		switch (c) {

			case 'f':
				FILE_ARG = optarg;
				file = 1;
			    	break;
			case 'r':
				MONITOR_REGS = atoi(optarg);
				break;
			case 'd':
				duration = atoi(optarg);
				break;
			case 'b':
				BREAKPOINT = strtol(optarg, NULL, 0);
				break;
			case 'q':
				SINGLE_STEP_QUIT = atoi(optarg);
				break;
			case 'h':
				printargdef();
				exit(0);
				break;
        	}
	}
	
	if(numopts==0 && (argc == 3 || argc == 2)) {
	
		FILE_ARG = argv[1];
		file=1;
	
		if(argc==3) {
	
			duration = atoi(argv[2]);
		}
	}

	//IF NO FILE WAS PROVIDED
	if(!file){
	
		//PRINT ERROR, PRINT POTENTIAL COMMAND LINE ARGUMENTS, EXIT
		fprintf(stderr, "ERROR: No File to Load\n");
		printargdef();
	
		exit(0);
	}
}

/**
 * MAIN METHOD; This is where the program starts upon execution
 * 
 * @param argc The number of command line arguments
 * @param argv The command line arguments
 * @return the final execution state (essentially void)
 */
int main(int argc, char *argv[]){

	//PASS COMMAND LINE ARGUMENTS TO VERILATOR
	Verilated::commandArgs(argc, argv);
	
	//CREATE A NEW INSTANCE OF THE CPU
	VMIPS *top = new VMIPS;

	//READ THE COMMAND LINE ARGUMENTS
	readcommandline(argc, argv);

	//USED FOR KEEPING TRACK OF EXECUTION TIME	
	time_t seconds;		

	//USED FOR STORING THE SYSCALL INDEX (Reg[2])
	int syscallIndex = 0;

	//USED FOR CHECKING FOR PROGRESS
	uint32_t prevInstructionAddr;
	uint32_t nextInstructionAddr;

	//VECTOR FOR STORING THE NAMES OF THE FILE DESCRIPTORS
	//https://en.wikipedia.org/wiki/File_descriptor	
	std::vector<std::string> FDT_filename;

	//VECTOR FOR STORING THE STATE OF EACH FILE DESCRIPTOR
	//1 = open, 0 = closed
	std::vector<int> FDT_state;

	//LOAD FILE DESCRIPTORS FOR STANDARD STREAMS
	//AUTOMATICALLY CREATED AND OPENED FOR <stdio>
	//https://en.wikipedia.org/wiki/Standard_streams
	FDT_filename.push_back("stdin");
	FDT_state.push_back(0);
	FDT_filename.push_back("stdout");
	FDT_state.push_back(0);//TODO should this be 1??
	FDT_filename.push_back("stderr");
	FDT_state.push_back(0);//TODO should this be 1??
	
	//USED TO TRACK INDEX OF NEXT AVAILABLE FILE DESCRIPTOR
	int FileDescriptorIndex = 3;

	//OPEN THE STANDARD INPUT AND STANDARD OUTPUT STREAMS
	std::ofstream stdoutFile("stdout.txt");
	std::ofstream stderrFile("stderr.txt");

	//SET INITIAL PARAMETERS
	top->Instruction_IN = 0;
	top->CLOCK = 0;

	//LOAD ELF
	printf("*** ELF LOADING, PLEASE WAIT ***\n");

	//LOAD ELF INTO MEMORY, IF ERROR STATUS
	if(LoadOSMemoryELF(FILE_ARG.c_str())<0){
	
		//PRINT ERROR AND TERMINATE
		fprintf(stderr,"Unable to load file %s\n",FILE_ARG.c_str());
		return -1;
	}

	write_initialization_vector(exec.GSP, exec.GP, exec.GPC_START);

	printf("*** PROGRAM EXECUTING ***\n");
	
	//PROVIDE THE ADDRESS OF THE REGFILE AND EXE STAGE TO 'sm_regfile'
	init_register_access(top->MIPS->ID->RegFile, top->MIPS->EXE);

	//RECORD THE CURRENT TIME
	seconds = time(NULL);

	/* Boot Sequence - Bring Reset High, Then Low, Then High
	 * Load The First Instruction (Boot Address After Reset)
	 */
	printf("########################################\n");
	printf("### Boot Sequence ###\n\n");

	top->RESET = 1;
	top->eval();

	top->RESET = 0;
	top->eval();

	top->RESET = 1;
	top->Instruction_IN = readWord(top->InstructionAddress_OUT);
	top->eval();
	
	printf("### Finished Boot ###\n");
	printf("########################################\n");

	/* Continue to loop until the verilog hits '$finish'
	 * Useful for debugging, but this will not typically happen
	 * Therefore, this is effectively an infinite loop
	 */
	while (!Verilated::gotFinish()){

		//INVERT CLOCK STATE
		top->CLOCK=!(top->CLOCK);

		//INCREMENT 'MAINTIME'	
		MAINTIME++;

		//RECORD THE ADDRESS IN THE PROGRAM COUNTER (for tracking progress)
		nextInstructionAddr = top->MIPS->IF->ProgramCounter;
	
		//IF THE CURRENT PROGRAM COUNTER DOES NOT MATCH THE PREVIOUS PROGRAM COUNTER
		if(prevInstructionAddr != nextInstructionAddr){

			//INCREMENT INSTRUCTION COUNT AND STORE CURRENT PROGRAM COUNTER AS PREVIOUS
			INSTR_COUNT++;
			prevInstructionAddr = nextInstructionAddr;
		}

		//PROVIDE WORD AT 'InstructionAddress_OUT' TO PROCESSOR
		top->Instruction_IN = readWord(top->InstructionAddress_OUT);

		//PROVIDE BLOCK AT 'InstructionAddress_OUT' TO PROCESSOR
		for(int i = 0; i < 8; i++) {
		
			top->InstructionBlock_IN[7-i] = readWord(top->InstructionAddress_OUT + (i*4));
		}

		//IF THE PROCESSOR IS REQUESTING A DATA MEMORY READ
		if(top->MemRead_OUT) {
			
			//PROVIDE WORD AT 'DataAddress_OUT' TO PROCESSOR (aligned)
			top->Data_IN = readWord(top->DataAddress_OUT & 0xfffffffc);
		}

		//IF THE PROCESSOR IS REQUESTING A DATA MEMORY WRITE
		if(top->MemWrite_OUT) {

			//SWITCH STATEMENT FOR DATA SIZE
			switch(top->DataSize_OUT) {

				//4 BYTES
				case 0:
					//WRITE WORD 'Data_OUT' AT 'DataAddress_OUT'
					writeWord(top->DataAddress_OUT, top->Data_OUT);
					break;
				//1 BYTE
				case 1:
					//WRITE LOWEST ORDER BYTE 'Data_OUT' AT 'DataAddress_OUT'
					writeByte(top->DataAddress_OUT, top->Data_OUT);
					break;
				//2 BYTES
				case 2:
					//WRITE LOW ORDER HALFWORD 'Data_OUT' AT 'DataAddress_OUT'
					writeHalfWord(top->DataAddress_OUT, top->Data_OUT);
					break;
				//3 BYTES
				case 3:
					//WRITE THIRD BYTE OF 'Data_OUT' AT 'DataAddress_OUT'
					writeByte(top->DataAddress_OUT, top->Data_OUT>>16);
					//WRITE LOW ORDER HALFWORD OF 'Data_OUT' AT 'DataAddress_OUT + 1'
					writeHalfWord(top->DataAddress_OUT + 1, top->Data_OUT & 0xffff);
					break;
			}
		}
	
		//IF THE PROCESSOR IS REQUESTING A DATA BLOCK READ
		if(top->MemBlockRead_OUT) {
			
			//PROVIDE BLOCK AT 'DataAddress_OUT' TO PROCESSOR
			for(int i = 0; i < 8; i++) {
			
				top->DataBlock_IN[7-i] = readWord(top->DataAddress_OUT + (i*4));
			}
		}

		//IF THE PROCESSOR IS REQUESTING A DATA BLOCK WRITE
		if(top->MemBlockWrite_OUT) {
			
			//WRITE BLOCK 'DataBlock_OUT' AT 'DataAddress_OUT'
			for(int i = 0; i < 8; i++) {
			
				writeWord(top->DataAddress_OUT + (i*4), top->DataBlock_OUT[7-i]);
			}
			
		}
		
		//IF THE CLOCK IS HIGH
		if(MAINTIME%2==0) {

			//INCREMENT CLOCK COUNTER
			CLOCK_COUNTER++;

			//IF THE PROCESS HAS REACHED THE BREAKPOINT
			if(BREAKPOINT == nextInstructionAddr) {
			
				printf("******  HIT BREAKPOINT  ******\n");
				duration = CLOCK_COUNTER;
			}

			//IF THE PROCESS HAS ATTEMPTED TO ACCESS OUTSIDE OF INSTRUCTION MEMORY
			if((nextInstructionAddr < 0x400000) && CLOCK_COUNTER > 1){
			
				printf("******  Jumped near 0  ******\n");
				duration = CLOCK_COUNTER;
			}

			if(CLOCK_COUNTER >= duration) {

				printf("\n########################################\n");
				printf("### @ Start of Cycle %d ###\n",CLOCK_COUNTER);

				if(MONITOR_REGS){
				
					printf("--REG DUMP-------------------------\n");
			
					//FOR EACH GENERAL PURPOSE REGISTER	
					for (int j = 0; j < 32; j++) {
				
						//PRINT CONTENTS OF THE REGISTER
						printf("REG[%2d]: %08x (%d)",j,read_register(j), read_register(j));

						//IF THE REGISTER IS EVEN
						if(j%2 == 0){
							
							//PRINT TWO TABS
							printf("\t\t");

						//IF THE REGISTER IS ODD
						}else{
							
							//PRINT A NEWLINE
							printf("\n");
						}
					}
				
					//PRINT THE CONTENTS OF THE HI AND LO REGISTERS
					printf("REG[LO]: %08x (%d)\t\tREG[HI]: %08x (%d)\n",read_register(33),read_register(33),read_register(34),read_register(34));
				}

				printf("\n### finished output for Cycle %d ###\n",CLOCK_COUNTER);
				printf("########################################\n\n");
			
			}else{

				printf("cycle %d\n",CLOCK_COUNTER);
			}

			//IF THE PROCESS IS NOT IN THE BOOT SEQUENCE AND THE GP IS ZERO
			if(((nextInstructionAddr & 0xFFFFFF00) != 0xBFC00000) && (!read_register(28))) {
				
				printf("!!!GP Tampering (==0) @ 0x%08x!!!\n", nextInstructionAddr);
				duration = CLOCK_COUNTER;
			}
			
			//GET SYSCALL INDEX FROM REGISTER 2
			syscallIndex = read_register(2);

			//IF THE PROCESSOR IS REQUESTING A SYSCALL
			if (top->SYS==1) {
		
				//PRINT SYSCALL INFORMATION	
				printf("SYSCALL: %d\n", syscallIndex);
				printf("SYSCALL Processing:\n");
				
				//CASE STATEMENT FOR SYSCALL INDEX
				//FOR DESCRIPTIONS OF 'syscall()' FUNTIONS:
				//man7.org/linux/man-pages/man2/syscalls.2.html
				switch (syscallIndex) {
			
					//exit_group	
					case 4246:

					//exit
					case 4001:{	

						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'exit' at time: %d\n", CLOCK_COUNTER);

						//SUBTRACT START TIME FROM CURRENT TIME
						seconds = time(NULL) - seconds;

						//PRINT EXECUTION INFORMATION
						printf("*********************************\n");
						printf("Simulation time : %d seconds\n", seconds);
						printf("Total cycles: %d\n", CLOCK_COUNTER);
						printf("Total instructions: %d\n", INSTR_COUNT);

						//CALCULATE INSTRUCTIONS PER CYCLE
						float IPC = (float)INSTR_COUNT/((float)CLOCK_COUNTER);
						printf("IPC: %f\n", IPC);

						//CLOSE THE STANDARD STREAMS
						stdoutFile.close();
						stderrFile.close();

						//CALL THE 'SYS_exit' SYSCALL WITH STATUS 'Reg[4]'
						syscall(SYS_exit, read_register(4));

						break;
						  
					}

					//write
					case 4004:{
					
						printf("'write' at time: %d\n", CLOCK_COUNTER);
						
						int convert;				//accumulator for filename char convert
						int flag = 0;				//loop break flag
						int byte_offset;
						unsigned int k=read_register(5);	//start at specified element
						unsigned int length=read_register(6);
						int i = k;
						
						if (read_register(4)!=1 && read_register(4)!=2) {
						
							std::ofstream _file;
							printf("WriteToFile char %02x, %02x\n",(char)MAIN_MEMORY[i], (char)MAIN_MEMORY[i+1]);
							_file.open(FDT_filename[read_register(4)].c_str(), std::ios::out | std::ios::app );
						
							while (length != 0) {
						
								length--; _file << (char)MAIN_MEMORY[i];
								i++;
							}
						
							_file.close();
						
						}else{

							while (MAIN_MEMORY[i]!=00) {
								
								length--; std::cout<<(char)MAIN_MEMORY[i];
								
								if(read_register(4)==1) {
								
									stdoutFile << (char)MAIN_MEMORY[i];
								
								} else {
								
									stderrFile << (char)MAIN_MEMORY[i];
								}
								
								i++; if(length == 0)break;
							}
							
							if(read_register(4)==1) {
							
								stdoutFile.flush();
							
							} else {
							
								stderrFile.flush();
							}
							
							std::cout.flush();
						}
						
						i++;
						write_register(2,i-k-1);
					
						break;
					}

					//open
					case 4005:{	

						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'open' at time: %d\n", CLOCK_COUNTER);
						
						//TEMPORARY VARIABLE TO STORE FILENAME
						std::string filename;
						
						//REGISTER 4 CONTAINS STARTING ADDRESS OF FILENAME
						int k=(read_register(4));
						
						//READ BYTES UNTIL NULL TERMINATION
						while ( MAIN_MEMORY[k]!=0 ) { 
						
							//ADD BYTE TO FILENAME
							filename = filename + (char)MAIN_MEMORY[k]; 
							k++; 
						}

						//ADD NEW FILE TO FDT
					 	FDT_filename.push_back(filename); 	/* add new filename to newest location */
						FDT_state.push_back(1);			/* add new open indicator to newest location */
						
						write_register(2,FileDescriptorIndex);	/* place file descriptor into register 2 */
						FileDescriptorIndex++;			/* ready the next file descriptor */
						
						std::ofstream _file;
						_file.open(filename.c_str(), std::ios::out | std::ios::trunc);	//And truncate it (since that's what file.cpp wants)
						_file.close();

						break;
					}

					//close
					case 4006:{
					
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'close' at time: %d\n", CLOCK_COUNTER);
						
						//MARK THE FILE DESCRIPTOR 'Reg[4]' AS CLOSED
						FDT_state[read_register(4)] = 0;

						//WRITE A '0' TO 'Reg[2]' TODO why?
						write_register(2,0);
						
						break;
					}

					//Stat TODO depricated?
					case 4018:{
						
						printf("Stat at time: %d\n", CLOCK_COUNTER);
						write_register(4,read_register(5));
						write_register(5,read_register(6));
						struct stat buf;
						write_register(2,stat(FDT_filename[read_register(4)].c_str(),&buf));
						fxstat64(read_register(29));
						break;
					}

					//getpid
					case 4020:{

						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getpid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getpid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getpid));
						
						break;
					}

					//getuid
					case 4024:{

						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getuid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getuid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getuid));
						
						break;
					}

					//FStat TODO depricated?
					case 4028:{	

						printf("FStat at time: %d\n", CLOCK_COUNTER);
						write_register(4,read_register(5));
						write_register(5,read_register(6));
						struct stat buf;
						write_register(2,fstat(read_register(4),&buf));
						fxstat64(read_register(29));
						
						break;
					}

					//kill
					case 4037:{

						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'kill' at time: %d\n", CLOCK_COUNTER);

						write_register(2,kill(read_register(4),read_register(5)));
						
						break;
					}
					
					//brk
					case 4045:{
					
						printf("'brk' at time: %d\n", CLOCK_COUNTER);
						
						uint32_t value = read_register(4);
						uint32_t result = mm_sbrk(value);
						
						printf("sbrk(%d) = %d\n", value, result);
						write_register(2, result);

						break;
					}

					//getgid
					case 4047:{
	
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getgid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getgid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getgid));
						
						break;
					}
					
					//geteuid
					case 4049:{
						
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'geteuid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_geteuid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_geteuid));
						
						break;
					}
					
					//getegid
					case 4050:{
							  
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getegid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getegid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getegid));
						
						break;
					}
					
					//getppid
					case 4064:{
					
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getppid' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'getppid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getppid));
						
						break;
					}
					
					//getpgrp
					case 4065:{
							  
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getpgrp' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getpgrp' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getpgrp));
						
						break;
					}
					
					//getrlimit
					case 4076:{
							  
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getrlimit' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getrlimit' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getrlimit));
						
						break;
					}
					
					//getrusage
					case 4077:{
							  
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getrusage' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_getrusage' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getrusage));
						
						break;
					}
					
					//getTimeofDay
					case 4078:{
					
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'gettimeofday' at time: %d\n", CLOCK_COUNTER);

						//CALL THE 'SYS_gettimeofday' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_gettimeofday,NULL,NULL));
						
						break;
					}
					
					//mmap
					case 4090:{
							  
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'mmap' at time: %d\n", CLOCK_COUNTER);

						uint32_t size = read_register(5)*(1+read_register(4));
						
						if(size < 32){
							
							size = 32;
						}

						uint32_t ans = mm_malloc(size);
						
						printf("MMap: %d\n", ans);
						write_register(2,ans);

						break;
					}
					
					//munmap
					case 4091:{
						
						printf("'munmap' at time: %d\n", CLOCK_COUNTER);
						mm_free(read_register(4));
						
						break;
					}
					
					//uname
					case 4122:{
						
						printf("'uname' at time: %d\n", CLOCK_COUNTER);
						sm_uname(read_register(29));
						write_register(2,0);
						
						break;
					}
					
					//getpgid
					case 4132:{
						
						//PRINT CYCLE THAT SYSCALL OCCURED AT
						printf("'getpgid' at time: %d\n", CLOCK_COUNTER);
						
						//CALL THE 'SYS_getpgid' SYSCALL AND WRITE RESULT TO 'Reg[2]'
						write_register(2,syscall(SYS_getpgid));
						
						break;
					}	
					
					//malloc TODO depricated?
					case 4555:{
						
						printf("Malloc at time: %d\n", CLOCK_COUNTER);
						
						int size = read_register(4);
						
						if(size < 32){
						
							size = 32;
						}
						
						uint32_t ans = mm_malloc(size);
						
						printf("MMap: %08x\n", ans);
						
						write_register(2,ans);
						
						break;
					}
					
					default: { 
						
						//PRINT ERROR AND TERMINATE
						fprintf(stderr, "ERROR: Syscall %d has not been implemented. Process terminated at cycle %d...\n", syscallIndex, MAINTIME/2); 
						return 0; 
					}
				}

			}

			//PREVENTS NEXT INSTRUCTION TRAVERSAL UNTIL USER INPUT (ANY KEY PRESSED)
			if(CLOCK_COUNTER >= duration) {
			
				std::string input;
				getline (std::cin,input);
			
				if(SINGLE_STEP_QUIT || input == "exit" || input == "q") {
			
					stdoutFile.close();
					stderrFile.close();
					exit(42);
				}

				if(input.length()!=0){
			
					BREAKPOINT = strtol(input.c_str(), NULL, 0);
					duration = 1000000;
				}
			}
		}

		//UPDATE PROCESSOR STATE
		top->eval();
	}
}
