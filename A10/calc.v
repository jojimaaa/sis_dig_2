module calc(
  input  [2:0]  ram_addr_juiz,
  input         clk,
  output [31:0] ram_out_juiz,
  output reg    done
);
  reg [2:0]  ram_addr;
  reg [31:0] ram_in;
  reg        ram_rw;

  wire [2:0] ram_addr_mux;
  assign ram_addr_mux = (ram_rw ? ram_addr : ram_addr_juiz);

  ram #(.W (32), .L (16)) mem
  (
    .addr     (ram_addr_mux),
    .data_in  (ram_in),
    .rw       (ram_rw),
    .oe       (1'b1),
    .data_out (ram_out_juiz)
  );

  initial
  begin
    done = 0;
    ram_rw = 1;
    ram_addr = 3'h00;
  end

  always@(posedge clk)
  begin
    if (done !== 1)
    begin
      if (ram_addr == 32'h0)
        ram_in = 32'd33;

      if (ram_addr == 32'h1)
        ram_in = 32'd58;

      if (ram_addr == 32'h2)
        ram_in = 32'd47;

      if (ram_addr == 32'h3)
        ram_in = 32'd159;    

      if (ram_addr == 3'h08)
        ram_in = 32'b000000000001_00000_010_00101_0000011;   

      if (ram_addr == 3'h09)   
        ram_in = 32'b000000000002_00000_010_00110_0000011;
    end
    else
      ram_rw = 0;
end
        
endmodule
