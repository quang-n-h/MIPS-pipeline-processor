module IFID(

	//MODULE INPUTS

		//SYSTEM --> IF/ID
		input CLOCK,
		input RESET,

		//HAZARD --> IF/ID
		input STALL,
		input FLUSH,
		
		//IM --> IF/ID
		input [31:0] 	Instruction_IN,	

		//IF --> IF/ID
		input [31:0] 	InstructionAddressPlus4_IN,

	//MODULE OUTPUTS

		//IF/ID --> ID
		output [31:0] Instruction_OUT,
		output [31:0] InstructionAddressPlus4_OUT

);

//PIPELINE REGISTERS
reg [31:0] Instruction;
reg [31:0] InstructionAddressPlus4;

//ASSIGN OUTPUTS TO PIPELINE REGISTERS
assign Instruction_OUT 			= Instruction;
assign InstructionAddressPlus4_OUT 	= InstructionAddressPlus4;

//WHEN CLOCK RISES OR RESET FALLS
always @(posedge CLOCK or negedge RESET) begin

	//IF RESET IS LOW
	if(!RESET) begin

		//SET PIPELINE REGISTERS TO 0
		Instruction 		<= 0;			
		InstructionAddressPlus4 <= 0;	

	//ELSE IF CLOCK IS HIGH
	end else if(CLOCK) begin

		$display("");
		$display("----- IF/ID -----");
		$display("Instruction:\t\t\t%x", Instruction);
		$display("Instruction Address + 4:\t%x", InstructionAddressPlus4);

		//IF MODULE IS NOT BEING STALLED AND IS NOT BEING FLUSHED 
		if(!STALL && !FLUSH) begin

			//SET PIPELINE REGISTERS TO INPUTS
			Instruction 		<= Instruction_IN;
			InstructionAddressPlus4 <= InstructionAddressPlus4_IN;

		//ELSE IF MODULE IS BEING FLUSHED
		end else if (FLUSH) begin

			//SET PIPELINE REGISTERS TO 0
			Instruction 		<= 0;
			InstructionAddressPlus4 <= 0;

		//ELSE IF MODULE IS BEING STALLED
		end else if (STALL) begin

			//DO NOTHING

		end

	end

end

endmodule
