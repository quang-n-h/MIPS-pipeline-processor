module Decoder(

	//MODULE INPUTS
	
		//ID --> Decoder
		/* verilator lint_off UNUSED */	
		input [31:0] Instruction_IN,		//INSTRUCTION TO BE DECODED
		/* verilator lint_on UNUSED */

	//MODULE OUTPUTS
	
		//Decoder --> ID
		output 		Link,		//Is this instruction an "And Link" instruction?
    		output 		RegDest,	//Does this instruction write to RD?
    		output 		Jump,		//Is this a jump instruction?			
    		output 		Branch,		//Is this a branch instruction?
    		output 		MemRead,	//Does this instruction read from memory?
    		output 		MemWrite,	//Does this instruction write to memory?
    		output 		ALUSrc,		//Does this instruction use an immediate as an input to the ALU?
    		output 		RegWrite,	//Does this instruction write to a register?
   		output 		JumpRegister,	//Does this instruction jump to a location in a register?
    		output 		SignOrZero,	//Should the immediate be sign extended (1) or zero extended (0)?
    		output 		Syscall,	//Is this instruction a syscall?
    		output [5:0] 	ALUControl,	//What operation should the ALU perform?
		output [1:0] 	MultRegAccess	//Does this instruction access HI/LO?

);

wire [5:0] Opcode;
wire [4:0] Format;
wire [4:0] rt;
wire [5:0] Funct;
	
assign 	Opcode 	= Instruction_IN[31:26];
assign 	Format 	= Instruction_IN[25:21];
assign 	rt 	= Instruction_IN[20:16];
assign 	Funct 	= Instruction_IN[5:0];

/* TODO
 * Procedural assignment to wires is not in standard
 * Need to find a better way to represent this
 * Preventing using higher versions of verilator
 */
