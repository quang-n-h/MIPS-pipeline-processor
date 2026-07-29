module MEMWB(

	//MODULE INPUTS
	
		//SYSTEM --> MEM/WB
		input CLOCK,
		input RESET,

		//HAZARD --> MEM/WB
		input STALL,
		input FLUSH,

		//MEM --> MEM/WB
		input [31:0] 	WriteData_IN,

		//EXE/MEM --> MEM/WB
		input [4:0] 	WriteRegister_IN,
		input 		WriteEnable_IN,

	//MODULE OUTPUTS

		//MEM/WB --> ID
		output [31:0] 	WriteData_OUT,
		output [4:0]  	WriteRegister_OUT,
		output 		WriteEnable_OUT

);

//PIPELINE REGISTERS
reg [31:0] 	WriteData;
reg [4:0]  	WriteRegister;
reg 		WriteEnable;

//ASSIGN OUTPUTS TO PIPELINE REGISTERS
assign WriteData_OUT 		= WriteData;
assign WriteRegister_OUT 	= WriteRegister;
assign WriteEnable_OUT 		= WriteEnable;

//WHEN CLOCK RISES OR RESET FALLS
always @(posedge CLOCK or negedge RESET) begin

	$display("");
	$display("----- MEM/WB Register -----");
	$display("WriteData:\t\t\t%x", WriteData);
	$display("WriteRegister:\t\t%d", WriteRegister);
	$display("WriteEnable:\t\t%d", WriteEnable);

	//IF RESET IS LOW
	if(!RESET) begin

		//SET PIPELINE REGISTERS TO 0
		WriteData 	<= 0;
		WriteRegister 	<= 0;
		WriteEnable 	<= 0;

	//ELSE IF CLOCK IS HIGH
	end else if(CLOCK) begin

		//IF MODULE IS NOT BEING STALLED AND IS NOT BEING FLUSHED
		if(!STALL && !FLUSH) begin

			//SET PIPELINE REGISTERS TO INPUTS
			WriteData 	<= WriteData_IN;
			WriteRegister 	<= WriteRegister_IN;
			WriteEnable 	<= WriteEnable_IN;

		//ELSE IF MODULE IS BEING FLUSHED
		end else if(FLUSH) begin
	
			//SET PIPELINE REGISTERS TO 0
			WriteData 	<= 0;
			WriteRegister 	<= 0;
			WriteEnable 	<= 0;
	
		// ELSE IF MODULE IS BEING STALLED
		end else if(STALL) begin

			//DO NOTHING

		end

	end

end

endmodule
