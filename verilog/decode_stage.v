module ID(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		input CLOCK,
		input RESET,
		
		//IF/ID --> ID
		input [31:0] 	Instruction_IN, 		
		input [31:0] 	InstructionAddressPlus4_IN,	

		//MEM/WB --> ID
		input [31:0] 	WriteData_IN,			
 		input [4:0] 	WriteRegister_IN,		
		input 		WriteEnable_IN,			
	
	//MODULE OUTPUTS


		//ID --> IF
		output [31:0]  	AltPC_OUT,			
    		output 	  	AltPCEnable_OUT,	
	
		//ID --> ID/EXE
		output [31:0] 	OperandA_OUT,			
     		output [31:0] 	OperandB_OUT,			
		output [5:0] 	ALUControl_OUT,				
    		output [4:0]  	ShiftAmount_OUT,		

     		output [31:0] 	MemWriteData_OUT,		
		output 	 	MemRead_OUT,			
		output 	 	MemWrite_OUT,			

		output [4:0]  	WriteRegister_OUT,		
		output 	 	WriteEnable_OUT,				

		//ID --> SYSTEM
		output 		Syscall_OUT

);

wire [5:0]	Opcode;
wire [25:0]	Index;
wire [4:0]     	RegisterRS;    
wire [4:0]      RegisterRT;
wire [4:0]     	RegisterRD;
wire [15:0]    	Immediate;
wire [4:0]	ShiftAmount;

assign 	Opcode 		= Instruction_IN[31:26];
assign 	Index		= Instruction_IN[25:0];
assign 	RegisterRS 	= Instruction_IN[25:21];
assign 	RegisterRT 	= Instruction_IN[20:16];
assign 	RegisterRD 	= Instruction_IN[15:11];
assign 	Immediate 	= Instruction_IN[15:0];
assign 	ShiftAmount 	= Instruction_IN[10:6];

wire [31:0]    	RegisterRSValue;
wire [31:0]    	RegisterRTValue;

RegFile RegFile(

	//MODULE INPUTS
		
		//SYSTEM --> RegFile
		.CLOCK(CLOCK),
		.RESET(RESET),
	
		.WriteData_IN(WriteData_IN),
		.WriteEnable_IN(WriteEnable_IN),
		.WriteRegister_IN(WriteRegister_IN),

		.ReadRegister1_IN(RegisterRS),
		.ReadRegister2_IN(RegisterRT),

	//MODULE OUTPUTS

		.ReadData1_OUT(RegisterRSValue),
		.ReadData2_OUT(RegisterRTValue)
    
);

wire		Link;			
wire		RegDest;		
wire		Jump;			
wire		Branch;			
wire		MemRead;		
wire		MemWrite;		
wire		RegWrite;		
wire		JumpRegister;		
wire		SignOrZero;		
wire		Syscall;		
wire [5:0]	ALUControl;		

Decoder Decoder(

	//MODULE INPUTS
			
		.Instruction_IN(Instruction_IN), 
	
	//MODULE OUTPUTS
	
    		.Link(Link), 
    		.RegDest(RegDest), 
    		.Jump(Jump), 
    		.Branch(Branch), 
    		.MemRead(MemRead), 
    		.MemWrite(MemWrite), 
    		.RegWrite(RegWrite), 
    		.JumpRegister(JumpRegister), 
    		.SignOrZero(SignOrZero), 
    		.Syscall(Syscall), 
    		.ALUControl(ALUControl),
		/* verilator lint_off PINCONNECTEMPTY */
    		.MultRegAccess(),   	
    		.ALUSrc() 
		/* verilator lint_on PINCONNECTEMPTY */

);

wire AltPCEnable;

Compare Compare(

	//MODULE INPUTS
	
		.Jump_IN(Jump), 
		.OperandA_IN(RegisterRSValue),
    		.OperandB_IN(RegisterRTValue),
		.Opcode_IN(Opcode),
	      	.RegisterRT_IN(RegisterRT),

	//MODULE OUTPUTS

    		.Taken_OUT(AltPCEnable)

);

wire [31:0] AltPC;

NextInstructionCalculator NextInstructionCalculator(

	//MODULE INPUTS

		.Immediate_IN(Immediate),
		.Index_IN(Index),
    		.InstructionAddressPlus4_IN(InstructionAddressPlus4_IN),
    		.Jump_IN(Jump), 
    		.JumpRegister_IN(JumpRegister), 
    		.RegisterValue_IN(RegisterRSValue), 

	//MODULE OUTPUTS
    	
		.NextInstructionAddress_OUT(AltPC)

);

wire [31:0]    	SignExtendedImmediate;
wire [31:0]    	ZeroExtendedImmediate; 

assign 	SignExtendedImmediate 	= {{16{Immediate[15]}},Immediate};
assign 	ZeroExtendedImmediate 	= {{16{1'b0}},Immediate};

//ASSIGNMENT OF MODULE OUTPUTS
assign OperandA_OUT 		= Link ? 0 : RegisterRSValue;
assign OperandB_OUT 		= Branch ? (Link ? (InstructionAddressPlus4_IN + 4) : RegisterRTValue ) : ( RegDest ? RegisterRTValue : ( SignOrZero ? SignExtendedImmediate : ZeroExtendedImmediate ));
assign ALUControl_OUT 		= ALUControl;
assign ShiftAmount_OUT 		= ShiftAmount;
assign MemWriteData_OUT 	= RegisterRTValue;
assign MemRead_OUT 		= MemRead;
assign MemWrite_OUT 		= MemWrite;
assign WriteRegister_OUT 	= RegDest ? RegisterRD : (Link ? 5'd31 : RegisterRT);
assign WriteEnable_OUT 		= (WriteRegister_OUT != 5'd0) ? RegWrite : 1'd0;
assign AltPCEnable_OUT 		= AltPCEnable;
assign AltPC_OUT 		= AltPC;
assign Syscall_OUT 		= Syscall;

endmodule
