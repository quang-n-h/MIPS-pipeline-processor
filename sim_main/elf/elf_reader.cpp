/*
 * elf_reader.c
 *
 *  Created on: Jul 25, 2014
 *      Author: irichter
 */

#include "elf.h"
#include "common.h"
#include "mips.h"
#include "elf_reader.h"
#include <stddef.h>
#include <string.h>

#include <stdio.h>
#ifndef __APPLE__
#include <byteswap.h>
#else
#define bswap_16(a) __builtin_bswap16(a)
#define bswap_32(a) __builtin_bswap32(a)
#endif

int parse_elf(const char * elf_data, size_t elf_length, Exe_Format &exeFormat) {
	
	Elf32_External_Ehdr *ehdr = (Elf32_External_Ehdr*) elf_data;

	if (ehdr->e_ident[EI_MAG0] != ELFMAG0 || ehdr->e_ident[EI_MAG1] != ELFMAG1
			|| ehdr->e_ident[EI_MAG2] != ELFMAG2
			|| ehdr->e_ident[EI_MAG3] != ELFMAG3)
		return -2;

	/* Fail if not 32bit */
	if (ehdr->e_ident[EI_CLASS] != ELFCLASS32) {
		return -3;
	}

	/* Fail if not BigEndian */
	if (ehdr->e_ident[EI_DATA] != ELFDATA2MSB) {
		return -4;
	}

	/* Fail if not ELF version 1 */
	if (ehdr->e_ident[EI_VERSION] != 1) {
		return -5;
	}

	/* Fail if not UNIX System V ABI*/
	if (ehdr->e_ident[EI_OSABI] != ELFOSABI_NONE) {
		return -6;
	}

	/* Fail if not supported architecture (MIPS) */
	if (bswap_16 (ehdr->e_machine) != 8)
		return -7;

	/* Fail if no valid program headers */
	if (bswap_16 (ehdr->e_phnum) < 1)
		return -8;

	/* Fail if reported ELF header size does not match actual
	 * ELF header size */
	if (bswap_16 (ehdr->e_ehsize) != sizeof(Elf32_External_Ehdr))
		return -9;

	/* Fail if reported program header size does not match actual
	 * program header size */
	if (bswap_16 (ehdr->e_phentsize) != sizeof(Elf32_External_Phdr))
		return -10;

	exeFormat.maxUsedAddr = 0;

	exeFormat.entryAddr = bswap_32(ehdr->e_entry);
	uint16_t numSegments = bswap_16(ehdr->e_phnum);
	Elf32_External_Phdr *phdr = (Elf32_External_Phdr *) (elf_data
			+ bswap_32(ehdr->e_phoff));

	int i;
	for (i = 0; i < numSegments; i++) {
		uint32_t offset = bswap_32(phdr->p_offset);
		uint32_t seg_type = bswap_32(phdr->p_type);
		switch (seg_type) {
		case PT_MIPS_REGINFO:
			exeFormat.globalPointer = bswap_32(((Elf32_External_RegInfo*) (elf_data + offset))->ri_gp_value);
			//No break (we do allocate it)
		case PT_NOTE:
		case PT_LOAD: {
			struct Exe_Segment seg;
			seg.offsetInFile = offset;
			seg.lengthInFile = bswap_32(phdr->p_filesz);
			seg.startAddress = bswap_32(phdr->p_vaddr);
			seg.sizeInMemory = bswap_32(phdr->p_memsz);
			seg.protFlags = bswap_16(phdr->p_flags);
			seg.type = seg_type;
			exeFormat.segmentList.push_back(seg);
			uint32_t seg_end = seg.startAddress + seg.sizeInMemory;
			if(seg_end < exeFormat.maxUsedAddr) {
				exeFormat.maxUsedAddr = seg_end;
			}
		}
			break;
		default:
			//Don't bother loading it -- we don't need it.
			//Only known section that would fit this is PAX_FLAGS
			break;
		}
		phdr++;
	}

	//Obtain largest allocated memory location:
	uint16_t shnum = bswap_16(ehdr->e_shnum);
	Elf32_External_Shdr *base_shdr = (Elf32_External_Shdr*) (elf_data
			+ bswap_32(ehdr->e_shoff));
	for(i = 0; i < shnum; i++) {
		uint32_t sh_flags = bswap_32(base_shdr[i].sh_flags);
		if(sh_flags & SHF_ALLOC) {
			uint32_t seg_end = bswap_32(base_shdr[i].sh_addr) + bswap_32(base_shdr[i].sh_entsize);
			if(seg_end < exeFormat.maxUsedAddr) {
				exeFormat.maxUsedAddr = seg_end;
			}
		}
	}

	//Try to get string tables:
	uint16_t shstrndx = bswap_16(ehdr->e_shstrndx);
	if (shstrndx && shnum) {
		Elf32_External_Shdr *shstrhdr = base_shdr + shstrndx;
		char * shstrtbl = (char*) (elf_data + bswap_32(shstrhdr->sh_offset));
		Elf32_External_Shdr *symtabhdr = NULL;
		Elf32_External_Shdr *strtabhdr = NULL;
		for (i = 0; i < shnum; i++) {
			uint32_t sh_name = bswap_32(base_shdr[i].sh_name);
			if (sh_name) {
				char * shname = shstrtbl + sh_name;
				switch (bswap_32(base_shdr[i].sh_type)) {
				case SHT_SYMTAB:
					if(!strcmp(shname, ".symtab")) {
						symtabhdr = base_shdr + i;
					}
					break;
				case SHT_STRTAB:
					if(!strcmp(shname, ".strtab")) {
						strtabhdr = base_shdr + i;
					}
					break;
				}
			}
		}
		if(symtabhdr && strtabhdr) {
			Elf32_External_Sym *sym_base = (Elf32_External_Sym*)(elf_data + bswap_32(symtabhdr->sh_offset));
			uint32_t sym_count = bswap_32(symtabhdr->sh_size) / bswap_32(symtabhdr->sh_entsize);
			const char *str_base = (elf_data + bswap_32(strtabhdr->sh_offset));
			for(i = 0; i < sym_count; i++) {
				if (ELF_ST_TYPE(sym_base[i].st_info) == STT_FUNC) {
					std::string name = std::string(str_base + bswap_32(sym_base[i].st_name));
					if(exeFormat.function_pointers.find(name) != exeFormat.function_pointers.end()) {
						*exeFormat.function_pointers[name] = bswap_32(sym_base[i].st_value);
					}
				}
			}
		}
	}

	return 0;

}

