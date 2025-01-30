module rom_8 (
    input [2:0] addr,
    input OE,
    output reg [31:0] out
);

    reg [31:0] data [7:0];

    initial begin
        data[0] = 32'h0986ab68;
        data[1] = 32'h10385ba9;
        data[2] = 32'b0_01111111_00000000000000000000000; //1 decimal
        data[3] = 32'b0_01111101_00000000000000000000000; //0.01 binario = 0,25 decimal
        data[4] = 32'b0_10000000_10000000000000000000000; //3 decimal
        data[5] = 32'b0_10000010_01000000000000000000000; //10 decimal
        data[6] = 32'b0_01111101_01000000000000000000000; //0.3125 decimal
        data[7] = 32'b0_01111110_11000000000000000000000; //0.875 decimal
    end

    always @(addr, OE) begin
        if (OE == 1'b1)
            out = data[addr];
        else
            out = 32'bz;
    end

endmodule

module fpa(ram_addr, ram_out, done);
    reg clk;
    output reg done;
    output [31:0] ram_out;
    input [1:0] ram_addr;

    reg [2:0] rom_addr = 3'b000;
    
    wire [1:0] ram_addr_mux;
    wire [31:0] rom_out1, rom_out2;
    wire [31:0] ram_in;
    reg ram_RW = 1'b1;
    reg ram_OE;
    reg rom_OE = 1'b1;
    reg [1:0] addr_counter = 2'b00;
    reg adder_en = 1'b0;

    always begin
        #1 clk = ~clk;
    end

    assign ram_addr_mux = (ram_RW ? addr_counter : ram_addr);

    // Instantiate the ROM and Adder modules
    rom_8 rom1(.addr(rom_addr), .OE(rom_OE), .out(rom_out1));
    rom_8 rom2(.addr(rom_addr + 1'b1), .OE(rom_OE), .out(rom_out2));
    adder adder1(.operand_1(rom_out1), .operand_2(rom_out2), .clk(clk), .en(adder_en), .sum(ram_in));

    always @(*) begin
        if (addr_counter < 2'b11) begin
            adder_en = 1'b1;
            ram_RW = 1'b1;
            rom_addr = rom_addr + 2'b10;
            addr_counter = addr_counter + 1'b1;
        end else begin
            done = 1'b1;
            ram_RW = 1'b0;
            rom_OE = 1'b0;
            ram_OE = 1'b1;
            adder_en = 1'b0;
        end
    end

    // Instantiate the RAM module
    ram_4 ram1(.in(ram_in), .addr(ram_addr_mux), .RW(ram_RW), .OE(ram_OE), .out(ram_out));
endmodule

