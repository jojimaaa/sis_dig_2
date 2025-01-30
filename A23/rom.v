module rom
  #(parameter L=8)
(
  input  [7:0] addr,
  input  sel,
  output [31:0] rdata,
  output ready
);
  reg [7:0] mem[L*4-1:0];
  
  assign rdata = (sel) ? {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]} : 32'bz;
  
  assign ready = (sel) ? 1 : 1'bz;

  initial $readmemh("rom.hex", mem, 0, L*4-1);
    
endmodule