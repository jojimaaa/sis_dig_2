module calculadora
    #(parameter W = 32)
    (input clock, reset, opera,
     input [4:0] read,
     output [W-1:0] data
    );

    /**************************************************************************
                                       ROM
    **************************************************************************/
    wire [3:0] rom_addr;
    reg rom_oe = 1'b0;
    wire [31:0] rom_out;
    wire [4:0]  operacao = {rom_out[5], rom_out[14:12], rom_out[30]};

    rom #(.W(32), .L(16)) rom (
        .address(rom_addr),
        .oe(rom_oe),
        .data(rom_out)
    );

    /**************************************************************************
                                    REGISTERFILE
    **************************************************************************/
    wire [4:0] read1_addr = rom_out[19:15];
    wire [4:0] read2_addr = rom_out[24:20];
    wire [4:0] resultado_addr = rom_out[11:7];

    reg reg_RW = 1'b0;

    wire [W-1:0] reg_in;
    assign reg_in = resultado;

    wire [4:0] read1_mux;
    assign read1_mux = (opera) ? read1_addr
                               : read;

    wire [W-1:0] reg_out1, reg_out2;

    registerfile #(.W(W)) registerfile (
        .Read1(read1_mux),
        .Read2(read2_addr),
        .WriteReg(resultado_addr),
        .WriteData(reg_in),
        .RegWrite(reg_RW),
        .Data1(reg_out1),
        .Data2(reg_out2),
        .clock(clock)
    );

    /**************************************************************************
                                        ULA
    **************************************************************************/
    localparam ALUe     = 4'b0000;
    localparam ALUou    = 4'b0001;
    localparam ALUmais  = 4'b0010;
    localparam ALUmenos = 4'b0110;
    localparam ALUmenor = 4'b0111;
    localparam ALUnor   = 4'b1100;

    wire [11:0] N = rom_out[31:20];

    reg [3:0] ALUctl;
    wire [W-1:0] A_alu, B_alu;
    assign A_alu = reg_out1;
    assign B_alu = reg_out2;

    wire [W-1:0] B_mux;
    assign B_mux = rom_out[5] ? B_alu
                              : N;

    wire [W-1:0] resultado;

    alu #(.W(W)) alu (
        .ALUctl(ALUctl),
        .A(A_alu),
        .B(B_mux),
        .ALUout(resultado),
        .Overflow(), //não utilizado
        .Zero()  //não utilizado
    );

    /**************************************************************************
                                     CALCULADORA
    **************************************************************************/
    localparam AmaisB  = 5'b00000;
    localparam AmenosB = 5'b00001;
    localparam AouB    = 5'b0110x;
    localparam AeB     = 5'b0111x;
    localparam AmenorB = 5'b0010x;
    localparam AmaisN  = 5'b1000x;
    localparam AouN    = 5'b1110x;
    localparam AeN     = 5'b1111x;
    localparam AmenorN = 5'b1010x;

    assign data = reg_out1;
    assign rom_addr = i[3:0];

    integer i = 0;
    always @(posedge clock) begin
        if (reset) begin
            i = 0;
            rom_oe = 1'b0;
            reg_RW = 1'b0;
        end
        else if(opera && i < 16) begin
            rom_oe = 1'b1;
            reg_RW = 1'b1;
            #2;
            if (~rom_out[5]) begin
                case (operacao)
                    AmaisB  : ALUctl = ALUmais;
                    AmenosB : ALUctl = ALUmenos;
                    AouB    : ALUctl = ALUou;
                    AeB     : ALUctl = ALUe;
                    AmenorB : ALUctl = ALUmenor;
                endcase
            end
            else begin
                case (operacao)
                    AmaisN  : ALUctl = ALUmais;
                    AouN    : ALUctl = ALUou;
                    AeN     : ALUctl = ALUe;
                    AmenorN : ALUctl = ALUmenor;
                endcase
            end
            
            i = i + 1;
        end
        rom_oe = 1'b0;
        reg_RW = 1'b0;
    end

endmodule

/**************************************************************************
                                  MODULO ULA
**************************************************************************/
module alu
    #(parameter W = 32)
    (input [3:0] ALUctl,
     input [W-1:0] A, B,
     output [W-1:0] ALUout,
     output Overflow, Zero
    );

    reg [W-1:0] saida;

    assign ALUout = saida;
    assign Zero = (saida == 0);
    assign Overflow = ALUctl[1] ? ALUctl[0] ? 1'bZ // XX11
                                            : ((~A[W-1] && ~B[W-1] && saida[W-1]) || (A[W-1] && B[W-1] && ~saida[W-1])) // XX10
                                : 1'bZ; // XX0X

    always @(ALUctl, A, B) begin
        case (ALUctl)
            4'b0000: saida = A & B; // AND
            4'b0001: saida = A | B; // OR
            4'b0010: saida = A + B; // Sum
            4'b0110: saida = A - B; // Subtract
            4'b0111: saida = ($signed(A) < $signed(B)) ? 4'b1 // Less than
                                                       : 4'b0; // Equal or more than
            4'b1100: saida = ~(A | B); // NOR
            default: saida = W-1'bZ; // Undefined
        endcase
    end
endmodule

/**************************************************************************
                              MODULO REGISTERFILE
**************************************************************************/
module registerfile
    #(parameter W = 32)
    (input [4:0] Read1, Read2, WriteReg,
     input [W-1:0] WriteData,
     input RegWrite,
     output [W-1:0] Data1, Data2,
     input clock
    );

    reg [W-1:0] registers [31:0];

    assign Data1 = registers[Read1];
    assign Data2 = registers[Read2];

    initial begin
        registers[0] = 0;
    end
    
    always @(posedge clock) begin
        if (RegWrite) begin
            if (WriteReg !== 0) begin
                registers[WriteReg] <= WriteData;
            end
        end
    end
endmodule