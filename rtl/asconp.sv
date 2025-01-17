// Licensed under the Creative Commons 1.0 Universal License (CC0), see LICENSE
// for details.
//
// Author: Robert Primas (rprimas 'at' proton.me, https://rprimas.github.io)
//
// Implementation of the Ascon permutation (Ascon-p).
// Performs UROL rounds per clock cycle.
//`ifdef VIVADO

`include "config_core.vh"
//`endif
module asconp #(parameter D = 2, parameter RDI_BITS = (D-1)*(D)/2) (
								    input logic			 clk,
								    input logic			 rst,								    
                                                                    input logic [ 3:0]		 round_cnt,
                                                                    input logic [5*64*RDI_BITS-1:0] rdi,
                                                                    input logic [D*64-1:0]	 x0_i,
                                                                    input logic [D*64-1:0]	 x1_i,
                                                                    input logic [D*64-1:0]	 x2_i,
                                                                    input logic [D*64-1:0]	 x3_i,
                                                                    input logic [D*64-1:0]	 x4_i,
                                                                    output logic [D*64-1:0]	 x0_o,
                                                                    output logic [D*64-1:0]	 x1_o,
                                                                    output logic [D*64-1:0]	 x2_o,
                                                                    output logic [D*64-1:0]	 x3_o,
                                                                    output logic [D*64-1:0]	 x4_o
                                                                    );

  logic [D-1:0][63:0] x0_aff1, x0_chi, x0_aff2;
  logic [D-1:0][63:0] x1_aff1, x1_chi, x1_aff2;
  logic [D-1:0][63:0] x2_aff1, x2_chi, x2_aff2;
  logic [D-1:0][63:0] x3_aff1, x3_chi, x3_aff2;
  logic [D-1:0][63:0] x4_aff1, x4_chi, x4_aff2;
  logic [D-1:0][63:0] x0, x1, x2, x3, x4;
  logic [3:0]	      t;
  logic [D*64-1:0]    nx0_chi_in, nx1_chi_in, nx2_chi_in, nx3_chi_in, nx4_chi_in;
  logic [D*64-1:0]    x0_chi_in, x1_chi_in, x2_chi_in, x3_chi_in, x4_chi_in;
  logic [D*64-1:0]    x0_chi_out, x1_chi_out, x2_chi_out, x3_chi_out, x4_chi_out;

  logic [64*RDI_BITS-1:0] Z [5];
  


  genvar		  i;
  generate
    for(i = 0; i < 5; i += 1) begin
      assign Z[i] = rdi[i*64*RDI_BITS +: 64*RDI_BITS];
    end
  endgenerate

  genvar share;
  generate

    for(share = 0; share < D; share += 1) begin
      // 1D -> 2D array
      assign x0[share] = x0_i[64*share+:64];
      assign x1[share] = x1_i[64*share+:64];
      assign x2[share] = x2_i[64*share+:64];
      assign x3[share] = x3_i[64*share+:64];
      assign x4[share] = x4_i[64*share+:64];
      // RC + 1st affine
      assign t = 4'hC - (round_cnt);
      assign x0_aff1[share] = x0[share] ^ x4[share];
      assign x1_aff1[share] = x1[share];
      if(share == 0) begin
        assign x2_aff1[share] = x2[share] ^ x1[share] ^ { {56{1'b0}}, {(4'hF - t), t}};
      end else begin
        assign x2_aff1[share] = x2[share] ^ x1[share];
      end
      assign x3_aff1[share] = x3[share];
      assign x4_aff1[share] = x4[share] ^ x3[share];


      

      // chi sbox stuff
      if(share == 0) begin
	assign nx0_chi_in[share*64 +: 64] = ~x0_aff1[0];
	assign nx1_chi_in[share*64 +: 64] = ~x1_aff1[0];
	assign nx2_chi_in[share*64 +: 64] = ~x2_aff1[0];
	assign nx3_chi_in[share*64 +: 64] = ~x3_aff1[0];
	assign nx4_chi_in[share*64 +: 64] = ~x4_aff1[0];
	// not x2
	assign x2_o[64*share +: 64] = ~(x2_aff2[share] ^ {x2_aff2[share][0:0], x2_aff2[share][63:01]} ^ {x2_aff2[share][05:0], x2_aff2[share][63:06]});
      end else begin
        assign nx0_chi_in[share*64 +: 64] = x0_aff1[share];
        assign nx1_chi_in[share*64 +: 64] = x1_aff1[share];
        assign nx2_chi_in[share*64 +: 64] = x2_aff1[share];
        assign nx3_chi_in[share*64 +: 64] = x3_aff1[share];
        assign nx4_chi_in[share*64 +: 64] = x4_aff1[share];
	
	assign x2_o[64*share +: 64] = x2_aff2[share] ^ {x2_aff2[share][0:0], x2_aff2[share][63:01]} ^ {x2_aff2[share][05:0], x2_aff2[share][63:06]};
      end

      assign x0_chi_in[share*64 +: 64] = x0_aff1[share];
      assign x1_chi_in[share*64 +: 64] = x1_aff1[share];
      assign x2_chi_in[share*64 +: 64] = x2_aff1[share];
      assign x3_chi_in[share*64 +: 64] = x3_aff1[share];      
      assign x4_chi_in[share*64 +: 64] = x4_aff1[share];
      

      
      
      assign x0_chi[share] = x0_aff1[share] ^ x0_chi_out[share*64 +: 64];
      assign x1_chi[share] = x1_aff1[share] ^ x1_chi_out[share*64 +: 64];
      assign x2_chi[share] = x2_aff1[share] ^ x2_chi_out[share*64 +: 64];
      assign x3_chi[share] = x3_aff1[share] ^ x3_chi_out[share*64 +: 64];
      assign x4_chi[share] = x4_aff1[share] ^ x4_chi_out[share*64 +: 64];

      // 2nd affine
      assign x0_aff2[share] = x0_chi[share] ^ x4_chi[share];
      assign x1_aff2[share] = x1_chi[share] ^ x0_chi[share];
      assign x2_aff2[share] = ~x2_chi[share];
      assign x3_aff2[share] = x3_chi[share] ^ x2_chi[share];
      assign x4_aff2[share] = x4_chi[share];

      assign x0_o[64*share +: 64] = x0_aff2[share] ^ {x0_aff2[share][18:0], x0_aff2[share][63:19]} ^ {x0_aff2[share][27:0], x0_aff2[share][63:28]};
      assign x1_o[64*share +: 64] = x1_aff2[share] ^ {x1_aff2[share][60:0], x1_aff2[share][63:61]} ^ {x1_aff2[share][38:0], x1_aff2[share][63:39]};
      assign x3_o[64*share +: 64] = x3_aff2[share] ^ {x3_aff2[share][9:0], x3_aff2[share][63:10]} ^ {x3_aff2[share][16:0], x3_aff2[share][63:17]};
      assign x4_o[64*share +: 64] = x4_aff2[share] ^ {x4_aff2[share][6:0], x4_aff2[share][63:07]} ^ {x4_aff2[share][40:0], x4_aff2[share][63:41]};   
    end
  endgenerate
  

  dom_and #(.D  (D), .W(64)) u_x0 (.clk (clk), .rst(rst), .rdi(Z[0]), .a_i(nx1_chi_in), .b_i(x2_chi_in), .c_o(x0_chi_out));
  dom_and #(.D  (D), .W(64)) u_x1 (.clk (clk), .rst(rst), .rdi(Z[1]), .a_i(nx2_chi_in), .b_i(x3_chi_in), .c_o(x1_chi_out));
  dom_and #(.D  (D), .W(64)) u_x2 (.clk (clk), .rst(rst), .rdi(Z[2]), .a_i(nx3_chi_in), .b_i(x4_chi_in), .c_o(x2_chi_out));
  dom_and #(.D  (D), .W(64)) u_x3 (.clk (clk), .rst(rst), .rdi(Z[3]), .a_i(nx4_chi_in), .b_i(x0_chi_in), .c_o(x3_chi_out));
  dom_and #(.D  (D), .W(64)) u_x4 (.clk (clk), .rst(rst), .rdi(Z[4]), .a_i(nx0_chi_in), .b_i(x1_chi_in), .c_o(x4_chi_out));


  // assign x0[0] = x0_i;
  // assign x1[0] = x1_i;
  // assign x2[0] = x2_i;
  // assign x3[0] = x3_i;
  // assign x4[0] = x4_i;

  // genvar i;
  // generate
  //   for (i = 0; i < UROL; i++) begin
  //     // 1st affine layer
  //     assign t[i] = (4'hC) - (round_cnt - i);
  //     assign x0_aff1[i] = x0[i] ^ x4[i];
  //     assign x1_aff1[i] = x1[i];
  //     assign x2_aff1[i] = x2[i] ^ x1[i] ^ { {56{1'b0}}, {(4'hF - t[i]), t[i]}};
  //     assign x3_aff1[i] = x3[i];
  //     assign x4_aff1[i] = x4[i] ^ x3[i];
  //     // non-linear chi layer
  //     assign x0_chi[i] = x0_aff1[i] ^ ((~x1_aff1[i]) & x2_aff1[i]);
  //     assign x1_chi[i] = x1_aff1[i] ^ ((~x2_aff1[i]) & x3_aff1[i]);
  //     assign x2_chi[i] = x2_aff1[i] ^ ((~x3_aff1[i]) & x4_aff1[i]);
  //     assign x3_chi[i] = x3_aff1[i] ^ ((~x4_aff1[i]) & x0_aff1[i]);
  //     assign x4_chi[i] = x4_aff1[i] ^ ((~x0_aff1[i]) & x1_aff1[i]);
  //     // 2nd affine layer
  //     assign x0_aff2[i] = x0_chi[i] ^ x4_chi[i];
  //     assign x1_aff2[i] = x1_chi[i] ^ x0_chi[i];
  //     assign x2_aff2[i] = ~x2_chi[i];
  //     assign x3_aff2[i] = x3_chi[i] ^ x2_chi[i];
  //     assign x4_aff2[i] = x4_chi[i];
  //     // linear layer
  //     assign x0[i+1] = x0_aff2[i] ^ {x0_aff2[i][18:0], x0_aff2[i][63:19]} ^ {x0_aff2[i][27:0], x0_aff2[i][63:28]};
  //     assign x1[i+1] = x1_aff2[i] ^ {x1_aff2[i][60:0], x1_aff2[i][63:61]} ^ {x1_aff2[i][38:0], x1_aff2[i][63:39]};
  //     assign x2[i+1] = x2_aff2[i] ^ {x2_aff2[i][0:0], x2_aff2[i][63:01]} ^ {x2_aff2[i][05:0], x2_aff2[i][63:06]};
  //     assign x3[i+1] = x3_aff2[i] ^ {x3_aff2[i][9:0], x3_aff2[i][63:10]} ^ {x3_aff2[i][16:0], x3_aff2[i][63:17]};
  //     assign x4[i+1] = x4_aff2[i] ^ {x4_aff2[i][6:0], x4_aff2[i][63:07]} ^ {x4_aff2[i][40:0], x4_aff2[i][63:41]};
  //   end
  // endgenerate

  // assign x0_o = x0[UROL];
  // assign x1_o = x1[UROL];
  // assign x2_o = x2[UROL];
  // assign x3_o = x3[UROL];
  // assign x4_o = x4[UROL];

endmodule
