module mfp(
  input  [1:0]  ram_addr_juiz,
  output [31:0] ram_out_juiz,
  output reg    done
);
  // Variaveis da ROM e RAM
  reg  [2:0]  rom_addr;
  reg  [1:0]  ram_addr;
  wire [31:0] rom_out, ram_in;
  reg         ram_RW, rom_OE, ram_OE;

  // Variaveis do multiplicador
  reg  [31:0] mul_a, mul_b;
  reg         mul_en, mul_rst, mul_clk=0;
  wire        mul_done;
  wire [31:0] mul_z;

  // Clock para o multiplicador
  always
    #1 mul_clk = ~mul_clk;

  // Multiplexador para o juiz
  wire [1:0] ram_addr_mux;
  assign ram_addr_mux = (ram_RW ? ram_addr : ram_addr_juiz);


  /* Sua resposta aqui */


endmodule