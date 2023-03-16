
/* TODO: Names of all group members
   Charlie Gottlieb, Keith Bonwitt
 * TODO: PennKeys of all group members
   cbg613, kbonwitt
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );
   
   
   
   wire [n-1:0] o_r0;
   wire [n-1:0] o_r1;
   wire [n-1:0] o_r2;
   wire [n-1:0] o_r3;
   wire [n-1:0] o_r4;
   wire [n-1:0] o_r5;
   wire [n-1:0] o_r6;
   wire [n-1:0] o_r7;
   
   Nbit_reg #(.n(16)) r0
   (.in(i_wdata), .out(o_r0),
    .clk(clk), .we(i_rd == 3'b0 && i_rd_we), .gwe(gwe), .rst(rst));
   
    Nbit_reg #(.n(16)) r1
    (.in(i_wdata), .out(o_r1),
     .clk(clk), .we(i_rd == 3'b1 && i_rd_we), .gwe(gwe), .rst(rst));
   
    Nbit_reg #(.n(16)) r2
    (.in(i_wdata), .out(o_r2),
     .clk(clk), .we(i_rd == 3'b10 && i_rd_we), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(.n(16)) r3
    (.in(i_wdata), .out(o_r3),
     .clk(clk), .we(i_rd == 3'b11 && i_rd_we), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(.n(16)) r4
    (.in(i_wdata), .out(o_r4),
     .clk(clk), .we(i_rd == 3'b100 && i_rd_we), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(.n(16)) r5
    (.in(i_wdata), .out(o_r5),
     .clk(clk), .we(i_rd == 3'b101 && i_rd_we), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(.n(16)) r6
    (.in(i_wdata), .out(o_r6),
     .clk(clk), .we(i_rd == 3'b110 && i_rd_we), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(.n(16)) r7
    (.in(i_wdata), .out(o_r7),
     .clk(clk), .we(i_rd == 3'b111 && i_rd_we), .gwe(gwe), .rst(rst));
   
     
     assign o_rs_data = (i_rs == 3'b0) ? o_r0 :
                       (i_rs == 3'b1) ? o_r1 :
                       (i_rs == 3'b10) ? o_r2 :
                       (i_rs == 3'b11) ? o_r3 :
                       (i_rs == 3'b100) ? o_r4 :
                       (i_rs == 3'b101) ? o_r5 :
                       (i_rs == 3'b110) ? o_r6 :
                       o_r7;
    
     assign o_rt_data = (i_rt == 3'b0) ? o_r0 :
                       (i_rt == 3'b1) ? o_r1 :
                       (i_rt == 3'b10) ? o_r2 :
                       (i_rt == 3'b11) ? o_r3 :
                       (i_rt == 3'b100) ? o_r4 :
                       (i_rt == 3'b101) ? o_r5 :
                       (i_rt == 3'b110) ? o_r6 :
                       o_r7;
     
     
   
   

endmodule