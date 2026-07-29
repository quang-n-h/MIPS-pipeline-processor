module NextInstructionCalculator(

	//MODULE INPUTS

		input [31:0] 	InstructionAddressPlus4_IN,	/* PC of the current instruction + 4*/

		input [15:0] 	Immediate_IN,
		input [25:0]	Index_IN,

		input 		Jump_IN,			/* Whether this instruction is a jump */
		input 		JumpRegister_IN,		/* Whether this is a jump register instruction */
		input [31:0] 	RegisterValue_IN,		/* If this is a jump register instruction, the value of the register (jump destination)*/

	//MODULE OUTPUTS

		output [31:0] 	NextInstructionAddress_OUT	/* Where we need to jump to */

);

wire [31:0] signExtended_shifted_immediate;
wire [31:0] jumpDestination_immediate;
wire [31:0] branchDestination_immediate;

assign signExtended_shifted_immediate 	= {{14{Immediate_IN[15]}},Immediate_IN,2'b00};
assign jumpDestination_immediate 	= {InstructionAddressPlus4_IN[31:28],Index_IN,2'b00};
assign branchDestination_immediate 	= InstructionAddressPlus4_IN + signExtended_shifted_immediate;

assign NextInstructionAddress_OUT 	= Jump_IN ? ( JumpRegister_IN ? RegisterValue_IN : jumpDestination_immediate ) : branchDestination_immediate;

endmodule
