module rom_8(
  input [2:0] addr,
  input OE,
  output reg [31:0] out
);
  reg [31:0] data[7:0];
  initial
  begin
    data[0] = 32'h0986ab68;
    data[1] = 32'h10385ba9;
    data[2] = 32'b0;
    data[3] = 32'b0;
    data[4] = 32'b0;
    data[5] = 32'b0;
    data[6] = 32'b0;
    data[7] = 32'b0;
  end
  always @(addr, OE)
    if (OE==1'b1)
      out=data[addr];
    else
      out=32'bz;
endmodule