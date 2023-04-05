`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/

   //since B overrides A, we set to B if B actually wants to and can write here
   // otherwise we set to A as default (EVEN IF A doesn't want to/cant write here)
   wire [n-1:0] r0_input = 
                  (i_rd_we_B && i_rd_B == 3'b000) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b000) ? i_wdata_A :
                  0;
   wire [n-1:0] r1_input = 
                  (i_rd_we_B && i_rd_B == 3'b001) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b001) ? i_wdata_A :
                  0;
   wire [n-1:0] r2_input = 
                  (i_rd_we_B && i_rd_B == 3'b010) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b010) ? i_wdata_A :
                  0;
   wire [n-1:0] r3_input = 
                  (i_rd_we_B && i_rd_B == 3'b011) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b011) ? i_wdata_A :
                  0;
   wire [n-1:0] r4_input = 
                  (i_rd_we_B && i_rd_B == 3'b100) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b100) ? i_wdata_A :
                  0;
   wire [n-1:0] r5_input = 
                  (i_rd_we_B && i_rd_B == 3'b101) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b101) ? i_wdata_A :
                  0;
   wire [n-1:0] r6_input = 
                  (i_rd_we_B && i_rd_B == 3'b110) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b110) ? i_wdata_A :
                  0;
   wire [n-1:0] r7_input = 
                  (i_rd_we_B && i_rd_B == 3'b111) ? i_wdata_B :
                  (i_rd_we_A && i_rd_A == 3'b111) ? i_wdata_A :
                  0;

   wire r0_we = 
            (i_rd_A == 3'b000 && i_rd_we_A) || (i_rd_B == 3'b000 && i_rd_we_B);
   wire r1_we = 
            (i_rd_A == 3'b001 && i_rd_we_A) || (i_rd_B == 3'b001 && i_rd_we_B);
   wire r2_we = 
            (i_rd_A == 3'b010 && i_rd_we_A) || (i_rd_B == 3'b010 && i_rd_we_B);
   wire r3_we = 
            (i_rd_A == 3'b011 && i_rd_we_A) || (i_rd_B == 3'b011 && i_rd_we_B);
   wire r4_we = 
            (i_rd_A == 3'b100 && i_rd_we_A) || (i_rd_B == 3'b100 && i_rd_we_B);
   wire r5_we = 
            (i_rd_A == 3'b101 && i_rd_we_A) || (i_rd_B == 3'b101 && i_rd_we_B);
   wire r6_we = 
            (i_rd_A == 3'b110 && i_rd_we_A) || (i_rd_B == 3'b110 && i_rd_we_B);
   wire r7_we = 
            (i_rd_A == 3'b111 && i_rd_we_A) || (i_rd_B == 3'b111 && i_rd_we_B);


   wire [n-1:0] r0_output, r1_output, r2_output, r3_output, r4_output, r5_output, r6_output, r7_output;

   Nbit_reg #(.n(n)) r0
      (.in(r0_input), .out(r0_output),
      .clk(clk), .we(r0_we), .gwe(gwe), .rst(rst));
   
   Nbit_reg #(.n(n)) r1
      (.in(r1_input), .out(r1_output),
      .clk(clk), .we(r1_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r2
      (.in(r2_input), .out(r2_output),
      .clk(clk), .we(r2_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r3
      (.in(r3_input), .out(r3_output),
      .clk(clk), .we(r3_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r4
      (.in(r4_input), .out(r4_output),
      .clk(clk), .we(r4_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r5
      (.in(r5_input), .out(r5_output),
      .clk(clk), .we(r5_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r6
      (.in(r6_input), .out(r6_output),
      .clk(clk), .we(r6_we), .gwe(gwe), .rst(rst));

   Nbit_reg #(.n(n)) r7
      (.in(r7_input), .out(r7_output),
      .clk(clk), .we(r7_we), .gwe(gwe), .rst(rst));

   
   assign o_rs_data_A = 
      (i_rs_A == 3'b000) ? (r0_we ? r0_input : r0_output) :
      (i_rs_A == 3'b001) ? (r1_we ? r1_input : r1_output) :
      (i_rs_A == 3'b010) ? (r2_we ? r2_input : r2_output) :
      (i_rs_A == 3'b011) ? (r3_we ? r3_input : r3_output) :
      (i_rs_A == 3'b100) ? (r4_we ? r4_input : r4_output) :
      (i_rs_A == 3'b101) ? (r5_we ? r5_input : r5_output) :
      (i_rs_A == 3'b110) ? (r6_we ? r6_input : r6_output) :
                           (r7_we ? r7_input : r7_output);

   assign o_rt_data_A = 
      (i_rt_A == 3'b000) ? (r0_we ? r0_input : r0_output) :
      (i_rt_A == 3'b001) ? (r1_we ? r1_input : r1_output) :
      (i_rt_A == 3'b010) ? (r2_we ? r2_input : r2_output) :
      (i_rt_A == 3'b011) ? (r3_we ? r3_input : r3_output) :
      (i_rt_A == 3'b100) ? (r4_we ? r4_input : r4_output) :
      (i_rt_A == 3'b101) ? (r5_we ? r5_input : r5_output) :
      (i_rt_A == 3'b110) ? (r6_we ? r6_input : r6_output) :
                           (r7_we ? r7_input : r7_output);

   assign o_rs_data_B = 
      (i_rs_B == 3'b000) ? (r0_we ? r0_input : r0_output) :
      (i_rs_B == 3'b001) ? (r1_we ? r1_input : r1_output) :
      (i_rs_B == 3'b010) ? (r2_we ? r2_input : r2_output) :
      (i_rs_B == 3'b011) ? (r3_we ? r3_input : r3_output) :
      (i_rs_B == 3'b100) ? (r4_we ? r4_input : r4_output) :
      (i_rs_B == 3'b101) ? (r5_we ? r5_input : r5_output) :
      (i_rs_B == 3'b110) ? (r6_we ? r6_input : r6_output) :
                           (r7_we ? r7_input : r7_output);

   assign o_rt_data_B = 
      (i_rt_B == 3'b000) ? (r0_we ? r0_input : r0_output) :
      (i_rt_B == 3'b001) ? (r1_we ? r1_input : r1_output) :
      (i_rt_B == 3'b010) ? (r2_we ? r2_input : r2_output) :
      (i_rt_B == 3'b011) ? (r3_we ? r3_input : r3_output) :
      (i_rt_B == 3'b100) ? (r4_we ? r4_input : r4_output) :
      (i_rt_B == 3'b101) ? (r5_we ? r5_input : r5_output) :
      (i_rt_B == 3'b110) ? (r6_we ? r6_input : r6_output) :
                           (r7_we ? r7_input : r7_output);


endmodule

