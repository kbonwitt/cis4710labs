/* TODO: name and PennKeys of all group members here
//Names: Charlie Gottlieb cbg613, Keith Bonwitt kbonwitt
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */

    wire [15:0] pc_plus_one;
    cla16 make_pc_plus_one 
      (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_plus_one));
   
   
   // --- DECODING ---
   wire [2:0] r1sel, r2sel, rd_sel;
   wire r1re, r2re, regfile_we, nzp_we, select_pc_plus_one, is_load, is_store, is_branch, is_control_insn;
   
   lc4_decoder decoder(.insn(i_cur_insn),               // instruction
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

   
   // ---- Regfile stuff ----
   /* TO ASSIGN
   */

   wire [15:0] rs_data, rt_data;
   wire [15:0] regfile_data_to_write;

   lc4_regfile #(.n(16)) regfile 
         (.clk(clk), .gwe(gwe), .rst(rst), 
         .i_rs(r1sel), .o_rs_data(rs_data), 
         .i_rt(r2sel), .o_rt_data(rt_data), 
         .i_rd(rd_sel), .i_wdata(regfile_data_to_write), .i_rd_we(regfile_we)
         );
   
 

   // ---- ALU stuff -----
   /* TO ASSIGN
   */

   wire [15:0] alu_output;

   lc4_alu alu 
      (.i_insn(i_cur_insn), .i_pc(pc),
      .i_r1data(rs_data), .i_r2data(rt_data),
      .o_result(alu_output)
      );
   
   

   // ---- MEMORY stuff -----  
   assign o_dmem_we = is_store;
   assign o_dmem_addr = alu_output;
   assign o_dmem_towrite = rt_data;


   // other, idk
   wire [15:0] memory_or_alu_output;
   assign memory_or_alu_output = is_load ? i_cur_dmem_data :
                                           alu_output;   
   

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





   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
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
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
