module EXE(

	//MODULE INPUTS
	
		//CONTROL SIGNALS
		input CLOCK,
		input RESET,		

		//ID/EXE --> EXE
		input [31:0] 	OperandA_IN,		
		input [31:0] 	OperandB_IN,		
		input [5:0]  	ALUControl_IN,		
		input [4:0]  	ShiftAmount_IN,		
	
	//MODULE OUTPUT

		//EXE --> EXE/MEM
		output [31:0] 	ALUResult_OUT		

);

reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;

wire [31:0] newHI;
wire [31:0] newLO;

ALU ALU(

	//MODULE INPUTS
	.HI_IN(HI),
	.LO_IN(LO),
	.OperandA_IN(OperandA_IN), 
	.OperandB_IN(OperandB_IN), 
	.ALUControl_IN(ALUControl_IN), 
	.ShiftAmount_IN(ShiftAmount_IN), 

	//MODULE OUTPUTS
	.ALUResult_OUT(ALUResult_OUT),
	.HI_OUT(newHI),
	.LO_OUT(newLO)

);

//ON THE RISING EDGE OF THE CLOCK OR FALLING EDGE OF RESET
always @(posedge CLOCK or negedge RESET) begin

	//IF THE MODULE HAS BEEN RESET
	if(!RESET) begin

		HI <= 0;
		LO <= 0;

	//ELSE IF THE CLOCK HAS RISEN
	end else if(CLOCK) begin

		HI <= newHI;
		LO <= newLO;

		$display("");
		$display("----- EXE -----");
		$display("HI:\t%x", HI);
		$display("LO:\t%x", LO);

	end

end

endmodule
