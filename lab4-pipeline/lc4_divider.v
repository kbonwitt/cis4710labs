/* TODO: INSERT NAME AND PENNKEY HERE */
//Names: Charlie Gottlieb cbg613, Keith Bonwitt kbonwitt

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      //one_iter 0
      wire [15:0] dividend_1, remainder_1, quotient_1;
      lc4_divider_one_iter i0(.i_dividend(i_dividend), .i_divisor(i_divisor),
             .i_remainder(16'b0), .i_quotient(16'b0),
             .o_dividend(dividend_1), .o_remainder(remainder_1), .o_quotient(quotient_1));

      //one_iter 1
      wire [15:0] dividend_2, remainder_2, quotient_2;
      lc4_divider_one_iter i1(.i_dividend(dividend_1), .i_divisor(i_divisor),
             .i_remainder(remainder_1), .i_quotient(quotient_1),
             .o_dividend(dividend_2), .o_remainder(remainder_2), .o_quotient(quotient_2));

      //one_iter 2
      wire [15:0] dividend_3, remainder_3, quotient_3;
      lc4_divider_one_iter i2(.i_dividend(dividend_2), .i_divisor(i_divisor),
             .i_remainder(remainder_2), .i_quotient(quotient_2),
             .o_dividend(dividend_3), .o_remainder(remainder_3), .o_quotient(quotient_3));

      //one_iter 3
      wire [15:0] dividend_4, remainder_4, quotient_4;
      lc4_divider_one_iter i3(.i_dividend(dividend_3), .i_divisor(i_divisor),
             .i_remainder(remainder_3), .i_quotient(quotient_3),
             .o_dividend(dividend_4), .o_remainder(remainder_4), .o_quotient(quotient_4));

      //one_iter 4
      wire [15:0] dividend_5, remainder_5, quotient_5;
      lc4_divider_one_iter i4(.i_dividend(dividend_4), .i_divisor(i_divisor),
             .i_remainder(remainder_4), .i_quotient(quotient_4),
             .o_dividend(dividend_5), .o_remainder(remainder_5), .o_quotient(quotient_5));

      //one_iter 5
      wire [15:0] dividend_6, remainder_6, quotient_6;
      lc4_divider_one_iter i5(.i_dividend(dividend_5), .i_divisor(i_divisor),
             .i_remainder(remainder_5), .i_quotient(quotient_5),
             .o_dividend(dividend_6), .o_remainder(remainder_6), .o_quotient(quotient_6));

      //one_iter 6
      wire [15:0] dividend_7, remainder_7, quotient_7;
      lc4_divider_one_iter i6(.i_dividend(dividend_6), .i_divisor(i_divisor),
             .i_remainder(remainder_6), .i_quotient(quotient_6),
             .o_dividend(dividend_7), .o_remainder(remainder_7), .o_quotient(quotient_7));

      //one_iter 7
      wire [15:0] dividend_8, remainder_8, quotient_8;
      lc4_divider_one_iter i7(.i_dividend(dividend_7), .i_divisor(i_divisor),
             .i_remainder(remainder_7), .i_quotient(quotient_7),
             .o_dividend(dividend_8), .o_remainder(remainder_8), .o_quotient(quotient_8));

      //one_iter 8
      wire [15:0] dividend_9, remainder_9, quotient_9;
      lc4_divider_one_iter i8(.i_dividend(dividend_8), .i_divisor(i_divisor),
             .i_remainder(remainder_8), .i_quotient(quotient_8),
             .o_dividend(dividend_9), .o_remainder(remainder_9), .o_quotient(quotient_9));

      //one_iter 9
      wire [15:0] dividend_10, remainder_10, quotient_10;
      lc4_divider_one_iter i9(.i_dividend(dividend_9), .i_divisor(i_divisor),
             .i_remainder(remainder_9), .i_quotient(quotient_9),
             .o_dividend(dividend_10), .o_remainder(remainder_10), .o_quotient(quotient_10));

      //one_iter 10
      wire [15:0] dividend_11, remainder_11, quotient_11;
      lc4_divider_one_iter i10(.i_dividend(dividend_10), .i_divisor(i_divisor),
             .i_remainder(remainder_10), .i_quotient(quotient_10),
             .o_dividend(dividend_11), .o_remainder(remainder_11), .o_quotient(quotient_11));

      //one_iter 11
      wire [15:0] dividend_12, remainder_12, quotient_12;
      lc4_divider_one_iter i11(.i_dividend(dividend_11), .i_divisor(i_divisor),
             .i_remainder(remainder_11), .i_quotient(quotient_11),
             .o_dividend(dividend_12), .o_remainder(remainder_12), .o_quotient(quotient_12));

      //one_iter 12
      wire [15:0] dividend_13, remainder_13, quotient_13;
      lc4_divider_one_iter i12(.i_dividend(dividend_12), .i_divisor(i_divisor),
             .i_remainder(remainder_12), .i_quotient(quotient_12),
             .o_dividend(dividend_13), .o_remainder(remainder_13), .o_quotient(quotient_13));

      //one_iter 13
      wire [15:0] dividend_14, remainder_14, quotient_14;
      lc4_divider_one_iter i13(.i_dividend(dividend_13), .i_divisor(i_divisor),
             .i_remainder(remainder_13), .i_quotient(quotient_13),
             .o_dividend(dividend_14), .o_remainder(remainder_14), .o_quotient(quotient_14));

      //one_iter 14
      wire [15:0] dividend_15, remainder_15, quotient_15;
      lc4_divider_one_iter i14(.i_dividend(dividend_14), .i_divisor(i_divisor),
             .i_remainder(remainder_14), .i_quotient(quotient_14),
             .o_dividend(dividend_15), .o_remainder(remainder_15), .o_quotient(quotient_15));

      //one_iter 15
      wire [15:0] dividend_16, remainder_16, quotient_16;
      lc4_divider_one_iter i15(.i_dividend(dividend_15), .i_divisor(i_divisor),
             .i_remainder(remainder_15), .i_quotient(quotient_15),
             .o_dividend(dividend_16), .o_remainder(remainder_16), .o_quotient(quotient_16));


      wire i_divisor_zero;
      assign i_divisor_zero = i_divisor == 16'b0;

      assign o_remainder = i_divisor_zero ? 16'b0: remainder_16;
      assign o_quotient = i_divisor_zero ? 16'b0: quotient_16;


      //questions for TA
      //1 do we need to have the [15:0] for assigning wires in the function-things
      //2 help with git pushing
      //3 is the iteration right (before we copy paste and stuff)
      //4 cool to use single-line assignments of complicated stuff?? like remainder_updated

      /*** YOUR CODE HERE ***/

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      assign o_dividend = i_dividend << 1;

      //remainder updater, 16 bits
      wire [15:0] remainder_updated;
      assign remainder_updated = (i_dividend >> 15 & 1'b1) | (i_remainder << 1);

      //remainder < divisor, will be used in both muxes, just 1 bit
      wire remainder_lt_divisor;
      assign remainder_lt_divisor = remainder_updated < i_divisor;

      assign o_remainder = remainder_lt_divisor ? remainder_updated : (remainder_updated - i_divisor);
      assign o_quotient = remainder_lt_divisor ? (i_quotient << 1) : ( (i_quotient << 1) | 1'b1);


      /*** YOUR CODE HERE ***/

endmodule