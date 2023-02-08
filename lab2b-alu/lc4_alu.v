/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
      
      wire [3:0] opcode, [2:0] midbits;
      assign opcode = i_insn[15:12];
      assign midbits = i_insn[5:3]; //these 'midbits' are helpful to distinguish between ADD/SUB/etc and AND/OR/etc

      wire BRANCH, NOP; //in this case, i'm considering Branches and NOP to be differnet, since there's a difference in ALU stuff
      assign NOP = (i_insn[15:9] == 7'b0); 
      assign BRANCH = (opcode == 4'b0 && !NOP); 
            //It will be a branch if the first 4 are 0 and it's not a NOP
      
      wire ADD, SUB, MUL, DIV, ADDIMM;
      assign ADD = (opcode == 4'b1 && midbits == 3'b0);
      assign MUL = (opcode == 4'b1 && midbits == 3'b1);
      assign SUB = (opcode == 4'b1 && midbits == 3'b10);
      assign DIV = (opcode == 4'b1 && midbits == 3'b11);
      assign ADDIMM = (opcode == 4'b1 && midbits[2] == 1'b1); //for ADDIMM, just the most significant midbit must be 1

      wire CMP, CMPU, CMPI, CMPIU;
      assign CMP = (opcode == 4'b10 && midbits[2:1] == 2'b0);
      assign CMPU = (opcode == 4'b10 && midbits[2:1] == 2'b1);
      assign CMPI = (opcode == 4'b10 && midbits[2:1] == 2'b10);
      assign CMPIU = (opcode == 4'b10 && midbits[2:1] == 2'b11);

      wire JSRR, JSR;
      assign CMP = (i_insn[15:11] == 5'b01000);
      assign CMPU = (i_insn[15:11] == 5'b01001);

      wire AND, NOT, OR, XOR, ANDIMM;
      assign AND = (opcode == 4'b101 && midbits == 3'b0);
      assign NOT = (opcode == 4'b101 && midbits == 3'b1);
      assign OR = (opcode == 4'b101 && midbits == 3'b10);
      assign XOR = (opcode == 4'b101 && midbits == 3'b11);
      assign ANDIMM = (opcode == 4'b1011 && midbits[2] == 1'b1); //for ANDIMM, just the most significant midbit must be 1

      wire LDR, STR;
      assign LDR = (opcode == 4'b0110);
      assign LDR = (opcode == 4'b0111);

      wire RTI, CONST, HICONST;
      assign RTI = (opcode == 4'b1000);
      assign CONST = (opcode == 4'b1001);
      assign HICONST = (opcode == 4'b1101);

      wire SLL, SRA, SRL, MOD;
      assign SLL = (opcode == 4'b1010 && midbits[2:1] == 2'b0);
      assign SRA = (opcode == 4'b1010 && midbits[2:1] == 2'b1);
      assign SRL = (opcode == 4'b1010 && midbits[2:1] == 2'b10);
      assign MOD = (opcode == 4'b1010 && midbits[2:1] == 2'b11);

      wire JMPR, JMP;
      assign JMPR = (i_insn[15:11] == 5'b11000);
      assign JMP = (i_insn[15:11] == 5'b11001);

      wire TRAP;
      assign TRAP = (opcode == 4'b1111);

      

      
      


      /*** YOUR CODE HERE ***/

endmodule
