module rom
  #(parameter L=16)
(
  input  [$clog2(L*4)-1:0] addr,
  input  oe,
  output [31:0] data
);
  reg [7:0] mem[L*4-1:0];
  
  assign data = (oe) ? {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]} : 32'bz;

  initial $readmemh("rom.hex", mem, 0, L*4-1);
    
endmodule
