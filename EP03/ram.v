module ram
  #(parameter W=32, L=64)
(
  input  [$clog2(L*(W/8))-1:0] addr, // for (W=32, L=64) -> addr is [7:0]
  input  [W-1:0] data_in,
  input  clk, oe,
  input  [1:0] w_mode,
  output [W-1:0] data_out
);
  reg [7:0] mem_byte[L*(W/8)-1:0];

  assign data_out = (w_mode == 0 && oe) ? {mem_byte[addr+3], mem_byte[addr+2], mem_byte[addr+1], mem_byte[addr]} : {W{1'bz}};
  
  always@(posedge clk)
    if (w_mode == 1) mem_byte[addr] <= data_in[7:0];
    else if (w_mode == 2) {mem_byte[addr+1], mem_byte[addr]} <= data_in[15:0];
    else if (w_mode == 3) {mem_byte[addr+3], mem_byte[addr+2], mem_byte[addr+1], mem_byte[addr]} <= data_in;

endmodule