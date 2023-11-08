module dom_and #(parameter D = 2, parameter W = 1, parameter Z=D*(D-1)/2) (
                                                                           input            clk,
                                                                           input            rst,
                                                                           input [D*W-1:0]  a_i,
                                                                           input [D*W-1:0]  b_i,
                                                                           input [Z*W-1:0]  rdi,
                                                                           output [D*W-1:0] c_o
                                                                           );



  logic [D-1:0][W-1:0] a;
  logic [D-1:0][W-1:0] b;
  logic [D-1:0][W-1:0] c;
  logic [Z-1:0][W-1:0] z;
  logic [D*D-1:0][W-1:0] ai_bj_r;


  always_comb begin
    for(integer share = 0; share < D; share += 1) begin
      a[share] = a_i[W*share +: W];
      b[share] = b_i[W*share +: W];
    end
    for(integer i = 0; i < Z; i += 1) begin
      z[i] = rdi[i*W +: W];
    end
  end

  genvar share;
  generate
    for(share = 0; share < D; share += 1) begin
      assign c_o[share*W +: W] = c[share];
    end
  endgenerate


  logic[(D*D)-1:0][W-1:0] ai_bj;
  always_comb begin
    for(integer i = 0; i < D; i += 1) begin
      for(integer j = 0; j < D; j += 1) begin
        if(i == j) begin
          ai_bj[D * i + j] = a[i] & b[j];
        end else if(j > i) begin
          ai_bj[D * i + j] = (a[i] & b[j]) ^ z[i + j * (j-1)/2];
        end else begin
          ai_bj[(D * i) + j] = (a[i] & b[j]) ^ z[j + i * (i-1)/2];
        end
      end
    end // for (integer i = 0; i < D; i += 1)
  end // always_comb

  always_ff @(posedge clk) begin
    for(integer i = 0; i < D; i+=1) begin
      for(integer j = 0; j < D; j += 1) begin
        if(rst) begin
          ai_bj_r[D*i +j] <= 0;
        end else begin
          ai_bj_r[D*i +j] <= ai_bj[D*i +j];
        end
      end
    end
  end // always_ff @ (posedge clk)



  always_comb begin
    for(integer i = 0; i < D; i += 1) begin
      c[i] = 0;
      for(integer j = 0; j < D; j += 1) begin
        if(i == j) begin
          c[i] = c[i] ^ ai_bj[D*i + j];
        end else begin
          c[i] = c[i] ^ ai_bj_r[D*i + j];
        end
      end
    end
  end

endmodule : dom_and
