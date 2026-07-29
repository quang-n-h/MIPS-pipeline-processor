//-----------------------------------------
//		Register File
//
//	Cleaned by B.C. Heyman
//-----------------------------------------

module RegFile(

	// MODULE INPUTS
	
		input CLOCK,
		input RESET,

		input [4:0]  	ReadRegister1_IN,
		input [4:0]	ReadRegister2_IN,

		input [31:0] 	WriteData_IN,	
		input [4:0]  	WriteRegister_IN,
		input 		WriteEnable_IN,

	// MODULE OUTPUTS

		output [31:0] 	ReadData1_OUT,
		output [31:0] 	ReadData2_OUT

);

reg [31:0] Reg [0:31]/*verilator public*/;

// ASSIGN DATA OUTPUTS TO CONTENTS OF SPECIFIED REGISTER
assign ReadData1_OUT = Reg[ReadRegister1_IN];
assign ReadData2_OUT = Reg[ReadRegister2_IN];

// WHEN THE CLOCK RISES OR THE RESET FALLS
always @(posedge CLOCK or negedge RESET) begin

	// IF RESET IS LOW
	if (!RESET) begin

		// SET ALL REGISTERS TO ZERO
		Reg[0] <= 0;
		Reg[1] <= 0;
		Reg[2] <= 0;
		Reg[3] <= 0;
		Reg[4] <= 0;
		Reg[5] <= 0;
		Reg[6] <= 0;
		Reg[7] <= 0;
		Reg[8] <= 0;
		Reg[9] <= 0;
		Reg[10] <= 0;
		Reg[11] <= 0;
		Reg[12] <= 0;
		Reg[13] <= 0;
		Reg[14] <= 0;
		Reg[15] <= 0;
		Reg[16] <= 0;
		Reg[17] <= 0;
		Reg[18] <= 0;
		Reg[19] <= 0;
		Reg[20] <= 0;
		Reg[21] <= 0;
		Reg[22] <= 0;
		Reg[23] <= 0;
		Reg[24] <= 0;
		Reg[25] <= 0;
		Reg[26] <= 0;
		Reg[27] <= 0;
		Reg[28] <= 0;
		Reg[29] <= 0;
		Reg[30] <= 0;
		Reg[31] <= 0;

	// ELSE IF CLOCK IS HIGH
	end else if (CLOCK) begin

		// IF WRITING IS ENABLED
		if (WriteEnable_IN) begin

			// WRITE 'WriteData_IN' TO REGISTER 'WriteRegister_IN'
			Reg[WriteRegister_IN] <= WriteData_IN;
	
		end

	end

end

endmodule
