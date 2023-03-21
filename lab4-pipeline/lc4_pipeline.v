/* TODO: name and PennKeys of all group members here */
//Charlie Gottlieb : cbg613
//Keith Bonwitt : kbonwitt



/*THOUGHTS & TODOs
   - we should probably have a whole new decoder for EACH stage, not just at start
   - the pc_plus_one wire is only utilized in the W stage, so probably compute it there
   - do we need to propogate the cur_pc through each stage? not certain, have to think about it
   - definitely need to comb through all wire stuff (like in 'other muxes' in W)
      to rename all wires to have W_, D_, etc prefixes, since this was copy-pasted from the 
      singlecycle file. Do NOT assume anything works until every line is checked for this.
   - haven't started implementing:
      - stall logic (when it happens and what it does, like NOPing and holding the PC)
      - branch prediction stuff (might not be necessary until part b, bc part a is just ALU insns)
      - bypasses

*/



`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /*** YOUR CODE HERE ***/

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;


   //  ----****************************************---
   //  ----************--- F stage ----************---
   //  ----****************************************---


   // pc wires attached to the PC register's ports
   wire [15:0]   F_pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)
      //note: this will come into play with branch prediction and stalling/flushing

   Nbit_reg #(16, 16'h8200) F_pc_reg (.in(next_pc), .out(F_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   //  ----****************************************---
   //  ----************--- D stage ----************---
   //  ----****************************************---

   wire [15:0] D_insn, D_pc;

   // wire [15:0] new_or_old_insn, new_or_old_pc; //loop back onto yourself if there is a stall
   // assign new_or_old_insn = i_cur_insn;
   // //(stall == 0) ? i_cur_insn :  D_insn;
   // assign new_or_old_pc = (stall == 0) ? F_pc :
   //                      D_pc; 

   wire D_read_new;
   assign D_read_new = (stall == 0);
      //this is for write enable for the regs below. If there is no stall, WE=1 so get next INSN/PC from F.
         //if there IS a stall, WE=0, so just 'keep' what you have now.                     
   
   Nbit_reg #(16) D_insn_reg (.in(i_cur_insn), .out(D_insn), .clk(clk), .we(D_read_new), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) D_pc_reg (.in(F_pc), .out(D_pc), .clk(clk), .we(D_read_new), .gwe(gwe), .rst(rst));


   assign o_cur_pc = F_pc; 

   wire [2:0] D_rs_sel, D_rt_sel, D_rd_sel;
   wire D_r1re, D_r2re, D_regfile_we, D_nzp_we, D_select_pc_plus_one, D_is_load, D_is_store, D_is_branch, D_is_control_insn;
   
   // wire [15:0] insn_or_NOP;
   // assign insn_or_NOP = (stall == 0) ? D_insn :
   //                      16'b0; //NOP 

   lc4_decoder D_decoder(.insn(D_insn),               // instruction (in D stage)
                       .r1sel(D_rs_sel),              // rs
                       .r1re(D_r1re),               // does this instruction read from rs?
                       .r2sel(D_rt_sel),              // rt
                       .r2re(D_r2re),               // does this instruction read from rt?
                       .wsel(D_rd_sel),               // rd
                       .regfile_we(D_regfile_we),         // does this instruction write to rd?
                       .nzp_we(D_nzp_we),             // does this instruction write the NZP bits?
                       .select_pc_plus_one(D_select_pc_plus_one), // write PC+1 to the regfile?
                       .is_load(D_is_load),            // is this a load instruction?
                       .is_store(D_is_store),           // is this a store instruction?
                       .is_branch(D_is_branch),          // is this a branch instruction?
                       .is_control_insn(D_is_control_insn)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );

   // ---- Regfile stuff ----

   wire [15:0] D_rs_data, D_rt_data, D_rs_data_tmp, D_rt_data_tmp;
   wire [15:0] W_regfile_data_to_write;

   lc4_regfile #(.n(16)) regfile 
         (.clk(clk), .gwe(gwe), .rst(rst), 
         .i_rs(D_rs_sel), .o_rs_data(D_rs_data_tmp), 
         .i_rt(D_rt_sel), .o_rt_data(D_rt_data_tmp), 
         .i_rd(W_rd_sel), .i_wdata(W_regfile_data_to_write), .i_rd_we(W_regfile_we)
         );
   
   assign D_rs_data = (W_rd_sel == D_rs_sel & W_regfile_we) ? W_regfile_data_to_write : 
                        D_rs_data_tmp; // WD Bypass
   assign D_rt_data = (W_rd_sel == D_rt_sel & W_regfile_we) ? W_regfile_data_to_write : 
                        D_rt_data_tmp; // WD Bypass

   //  ----****************************************---
   //  ----************--- X stage ----************---
   //  ----****************************************---


   //PIPE REGISTERS
   wire [15:0] X_rs_data, X_rt_data, X_insn, X_pc;

   Nbit_reg #(16) X_rs_data_reg (.in(D_rs_data), .out(X_rs_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) X_rt_data_reg (.in(D_rt_data), .out(X_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) X_insn_reg (.in(D_insn), .out(X_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); //will be NOP when stalling
   Nbit_reg #(16) X_pc_reg (.in(D_pc), .out(X_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));       //will be 000 when stalling

   wire [2:0] X_rs_sel, X_rt_sel, X_rd_sel;
   Nbit_reg #(3) X_rs_sel_reg (.in(D_rs_sel), .out(X_rs_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) X_rt_sel_reg (.in(D_rt_sel), .out(X_rt_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) X_rd_sel_reg (.in(D_rd_sel), .out(X_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire X_regfile_we, X_nzp_we, X_select_pc_plus_one;
   Nbit_reg #(1) X_regfile_we_reg (.in(D_regfile_we), .out(X_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) X_nzp_we_reg (.in(D_nzp_we), .out(X_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) X_pc_plus_one_reg (.in(D_select_pc_plus_one), .out(X_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire X_is_load, X_is_branch, X_is_store, X_is_control_insn;
   Nbit_reg #(1) X_is_load_reg (.in(D_is_load), .out(X_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) X_is_store_reg (.in(D_is_store), .out(X_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) X_is_branch_reg (.in(D_is_branch), .out(X_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) X_is_control_insn_reg (.in(D_is_control_insn), .out(X_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));



   // ---- ALU stuff -----
   //TODO: add muxes for bypasses
   // the 



   wire [15:0] X_alu_output;

   wire [15:0] X_rs_bypass_val_mux1, X_rt_bypass_val_mux2;
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

   wire [15:0] M_alu_output, M_rt_data, M_insn, M_pc;
   Nbit_reg #(16) M_alu_output_reg (.in(X_alu_output), .out(M_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_rt_data_reg (.in(X_rt_bypass_val_mux2), .out(M_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_insn_reg (.in(X_insn), .out(M_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_reg (.in(X_pc), .out(M_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   

   wire [2:0] M_rs_sel, M_rt_sel, M_rd_sel;
   Nbit_reg #(3) M_rs_sel_reg (.in(X_rs_sel), .out(M_rs_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rt_sel_reg (.in(X_rt_sel), .out(M_rt_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3) M_rd_sel_reg (.in(X_rd_sel), .out(M_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire M_regfile_we, M_nzp_we, M_select_pc_plus_one;
   Nbit_reg #(1) M_regfile_we_reg (.in(X_regfile_we), .out(M_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_nzp_we_reg (.in(X_nzp_we), .out(M_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_pc_plus_one_reg (.in(X_select_pc_plus_one), .out(M_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire M_is_load, M_is_branch, M_is_store, M_is_control_insn;
   Nbit_reg #(1) M_is_load_reg (.in(X_is_load), .out(M_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_store_reg (.in(X_is_store), .out(M_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_branch_reg (.in(X_is_branch), .out(M_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) M_is_control_insn_reg (.in(X_is_control_insn), .out(M_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));



   // ---- MEMORY stuff -----  
   wire [15:0] M_dmem_data_bypass_mux3;
   assign M_dmem_data_bypass_mux3 = (M_is_store && M_rt_sel == W_rd_sel) ? W_memory_or_alu_output :
                                    M_rt_data;
                                    


   assign o_dmem_we = M_is_store;
   assign o_dmem_addr = (M_is_load || M_is_store) ? M_alu_output : 16'b0;
   assign o_dmem_towrite = (M_is_store) ? M_dmem_data_bypass_mux3 : 16'b0;



   //  ----****************************************---
   //  ----************--- W stage ----************---
   //  ----****************************************---
   wire [15:0] W_alu_output, W_dmem_data_output, W_insn, W_pc;
   Nbit_reg #(16) W_alu_output_reg (.in(M_alu_output), .out(W_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_datamem_reg (.in(i_cur_dmem_data), .out(W_dmem_data_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_insn_reg (.in(M_insn), .out(W_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_reg (.in(M_pc), .out(W_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] W_dmem_data_input;
   Nbit_reg #(16) W_dmem_data_reg (.in(M_dmem_data_bypass_mux3), .out(W_dmem_data_input), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] W_dmem_addr;
   Nbit_reg #(16) W_dmem_addr_reg (.in(M_alu_output), .out(W_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] W_rd_sel;
   Nbit_reg #(3) W_rd_sel_reg (.in(M_rd_sel), .out(W_rd_sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire W_regfile_we, W_nzp_we, W_select_pc_plus_one, W_dmem_we;
   Nbit_reg #(1) W_regfile_we_reg (.in(M_regfile_we), .out(W_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_nzp_we_reg (.in(M_nzp_we), .out(W_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_pc_plus_one_reg (.in(M_select_pc_plus_one), .out(W_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_dmem_we_reg (.in(M_is_store), .out(W_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   
   wire W_is_load, W_is_branch, W_is_control_insn;
   Nbit_reg #(1) W_is_load_reg (.in(M_is_load), .out(W_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_branch_reg (.in(M_is_branch), .out(W_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(1) W_is_control_insn_reg (.in(M_is_control_insn), .out(W_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   wire W_is_store;
   assign W_is_store = W_dmem_we; //I know this is unecessary but helps with naming convention


   // other, idk
   wire [15:0] W_memory_or_alu_output;
   assign W_memory_or_alu_output = W_is_load ? W_dmem_data_output :
                                           W_alu_output;   


   //TODO:
   // probably need to replace wires below with the decoded insn in the W stage
   // right now i guess something like should_branch is technically from all the way back to the D stage above


   //i can't remember why i had these next two lines in singlecycle. pc_plus_one_or_alu_output goes nowhere...
   // wire [15:0] pc_plus_one_or_alu_output;
   // assign pc_plus_one_or_alu_output = should_branch ? alu_output :
   //                                                    pc_plus_one;

   wire [15:0] W_pc_plus_one;
   cla16 make_pc_plus_one 
      (.a(W_pc), .b(16'b1), .cin(1'b0), .sum(W_pc_plus_one));

   assign W_regfile_data_to_write = W_select_pc_plus_one ? W_pc_plus_one :
                                                       W_memory_or_alu_output;
   wire [15:0] F_pc_plus_one;
   cla16 pc_plus_one (.a(F_pc), .b(16'b1), .cin(1'b0), .sum(F_pc_plus_one));

   assign next_pc = F_pc_plus_one;
   // stall != 0 ? F_pc :
   //                   W_is_control_insn || should_branch ? W_memory_or_alu_output :
   //                   W_pc_plus_one;                                
   

   // ----  NZP stuff ------
   wire [2:0] nzp_reg_input, nzp_reg_output;
   assign nzp_reg_input = (W_regfile_data_to_write == 0) ? 3'b010 : //Z
                          (W_regfile_data_to_write[15] == 0) ? 3'b001 : //P
                          3'b100; //N

   Nbit_reg #(.n(3)) nzp_reg 
      (.in(nzp_reg_input), .out(nzp_reg_output),
      .clk(clk), .we(W_nzp_we), .gwe(gwe), .rst(rst));
   
   wire [2:0] nzp_and_insn_11_9; //used just as an intermediate to calculate 'should_branch'
   assign nzp_and_insn_11_9 = nzp_reg_output & i_cur_insn[11:9]; //bitwise AND

   wire should_branch;
   assign should_branch = W_is_branch && ( |nzp_and_insn_11_9 ); 
      //'should_branch' is true when is_branch is active AND at least one bit matches between the insn[11:9] and NZP bits



   //STALL LOGIC

   //question to think about: on the slides, there is a connection from M to should_stall. Is this real and if so when?
   // also, do we need to ensure that the thing after LDR is in X when LDR is in W?
   wire [1:0] F_stall, D_stall, X_stall, M_stall, W_stall;
   assign F_stall = 2'b0;
   // X_is_load && (X_rd_sel == D_rs_sel || X_rd_sel == D_rt_sel || D_is_branch) ? 2'b11 : 2'b00;
   // For the next section: create stall registers so that you carry dstall into writeback and set test_stall=wstall
   Nbit_reg #(2, 2'd2) dstall (.in(F_stall), .out(D_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) xstall (.in(D_stall), .out(X_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) mstall (.in(X_stall), .out(M_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2) wstall (.in(M_stall), .out(W_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   
   
   
   // ---- TEST WIRES -----
   
   assign test_cur_pc = W_pc;                // Testbench: program counter
   assign test_cur_insn = W_insn;           // Testbench: instruction bits
   assign test_regfile_we = W_regfile_we;       // Testbench: register file write enable
   assign test_regfile_wsel = W_rd_sel;           // Testbench: which register to write in the register file 
   assign test_regfile_data = W_regfile_data_to_write; // Testbench: value to write into the register file
   assign test_nzp_we = W_nzp_we;                 // Testbench: NZP condition codes write enable
   assign test_nzp_new_bits = nzp_reg_input;    // Testbench: value to write to NZP bits
   assign test_dmem_we = W_dmem_we;             // Testbench: data memory write enable
   assign test_dmem_addr = (W_is_load || W_is_store) ? W_dmem_addr :
                           16'b0;               // Testbench: address to read/write memory
   assign test_dmem_data = (W_is_load) ? W_dmem_data_output :
                           (W_is_store) ? W_dmem_data_input :
                           16'b0;               // Testbench: value read/writen from/to memory
   
   //***TODO***
   assign test_stall = (W_insn == 16'b0) ? 2'b10 : 2'b0; 
   // W_stall;        








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
         $display("f_pc: %h, i_cur_insn: %h", F_pc, i_cur_insn);
         $display("d_pc: %h | r%d: %h | r%d: %h", D_pc, D_rs_sel, D_rs_data, D_rt_sel, D_rt_data);
         $display("x_pc: %h | alu1: %h | alu2: %h | alu_out: %h", X_pc, X_rs_bypass_val_mux1, X_rt_bypass_val_mux2, X_alu_output);
         $display("m_pc: %h | dmem_addr: %h | dmem_we: %b | dmem_data: %h", M_pc, o_dmem_addr, o_dmem_we, o_dmem_towrite);
         $display("w_pc: %h | w_insn: %h | writing to r%d | wdata: %h | regfile_we: %b | dmem_addr: %h | dmem_we: %b | dmem_data: %h | is_load: %b | is_store: %b", 
            W_pc, W_insn, W_rd_sel, W_regfile_data_to_write, W_regfile_we, W_dmem_addr, W_dmem_we, test_dmem_data, W_is_load, W_is_store);
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
