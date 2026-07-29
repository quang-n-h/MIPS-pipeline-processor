module EXEMEM(

	//MODULE INPUTS
		
		//SYSTEM --> EXE/MEM
		input CLOCK,
		input RESET,

		//HAZARD --> EXE/MEM
		input STALL,
		input FLUSH,

		//ID/EXE --> EXE/MEM (MEM INFORMATION)
		input [31:0] 	MemWriteData_IN,
		input [5:0] 	MemControl_IN,
		input 		MemRead_IN,
		input 		MemWrite_IN,

		//ID/EXE --> EXE/MEM (WB INFORMATION)
		input [31:0] 	ALUResult_IN,
		input [4:0]  	WriteRegister_IN,
		input 		WriteEnable_IN,

	// MODULE OUTPUTS

		//EXE/MEM --> MEM
		output [31:0] 	MemWriteData_OUT,
		output [5:0] 	MemControl_OUT,
		output 		MemRead_OUT,
		output 		MemWrite_OUT,

		//EXE/MEM --> MEM/WB (WB INFORMATION)
		output [31:0] 	ALUResult_OUT,
		output [4:0]  	WriteRegister_OUT,
		output 		WriteEnable_OUT

);

//PIPELINE REGISTERS
reg [31:0] 	MemWriteData;
reg [5:0]	MemControl;
reg 		MemRead;
reg 		MemWrite;

reg [31:0] 	ALUResult;
reg [4:0] 	WriteRegister;
reg 		WriteEnable;

//ASSIGN OUTPUTS TO PIPELINE REGISTERS 
assign MemWriteData_OUT 	= MemWriteData;
assign MemControl_OUT 		= MemControl;
assign MemRead_OUT 		= MemRead;
assign MemWrite_OUT 		= MemWrite;

assign ALUResult_OUT 		= ALUResult;
assign WriteRegister_OUT 	= WriteRegister;
assign WriteEnable_OUT 		= WriteEnable;

//WHEN CLOCK RISES OR RESET FALLS
always @(posedge CLOCK or negedge RESET) begin

	//IF RESET IS LOW
	if(!RESET) begin

		//SET PIPELINE REGISTERS TO 0
		MemWriteData 	<= 0;
		MemControl 	<= 0;
		MemRead 	<= 0;				
		MemWrite 	<= 0;

		ALUResult 	<= 0;
		WriteRegister 	<= 0;
		WriteEnable 	<= 0;

	//ELSE IF CLOCK IS HIGH
	end else if(CLOCK) begin

		$display("");
		$display("----- EXE/MEM -----");
		$display("MemWriteData:\t\t%x", MemWriteData);
		$display("MemControl:\t\t%d", MemControl);
		$display("MemRead:\t\t%b", MemRead);
		$display("MemWrite:\t\t%b", MemWrite); 
		$display("");
		$display("ALUResult:\t\t%x", ALUResult);
		$display("WriteRegister:\t\t%d", WriteRegister);
		$display("WriteEnable:\t\t%b", WriteEnable);

		//IF MODULE IS NOT BEING STALLED AND IS NOT BEING FLUSHED
		if(!STALL && !FLUSH) begin

			//SET PIPELINE REGISTERS TO INPUTS
			MemWriteData 	<= MemWriteData_IN;	
			MemControl 	<= MemControl_IN;
			MemRead 	<= MemRead_IN;
			MemWrite 	<= MemWrite_IN;
			
			ALUResult 	<= ALUResult_IN;
			WriteRegister 	<= WriteRegister_IN;
			WriteEnable 	<= WriteEnable_IN;

		//ELSE IF MODULE IS BEING FLUSHED
		end else if (FLUSH) begin
	
			//SET PIPELINE REGISTERS TO ZERO
			MemWriteData 	<= 0;
			MemControl 	<= 0;
			MemRead 	<= 0;				
			MemWrite 	<= 0;

			ALUResult 	<= 0;
			WriteRegister 	<= 0;
			WriteEnable 	<= 0;

		//ELSE IF MODULE IS BEING STALLED
		end else if (STALL) begin

			//DO NOTHING

		end

	end

end

endmodule
