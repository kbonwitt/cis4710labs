/* TODO: name and PennKeys of all group members here */
//Charlie Gottlieb : cbg613
//Keith Bonwitt : kbonwitt



/*THOUGHTS
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

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] pc_plus_one;
   cla16 make_pc_plus_one 
      (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_plus_one));
   
   //  ----****************************************---
   //  ----************--- D stage ----************---
   //  ----****************************************---

   wire [15:0] D_insn, D_pc;
   Nbit_reg #(16) D_insn_reg (.in(i_cur_insn), .out(D_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) D_pc_reg (.in(pc), .out(D_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));



   wire [2:0] r1sel, r2sel, rd_sel;
   wire r1re, r2re, regfile_we, nzp_we, select_pc_plus_one, is_load, is_store, is_branch, is_control_insn;
   
   lc4_decoder D_decoder(.insn(D_insn),               // instruction (in D stage)
                       .r1sel(r1sel),              // rs
                       .r1re(r1re),               // does this instruction read from rs?
                       .r2sel(r2sel),              // rt
                       .r2re(r2re),               // does this instruction read from rt?
                       .wsel(rd_sel),               // rd
                       .regfile_we(regfile_we),         // does this instruction write to rd?
                       .nzp_we(nzp_we),             // does this instruction write the NZP bits?
                       .select_pc_plus_one(select_pc_plus_one), // write PC+1 to the regfile?
                       .is_load(is_load),            // is this a load instruction?
                       .is_store(is_store),           // is this a store instruction?
                       .is_branch(is_branch),          // is this a branch instruction?
                       .is_control_insn(is_control_insn)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );
                   //to think about: should all of these change with each insn in the pipeline?
                   // the INSN is pushed to each stage in the pipeline. Should we have a decoder 
                   // at each stage, so we have the correct value for each wire at a particular stage?

   // ---- Regfile stuff ----

   wire [15:0] D_rs_data, D_rt_data;
   wire [15:0] regfile_data_to_write;

   lc4_regfile #(.n(16)) regfile 
         (.clk(clk), .gwe(gwe), .rst(rst), 
         .i_rs(r1sel), .o_rs_data(D_rs_data), 
         .i_rt(r2sel), .o_rt_data(D_rt_data), 
         .i_rd(rd_sel), .i_wdata(regfile_data_to_write), .i_rd_we(regfile_we)
         );
   

   //  ----****************************************---
   //  ----************--- X stage ----************---
   //  ----****************************************---

   wire [15:0] X_rs_data, X_rt_data, X_insn, X_pc;
   Nbit_reg #(16) X_rs_reg (.in(rs_data), .out(X_rs_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) X_rt_reg (.in(rt_data), .out(X_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) X_insn_reg (.in(D_insn), .out(X_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) X_pc_reg (.in(D_pc), .out(X_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   // ---- ALU stuff -----

   wire [15:0] X_alu_output;

   lc4_alu alu 
      (.i_insn(i_cur_insn), .i_pc(pc),
      .i_r1data(X_rs_data), .i_r2data(X_rt_data),
      .o_result(X_alu_output)
      );
   
   

   //  ----****************************************---
   //  ----************--- M stage ----************---
   //  ----****************************************---

   wire [15:0] M_alu_output, M_rt_data, M_insn, M_pc;
   Nbit_reg #(16) M_alu_output_reg (.in(X_alu_output), .out(M_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_rt_reg (.in(X_rt_data), .out(M_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_insn_reg (.in(X_insn), .out(M_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) M_pc_reg (.in(X_pc), .out(M_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));




   // ---- MEMORY stuff -----  
   assign o_dmem_we = is_store;
   assign o_dmem_addr = alu_output;
   assign o_dmem_towrite = rt_data;



   //  ----****************************************---
   //  ----************--- W stage ----************---
   //  ----****************************************---
   wire [15:0] W_datamem;
   Nbit_reg #(16) W_alu_output_reg (.in(M_alu_output), .out(W_alu_output), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_datamem_reg (.in(i_cur_dmem_data), .out(W_datamem), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_insn_reg (.in(M_insn), .out(W_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) W_pc_reg (.in(M_pc), .out(W_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));




   // other, idk
   wire [15:0] memory_or_alu_output;
   assign memory_or_alu_output = is_load ? W_datamem :
                                           W_alu_output;   


   //TODO:
   // probably need to replace wires below with the decoded insn in the W stage
   // right now i guess something like should_branch is technically from all the way back to the D stage above

   //other muxes
      // including regfile_data and next_pc
   wire [15:0] pc_plus_one_or_alu_output;
   assign pc_plus_one_or_alu_output = should_branch ? alu_output :
                                                      pc_plus_one;

   assign regfile_data_to_write = select_pc_plus_one ? pc_plus_one :
                                                       memory_or_alu_output;

   assign next_pc = is_control_insn || should_branch ? memory_or_alu_output :
                                                       pc_plus_one;
   assign o_cur_pc = pc;                                 
   

   // ----  NZP stuff ------
   wire [2:0] nzp_reg_input, nzp_reg_output;
   assign nzp_reg_input = (regfile_data_to_write == 0) ? 3'b010 : //Z
                          (regfile_data_to_write[15] == 0) ? 3'b001 : //P
                          3'b100; //N

   Nbit_reg #(.n(3)) nzp_reg 
      (.in(nzp_reg_input), .out(nzp_reg_output),
      .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));
   
   wire [2:0] nzp_and_insn_11_9; //used just as an intermediate to calculate 'should_branch'
   assign nzp_and_insn_11_9 = nzp_reg_output & i_cur_insn[11:9]; //bitwise AND

   wire should_branch;
   assign should_branch = is_branch && ( |nzp_and_insn_11_9 ); 
      //'should_branch' is true when is_branch is active AND at least one bit matches between the insn[11:9] and NZP bits

   
   
   
   // ---- TEST WIRES -----
   
   assign test_cur_pc = o_cur_pc;                // Testbench: program counter
   assign test_cur_insn = i_cur_insn;           // Testbench: instruction bits
   assign test_regfile_we = regfile_we;       // Testbench: register file write enable
   assign test_regfile_wsel = rd_sel;           // Testbench: which register to write in the register file 
   assign test_regfile_data = regfile_data_to_write; // Testbench: value to write into the register file
   assign test_nzp_we = nzp_we;                 // Testbench: NZP condition codes write enable
   assign test_nzp_new_bits = nzp_reg_input;    // Testbench: value to write to NZP bits
   assign test_dmem_we = o_dmem_we;             // Testbench: data memory write enable
   assign test_dmem_addr = is_load ? o_dmem_addr :
                           is_store ? o_dmem_addr :
                           16'b0;               // Testbench: address to read/write memory
   assign test_dmem_data = is_load ? i_cur_dmem_data :
                           is_store ? o_dmem_towrite :
                           16'b0;               // Testbench: value read/writen from/to memory
   
   //***TODO***
   assign test_stall =         








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
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
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
