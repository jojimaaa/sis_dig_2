module ram
#(parameter W=32, L=16)
(
  input  [$clog2(L)-1:0] addr,
  input  [W-1:0] data_in,
  input  rw, oe,
  output [W-1:0] data_out
);
  reg [W-1:0] mem[L-1:0];

  assign data_out = (rw==1'b0 & oe==1'b1) ? mem[addr] : {W{1'bz}};
  
  always@(*)
    if(rw===1'b1)
      mem[addr] = data_in;

endmodule
