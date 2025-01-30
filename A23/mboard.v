module mboard
#(
  parameter IM_L = 8, DM_L = 128
) (
  input clk, rst
);
  wire
    ready,
    readyout,
    sel1,
    sel2,
    write,
    done;
  
  wire [31:0]
    rdata,
    wdata,
    addr;

  cpu #(IM_L, DM_L) processor(.*);

  rom #(IM_L) instMem(
    .addr (addr[7:0]),
    .sel  (sel1),
    .*
  );

  ram #(DM_L) dataMem(
    .addr (addr[31:8]),
    .sel  (sel2),
    .*
  );

  // Address Decoder
  assign sel1 = (addr <  32'h000100) ? 1 : 0;
  assign sel2 = (addr >= 32'h000100) ? 1 : 0;

endmodule