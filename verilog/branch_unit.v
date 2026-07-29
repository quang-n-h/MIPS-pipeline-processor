module Compare(	

	//MODULE INPUTS
	
		input 		Jump_IN,
		input [5:0]	Opcode_IN,
	      	input [4:0]	RegisterRT_IN,	
		input [31:0] 	OperandA_IN,
		input [31:0] 	OperandB_IN,

	//MODULE OUTPUTS
	
		output Taken_OUT

);

wire 	BranchTaken;				
assign 	Taken_OUT = BranchTaken | Jump_IN;	

/* TODO
 * Procedural assignment to wires is not in standard
 * Need to find a better way to represent this
 * Preventing using higher versions of verilator
 */
always begin
	
	//CASE STATEMENT FOR OPCODE
	case(Opcode_IN)
		
		//OPCODE: 1 (REGIMM)
		6'b000001:begin

			//CASE STATEMENT FOR RT
			case(RegisterRT_IN)
				
				//RT: 0, 16 (BLTZ, BTZAL)
				5'b00000,5'b10000:begin
				
					//BRANCH IS TAKEN IF OPERAND A IS NEGATIVE
					BranchTaken = (OperandA_IN[31] == 1) ? 1'b1 : 1'b0;

				end				
				
				//RT: 1, 17 (BGEZ, BGEZAL)
				5'b00001,5'b10001:begin

					//BRANCH IS TAKEN IF OPERAND A IS POSITIVE OR ZERO
					BranchTaken = (OperandA_IN[31] == 0) ? 1'b1 : 1'b0;	
	
				end

				//RT: NOT A BRANCH INSTRUCTION
				default:begin
					
					//BRANCH IS NOT TAKEN
					BranchTaken = 1'b0;

				end

			endcase
		end

		//OPCODE: 4 (BEQ)			
		6'b000100:begin

			//BRANCH IS TAKEN IF OPERAND A AND OPERAND B ARE EQUAL
			BranchTaken = (OperandA_IN == OperandB_IN) ? 1'b1 : 1'b0;

		end

		//OPCODE: 5 (BNE)
		6'b000101:begin

			//BRANCH IS TAKEN IF OPERAND A AND OPERAND B ARE NOT EQUAL
			BranchTaken = (OperandA_IN != OperandB_IN) ? 1'b1 : 1'b0;

		end
		
		//OPCODE: 6 (BLEZ)
		6'b000110:begin
		
			//BRANCH IS TAKEN IF OPERAND A IS NEGATIVE OR ZERO
			BranchTaken = ((OperandA_IN[31] == 1) || (OperandA_IN == 0)) ? 1'b1 : 1'b0;

		end

		//OPCODE: 7 (BGTZ)
		6'b000111: begin

			//BRANCH IS TAKEN IF OPERAND A IS POSITIVE AND NOT ZERO
			BranchTaken = ((OperandA_IN[31] == 0) && (OperandA_IN != 0)) ? 1'b1 : 1'b0;

		end

		//OPCODE: NOT A BRANCH INSTRUCTION
		default: begin

			//BRANCH IS NOT TAKEN
			BranchTaken = 1'b0;

		end

	endcase

end

endmodule

