module ram
  #(parameter W=32, L=128)
(
  input  [23:0] addr,
  input  [31:0] wdata,
  input  write, sel, clk,
  output [31:0] rdata,
  output ready
);
  reg [7:0] mem[L*(W/8)-1:0];

  assign rdata = (~write & sel) ? {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} : {W{1'bz}};

  assign ready = (sel) ? 1 : 1'bz;
  
  always@(posedge clk)
    if(write)
      {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= wdata;
  
  initial begin
    {mem[32'h7], mem[32'h6], mem[32'h5], mem[32'h4]} <= 32'h76;
    {mem[32'hB], mem[32'hA], mem[32'h9], mem[32'h8]} <= 32'h04;
  end

endmodule