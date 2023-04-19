

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



   //TODO: TODO: TODO: for part B
      /*
      - set flush_A and flush_B
         - what to do on flushes: reset all the ones affected
      - nzp
         - make sure it works correctly (like is updated in correct stage- currently it's in X but i think it might be in M because of LDR...)
         - also it should prioritize b
      - figure out stalls for flushes, D_both_memory, ldr_stalls 
      - **Figure out what to do if there is both a pipe switch AND a stall
         right now, both happen at once: DA moves to XA, and DB moves to DA, but everything else stays the same,
            so what was in DB is now in BOTH DA and DB.
            --so i think that if B should stall for a (ldr_stall_A) but there is also a pipe_switch, then just do pipe switch
      */


      /*
      In D will need to consider the following dependency cases:
      1. DA has a LTU dependence: either XA or XB writes to a reg that DA uses
         - `ldr_stall_A`
         - Insert NOP into both pipes, stall all of F and D. 
         - Record LTU (stall=3) in DA
         - Record superscalar (stall=1) in DB
      2. DB requires value computed by DA (incl if DA is load) and DA does not stall
         - `D_super_dependency`
         - Stall DB with superscalar (stall=1)
         - Pipe switch (so DA --> XA, DB --> DA, FA --> DB, and increment PC by just 1 instead of 2)
      3. DB has a LTU dependence [and NO reliance on DA]: either XA or XB writes to a reg that DB uses
         - `ldr_stall_B`
         - *ONLY if DA does not stall, so only if stall_DA=0
         - stall DB with LTU (stall=3)
         - Pipe switch (so DA --> XA, DB --> DA, FA --> DB, and increment PC by just 1 instead of 2)
      4. Both DA and DB are memory insns (LDR or STR)
         - `D_both_memory`
         - stall DB with superscalar (stall=1)
         - Pipe switch (so DA --> XA, DB --> DA, FA --> DB, and increment PC by just 1 instead of 2)
      *** If both superscalar AND LTU stall, superscalar takes precedence

      */

   wire ldr_stall_A, ldr_stall_B;
   assign ldr_stall_A = (X_is_load_A && 
                           (D_is_branch_A ||
                           (D_rs_sel_A == X_rd_sel_A && D_rs_re_A) ||
                           (D_rt_sel_A == X_rd_sel_A && D_rt_re_A && (!D_is_store_A))
                           ) && 
                              !(X_regfile_we_B && ( //if DA relies on XB, then that would nullify the XA-DA LTU 
                                 (D_rs_sel_A == X_rd_sel_B && D_rs_re_A) ||
                                 (D_rt_sel_A == X_rd_sel_B && D_rt_re_A && !D_is_store_A)
                              )
                           )
                        )
                        ||
                        (X_is_load_B && 
                           (D_is_branch_A ||
                            (D_rs_sel_A == X_rd_sel_B && D_rs_re_A) ||
                            (D_rt_sel_A == X_rd_sel_B && D_rt_re_A && (!D_is_store_A))
                           )
                        ); //this is for situation #1 above
   assign ldr_stall_B = !D_super_dependency && (
                        (X_is_load_A && 
                           (D_is_branch_B ||
                           (D_rs_sel_B == X_rd_sel_A && D_rs_re_B) ||
                           (D_rt_sel_B == X_rd_sel_A && D_rt_re_B && (!D_is_store_B))
                           ) && 
                              !(X_regfile_we_B && (//if DB relies on XB, then that would nullify the XA-DB LTU 
                                 (D_rs_sel_B == X_rd_sel_B && D_rs_re_B) ||
                                 (D_rt_sel_B == X_rd_sel_B && D_rt_re_B && !D_is_store_B))
                              )
                        )
                        ||
                        (X_is_load_B && 
                           (D_is_branch_B ||
                              (D_rs_sel_B == X_rd_sel_B && D_rs_re_B) ||
                              (D_rt_sel_B == X_rd_sel_B && D_rt_re_B && (!D_is_store_B))
                           )
                        )); //Situation #3 above

   wire D_super_dependency; //Situation #2 above
   assign D_super_dependency = D_regfile_we_A && (
                                 (D_rd_sel_A == D_rs_sel_B && D_rs_re_B) ||
                                 (D_rd_sel_A == D_rt_sel_B && D_rt_re_B && !D_is_store_B)
                                 );
   

   wire D_both_memory; //Situation #4 above
   assign D_both_memory = ((D_is_load_A || D_is_store_A) && (D_is_load_B || D_is_store_B));

   wire pipe_switch;
   assign pipe_switch = !ldr_stall_A && (D_super_dependency || ldr_stall_B || D_both_memory); //only pipe switch if no stalling A

   //TODO: make a flush_a and flush_b, and they can be locked in at 0 for part A of the lab (b/c no branches or control insns)
      wire X_branch_misprediction_A, X_branch_misprediction_B, flush_A, flush_B; 
      assign flush_A = 0;
      assign flush_B = 0;
      assign X_branch_misprediction_A = 0;
      assign X_branch_misprediction_B = 0;
      // assign X_branch_misprediction = (|(nzp_reg_output & X_insn[11:9])) && X_is_branch; //==1 when we SHOULD have branched from this BR
      // assign flush = (X_is_control_insn || X_branch_misprediction);


      //THIS WAS FOR LAB4 PIPELINE
         // wire [1:0] F_stall, D_stall, X_stall, M_stall, W_stall;   
         // //Nbit_reg #(2, 0) fstall_reg (.in(flush ? 2'b10 : 2'b0), .out(F_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         // assign F_stall = flush ? 2'b10 : 2'b0;
         // Nbit_reg #(2, 2'b10) dstall_reg (.in(F_stall), .out(D_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         // Nbit_reg #(2, 2'b10) xstall_reg (.in(ldr_stall ? 2'b11 : flush ? 2'b10 : D_stall), .out(X_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         //    //note that X_stall is forced to 3 if there is a load-to-use stall. Otherwise, it gets its val from D_stall, since 
         //    //D_stall would be non-0 only in the event of a branch misprediction stall
         // Nbit_reg #(2, 2'b10) mstall_reg (.in(X_stall), .out(M_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         // Nbit_reg #(2, 2'b10) wstall_reg (.in(M_stall), .out(W_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //TODO: **for lab part B figure out where to change the stalls for flushes, ldr_stalls, and maybe D_both_memory
      wire [1:0] F_stall_A, F_stall_B, D_stall_A, D_stall_B, X_stall_A, X_stall_B, M_stall_A, M_stall_B, W_stall_A, W_stall_B;
      assign F_stall_A = flush_A || flush_B ? 2'b10 : 2'b0;
      assign F_stall_B = flush_A || flush_B ? 2'b10 : 2'b0;
      Nbit_reg #(2, 2'b10) dstall_reg_A (.in(F_stall_A), .out(D_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) dstall_reg_B (.in(F_stall_B), .out(D_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) xstall_reg_A (.in(ldr_stall_A ? 2'b11 : D_stall_A), .out(X_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) xstall_reg_B (.in(D_super_dependency || D_both_memory || ldr_stall_A ? 2'b01 : ldr_stall_B ? 2'b11 : D_stall_B), .out(X_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
         //note that X_stall is forced to 3 if there is a load-to-use stall. Otherwise, it gets its val from D_stall, since 
         //D_stall would be non-0 only in the event of a branch misprediction stall
      Nbit_reg #(2, 2'b10) mstall_reg_A (.in(X_stall_A), .out(M_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) mstall_reg_B (.in(X_stall_B), .out(M_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) wstall_reg_A (.in(M_stall_A), .out(W_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
      Nbit_reg #(2, 2'b10) wstall_reg_B (.in(M_stall_B), .out(W_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); 
      

   
   //  ----****************************************---
   //  ----************--- F stage ----************---
   //  ----****************************************---


   // pc wires attached to the PC register's ports
   wire [15:0]   F_pc_A;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)
      //note: this will come into play with branch prediction and stalling/flushing

   
   wire FD_no_update = ldr_stall_A && !pipe_switch;

   Nbit_reg #(16, 16'h8200) F_pc_reg_A (.in(next_pc), .out(F_pc_A), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst));
   assign o_cur_pc = F_pc_A; 

   //---here we would get inputs from the outer PC module
   //so we get i_cur_insn_A, i_cur_insn_B

   wire [15:0] F_pc_B;
   cla16 make_pc_plus_one_A 
      (.a(F_pc_A), .b(16'b1), .cin(1'b0), .sum(F_pc_B));
   
   wire [15:0] F_pc_plus_one_A; //this is effectively the PC of F_B, as it is +1 from the PC in F_A
   assign F_pc_plus_one_A = F_pc_B;

   wire [15:0] F_pc_plus_one_B; //this is effectively the PC of F_A + 2 = F_B + 1, so the next insn after F_B, selected when no pipe switch
   cla16 make_pc_plus_one_B 
      (.a(F_pc_B), .b(16'b1), .cin(1'b0), .sum(F_pc_plus_one_B));


   
   
   //  ----****************************************---
   //  ----************--- D stage ---*************---
   //  ----****************************************---
                   
   wire [15:0] D_insn_A, D_pc_A, D_pc_plus_one_A;
   Nbit_reg #(16) D_insn_reg_A (.in(pipe_switch ? D_insn_B : i_cur_insn_A), .out(D_insn_A), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));
   Nbit_reg #(16) D_pc_reg_A (.in(pipe_switch ? D_pc_B : F_pc_A), .out(D_pc_A), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));
   Nbit_reg #(16) D_pc_plus_one_reg_A (.in(pipe_switch ? D_pc_plus_one_B : F_pc_plus_one_A), .out(D_pc_plus_one_A), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));

   wire [15:0] D_insn_B, D_pc_B, D_pc_plus_one_B;
   Nbit_reg #(16) D_insn_reg_B (.in(pipe_switch ? i_cur_insn_A : i_cur_insn_B), .out(D_insn_B), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));
   Nbit_reg #(16) D_pc_reg_B (.in(pipe_switch ? F_pc_A : F_pc_B), .out(D_pc_B), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));
   Nbit_reg #(16) D_pc_plus_one_reg_B (.in(pipe_switch ? D_pc_plus_one_A : F_pc_plus_one_B), .out(D_pc_plus_one_B), .clk(clk), .we(!FD_no_update), .gwe(gwe), .rst(rst || flush_A || flush_B));


   wire [2:0] D_rs_sel_A, D_rt_sel_A, D_rd_sel_A;
   wire D_rs_re_A, D_rt_re_A, D_regfile_we_A, D_nzp_we_A, D_select_pc_plus_one_A, D_is_load_A, D_is_store_A, D_is_branch_A, D_is_control_insn_A;

   lc4_decoder D_decoder_A (.insn(D_insn_A),               // instruction (in D stage)
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

   lc4_decoder D_decoder_B (.insn(D_insn_B),               // instruction (in D stage)
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

   lc4_regfile_ss #(.n(16)) regfile 
         (.clk(clk), .gwe(gwe), .rst(rst), 
         .i_rs_A(D_rs_sel_A), .o_rs_data_A(D_rs_data_A), 
         .i_rt_A(D_rt_sel_A), .o_rt_data_A(D_rt_data_A), 
         .i_rd_A(W_rd_sel_A), .i_wdata_A(W_regfile_data_to_write_A), .i_rd_we_A(W_regfile_we_A),
         
         .i_rs_B(D_rs_sel_B), .o_rs_data_B(D_rs_data_B), 
         .i_rt_B(D_rt_sel_B), .o_rt_data_B(D_rt_data_B), 
         .i_rd_B(W_rd_sel_B), .i_wdata_B(W_regfile_data_to_write_B), .i_rd_we_B(W_regfile_we_B)
         
         );





   
   //  ----****************************************---
   //  ----************--- X stage ----************---
   //  ----****************************************---

   
   //PIPE REGISTERS
   //Note: we reset (see each .rst) if there is a flush or a load_to_use, because resetting X is the same as throwing a NOP in
   //pipe A
   wire [15:0] X_rs_data_A, X_rt_data_A, X_insn_A, X_pc_A, X_pc_plus_one_A;
   wire X_rst_A = flush_A || ldr_stall_A;
   Nbit_reg #(16) X_rs_data_reg_A (.in(D_rs_data_A), .out(X_rs_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(16) X_rt_data_reg_A (.in(D_rt_data_A), .out(X_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(16) X_insn_reg_A (.in(D_insn_A), .out(X_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A)); //will be NOP when stalling
   Nbit_reg #(16) X_pc_reg_A (.in(D_pc_A), .out(X_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));       //will be 000 when stalling
   Nbit_reg #(16) X_pc_plus_one_reg_A (.in(D_pc_plus_one_A), .out(X_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));

   wire [2:0] X_rs_sel_A, X_rt_sel_A, X_rd_sel_A;
   Nbit_reg #(3) X_rs_sel_reg_A (.in(D_rs_sel_A), .out(X_rs_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(3) X_rt_sel_reg_A (.in(D_rt_sel_A), .out(X_rt_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(3) X_rd_sel_reg_A (.in(D_rd_sel_A), .out(X_rd_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));

   wire X_regfile_we_A, X_nzp_we_A, X_select_pc_plus_one_A;
   Nbit_reg #(1) X_regfile_we_reg_A (.in(D_regfile_we_A), .out(X_regfile_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(1) X_nzp_we_reg_A (.in(D_nzp_we_A), .out(X_nzp_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(1) X_sel_pc_plus_one_reg_A (.in(D_select_pc_plus_one_A), .out(X_select_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   
   wire X_is_load_A, X_is_branch_A, X_is_store_A, X_is_control_insn_A;
   Nbit_reg #(1) X_is_load_reg_A (.in(D_is_load_A), .out(X_is_load_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(1) X_is_store_reg_A (.in(D_is_store_A), .out(X_is_store_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(1) X_is_branch_reg_A (.in(D_is_branch_A), .out(X_is_branch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));
   Nbit_reg #(1) X_is_control_insn_reg_A (.in(D_is_control_insn_A), .out(X_is_control_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_A));


   //pipe B
   wire X_rst_B = flush_A || flush_B || pipe_switch || ldr_stall_A; //recall: pipe switch on ldr_stall_B, D_both_memory, D_super_dependency
   wire [15:0] X_rs_data_B, X_rt_data_B, X_insn_B, X_pc_B, X_pc_plus_one_B;
   Nbit_reg #(16) X_rs_data_reg_B (.in(D_rs_data_B), .out(X_rs_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(16) X_rt_data_reg_B (.in(D_rt_data_B), .out(X_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(16) X_insn_reg_B (.in(D_insn_B), .out(X_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B)); //will be NOP when stalling
   Nbit_reg #(16) X_pc_reg_B (.in(D_pc_B), .out(X_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));       //will be 000 when stalling
   Nbit_reg #(16) X_pc_plus_one_reg_B (.in(D_pc_plus_one_B), .out(X_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));

   wire [2:0] X_rs_sel_B, X_rt_sel_B, X_rd_sel_B;
   Nbit_reg #(3) X_rs_sel_reg_B (.in(D_rs_sel_B), .out(X_rs_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(3) X_rt_sel_reg_B (.in(D_rt_sel_B), .out(X_rt_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(3) X_rd_sel_reg_B (.in(D_rd_sel_B), .out(X_rd_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));

   wire X_regfile_we_B, X_nzp_we_B, X_select_pc_plus_one_B;
   Nbit_reg #(1) X_regfile_we_reg_B (.in(D_regfile_we_B), .out(X_regfile_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(1) X_nzp_we_reg_B (.in(D_nzp_we_B), .out(X_nzp_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || flush_A || X_rst_B));
   Nbit_reg #(1) X_sel_pc_plus_one_reg_B (.in(D_select_pc_plus_one_B), .out(X_select_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   
   wire X_is_load_B, X_is_branch_B, X_is_store_B, X_is_control_insn_B;
   Nbit_reg #(1) X_is_load_reg_B (.in(D_is_load_B), .out(X_is_load_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(1) X_is_store_reg_B (.in(D_is_store_B), .out(X_is_store_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(1) X_is_branch_reg_B (.in(D_is_branch_B), .out(X_is_branch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));
   Nbit_reg #(1) X_is_control_insn_reg_B (.in(D_is_control_insn_B), .out(X_is_control_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst || X_rst_B));


   
   // ---- ALU stuff -----
   wire [15:0] X_rs_bypass_val_mux1_A, X_rt_bypass_val_mux2_A, X_alu_output_A;
   assign X_rs_bypass_val_mux1_A = 
         ((X_rs_sel_A == M_rd_sel_B) && M_regfile_we_B) ? M_alu_output_B : // MB -> XA Bypass
         ((X_rs_sel_A == M_rd_sel_A) && M_regfile_we_A) ? M_alu_output_A : // MA -> XA Bypass

         ((X_rs_sel_A == W_rd_sel_B) && W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XA Bypass
         ((X_rs_sel_A == W_rd_sel_A) && W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XA Bypass

         X_rs_data_A;
   assign X_rt_bypass_val_mux2_A = 
         ((X_rt_sel_A == M_rd_sel_B) && M_regfile_we_B) ? M_alu_output_B : // MB -> XA Bypass
         ((X_rt_sel_A == M_rd_sel_A) && M_regfile_we_A) ? M_alu_output_A : // MA -> XA Bypass

         ((X_rt_sel_A == W_rd_sel_B) && W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XA Bypass
         ((X_rt_sel_A == W_rd_sel_A) && W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XA Bypass

         X_rt_data_A;
   lc4_alu alu_A 
      (.i_insn(X_insn_A), .i_pc(X_pc_A),
      .i_r1data(X_rs_bypass_val_mux1_A), .i_r2data(X_rt_bypass_val_mux2_A),
      .o_result(X_alu_output_A)
      );


   wire [15:0] X_rs_bypass_val_mux1_B, X_rt_bypass_val_mux2_B, X_alu_output_B;
   assign X_rs_bypass_val_mux1_B = 
         (X_rs_sel_B == M_rd_sel_B & M_regfile_we_B) ? M_alu_output_B : // MB -> XA Bypass
         (X_rs_sel_B == M_rd_sel_A & M_regfile_we_A) ? M_alu_output_A : // MA -> XA Bypass

         (X_rs_sel_B == W_rd_sel_B & W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XA Bypass
         (X_rs_sel_B == W_rd_sel_A & W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XA Bypass

         X_rs_data_B;
   assign X_rt_bypass_val_mux2_B = 
         (X_rt_sel_B == M_rd_sel_B & M_regfile_we_B) ? M_alu_output_B : // MB -> XB Bypass
         (X_rt_sel_B == M_rd_sel_A & M_regfile_we_A) ? M_alu_output_A : // MA -> XB Bypass
         
         (X_rt_sel_B == W_rd_sel_B & W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XB Bypass
         (X_rt_sel_B == W_rd_sel_A & W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XB Bypass

         X_rt_data_B;
   lc4_alu alu_B 
      (.i_insn(X_insn_B), .i_pc(X_pc_B),
      .i_r1data(X_rs_bypass_val_mux1_B), .i_r2data(X_rt_bypass_val_mux2_B),
      .o_result(X_alu_output_B)
      );

   
   //prioritize B, and if not then try A
   // ----  NZP stuff ------
   wire [2:0] X_nzp_newbits_A;
   wire X_writes_to_r7_A = (X_insn_A[15:12] == 4'b1111 || //TRAP
                        X_insn_A[15:12] == 4'b0100 || //JSR/JSRR
                        X_insn_A[15:12] == 4'b1000); //RTI //TODO: maybe remove this? RTI doesn't write to R7... :(
   wire [15:0] X_nzp_wdata_A = 
                     (X_writes_to_r7_A) ? X_pc_plus_one_A :
                     X_alu_output_A;
   
   assign X_nzp_newbits_A = (X_nzp_wdata_A == 0) ? 3'b010 : //Z
                        (X_nzp_wdata_A[15] == 0) ? 3'b001 : //P
                        3'b100; //N

   wire [2:0] X_nzp_newbits_B;
   wire X_writes_to_r7_B = (X_insn_B[15:12] == 4'b1111 || //TRAP
                        X_insn_B[15:12] == 4'b0100 || //JSR/JSRR
                        X_insn_B[15:12] == 4'b1000); //RTI //TODO: maybe remove this? RTI doesn't write to R7... :(
   wire [15:0] X_nzp_wdata_B = 
                     (X_writes_to_r7_B) ? X_pc_plus_one_B :
                     X_alu_output_B;
   
   assign X_nzp_newbits_B = (X_nzp_wdata_B == 0) ? 3'b010 : //Z
                        (X_nzp_wdata_B[15] == 0) ? 3'b001 : //P
                        3'b100; //N

   wire [2:0] X_nzp_newbits_choose;
   assign X_nzp_newbits_choose = X_nzp_we_B ? X_nzp_newbits_B :
                                 X_nzp_we_A ? X_nzp_newbits_A :
                                 3'b000;
   wire X_nzp_we_choose;
   assign X_nzp_we_choose = X_nzp_we_B || X_nzp_we_A;

   wire [2:0] nzp_reg_output;
   Nbit_reg #(3) nzp_reg 
      (.in(X_nzp_newbits_choose), .out(nzp_reg_output),
      .clk(clk), .we(X_nzp_we_choose), .gwe(gwe), .rst(rst));
      
       

   //----MEMORY STUFF-----   
   
   

   //  ----****************************************---
   //  ----************--- M stage ----************---
   //  ----****************************************---

   //TODO: ***FOR LAB PART B***:
      //there is a new MM bypass, will need to implement:
         //which forwards data from the M stage of pipe A to the M stage of pipe B. 
         //This is used when you have for example an ADD to register x followed directly by a STR of register x (for the data only, not the address!).
   
   //pipe A
   wire [15:0] M_alu_output_A, M_rt_data_A, M_insn_A, M_pc_A, M_pc_plus_one_A;
   Nbit_reg #(16) M_alu_output_reg_A (.in(X_alu_output_A), .out(M_alu_output_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_rt_data_reg_A (.in(X_rt_bypass_val_mux2_A), .out(M_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_insn_reg_A (.in(X_insn_A), .out(M_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_reg_A (.in(X_pc_A), .out(M_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_plus_one_reg_A (.in(X_pc_plus_one_A), .out(M_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] M_rs_sel_A, M_rt_sel_A, M_rd_sel_A;
   Nbit_reg #(3) M_rs_sel_reg_A (.in(X_rs_sel_A), .out(M_rs_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rt_sel_reg_A (.in(X_rt_sel_A), .out(M_rt_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rd_sel_reg_A (.in(X_rd_sel_A), .out(M_rd_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_regfile_we_A, M_nzp_we_A, M_select_pc_plus_one_A;
   Nbit_reg #(1) M_regfile_we_reg_A (.in(X_regfile_we_A), .out(M_regfile_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_nzp_we_reg_A (.in(X_nzp_we_A), .out(M_nzp_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_sel_pc_plus_one_reg_A (.in(X_select_pc_plus_one_A), .out(M_select_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [2:0] M_nzp_newbits_A;
   Nbit_reg #(3) M_nzp_newbits_reg_A (.in(X_nzp_newbits_A), .out(M_nzp_newbits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_is_load_A, M_is_branch_A, M_is_store_A, M_is_control_insn_A;
   Nbit_reg #(1) M_is_load_reg_A (.in(X_is_load_A), .out(M_is_load_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_store_reg_A (.in(X_is_store_A), .out(M_is_store_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_branch_reg_A (.in(X_is_branch_A), .out(M_is_branch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_control_insn_reg_A (.in(X_is_control_insn_A), .out(M_is_control_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //pipe B
   wire [15:0] M_alu_output_B, M_rt_data_B, M_insn_B, M_pc_B, M_pc_plus_one_B;
   Nbit_reg #(16) M_alu_output_reg_B (.in(X_alu_output_B), .out(M_alu_output_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_rt_data_reg_B (.in(X_rt_bypass_val_mux2_B), .out(M_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_insn_reg_B (.in(X_insn_B), .out(M_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_reg_B (.in(X_pc_B), .out(M_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_plus_one_reg_B (.in(X_pc_plus_one_B), .out(M_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] M_rs_sel_B, M_rt_sel_B, M_rd_sel_B;
   Nbit_reg #(3) M_rs_sel_reg_B (.in(X_rs_sel_B), .out(M_rs_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rt_sel_reg_B (.in(X_rt_sel_B), .out(M_rt_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rd_sel_reg_B (.in(X_rd_sel_B), .out(M_rd_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_regfile_we_B, M_nzp_we_B, M_select_pc_plus_one_B;
   Nbit_reg #(1) M_regfile_we_reg_B (.in(X_regfile_we_B), .out(M_regfile_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_nzp_we_reg_B (.in(X_nzp_we_B), .out(M_nzp_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_sel_pc_plus_one_reg_B (.in(X_select_pc_plus_one_B), .out(M_select_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [2:0] M_nzp_newbits_B;
   Nbit_reg #(3) M_nzp_newbits_reg_B (.in(X_nzp_newbits_B), .out(M_nzp_newbits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_is_load_B, M_is_branch_B, M_is_store_B, M_is_control_insn_B;
   Nbit_reg #(1) M_is_load_reg_B (.in(X_is_load_B), .out(M_is_load_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_store_reg_B (.in(X_is_store_B), .out(M_is_store_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_branch_reg_B (.in(X_is_branch_B), .out(M_is_branch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_control_insn_reg_B (.in(X_is_control_insn_B), .out(M_is_control_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //bypasses
   wire [15:0] M_dmem_data_bypass_mux3_A;
   assign M_dmem_data_bypass_mux3_A = 
               (M_is_store_A && (M_rt_sel_A == W_rd_sel_B) && W_regfile_we_B) ? W_memory_or_alu_output_B : //WB -> MA bypass
               (M_is_store_A && (M_rt_sel_A == W_rd_sel_A) && W_regfile_we_A) ? W_memory_or_alu_output_A : //WA -> MA bypass
               M_rt_data_A;

   wire [15:0] M_memory_or_alu_output_A, M_regfile_data_to_write_A;
   assign M_memory_or_alu_output_A = M_is_load_A ? i_cur_dmem_data :
                                             M_alu_output_A;   
   assign M_regfile_data_to_write_A = M_select_pc_plus_one_A ? M_pc_plus_one_A :
                                    M_memory_or_alu_output_A;

   wire [15:0] M_dmem_data_bypass_mux3_B;
   assign M_dmem_data_bypass_mux3_B = 
               (M_is_store_B && (M_rt_sel_B == W_rd_sel_B) && W_regfile_we_B) ? W_memory_or_alu_output_B : //WB -> MB bypass
               (M_is_store_B && (M_rt_sel_B == W_rd_sel_A) && W_regfile_we_A) ? W_memory_or_alu_output_A : //WA -> MB bypass
               M_rt_data_B;

   wire [15:0] M_memory_or_alu_output_B, M_regfile_data_to_write_B;
   assign M_memory_or_alu_output_B = M_is_load_B ? i_cur_dmem_data :
                                             M_alu_output_B;   
   assign M_regfile_data_to_write_B = M_select_pc_plus_one_B ? M_pc_plus_one_B :
                                    M_memory_or_alu_output_B;


   wire [15:0] MM_bypass_mux4_B =  //note: rt is the register whose data we are storing
            M_is_store_B && M_regfile_we_A && (M_rt_sel_B == M_rd_sel_A) ? M_alu_output_A : //MM Bypass
            M_dmem_data_bypass_mux3_B;

   
   //making these just for test wires
   wire M_dmem_we_A = M_is_store_A;
   wire M_dmem_we_B = M_is_store_B;
   wire [15:0] M_dmem_addr_A = M_is_store_A || M_is_load_A ? M_alu_output_A : 16'b0;
   wire [15:0] M_dmem_addr_B = M_is_store_B || M_is_load_B ? M_alu_output_B : 16'b0;
   wire [15:0] M_dmem_data_A = 
                  M_is_store_A ? M_dmem_data_bypass_mux3_A :
                  M_is_load_A ? i_cur_dmem_data :
                  16'b0;
   wire [15:0] M_dmem_data_B = 
                  M_is_store_B ? MM_bypass_mux4_B : 
                  M_is_load_B ? i_cur_dmem_data :
                  16'b0;

   //Setting wires for memory module
   assign o_dmem_we = M_is_store_A || M_is_store_B;
      // 1'b0;
   assign o_dmem_addr = M_is_store_B || M_is_load_B ? M_alu_output_B :
                        M_is_store_A || M_is_load_A ? M_alu_output_A :
                        16'b0; 
      //16'b0;
   assign o_dmem_towrite = M_is_store_B ? MM_bypass_mux4_B :
                           M_is_store_A ? M_dmem_data_bypass_mux3_A :
                           16'b0;
      //16'b0;




   //  ----****************************************---
   //  ----************--- W stage ----************---
   //  ----****************************************---

   //pipe A
   wire [15:0] W_alu_output_A, W_dmem_data_output_A, W_insn_A, W_pc_A, W_pc_plus_one_A;
   Nbit_reg #(16) W_alu_output_reg_A (.in(M_alu_output_A), .out(W_alu_output_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_datamem_reg_A (.in(i_cur_dmem_data), .out(W_dmem_data_output_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_insn_reg_A (.in(M_insn_A), .out(W_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_reg_A (.in(M_pc_A), .out(W_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_plus_one_reg_A (.in(M_pc_plus_one_A), .out(W_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] W_rd_sel_A;
   Nbit_reg #(3) W_rd_sel_reg_A (.in(M_rd_sel_A), .out(W_rd_sel_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire W_regfile_we_A, W_nzp_we_A, W_select_pc_plus_one_A;
   Nbit_reg #(1) W_regfile_we_reg_A (.in(M_regfile_we_A), .out(W_regfile_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_nzp_we_reg_A (.in(M_nzp_we_A), .out(W_nzp_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_sel_pc_plus_one_reg_A (.in(M_select_pc_plus_one_A), .out(W_select_pc_plus_one_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire [15:0] W_dmem_data_A, W_dmem_addr_A;
   wire W_dmem_we_A;
   Nbit_reg #(16) W_dmem_data_reg_A (.in(M_dmem_data_A), .out(W_dmem_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_dmem_addr_reg_A (.in(M_dmem_addr_A), .out(W_dmem_addr_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_dmem_we_reg_A (.in(M_dmem_we_A), .out(W_dmem_we_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire W_is_load_A, W_is_branch_A, W_is_control_insn_A;
   Nbit_reg #(1) W_is_load_reg_A (.in(M_is_load_A), .out(W_is_load_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_branch_reg_A (.in(M_is_branch_A), .out(W_is_branch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_control_insn_reg_A (.in(M_is_control_insn_A), .out(W_is_control_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire W_is_store_A;
   assign W_is_store_A = W_dmem_we_A; //I know this is unecessary but helps with naming convention

   wire [15:0] W_memory_or_alu_output_A, W_regfile_data_to_write_A;
   Nbit_reg #(16) W_mem_or_alu_reg_A (.in(M_memory_or_alu_output_A), .out(W_memory_or_alu_output_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_regfile_data_reg_A (.in(M_regfile_data_to_write_A), .out(W_regfile_data_to_write_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //pipe B
   wire [15:0] W_alu_output_B, W_dmem_data_output_B, W_insn_B, W_pc_B, W_pc_plus_one_B;
   Nbit_reg #(16) W_alu_output_reg_B (.in(M_alu_output_B), .out(W_alu_output_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_datamem_reg_B (.in(i_cur_dmem_data), .out(W_dmem_data_output_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_insn_reg_B (.in(M_insn_B), .out(W_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_reg_B (.in(M_pc_B), .out(W_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_plus_one_reg (.in(M_pc_plus_one_B), .out(W_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] W_rd_sel_B;
   Nbit_reg #(3) W_rd_sel_reg_B (.in(M_rd_sel_B), .out(W_rd_sel_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire W_regfile_we_B, W_nzp_we_B, W_select_pc_plus_one_B;
   Nbit_reg #(1) W_regfile_we_reg_B (.in(M_regfile_we_B), .out(W_regfile_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_nzp_we_reg_B (.in(M_nzp_we_B), .out(W_nzp_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_sel_pc_plus_one_reg_B (.in(M_select_pc_plus_one_B), .out(W_select_pc_plus_one_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] W_dmem_data_B, W_dmem_addr_B;
   wire W_dmem_we_B;
   Nbit_reg #(16) W_dmem_data_reg_B (.in(M_dmem_data_B), .out(W_dmem_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_dmem_addr_reg_B (.in(M_dmem_addr_B), .out(W_dmem_addr_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_dmem_we_reg_B (.in(M_dmem_we_B), .out(W_dmem_we_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   wire W_is_load_B, W_is_branch_B, W_is_control_insn_B;
   Nbit_reg #(1) W_is_load_reg_B (.in(M_is_load_B), .out(W_is_load_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_branch_reg_B (.in(M_is_branch_B), .out(W_is_branch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_control_insn_reg_B (.in(M_is_control_insn_B), .out(W_is_control_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire W_is_store_B;
   assign W_is_store_B = W_dmem_we_B; //I know this is unecessary but helps with naming convention

   wire [15:0] W_memory_or_alu_output_B, W_regfile_data_to_write_B;
   Nbit_reg #(16) W_mem_or_alu_reg_B (.in(M_memory_or_alu_output_B), .out(W_memory_or_alu_output_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_regfile_data_reg_B (.in(M_regfile_data_to_write_B), .out(W_regfile_data_to_write_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   //TODO: TODO: TODO: TODO: figureout what newbits should look like for the dif pipes [//TODO: FOR LAB part B]
   //    - I think we prioritize B's newbits, but also think about how to check if B is NOP and if so, then do A's newbits
      wire [2:0] M_nzp_newbits_load = (i_cur_dmem_data == 0) ? 3'b010 : //Z
                           (i_cur_dmem_data[15] == 0) ? 3'b001 : //P
                           3'b100;
      
      wire [2:0] W_nzp_newbits_A;
      Nbit_reg #(3) W_nzp_newbits_reg_A (.in(M_is_load_A ? M_nzp_newbits_load : M_nzp_newbits_A), .out(W_nzp_newbits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

      wire [2:0] W_nzp_newbits_B;
      Nbit_reg #(3) W_nzp_newbits_reg_B (.in(M_is_load_B ? M_nzp_newbits_load : M_nzp_newbits_B), .out(W_nzp_newbits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   

   //if pipe switch, just want pc+1. otherwise want the normal pc+2
   wire [15:0] pc_incremented;
   assign pc_incremented = pipe_switch ? F_pc_plus_one_A : //that is, pc+1
                                         F_pc_plus_one_B;  //that is, pc+2

   assign next_pc = flush_A ? X_alu_output_A : flush_B ? X_alu_output_B :
                     pc_incremented;
   
   
   
   // ---- TEST WIRES -----
   
   assign test_cur_pc_A = W_pc_A;                // Testbench: program counter
   assign test_cur_insn_A = W_insn_A;           // Testbench: instruction bits
   assign test_regfile_we_A = W_regfile_we_A;       // Testbench: register file write enable
   assign test_regfile_wsel_A = W_rd_sel_A;           // Testbench: which register to write in the register file 
   assign test_regfile_data_A = W_regfile_data_to_write_A; // Testbench: value to write into the register file
   assign test_nzp_we_A = W_nzp_we_A;                 // Testbench: NZP condition codes write enable
   assign test_nzp_new_bits_A = W_nzp_newbits_A;    // Testbench: value to write to NZP bits
   assign test_dmem_we_A = W_dmem_we_A;             // Testbench: data memory write enable
   assign test_dmem_addr_A = W_dmem_addr_A;         // Testbench: address to read/write memory
   assign test_dmem_data_A = W_dmem_data_A;         // Testbench: value read/writen from/to memory
   assign test_stall_A = W_stall_A;



   assign test_cur_pc_B = W_pc_B;                // Testbench: program counter
   assign test_cur_insn_B = W_insn_B;           // Testbench: instruction bits
   assign test_regfile_we_B = W_regfile_we_B;       // Testbench: register file write enable
   assign test_regfile_wsel_B = W_rd_sel_B;           // Testbench: which register to write in the register file 
   assign test_regfile_data_B = W_regfile_data_to_write_B; // Testbench: value to write into the register file
   assign test_nzp_we_B = W_nzp_we_B;                 // Testbench: NZP condition codes write enable
   assign test_nzp_new_bits_B = W_nzp_newbits_B;    // Testbench: value to write to NZP bits
   assign test_dmem_we_B = W_dmem_we_B;             // Testbench: data memory write enable
   assign test_dmem_addr_B = W_dmem_addr_B;               // Testbench: address to read/write memory
   assign test_dmem_data_B = W_dmem_data_B;               // Testbench: value read/writen from/to memory
   assign test_stall_B = W_stall_B;








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
      if (1) begin
         $display("--------------------");
         $display("FA f_pc: %h, i_cur_insn_a: %h", F_pc_A, i_cur_insn_A);
         $display("FB f_pc: %h, i_cur_insn_b: %h", F_pc_B, i_cur_insn_B);
         
         $display(" DA d_pc: %h | r%d: %h | r%d: %h", D_pc_A, D_rs_sel_A, D_rs_data_A, D_rt_sel_A, D_rt_data_A);
         $display(" DB d_pc: %h | r%d: %h | r%d: %h", D_pc_B, D_rs_sel_B, D_rs_data_B, D_rt_sel_B, D_rt_data_B);
         $display(" DSUP d_rd_we_B  %b | d_rd_sel_B  %b | d_rs_sel_A %b | d_rs_sel_A %b:", D_regfile_we_A, D_rd_sel_A, D_rs_sel_B, D_rt_sel_B);

         $display("  XA x_pc: %h | alu1: %h | alu2: %h | alu_out: %h", X_pc_A, X_rs_bypass_val_mux1_A, X_rt_bypass_val_mux2_A, X_alu_output_A);
         $display("  XB x_pc: %h | alu1: %h | alu2: %h | alu_out: %h", X_pc_B, X_rs_bypass_val_mux1_B, X_rt_bypass_val_mux2_B, X_alu_output_B);

         
         $display("   MA m_pc: %h | dmem_addr: %h | dmem_we: %b | dmem_data: %h", M_pc_A, M_dmem_addr_A, M_dmem_we_A, M_dmem_data_A);
         $display("   MB m_pc: %h | dmem_addr: %h | dmem_we: %b | dmem_data: %h", M_pc_B, M_dmem_addr_B, M_dmem_we_B, M_dmem_data_B);
         $display("   -o_dmem_we: %b | o_dmem_addr: %h | o_dmem_towrite: %h | i_cur_dmem_data : %h", o_dmem_we, o_dmem_addr, o_dmem_towrite, i_cur_dmem_data);

         
         $display("    WA w_pc: %h | w_insn: %h | writing to r%d | wdata: %h | regfile_we: %b | dmem_addr: %h | dmem_we: %b | dmem_data: %h | is_load: %b | is_store: %b", 
            W_pc_A, W_insn_A, W_rd_sel_A, W_regfile_data_to_write_A, W_regfile_we_A, W_dmem_addr_A, W_dmem_we_A, test_dmem_data_A, W_is_load_A, W_is_store_A);
         $display("    WB w_pc: %h | w_insn: %h | writing to r%d | wdata: %h | regfile_we: %b | dmem_addr: %h | dmem_we: %b | dmem_data: %h | is_load: %b | is_store: %b", 
            W_pc_B, W_insn_B, W_rd_sel_B, W_regfile_data_to_write_B, W_regfile_we_B, W_dmem_addr_B, W_dmem_we_B, test_dmem_data_B, W_is_load_B, W_is_store_B);
         $display("    -M_dmem_data_bypass_B: %h | MM_bypass_mux4_B: %h, | W_memoralu_A : %h | W_memoralu_A : %h | M_rt_data_B : %h", M_dmem_data_bypass_mux3_B, MM_bypass_mux4_B, W_memory_or_alu_output_A, W_memory_or_alu_output_B, M_rt_data_B);

         $display("xnzp: %b | next_pc: %h", nzp_reg_output, next_pc);
         $display("flush A: %b | flush B: %b | ldr_stall A: %b | ldr_stall B: %b | D_super_dependency: %b | D_both_mem: %b | pipe switch: %b", flush_A, flush_B, ldr_stall_A, ldr_stall_B, D_super_dependency, D_both_memory, pipe_switch);
         
         $display("StallA F_stall: %b | D_stall: %b | X_stall: %b | M_stall: %b | W_stall: %b", F_stall_A, D_stall_A, X_stall_A, M_stall_A, W_stall_A);
         $display("StallB F_stall: %b | D_stall: %b | X_stall: %b | M_stall: %b | W_stall: %b", F_stall_B, D_stall_B, X_stall_B, M_stall_B, W_stall_B);

         $display("- M-XA: X_rs_A: %b, M_rd_sel_B: %b, M_regfile_we_B: %b, M_alu_output_B: %h, M_rd_sel_A: %h, M_alu_output_A: %h", X_rs_sel_A, M_rd_sel_B, M_regfile_we_B, M_alu_output_B, M_rd_sel_A, M_alu_output_A);
         $display("-FD no up: %b", FD_no_update);

   //    assign X_rs_bypass_val_mux1_A = 
   //       ((X_rs_sel_A == M_rd_sel_B) && M_regfile_we_B) ? M_alu_output_B : // MB -> XA Bypass
   //       ((X_rs_sel_A == M_rd_sel_A) && M_regfile_we_A) ? M_alu_output_A : // MA -> XA Bypass

   //       ((X_rs_sel_A == W_rd_sel_B) && W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XA Bypass
   //       ((X_rs_sel_A == W_rd_sel_A) && W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XA Bypass

   //       X_rs_data_A;
   // assign X_rt_bypass_val_mux2_A = 
   //       ((X_rt_sel_A == M_rd_sel_B) && M_regfile_we_B) ? M_alu_output_B : // MB -> XA Bypass
   //       ((X_rt_sel_A == M_rd_sel_A) && M_regfile_we_A) ? M_alu_output_A : // MA -> XA Bypass

   //       ((X_rt_sel_A == W_rd_sel_B) && W_regfile_we_B)? W_memory_or_alu_output_B : // WB -> XA Bypass
   //       ((X_rt_sel_A == W_rd_sel_A) && W_regfile_we_A)? W_memory_or_alu_output_A : // WA -> XA Bypass

   //       X_rt_data_A;


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
