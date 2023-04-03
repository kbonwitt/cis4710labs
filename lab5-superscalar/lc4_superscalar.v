`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/

   /*** YOUR CODE HERE ***/

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;


   //STALL LOGIC
   /*
   + 0: no stall
   + 1: reserved for the superscalar design; for this lab, never set test_stall to 1
   + 2: flushed due to misprediction or because the first real instruction hasn't made it through to the writeback stage yet
   + 3: stalled due to load-to-use penalty
   */

   // X_is_load && (X_rd_sel == D_rs_sel || X_rd_sel == D_rt_sel || D_is_branch) ? 2'b11 : 2'b00;
   // For the next section: create stall registers so that you carry dstall into writeback and set test_stall=wstall

   //TODO:Load-To-Use Stalling
      wire ldr_stall;
   //( (D_is_store && (D_rs_sel == X_rd_sel)) || 
   //assign ldr_stall = (X_is_load && !(D_is_store && (D_rt_sel == X_rd_sel)) && ( (D_rs_re && D_rs_sel == X_rd_sel) || (D_rt_re && D_rt_sel == X_rd_sel) || D_is_branch) );
      //note to self: load-to-use stall DOESNT happen if the second insn is a store

   //TODO: 
      assign ldr_stall = X_is_load && 
                        (D_is_branch ||
                        (D_rs_sel == X_rd_sel && D_rs_re) ||
                        (D_rt_sel == X_rd_sel && D_rt_re && (!D_is_store))
                        );

      wire X_branch_misprediction, flush; 
      assign X_branch_misprediction = (|(nzp_reg_output & X_insn[11:9])) && X_is_branch; //==1 when we SHOULD have branched from this BR
      assign flush = (X_is_control_insn || X_branch_misprediction);

      wire [1:0] F_stall, D_stall, X_stall, M_stall, W_stall;   
      //Nbit_reg #(2, 0) fstall_reg (.in(flush ? 2'b10 : 2'b0), .out(F_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      assign F_stall = flush ? 2'b10 : 2'b0;
      Nbit_reg #(2, 2'b10) dstall_reg (.in(F_stall), .out(D_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) xstall_reg (.in(ldr_stall ? 2'b11 : flush ? 2'b10 : D_stall), .out(X_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         //note that X_stall is forced to 3 if there is a load-to-use stall. Otherwise, it gets its val from D_stall, since 
         //D_stall would be non-0 only in the event of a branch misprediction stall
      Nbit_reg #(2, 2'b10) mstall_reg (.in(X_stall), .out(M_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) wstall_reg (.in(M_stall), .out(W_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   /*
   
   */
   
   //  ----****************************************---
   //  ----************--- F stage ----************---
   //  ----****************************************---


   // pc wires attached to the PC register's ports
   wire [15:0]   F_pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)
      //note: this will come into play with branch prediction and stalling/flushing

   Nbit_reg #(16, 16'h8200) F_pc_reg (.in(next_pc), .out(F_pc), .clk(clk), .we(!ldr_stall), .gwe(gwe), .rst(rst));
   assign o_cur_pc = F_pc; 

   //---here we would get inputs from the outer PC module
   //so we get i_cur_insn_A, i_cur_insn_B


   wire [15:0] F_pc_plus_one_B; //B because we want the insn AFTER B, not A (B legit IS the insn after A --> A+1)
   cla16 make_pc_plus_one 
      (.a(F_pc), .b(16'b1), .cin(1'b0), .sum(F_pc_plus_one_B));


   
   
   //  ----****************************************---
   //  ----************--- D stage ---*************---
   //  ----****************************************---

   //TODO:
      wire D_read_new;
      assign D_read_new = (D_stall == 0);
         //this is for write enable for the regs below. If there is no stall, WE=1 so get next INSN/PC from F.
            //if there IS a stall, WE=0, so just 'keep' what you have now.                     
   
   wire [15:0] D_insn_A, D_pc_A, D_pc_plus_one_A;
   Nbit_reg #(16) D_insn_reg_A (.in(i_cur_insn_A), .out(D_insn_A), .clk(clk), .we(!ldr_stall_A), .gwe(gwe), .rst(rst | flush_A));
   Nbit_reg #(16) D_pc_reg_A (.in(F_pc_A), .out(D_pc_A), .clk(clk), .we(!ldr_stall_A), .gwe(gwe), .rst(rst | flush_A));
   Nbit_reg #(16) D_pc_plus_one_reg_A (.in(F_pc_plus_one_A), .out(D_pc_plus_one_A), .clk(clk), .we(!ldr_stall_A), .gwe(gwe), .rst(rst | flush_A));

   wire [15:0] D_insn_B, D_pc_B, D_pc_plus_one_B;
   Nbit_reg #(16) D_insn_reg_B (.in(i_cur_insn_B), .out(D_insn_B), .clk(clk), .we(!ldr_stall_B), .gwe(gwe), .rst(rst | flush_B));
   Nbit_reg #(16) D_pc_reg_B (.in(F_pc_B), .out(D_pc_B), .clk(clk), .we(!ldr_stall_B), .gwe(gwe), .rst(rst | flush_B));
   Nbit_reg #(16) D_pc_plus_one_reg_B (.in(F_pc_plus_one_B), .out(D_pc_plus_one_B), .clk(clk), .we(!ldr_stall_B), .gwe(gwe), .rst(rst | flush_B));


   wire [2:0] D_rs_sel_A, D_rt_sel_A, D_rd_sel_A;
   wire D_rs_re_A, D_rt_re_A, D_regfile_we_A, D_nzp_we_A, D_select_pc_plus_one_A, D_is_load_A, D_is_store_A, D_is_branch_A, D_is_control_insn_A;

   lc4_decoder D_decoder(.insn(D_insn_A),               // instruction (in D stage)
                       .r1sel(D_rs_sel_A),              // rs
                       .r1re(D_rs_re_A),               // does this instruction read from rs?
                       .r2sel(D_rt_sel_A),              // rt
                       .r2re(D_rt_re_A),               // does this instruction read from rt?
                       .wsel(D_rd_sel_A),               // rd
                       .regfile_we(D_regfile_we_A),         // does this instruction write to rd?
                       .nzp_we(D_nzp_we_A),             // does this instruction write the NZP bits?
                       .select_pc_plus_one(D_select_pc_plus_one_A), // write PC+1 to the regfile?
                       .is_load(D_is_load_A),            // is this a load instruction?
                       .is_store(D_is_store_A),           // is this a store instruction?
                       .is_branch(D_is_branch_A),          // is this a branch instruction?
                       .is_control_insn(D_is_control_insn_A)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );
   
   wire [2:0] D_rs_sel_B, D_rt_sel_B, D_rd_sel_B;
   wire D_rs_re_B, D_rt_re_B, D_regfile_we_B, D_nzp_we_B, D_select_pc_plus_one_B, D_is_load_B, D_is_store_B, D_is_branch_B, D_is_control_insn_B;

   lc4_decoder D_decoder(.insn(D_insn_B),               // instruction (in D stage)
                       .r1sel(D_rs_sel_B),              // rs
                       .r1re(D_rs_re_B),               // does this instruction read from rs?
                       .r2sel(D_rt_sel_B),              // rt
                       .r2re(D_rt_re_B),               // does this instruction read from rt?
                       .wsel(D_rd_sel_B),               // rd
                       .regfile_we(D_regfile_we_B),         // does this instruction write to rd?
                       .nzp_we(D_nzp_we_B),             // does this instruction write the NZP bits?
                       .select_pc_plus_one(D_select_pc_plus_one_B), // write PC+1 to the regfile?
                       .is_load(D_is_load_B),            // is this a load instruction?
                       .is_store(D_is_store_B),           // is this a store instruction?
                       .is_branch(D_is_branch_B),          // is this a branch instruction?
                       .is_control_insn(D_is_control_insn_B)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );

   // ---- Regfile stuff ----

   wire [15:0] D_rs_data_A, D_rt_data_A;
   wire [15:0] D_rs_data_B, D_rt_data_B;

   lc4_regfile #(.n(16)) regfile 
         (.clk(clk), .gwe(gwe), .rst(rst), 
         .i_rs_A(D_rs_sel_A), .o_rs_data_A(D_rs_data_A), 
         .i_rt_A(D_rt_sel_A), .o_rt_data_A(D_rt_data_A), 
         .i_rd_A(W_rd_sel_A), .i_wdata_A(W_regfile_data_to_write_A), .i_rd_we_A(W_regfile_we_A)
         
         .i_rs_B(D_rs_sel_B), .o_rs_data_B(D_rs_data_B), 
         .i_rt_B(D_rt_sel_B), .o_rt_data_B(D_rt_data_B), 
         .i_rd_B(W_rd_sel_B), .i_wdata_B(W_regfile_data_to_write_B), .i_rd_we_B(W_regfile_we_B)
         
         );
   
   //  ----****************************************---
   //  ----************--- X stage ----************---
   //  ----****************************************---


   //PIPE REGISTERS
   //Note: we reset (see each .rst) if there is a flush or a load_to_use, because resetting X is the same as throwing a NOP in
   wire [15:0] X_rs_data, X_rt_data, X_insn, X_pc, X_pc_plus_one;
   Nbit_reg #(16) X_rs_data_reg (.in(D_rs_data), .out(X_rs_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(16) X_rt_data_reg (.in(D_rt_data), .out(X_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(16) X_insn_reg (.in(D_insn), .out(X_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall)); //will be NOP when stalling
   Nbit_reg #(16) X_pc_reg (.in(D_pc), .out(X_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));       //will be 000 when stalling
   Nbit_reg #(16) X_pc_plus_one_reg (.in(D_pc_plus_one), .out(X_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));

   wire [2:0] X_rs_sel, X_rt_sel, X_rd_sel;
   Nbit_reg #(3) X_rs_sel_reg (.in(D_rs_sel), .out(X_rs_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(3) X_rt_sel_reg (.in(D_rt_sel), .out(X_rt_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(3) X_rd_sel_reg (.in(D_rd_sel), .out(X_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));

   wire X_regfile_we, X_nzp_we, X_select_pc_plus_one;
   Nbit_reg #(1) X_regfile_we_reg (.in(D_regfile_we), .out(X_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(1) X_nzp_we_reg (.in(D_nzp_we), .out(X_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(1) X_sel_pc_plus_one_reg (.in(D_select_pc_plus_one), .out(X_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   
   wire X_is_load, X_is_branch, X_is_store, X_is_control_insn;
   Nbit_reg #(1) X_is_load_reg (.in(D_is_load), .out(X_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(1) X_is_store_reg (.in(D_is_store), .out(X_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(1) X_is_branch_reg (.in(D_is_branch), .out(X_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));
   Nbit_reg #(1) X_is_control_insn_reg (.in(D_is_control_insn), .out(X_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush || ldr_stall));



   // ---- ALU stuff -----
   wire [15:0] X_rs_bypass_val_mux1, X_rt_bypass_val_mux2, X_alu_output;
   assign X_rs_bypass_val_mux1 = 
         (X_rs_sel == M_rd_sel & M_regfile_we) ? M_alu_output : // MX Bypass
         (X_rs_sel == W_rd_sel & W_regfile_we)? W_memory_or_alu_output : // WX Bypass
         X_rs_data;
   assign X_rt_bypass_val_mux2 = 
         (X_rt_sel == M_rd_sel & M_regfile_we) ? M_alu_output : // MX Bypass
         (X_rt_sel == W_rd_sel & W_regfile_we) ? W_memory_or_alu_output : // WX Bypass
         X_rt_data;
   lc4_alu alu 
      (.i_insn(X_insn), .i_pc(X_pc),
      .i_r1data(X_rs_bypass_val_mux1), .i_r2data(X_rt_bypass_val_mux2),
      .o_result(X_alu_output)
      );
   
   

   //  ----****************************************---
   //  ----************--- M stage ----************---
   //  ----****************************************---

   wire [15:0] M_alu_output, M_rt_data, M_insn, M_pc, M_pc_plus_one;
   Nbit_reg #(16) M_alu_output_reg (.in(X_alu_output), .out(M_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_rt_data_reg (.in(X_rt_bypass_val_mux2), .out(M_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_insn_reg (.in(X_insn), .out(M_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_reg (.in(X_pc), .out(M_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_plus_one_reg (.in(X_pc_plus_one), .out(M_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire [2:0] M_rs_sel, M_rt_sel, M_rd_sel;
   Nbit_reg #(3) M_rs_sel_reg (.in(X_rs_sel), .out(M_rs_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rt_sel_reg (.in(X_rt_sel), .out(M_rt_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rd_sel_reg (.in(X_rd_sel), .out(M_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_regfile_we, M_nzp_we, M_select_pc_plus_one;
   Nbit_reg #(1) M_regfile_we_reg (.in(X_regfile_we), .out(M_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_nzp_we_reg (.in(X_nzp_we), .out(M_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_sel_pc_plus_one_reg (.in(X_select_pc_plus_one), .out(M_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [2:0] M_nzp_newbits;
   Nbit_reg #(3) M_nzp_newbits_reg (.in(X_nzp_newbits), .out(M_nzp_newbits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire M_is_load, M_is_branch, M_is_store, M_is_control_insn;
   Nbit_reg #(1) M_is_load_reg (.in(X_is_load), .out(M_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_store_reg (.in(X_is_store), .out(M_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_branch_reg (.in(X_is_branch), .out(M_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_control_insn_reg (.in(X_is_control_insn), .out(M_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   // ----  NZP stuff ------
   //yes, for now i'm assuming this happens in M
   wire [2:0] X_nzp_newbits, nzp_reg_output;
   wire X_writes_to_r7 = (X_insn[15:12] == 4'b1111 || //TRAP
                          X_insn[15:12] == 4'b0100 || //JSR/JSRR
                          X_insn[15:12] == 4'b1000); //RTI
   wire [15:0] X_nzp_wdata = 
                     (X_writes_to_r7) ? X_pc_plus_one :
                     X_alu_output;
   assign X_nzp_newbits = (X_nzp_wdata == 0) ? 3'b010 : //Z
                          (X_nzp_wdata[15] == 0) ? 3'b001 : //P
                          3'b100; //N

   Nbit_reg #(3) nzp_reg 
      (.in(X_nzp_newbits), .out(nzp_reg_output),
      .clk(clk), .we(X_nzp_we), .gwe(gwe), .rst(rst));
   

   // ---- MEMORY stuff -----  
   wire [15:0] M_dmem_data_bypass_mux3;
   assign M_dmem_data_bypass_mux3 = (M_is_store && (M_rt_sel == W_rd_sel) && W_regfile_we) ? W_memory_or_alu_output :
                                    M_rt_data;
   assign o_dmem_we = M_is_store;
   assign o_dmem_addr = (M_is_load || M_is_store) ? M_alu_output : 16'b0;
   assign o_dmem_towrite = (M_is_store) ? M_dmem_data_bypass_mux3 : 16'b0;

   wire [15:0] M_memory_or_alu_output, M_regfile_data_to_write;
   assign M_memory_or_alu_output = M_is_load ? i_cur_dmem_data :
                                               M_alu_output;   
   assign M_regfile_data_to_write = M_select_pc_plus_one ? M_pc_plus_one :
                                    M_memory_or_alu_output;




   //  ----****************************************---
   //  ----************--- W stage ----************---
   //  ----****************************************---
   wire [15:0] W_alu_output, W_dmem_data_output, W_insn, W_pc, W_pc_plus_one;
   Nbit_reg #(16) W_alu_output_reg (.in(M_alu_output), .out(W_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_datamem_reg (.in(i_cur_dmem_data), .out(W_dmem_data_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_insn_reg (.in(M_insn), .out(W_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_reg (.in(M_pc), .out(W_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_plus_one_reg (.in(M_pc_plus_one), .out(W_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] W_dmem_data_input;
   Nbit_reg #(16) W_dmem_data_reg (.in(M_dmem_data_bypass_mux3), .out(W_dmem_data_input), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] W_dmem_addr;
   Nbit_reg #(16) W_dmem_addr_reg (.in(M_alu_output), .out(W_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] W_rd_sel;
   Nbit_reg #(3) W_rd_sel_reg (.in(M_rd_sel), .out(W_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] W_nzp_newbits;
   wire W_regfile_we, W_nzp_we, W_select_pc_plus_one, W_dmem_we;
   wire [2:0] M_nzp_newbits_load = (i_cur_dmem_data == 0) ? 3'b010 : //Z
                          (i_cur_dmem_data[15] == 0) ? 3'b001 : //P
                          3'b100;
   Nbit_reg #(3) W_nzp_newbits_reg (.in(M_is_load ? M_nzp_newbits_load : M_nzp_newbits), .out(W_nzp_newbits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   Nbit_reg #(1) W_regfile_we_reg (.in(M_regfile_we), .out(W_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_nzp_we_reg (.in(M_nzp_we), .out(W_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_sel_pc_plus_one_reg (.in(M_select_pc_plus_one), .out(W_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_dmem_we_reg (.in(M_is_store), .out(W_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire W_is_load, W_is_branch, W_is_control_insn;
   Nbit_reg #(1) W_is_load_reg (.in(M_is_load), .out(W_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_branch_reg (.in(M_is_branch), .out(W_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_control_insn_reg (.in(M_is_control_insn), .out(W_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire W_is_store;
   assign W_is_store = W_dmem_we; //I know this is unecessary but helps with naming convention

   wire [15:0] W_memory_or_alu_output, W_regfile_data_to_write;
   Nbit_reg #(16) W_mem_or_alu_reg (.in(M_memory_or_alu_output), .out(W_memory_or_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_regfile_data_reg (.in(M_regfile_data_to_write), .out(W_regfile_data_to_write), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));




   //not confident about this
   assign next_pc = flush ? X_alu_output:
                            F_pc_plus_one;
   
   
   
   // ---- TEST WIRES -----
   
   assign test_cur_pc = W_pc;                // Testbench: program counter
   assign test_cur_insn = W_insn;           // Testbench: instruction bits
   assign test_regfile_we = W_regfile_we;       // Testbench: register file write enable
   assign test_regfile_wsel = W_rd_sel;           // Testbench: which register to write in the register file 
   assign test_regfile_data = W_regfile_data_to_write; // Testbench: value to write into the register file
   assign test_nzp_we = W_nzp_we;                 // Testbench: NZP condition codes write enable
   assign test_nzp_new_bits = W_nzp_newbits;    // Testbench: value to write to NZP bits
   assign test_dmem_we = W_dmem_we;             // Testbench: data memory write enable
   assign test_dmem_addr = (W_is_load || W_is_store) ? W_dmem_addr :
                           16'b0;               // Testbench: address to read/write memory
   assign test_dmem_data = (W_is_load) ? W_dmem_data_output :
                           (W_is_store) ? W_dmem_data_input :
                           16'b0;               // Testbench: value read/writen from/to memory
   assign test_stall = W_stall;








   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      if (0) begin
         $display("--------------------");
         $display("f_pc: %h, i_cur_insn: %h", F_pc, i_cur_insn);
         $display("d_pc: %h | r%d: %h | r%d: %h", D_pc, D_rs_sel, D_rs_data, D_rt_sel, D_rt_data);
         $display("x_pc: %h | alu1: %h | alu2: %h | alu_out: %h", X_pc, X_rs_bypass_val_mux1, X_rt_bypass_val_mux2, X_alu_output);
         $display("m_pc: %h | dmem_addr: %h | dmem_we: %b | dmem_data: %h | WM Bypass: %b", M_pc, o_dmem_addr, o_dmem_we, o_dmem_towrite, (M_is_store && M_rt_sel == W_rd_sel));
         $display("w_pc: %h | w_insn: %h | writing to r%d | wdata: %h | regfile_we: %b | dmem_addr: %h | dmem_we: %b | dmem_data: %h | is_load: %b | is_store: %b", 
            W_pc, W_insn, W_rd_sel, W_regfile_data_to_write, W_regfile_we, W_dmem_addr, W_dmem_we, test_dmem_data, W_is_load, W_is_store);
         $display("xnzp: %b | next_pc: %h", nzp_reg_output, next_pc);
         $display("flush: %b | ldr_stall: %b", flush, ldr_stall);
         $display("F_stall: %b | D_stall: %b | X_stall: %b | M_stall: %b | W_stall: %b", F_stall, D_stall, X_stall, M_stall, W_stall);

      end
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then youDcan easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display(); 
   end
`endif
endmodule
