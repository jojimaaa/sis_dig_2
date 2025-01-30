module ram_4(
  input [31:0] in,
  input [1:0] addr,
  input RW, OE,
  output reg [31:0] out
);
  reg [31:0] data[3:0];
  always @(in, addr, RW, OE)
  begin
    if(RW==1'b0 & OE==1'b1)
      out=data[addr];
    else
      out=32'bz;
    if(RW==1'b1)
      data[addr]=in;
  end
endmodule