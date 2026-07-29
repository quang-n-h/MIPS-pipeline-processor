# Makefile: build the pipelined MIPS processor with Verilator -> ./VMIPS

#WHAT VERSION OF VERILATOR SHOULD BE USED?
VERILATOR_VER=4.006
#NOTE: Known to work with Version 4.006
#In version 4.008, procedural assignment to wires is not allowed
#Haven't yet figured out a comprehensive way to change the verilog

#WHAT OPTIONS SHOULD BE USED TO UNTAR?
VERILATOR_UNTAR_OPTIONS=-xzf

#WHERE IS VERILATOR RELATIVE TO THE CURRENT PATH?
VERILATOR_REL_PATH=./

#WHERE IS VERILATOR?
VERILATOR_DIR=${VERILATOR_REL_PATH}verilator-${VERILATOR_VER}

#WHAT IS THE NAME OF THE VERILATOR TARBALL?
VERLIATOR_TAR=verilator-${VERILATOR_VER}.tgz

#WHERE CAN THE VERILATOR TARBALL BE DOWNLOADED FROM?
VERILATOR_TAR_URL=http://www.veripool.org/ftp/${VERLIATOR_TAR}

#WHERE SHOULD THE TARBALL BE STORED ONCE DOWNLOADED?
VERILATOR_TAR_PATH=${VERILATOR_REL_PATH}${VERLIATOR_TAR}

#WHAT C++ FILES ARE NEEDED FOR SIMULATION?
SIM_FILES=sim_main/sim_main.cpp sim_main/sm_heap.cpp sim_main/sm_memory.cpp sim_main/sm_syscalls.cpp sim_main/sm_elfload.cpp sim_main/elf/elf_reader.cpp sim_main/sm_regfile.cpp

#WHAT VERILOG FILES ARE NEEDED FOR SIMULATION?
VERILOG_FILES=$(wildcard verilog/*.v)

#WHERE IS THE VERILATOR BIN?
VERILATOR_BIN=${VERILATOR_DIR}/bin/verilator
SM_FLAGS=-O3
VFLAGS+=--autoflush -O4 -Wall -Wno-fatal

all: VMIPS

.PHONY : all

VMIPS : obj_dir/VMIPS
	cp obj_dir/VMIPS ./

obj_dir/VMIPS : obj_dir/VMIPS.mk ${SIM_FILES} ${VERILOG_FILES}
	$(MAKE) -C obj_dir -f VMIPS.mk VMIPS

obj_dir/VMIPS.mk : ${VERILATOR_BIN} ${SIM_FILES} ${VERILOG_FILES}
	VERILATOR_ROOT=$(shell pwd)/${VERILATOR_DIR} ${VERILATOR_BIN} ${VFLAGS} -CFLAGS "${SM_FLAGS}" -cc verilog/cpu_top.v -I./verilog/ --exe ${SIM_FILES}

${VERILATOR_BIN} : ${VERILATOR_DIR}/Makefile
	$(MAKE) -C ${VERILATOR_DIR}/src ${MAKEFLAGS}

${VERILATOR_DIR}/Makefile : ${VERILATOR_DIR}/configure
	cd ${VERILATOR_DIR} && ./configure --enable-prec11

${VERILATOR_DIR}/configure : ${VERILATOR_TAR_PATH}
	tar ${VERILATOR_UNTAR_OPTIONS} ${VERILATOR_TAR_PATH} -C ${VERILATOR_REL_PATH}
	touch ${VERILATOR_DIR}/configure

${VERILATOR_TAR_PATH} :
	wget ${VERILATOR_TAR_URL} -O ${VERILATOR_TAR_PATH} --no-check-certificate

.INTERMEDIATE : ${VERILATOR_TAR_PATH}

clean :
	rm -rf obj_dir VMIPS stdout.txt stderr.txt out.txt

clean_verilator :
	rm -rf ${VERILATOR_REL_PATH}verilator-*/
