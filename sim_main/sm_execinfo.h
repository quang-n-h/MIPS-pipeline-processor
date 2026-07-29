#ifndef EXECINFO_H
#define EXECINFO_H

struct execinfo{

	// all values here are big endian
	// since they mirror what's in the CPU

	int GSP;	// Global Stack Pointer
	int GRA; 	// Global Return Address
	int GPC_START;	// Starting PC
	int HEAPSTART;  // Start of Heap
	int BREAKSTART;	// Start of Break
	int GP;		// Global Pointer (r28)
};

#ifdef DEFINE_GLOBALS
#define EXTERN
#else
#define EXTERN extern
#endif

EXTERN struct execinfo exec;

#endif