always begin
	
	//CASE STATEMENT FOR OP CODE
	case(Opcode)
        	
		//OPCODE: 0 (SPECIAL)
		6'b000000: begin
			
			//CASE STATEMENT FOR FUNCTION
            		case(Funct)
				
				//FUNCTION: 0 (SLL)
                		6'b000000:begin 
					
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001001100; 
				
				end

				//FUNCTION: 2 (SRL)
                		6'b000010:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001101100; 

				end

				//FUNCTION: 3 (SRA)
                		6'b000011:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001100100; 

				end

				//FUNCTION: 4 (SLLV)
                		6'b000100:begin 
		
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001010000;

				end
                		
				//FUNCTION: 6 (SRLV)
				6'b000110:begin

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001110000;

				end
                		
				//FUNCTION: 7 (SRAV)
				6'b000111:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001101000;

				end
				
				//FUNCTION: 8 (JR)
				6'b001000:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0011000010011111000;

				end
				
				//FUNCTION: 9 (JALR)
				6'b001001:begin 
			
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b1111001110000000100;

				end
                		
				//FUNCTION: 12 (SYSCALL)
				6'b001100:begin
	
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101100001100;

				end
         
				//FUNCTION: 13 (BREAK)
				6'b001101:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100001100001001100;

				end
                		
				//FUNCTION: 16 (MFHI)
				6'b010000:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100000100110;

				end
                		
				//FUNCTION: 17 (MTHI)
				6'b010001:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000000000000101110;

				end
                		
				//FUNCTION: 18 (MFLO)
				6'b010010:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100000101001;

				end
                		
				//FUNCTION: 19 (MTLO)
				6'b010011:begin 
					
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000000000000110001; 
				
				end
				
				//FUNCTION: 24 (MULT)
				6'b011000:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000000000110111; 
				
				end
				
				//FUNCTION: 25 (MULTU)
				6'b011001:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000000000110111; 
				
				end
				
				//FUNCTION: 26 (DIV)
				6'b011010:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000000000010111; 
				
				end
				
				//FUNCTION: 27 (DIVU)
				6'b011011:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000000000011011; 
				
				end
                		
				//FUNCTION: 32 (ADD)
				6'b100000:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100000000000; 
				
				end
                		
				//FUNCTION: 33 (ADDU)
				6'b100001:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100011011100; 
				
				end
                		
				//FUNCTION: 34 (SUB)
				6'b100010:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001110100; 
				
				end
                		
				//FUNCTION: 35 (SUBU)
				6'b100011:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001111000; 
				
				end
                		
				//FUNCTION: 36 (AND)
				6'b100100:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100000010000; 
				
				end
                		
				//FUNCTION: 37 (OR)
				6'b100101:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001000000; 
				
				end
                		
				//FUNCTION: 38 (XOR)
				6'b100110:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001111100; 
				
				end
                		
				//FUNCTION: 39 (NOR)
				6'b100111:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100000111100; 
				
				end
                		
				//FUNCTION: 42 (SLT)		
				6'b101010:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100001010100; 
				
				end
                		
				//FUNCTION: 43 (SLTU)
				6'b101011:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000100011111100; 
				
				end
                		
				//FUNCTION: Default
				default:begin
				       
					$display("Not an Instruction!");
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'd0;

				end
            		endcase
        	end
        
		//OPCODE: 1 (REGIMM)
		6'b000001:begin
           
			//CASE STATEMENT FOR RT	
			case(rt)
                
				//RT: 0 (BLTZ)
				5'b00000:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0001000001010011100; 
				
				end
                		
				//RT: 1 (BGEZ)
				5'b00001:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0001000001010001100; 
				
				end
                		
				//RT: 16 (BLTZAL)
				5'b10000:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b1001001101000000100; 
				
				end
                
				//RT: 17 (BGEZAL)
				5'b10001:begin 
				
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b1001001101000000100; 
				
				end
                
				//RT: Default
				default:begin
				       
					$display("Not an Instruction!");	
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'd0;
				
				end
	
			endcase

        	end
		
		//OPCODE: 2 (J)
		6'b000010:begin 
			
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0011000000000111000; 
		
		end
	
		//OPCODE: 3 (JAL)
		6'b000011:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b1011001101000000100; 
		
		end
	
		//OPCODE: 4 (BEQ)
		6'b000100:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0101000001010001000; 
		
		end
		
		//OPCODE: 5 (BNE)
		6'b000101:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0101000001010100100; 
		
		end
        
		//OPCODE: 6 (BLEZ)
		6'b000110:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0001000001010011000; 
		
		end
        
		//OPCODE: 7 (BGTZ)
		6'b000111:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0001000001010010100; 
		
		end
        
		//OPCODE: 8 (ADDI)
		6'b001000:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101000000100; 
		
		end  
        
		//OPCODE: 9 (ADDIU)
		6'b001001:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101000001000; 
		
		end

		//OPCODE: 10 (SLTI)
		6'b001010:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101001010100; 
		
		end
        
		//OPCODE: 11 (SLTIU)
		6'b001011:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101011111100; 
		
		end
        
		//OPCODE: 12 (ANDI)
		6'b001100:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001100000010000; 
		
		end
        	
		//OPCODE: 13 (ORI)
		6'b001101:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001100001000000; 
		
		end
        
		//OPCODE: 14 (XORI)
		6'b001110:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001100010000000; 
		
		end
	
		//OPCODE: 15 (LUI)
		6'b001111:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000001101000100000; 
		
		end
      
		//OPCODE: 32 (LB)
		6'b100000:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010000100; 
		
		end

		//OPCODE: 33 (LH)
		6'b100001:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010101100; 
		
		end

		//OPCODE: 34 (LWL)
		6'b100010:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010110100; 
		
		end

		//OPCODE: 35 (LW)
		6'b100011:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101011110100; 
		
		end

		//OPCODE: 36 (LBU)  	 
		6'b100100:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010101000; 
		
		end
		  
		//OPCODE: 37 (LHU)
		6'b100101:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010110000; 
		
		end
		  
		//OPCODE: 38 (LWR)
		6'b100110:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000101101010111000; 
		
		end
		  
		//OPCODE: 40 (SB)
		6'b101000:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000011001010111100; 
		
		end
		
	      	//OPCODE: 41 (SH)	
		6'b101001:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000011001011000000; 
		
		end
		
	      	//OPCODE: 42 (SWL)	
		6'b101010:begin 
			
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000011001011001000; 
		
		end
		
	      	//OPCODE: 43 (SW)	
		6'b101011:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000011001011000100; 
		
		end

		//OPCODE: 46 (SWR)
		6'b101110:begin 
		
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000011001011001100; 
		
		end

		//OPCODE: 17 (COP1)
		6'b010001:begin
			
			$display("UNHANDLED CASE - COP1");

			case(Format)
                
				//FORMAT: 2 (CFC1)
				5'b00010:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0000000101001101000; 

				end
                
				//FORMAT: 5 (CTC1)
				5'b00110:begin 

					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'b0100000001011010000; 

				end
              	 
				default:begin 

					$display("Not an Instruction!");
					{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'd0;

				end

            		endcase

        	end
        
		default:begin

			$display("Not an Instruction!");
			{Link,RegDest,Jump,Branch,MemRead,MemWrite,ALUSrc,RegWrite,JumpRegister,SignOrZero,Syscall,ALUControl,MultRegAccess} = 19'd0;

		end

    	endcase
    
end

endmodule
