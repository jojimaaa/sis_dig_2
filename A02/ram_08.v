module rom_16 (addr, CS, OE, out);
    input [3:0] addr;
    input CS, OE;
    output reg [15:0] out;
    reg [15:0] data [15:0];

    initial
        for (integer i = 0; i < 16; i++)
            data[i] = ~i[15:0];

    always @(addr, CS, OE)
        if (OE == 1'b1 && CS == 1'b1)
            out = data[addr];
        else
            out = 16'bz;
endmodule

module ram_4 (in, addr, RW, CS, OE, out);
    input [15:0] in;
    input [1:0] addr;
    input RW, CS, OE;
    output reg [15:0] out;
    reg [15:0] data [3:0];

    always @(addr, CS, OE, RW)
    begin
        if (RW == 1'b0 && OE == 1'b1 && CS == 1'b1)
            out = data[addr];
        else
            out = 16'bz;

        if (RW == 1'b1 && CS == 1'b1) //RW = 1 - WRITE
            data[addr] = in;
    end
endmodule

module ram_8 (in, addr, RW, CS, OE, out);
    input [15:0] in;
    input [2:0] addr;
    input RW, CS, OE;
    output [15:0] out;

    reg select1, select2;

    ram_4 ram1 (.in(in), .addr(addr[1:0]), .RW(RW), .CS(select1), .OE(OE), .out(out));
    ram_4 ram2 (.in(in), .addr(addr[1:0]), .RW(RW), .CS(select2), .OE(OE), .out(out));

    always @(addr, CS, OE, RW) begin
        if(addr[2] == 1'b0 && CS == 1'b1) begin
            select1 = 1'b1;
            select2 = 1'b0;
        end
        if(addr[2] == 1'b1 && CS == 1'b1) begin
            select1 = 1'b0;
            select2 = 1'b1;
        end
        else begin
            select1 = 1'b1;
            select2 = 1'b0;
        end
    end

endmodule


module rom_16(addr, CS, OE, out);
  input [3:0] addr;
  input CS, OE;
  output reg [15:0] out;
  reg [15:0] data[15:0];
  initial
    for (integer i = 0; i < 16; i++)
      data[i]=~i[15:0];
  always @(addr, CS, OE)
    if (OE==1'b1)
      out=data[addr];
    else
      out=16'bz;
endmodule

module ram_4(in, addr, RW, CS, OE, out);
  input [15:0] in;
  input [1:0] addr;
  input RW, CS, OE;
  output reg [15:0] out;
  reg [15:0] data[3:0];
  always @(addr, CS, OE, RW)
  begin
    if(RW==1'b0 & OE==1'b1)
      out=data[addr];
    else
      out=16'bz;
    if(RW==1'b1)
      data[addr]=in;
  end
endmodule


module ram_8(in, addr, RW, CS, OE, out);    
    input [15:0] in;
    input [2:0] addr;
    input RW, CS, OE;
    output [15:0] out;

    wire r1_CS;
    wire r2_CS;

    assign r1_CS = ~addr[2] & CS;
    assign r2_CS = addr[2] & CS;

    assign r1_RW = ~addr[2] & RW;
    assign r2_RW = addr[2] & RW;

    assign r1_OE = ~addr[2] & OE;
    assign r2_OE = addr[2] & OE;

    ram_4 r1(in, addr[1:0], r1_RW, r1_CS, r1_OE, out);
    ram_4 r2(in, addr[1:0], r2_RW, r2_CS, r2_OE, out);

endmodule


module memchip_64(in, addr, RW, out);
    input [15:0] in;
    input [5:0] addr;
    input RW;
    output [15:0] out;

    wire [3:0] rom_16_addr;
    wire rom_16_CS;
    wire rom_16_OE; 

    assign rom_16_addr = addr[3:0];
    assign rom_16_CS = ~addr[5] & ~addr[4];
    assign rom_16_OE = ~addr[5] & ~addr[4];
    assign rom_16_addr = addr[3:0];


    wire [2:0] ram_8_0_addr;
    wire ram_8_0_RW;
    wire ram_8_0_CS;
    wire ram_8_0_OE;

    assign ram_8_0_addr = addr[2:0];
    assign ram_8_0_RW = ~addr[5] & addr[4] & ~addr[3] & RW;
    assign ram_8_0_CS = ~addr[5] & addr[4] & ~addr[3];
    assign ram_8_0_OE = ~addr[5] & addr[4] & ~addr[3];

    wire [2:0] ram_8_1_addr;
    wire ram_8_1_RW;
    wire ram_8_1_CS;
    wire ram_8_1_OE;

    assign ram_8_1_addr = addr[2:0];
    assign ram_8_1_RW = addr[5] & ~addr[4] & addr[3] & RW;
    assign ram_8_1_CS = addr[5] & ~addr[4] & addr[3];
    assign ram_8_1_OE = addr[5] & ~addr[4] & addr[3];


    rom_16 r_00_0f(rom_16_addr, rom_16_CS, rom_16_OE, out);
    ram_8 r_10_17(in, ram_8_0_addr, ram_8_0_RW, ram_8_0_CS, ram_8_0_OE, out);
    ram_8 r_30_3f(in, ram_8_1_addr, ram_8_1_RW, ram_8_1_CS, ram_8_1_OE, out);
endmodule
