module ALU(

	//MODULE INPUTS
	
		input [31:0] 	HI_IN,
		input [31:0] 	LO_IN,
		input [31:0] 	OperandA_IN,
		input [31:0] 	OperandB_IN,
		input [5:0] 	ALUControl_IN,
		input [4:0] 	ShiftAmount_IN,
	
	//MODULE OUTPUTS
	
		output [31:0] 	ALUResult_OUT,
		output [31:0] 	HI_OUT,
		output [31:0] 	LO_OUT
);

//TEMPORARY WIRES USED FOR CALCULATION
wire [63:0] temp;

//DEFAULT HI AND LO TO BE UNCHANGED
assign HI_OUT = HI_IN;
assign LO_OUT = LO_IN;

//RENAMED FOR READABILITY
wire [31:0] A = OperandA_IN;
wire [31:0] B = OperandB_IN;

//USED FOR BLOCK ASSIGNMENT
/* TODO
 * Procedural assignment to wires is not in standard
 * Need to find a better way to represent this
 * Preventing using higher versions of verilator
 */
always begin

	//CASE STATEMENT FOR ALU CONTROL WORD
	/* verilator lint_off BLKSEQ */
	case(ALUControl_IN) 
	
		//ALU CONTROL WORD: 0, 1, 2, 3, 53, 55 
		6'b000000,6'b000010,6'b000001,6'b000011,6'b110111,6'b110101:begin 
			
			ALUResult_OUT = A + B; 
			
		end
			
		//ALU CONTROL WORD: 4
		6'b000100:begin
		
			ALUResult_OUT = A & B;
			
		end
		
		//ALU CONTROL WORD: 5
		6'b000101:begin
		
			if(B != 0) begin
			
				LO_OUT[31] = A[31] | B[31];	
				LO_OUT[30:0] = A[30:0] / B[30:0];	
				HI_OUT[30:0] = A[30:0] % B[30:0];

				LO_OUT = $signed(A) / $signed(B);
				HI_OUT = $signed(A) % $signed(B);
		
			end
		end
		
		//ALU CONTROL WORD: 6
		6'b000110:begin
		
			if(B!=0)begin
			
				LO_OUT = A / B;
				HI_OUT = A % B;
				
			end
		end

		//ALU CONTROL WORD: 8		
		6'b001000:begin 
			
			ALUResult_OUT = {B[15:0],16'b0};
			
		end
		
		//ALU CONTROL WORD: 9
		6'b001001:begin 
			
			ALUResult_OUT = HI_IN; 
			
		end
		
		//ALU CONTROL WORD: 10
		6'b001010:begin 
		
			ALUResult_OUT = LO_IN;
			
		end
		
		//ALU CONTROL WORD: 11
		6'b001011:begin 
			
			HI_OUT = A;
			
		end
		
		//ALU CONTROL WORD: 12
		6'b001100:begin 
		
			LO_OUT = A;
			
		end
		
		//ALU CONTROL WORD: 13
		6'b001101:begin
		
			temp[63:0] = A * B;
			HI_OUT = temp[63:32];
			LO_OUT = temp[31:0];
			
		end
		
		//ALU CONTROL WORD: 15
		6'b001111:begin 
			
			ALUResult_OUT = ~(A | B);
			
		end
		
		//ALU CONTROL WORD: 16
		6'b010000:begin 
			
			ALUResult_OUT = A | B; 
			
		end
		
		//ALU CONTROL WORD: 19
		6'b010011:begin 
			
			ALUResult_OUT = B << ShiftAmount_IN; 
			
		end
		
		//ALU CONTROL WORD: 20
		6'b010100:begin 
			
			ALUResult_OUT = B << A;
			
		end
		
		//ALU CONTROL WORD: 21
		6'b010101:begin
		
			if( A[31] < B[31] ) begin
			
				ALUResult_OUT = 0;
			
			end else if( A[30:0] > B[30:0] ) begin
			
				ALUResult_OUT = 0;
			
			end else if( A == B ) begin
				
				ALUResult_OUT = 0;	
			
			end else begin 
				
				ALUResult_OUT = 1;
			
			end
		end
		
		//ALU CONTROL WORD: 25
		6'b011001:begin
			
			temp[32]=B[31];
			temp[31:0] = {B[31:0] >> ShiftAmount_IN};
			temp[31]=temp[32];
			if(ShiftAmount_IN>=1)temp[30]=temp[32];
			if(ShiftAmount_IN>=2)temp[29]=temp[32];
			if(ShiftAmount_IN>=3)temp[28]=temp[32];
			if(ShiftAmount_IN>=4)temp[27]=temp[32];
			if(ShiftAmount_IN>=5)temp[26]=temp[32];
			if(ShiftAmount_IN>=6)temp[25]=temp[32];
			if(ShiftAmount_IN>=7)temp[24]=temp[32];
			if(ShiftAmount_IN>=8)temp[23]=temp[32];
			if(ShiftAmount_IN>=9)temp[22]=temp[32];
			if(ShiftAmount_IN>=10)temp[21]=temp[32];
			if(ShiftAmount_IN>=11)temp[20]=temp[32];
			if(ShiftAmount_IN>=12)temp[19]=temp[32];
			if(ShiftAmount_IN>=13)temp[18]=temp[32];
			if(ShiftAmount_IN>=14)temp[17]=temp[32];
			if(ShiftAmount_IN>=15)temp[16]=temp[32];
			if(ShiftAmount_IN>=16)temp[15]=temp[32];
			if(ShiftAmount_IN>=17)temp[14]=temp[32];
			if(ShiftAmount_IN>=18)temp[13]=temp[32];
			if(ShiftAmount_IN>=19)temp[12]=temp[32];
			if(ShiftAmount_IN>=20)temp[11]=temp[32];
			if(ShiftAmount_IN>=21)temp[10]=temp[32];
			if(ShiftAmount_IN>=22)temp[9]=temp[32];
			if(ShiftAmount_IN>=23)temp[8]=temp[32];
			if(ShiftAmount_IN>=24)temp[7]=temp[32];
			if(ShiftAmount_IN>=25)temp[6]=temp[32];
			if(ShiftAmount_IN>=26)temp[5]=temp[32];
			if(ShiftAmount_IN>=27)temp[4]=temp[32];
			if(ShiftAmount_IN>=28)temp[3]=temp[32];
			if(ShiftAmount_IN>=29)temp[2]=temp[32];
			if(ShiftAmount_IN>=30)temp[1]=temp[32];
			if(ShiftAmount_IN>=31)temp[0]=temp[32];
			ALUResult_OUT = temp[31:0];

		end
			
		//ALU CONTROL WORD: 26
		6'b011010:begin
		
			temp[32]=B[31];
			temp[31:0] = {B[31:0] >> (A[4:0])};
			temp[31]=temp[32];
			if(1<=A[4:0])temp[30]=temp[32];
			if(2<=A[4:0])temp[29]=temp[32];
			if(3<=A[4:0])temp[28]=temp[32];
			if(4<=A[4:0])temp[27]=temp[32];
			if(5<=A[4:0])temp[26]=temp[32];
			if(6<=A[4:0])temp[25]=temp[32];
			if(7<=A[4:0])temp[24]=temp[32];
			if(8<=A[4:0])temp[23]=temp[32];
			if(9<=A[4:0])temp[22]=temp[32];
			if(10<=A[4:0])temp[21]=temp[32];
			if(11<=A[4:0])temp[20]=temp[32];
			if(12<=A[4:0])temp[19]=temp[32];
			if(13<=A[4:0])temp[18]=temp[32];
			if(14<=A[4:0])temp[17]=temp[32];
			if(15<=A[4:0])temp[16]=temp[32];
			if(16<=A[4:0])temp[15]=temp[32];
			if(17<=A[4:0])temp[14]=temp[32];
			if(18<=A[4:0])temp[13]=temp[32];
			if(19<=A[4:0])temp[12]=temp[32];
			if(20<=A[4:0])temp[11]=temp[32];
			if(21<=A[4:0])temp[10]=temp[32];
			if(22<=A[4:0])temp[9]=temp[32];
			if(23<=A[4:0])temp[8]=temp[32];
			if(24<=A[4:0])temp[7]=temp[32];
			if(25<=A[4:0])temp[6]=temp[32];
			if(26<=A[4:0])temp[5]=temp[32];
			if(27<=A[4:0])temp[4]=temp[32];
			if(28<=A[4:0])temp[3]=temp[32];
			if(29<=A[4:0])temp[2]=temp[32];
			if(30<=A[4:0])temp[1]=temp[32];
			if(31<=A[4:0])temp[0]=temp[32];
			ALUResult_OUT = temp[31:0];
			
		end
		
		//ALU CONTROL WORD: 27
		6'b011011:begin 
			
			ALUResult_OUT = (B[31:0] >> ShiftAmount_IN);
			
		end
		
		//ALU CONTROL WORD: 28
		6'b011100:begin
		
			temp[31:0] = (B[31:0] >> A[4:0]);
			ALUResult_OUT = temp[31:0];
			
		end
		
		//ALU CONTROL WORD: 29, 30
		6'b011101,6'b011110:begin 
			
			ALUResult_OUT = A - B;
			
		end
		
		//ALU CONTROL WORD: 31, 32
		6'b011111,6'b100000:begin 
			
			ALUResult_OUT = A ^ B;
			
		end
		
		//ALU CONTROL WORD: 33, 40, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 54, 57, 61 (LW) 
		6'b100001,6'b101000,6'b101010,6'b101011,6'b101100,6'b101101,6'b101110,6'b101111,6'b110000,6'b110001,6'b110010,6'b110011,6'b110110,06'b111001,6'b111101:begin
			
			ALUResult_OUT = A+{{16{B[15]}},B[15:0]};
			
		end
		
		//ALU CONTROL WORD: 52, 56
		6'b110100,6'b111000:begin 
			
			ALUResult_OUT = B;
			
		end
			
		//ALU CONTROL WORD: 63
		6'b111111:begin
		
			if( A[31:0] > B[31:0] ) ALUResult_OUT = 0;	//A is greater than B
			else if( A == B ) ALUResult_OUT = 0;	//A is equal to B
			else ALUResult_OUT = 1;	//A must be less than B
		
		end

		//ALU CONTROL WORD: Default
		default:begin 
		
			ALUResult_OUT = 0;
			
		end

	endcase
	/* verilator lint_on BLKSEQ */

end

endmodule
