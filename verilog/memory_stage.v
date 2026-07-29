module MEM(

	//MODULE INPUTS

		//EXE/MEM --> MEM
		input [31:0] 		MemWriteData_IN,
		input [5:0] 		MemControl_IN,	
		input 			MemRead_IN,	

		input [31:0] 		ALUResult_IN,	

		//DM --> MEM
		input [31:0] 		Data_IN,	

	//MODULE OUTPUTS

		//MEM --> MEM/WB
		output [31:0] 		WriteData_OUT,	

		//MEM --> DM		
		output [31:0] 		Data_OUT,		
		output [1:0]  		DataSize_OUT	

);

wire [31:0]	data_read_aligned;

assign WriteData_OUT 	= MemRead_IN ? data_read_aligned : ALUResult_IN;

/* TODO
 * Procedural assignment to wires is not in standard
 * Need to find a better way to represent this
 * Preventing using higher versions of verilator
 */
always begin

	data_read_aligned = MemWriteData_IN;

	//CASE STATEMENT FOR MEM CONTROL WORD
	case(MemControl_IN)

		//MEM CONTROL WORD: 33 (LB) 
		6'b100001: begin
		
			case (ALUResult_IN[1:0])
			
				0: data_read_aligned = {{24{Data_IN[31]}},Data_IN[31:24]};
				1: data_read_aligned = {{24{Data_IN[23]}},Data_IN[23:16]};
				2: data_read_aligned = {{24{Data_IN[15]}},Data_IN[15:8]};
				3: data_read_aligned = {{24{Data_IN[7]}},Data_IN[7:0]};
			
			endcase
			DataSize_OUT = 0;
		end

		//MEM CONTROL WORD: 42 (LBU)
		6'b101010: begin
			
			case (ALUResult_IN[1:0])
			
				0: data_read_aligned = {{24{1'b0}},Data_IN[31:24]};
				1: data_read_aligned = {{24{1'b0}},Data_IN[23:16]};
				2: data_read_aligned = {{24{1'b0}},Data_IN[15:8]};
				3: data_read_aligned = {{24{1'b0}},Data_IN[7:0]};
			
			endcase
			DataSize_OUT = 0;
		end

		//MEM CONTROL WORD: 43 (LH) 
		6'b101011: begin
		
			case(ALUResult_IN[1:0])
			
				0: data_read_aligned = {{16{Data_IN[31]}},Data_IN[31:16]};
				2: data_read_aligned = {{16{Data_IN[15]}},Data_IN[15:0]};
			
			endcase
			
			DataSize_OUT = 0;
		end

		//ALU CONTROL WORD: 44 (LHU)
		6'b101100: begin
			
			case(ALUResult_IN[1:0])

				0: data_read_aligned = {{16{1'b0}},Data_IN[31:16]};
				2: data_read_aligned = {{16{1'b0}},Data_IN[15:0]};
			
			endcase

			DataSize_OUT = 0;
		end

		//MEM CONTROL WORD: 45 (LWL)
		6'b101101: begin
			
			//CASE STATEMENT FOR ALU RESULT	
			case (ALUResult_IN[1:0])

				0: data_read_aligned 		= Data_IN;		//Aligned access; read everything
				1: data_read_aligned[31:8] 	= Data_IN[23:0];	//Mem:[3,2,1,0] => [2,1,0,8'h00]
				2: data_read_aligned[31:16] 	= Data_IN[15:0]; 	//Mem: [3,2,1,0] => [1,0,16'h0000]
				3: data_read_aligned[31:24] 	= Data_IN[7:0];		//Mem: [3,2,1,0] => [0,24'h000000]
			
			endcase

			DataSize_OUT = 0;
		end

		//MEM CONTROL WORD: 46 (LWR) 
		6'b101110: begin
			
			case (ALUResult_IN[1:0])
			
				0: data_read_aligned[7:0] 	= Data_IN[31:24];	//Mem:[3,2,1,0] => [2,1,0,8'h00]
				1: data_read_aligned[15:0] 	= Data_IN[31:16]; 	//Mem: [3,2,1,0] => [1,0,16'h0000]
				2: data_read_aligned[23:0] 	= Data_IN[31:8];	//Mem: [3,2,1,0] => [0,24'h000000]
				3: data_read_aligned 		= Data_IN;		//Aligned access; read everything
			
			endcase

			DataSize_OUT = 0;
		end

		//MEM CONTROL WORD: 53 (LW)
		6'b111101, 6'b101000, 6'b110101: begin
			
			data_read_aligned 	= Data_IN;
			DataSize_OUT 	= 0;
		
		end

		//MEM CONTROL WORD: 
		6'b101111: begin	//SB

			DataSize_OUT	= 1;
			Data_OUT[7:0] 	= MemWriteData_IN[7:0];
		end

		//MEM CONTROL WORD: 
		6'b110000: begin	//SH
			
			DataSize_OUT 	= 2;
			Data_OUT[15:0] 	= MemWriteData_IN[15:0];
		end
		
		//MEM CONTROL WORD: 
		6'b110001, 6'b110110: begin	//SW
			
			DataSize_OUT	= 0;
			Data_OUT 		= MemWriteData_IN;
		end
		
		//MEM CONTROL WORD: 
		6'b110010: begin	//SWL
			
			case(ALUResult_IN[1:0])

				0: begin 
					Data_OUT 		= MemWriteData_IN; 
					DataSize_OUT	= 0; 
				end

				1: begin 
					Data_OUT[23:0] 	= MemWriteData_IN[31:8]; 
					DataSize_OUT	= 3; 
				end

				2: begin 
					Data_OUT[15:0]	= MemWriteData_IN[31:16]; 
					DataSize_OUT	= 2; 
				end

				3: begin 
					Data_OUT[7:0] 	= MemWriteData_IN[31:24]; 
					DataSize_OUT	= 1; 
				end

			endcase
		end
		
		//MEM CONTROL WORD: 
		6'b110011: begin	//SWR
			
			case(ALUResult_IN[1:0])
				
				0: begin 
					Data_OUT[7:0] 	= MemWriteData_IN[7:0]; 
					DataSize_OUT	= 1; 
				end

				1: begin 
					Data_OUT[15:0] 	= MemWriteData_IN[15:0]; 
					DataSize_OUT	= 2; 
				end
				
				2: begin 
					Data_OUT[23:0] 	= MemWriteData_IN[23:0]; 
					DataSize_OUT	= 3; 
				end

				3: begin 
					Data_OUT 		= MemWriteData_IN; 
					DataSize_OUT	= 0; 
				end

			endcase
		end

		//ALU CONTROL WORD: DEFAULT
		default: begin
			
			data_read_aligned 	= Data_IN;
			DataSize_OUT	= 0;
		
		end

	endcase

end

endmodule
