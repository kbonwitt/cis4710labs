/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
      
      wire [3:0] opcode;
      wire [2:0] midbits;
      assign opcode = i_insn[15:12];
      assign midbits = i_insn[5:3]; //these 'midbits' are helpful to distinguish between ADD/SUB/etc and AND/OR/etc

      wire BRANCH; 
      assign BRANCH = (opcode == 4'b0); 
      
      wire ADD, SUB, MUL, DIV, ADDIMM;
      assign ADD = (opcode == 4'b1 && midbits == 3'b0);
      assign MUL = (opcode == 4'b1 && midbits == 3'b1);
      assign SUB = (opcode == 4'b1 && midbits == 3'b10);
      assign DIV = (opcode == 4'b1 && midbits == 3'b11);
      assign ADDIMM = (opcode == 4'b1 && i_insn[5] == 1'b1); //for ADDIMM, just the most significant midbit must be 1

      wire CMP, CMPU, CMPI, CMPIU;
      assign CMP = (opcode == 4'b10 && i_insn[8:7] == 2'b0);
      assign CMPU = (opcode == 4'b10 && i_insn[8:7] == 2'b1);
      assign CMPI = (opcode == 4'b10 && i_insn[8:7] == 2'b10);
      assign CMPIU = (opcode == 4'b10 && i_insn[8:7] == 2'b11);

      wire JSRR, JSR;
      assign JSRR = (i_insn[15:11] == 5'b01000);
      assign JSR = (i_insn[15:11] == 5'b01001);

      wire AND, NOT, OR, XOR, ANDIMM;
      assign AND = (opcode == 4'b101 && midbits == 3'b0);
      assign NOT = (opcode == 4'b101 && midbits == 3'b1);
      assign OR = (opcode == 4'b101 && midbits == 3'b10);
      assign XOR = (opcode == 4'b101 && midbits == 3'b11);
      assign ANDIMM = (opcode == 4'b1011 && midbits[2] == 1'b1); //for ANDIMM, just the most significant midbit must be 1

      wire LDR, STR;
      assign LDR = (opcode == 4'b0110);
      assign STR = (opcode == 4'b0111);

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

            //Is it necessary to state that these are signed?
      wire signed [4:0] IMM5;
      wire signed [5:0] IMM6;
      wire signed [6:0] IMM7;
      wire signed [7:0] IMM8; 
      wire signed [8:0] IMM9; 
      wire signed [10:0] IMM11;
      assign IMM5 = i_insn[4:0];
      assign IMM6 = i_insn[5:0];
      assign IMM7 = i_insn[6:0];
      assign IMM8 = i_insn[7:0];
      assign IMM9 = i_insn[8:0];
      assign IMM11 = i_insn[10:0];

            //is there a way to indicate that these are UNsigned?
      wire [3:0] UIMM4;
      wire [6:0] UIMM7;
      wire [7:0] UIMM8;
      assign UIMM4 = i_insn[3:0];
      assign UIMM7 = i_insn[6:0];
      assign UIMM8 = i_insn[7:0];

      /*** END DECODER ***/


      //insns that use the CLA: add, sub, addimm, ldr, str, jmp, branches
      wire [15:0] cla_num1 = (JMP || BRANCH) ? i_pc : i_r1data;
      wire [15:0] cla_num2 = ADD ? i_r2data :
                              SUB ? ~(i_r2data) :
                              ADDIMM ? ({{11{IMM5[4]}}, IMM5}) :
                              (LDR || STR) ? ({{10{IMM6[5]}}, IMM6}) :
                              BRANCH ? ({{7{IMM9[8]}}, IMM9}) :
                              JMP ? ({{5{IMM11[10]}}, IMM11}) :
                              16'b0; 
      wire cla_cin = (SUB || BRANCH);
      wire [15:0] cla_sum;
      cla16 c0 (.a(cla_num1), .b(cla_num2), .cin(cla_cin), .sum(cla_sum));



      //MUL, DIV, MOD
      //TODO: figure out if r1data and r2data are signed or unsigned
      // and if the * operator cares
      wire signed [15:0] mul_op = i_r1data * i_r2data;
      wire [15:0] div_op, mod_op;
      lc4_divider d0 (.i_dividend(i_r1data), .i_divisor(i_r2data),
            .o_remainder(mod_op), .o_quotient(div_op));
      wire [15:0] muldivmod = MUL ? mul_op :
                              DIV ? div_op :
                              MOD ? mod_op :
                              16'b0;

      
      //logical operators
      wire [15:0] and_op = i_r1data & i_r2data;
      wire [15:0] or_op = i_r1data | i_r2data;
      wire [15:0] not_op = !i_r1data;
      wire [15:0] xor_op = i_r1data ^ i_r2data; 
      wire [15:0] andimm_op = i_r1data & {{11{IMM5[4]}}, IMM5};
            //note: i *think* this is how you sign extend...
      wire [15:0] logicals = AND ? and_op :
                              OR ? or_op :
                              NOT ? not_op :
                              XOR ? xor_op :
                              ANDIMM ? andimm_op :
                              16'b0;


      //shifts
      wire [16:0] sll_op = i_r1data << i_r2data;
      wire [16:0] srl_op = i_r1data >> i_r2data;
      wire [16:0] sra_op = i_r1data >>> i_r2data;
      wire [15:0] shifts = SLL ? sll_op :
                              SRL ? srl_op :
                              SRA ? sra_op :
                              16'b0;


      //comparisons
      wire [15:0] cmp_num1, cmp_num2;
      wire unsigned r1_unsigned = i_r1data;
      wire signed r1_signed = i_r1data;
      wire unsigned r2_unsigned = i_r2data;
      wire signed r2_signed = i_r2data;
      assign cmp_num1 = (CMP || CMPI) ? r1_signed :
                                          r1_unsigned;
      assign cmp_num2 = CMP ? r2_signed :
                        CMPU ? r2_unsigned :
                        ({{9{IMM7[6]}}, IMM7}); 
      wire [15:0] comparisons = cmp_num1 > cmp_num2 ? 16'b1 :
                                    cmp_num1 == cmp_num2 ? 16'b0 :
                                    16'hFFFF;


      //trap, jsr, jsrr      
      wire [15:0] trapjsrjsrr = TRAP ? (UIMM8 | 16'h8000) :
                                    JSR ? (16'h8000 & i_pc) | (IMM11 << 4) :
                                    i_r1data;


      //const, hiconst
      wire [15:0] constants = CONST ? {{7{IMM9[8]}}, IMM9} :
                              (i_r1data & 16'hFF) | (UIMM8 << 8);



      //final MUX:
            //cla_sum = (AND || SUB || ADDIMM || LDR || STR || JMP || BRANCH)
            //muldivmod = (MUL || DIV || MOD)
            //logicals = (AND || OR || NOT || XOR || ANDIMM)
            //comparisons = (CMP || CMPI || CMPU || CMPIU)
            //shifts = (SLL || SRL || SRA)
            //trapjsrjsrr = (TRAP || JSR || JSRR)
            //constants = (CONST || HICONST)
      assign o_result = (ADD || SUB || ADDIMM || LDR || STR || JMP || BRANCH) ? cla_sum :
                        (MUL || DIV || MOD) ? muldivmod :
                        (AND || OR || NOT || XOR || ANDIMM) ? logicals :
                        (CMP || CMPI || CMPU || CMPIU) ? comparisons :
                        (SLL || SRL || SRA) ? shifts :
                        (TRAP || JSR || JSRR) ? trapjsrjsrr :
                        (CONST || HICONST) ? constants :
                        16'b0;


      /*** YOUR CODE HERE ***/

endmodule
