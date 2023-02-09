/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
           
   assign cout[0] = gin[1] | (pin[1] & gin[0]) | (cin & pin[1] & pin[0]);
   assign cout[1] = gin[2] | (pin[2] & gin[1]) | (pin[2] & pin[1] & gin[0]) | (pin[2] & pin[1] & pin[0] & cin);
   assign cout[2] = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]) | (pin[3] & pin[2] & pin[1] & pin[0] & cin);
   assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);
   assign pout = (& pin);
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

   wire [3:0] gin1, gin2, gin3, gin4;
   wire [3:0] pin1, pin2, pin3, pin4;

   //fillign in gin1, pin 1
   gp1 gin11(.a(a[0]), .b(b[0]), .g(gin1[0]), .p(pin1[0]));
   gp1 gin12(.a(a[1]), .b(b[1]), .g(gin1[1]), .p(pin1[1]));
   gp1 gin13(.a(a[2]), .b(b[2]), .g(gin1[2]), .p(pin1[2]));
   gp1 gin14(.a(a[3]), .b(b[3]), .g(gin1[3]), .p(pin1[3]));
   //fillign in gin2, pin 2
   gp1 gin21(.a(a[4]), .b(b[4]), .g(gin2[0]), .p(pin2[0]));
   gp1 gin22(.a(a[5]), .b(b[5]), .g(gin2[1]), .p(pin2[1]));
   gp1 gin23(.a(a[6]), .b(b[6]), .g(gin2[2]), .p(pin2[2]));
   //TODO:CLA16
   gp1 gin11(.a(a[7]), .b(b[7]), .g(gin2[3]), .p(pin2[3]));
   //fillign in gin3, pin 3
   gp1 gin11(.a(a[8]), .b(b[8]), .g(gin3[0]), .p(pin3[0]));
   gp1 gin11(.a(a[9]), .b(b[9]), .g(gin3[1]), .p(pin3[1]));
   gp1 gin11(.a(a[10]), .b(b[10]), .g(gin3[2]), .p(pin3[2]));
   gp1 gin11(.a(a[11]), .b(b[11]), .g(gin3[3]), .p(pin3[3]));
   //fillign in gin4, pin 4
   gp1 gin11(.a(a[12]), .b(b[12]), .g(gin4[0]), .p(pin4[0]));
   gp1 gin11(.a(a[13]), .b(b[13]), .g(gin4[1]), .p(pin4[1]));
   gp1 gin11(.a(a[14]), .b(b[14]), .g(gin4[2]), .p(pin4[2]));
   gp1 gin11(.a(a[15]), .b(b[15]), .g(gin4[3]), .p(pin4[3]));

   //calcuating seperate carry out of 4 bit sections
   wire [2:0] cout1, cout2, cout3, cout4;
   //TODO: find middle carries
   wire pout1, pout2, pout3, pout4;
   wire gout1, gout2, gout3, gout4;
   gp4 gp1(.gin(gin1), .pin(pin1), .cin(cin), .gout(gout1), .pout(pout1), .cout(cout1));
   gp4 gp2(.gin(gin2), .pin(pin2), .cin(cout1), .gout(gout2), .pout(pout2), .cout(cout2));
   gp4 gp3(.gin(gin3), .pin(pin3), .cin(cout2), .gout(gout3), .pout(pout3), .cout(cout3));
   gp4 gp4(.gin(gin4), .pin(pin4), .cin(cout3), .gout(gout4), .pout(pout4), .cout(cout4));
   //TODO: sum = xoring in a xor b xor carry for each individual bit








endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 
endmodule
