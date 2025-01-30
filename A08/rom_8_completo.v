module rom_8(
  input [2:0] addr,
  input OE,
  output reg [31:0] out
);
  reg [31:0] data[7:0];
  
  initial begin
    data[0] = 32'h15350076;
    data[1] = 32'h5952599f;
    data[2] = 32'h3f800000;
    data[3] = 32'h3e800000;
    data[4] = 32'h40400000;
    data[5] = 32'h41200000;
    data[6] = 32'h3ea00000;
    data[7] = 32'h3f600000;
  end

  always @(addr, OE)
    if (OE==1'b1)
      out=data[addr];
    else
      out=32'bz;
endmodule