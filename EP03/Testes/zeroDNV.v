module control_unit
(
  input [31:0] im_data,
  input ALUzero, ALUneg,
  output reg RegWrite, ALUsrc,
  output reg [1:0] PCsrc, MemWrite,
  output reg [2:0] ALUctl, MemtoReg
);
  
  // ALU operation codes
  localparam
    op_add  = 3'd0,
    op_and  = 3'd1,
    op_or   = 3'd2,
    op_sl   = 3'd3,
    op_sra  = 3'd4,
    op_srl  = 3'd5,
    op_sub  = 3'd6,
    op_xor  = 3'd7;
  
  // Partition instruction
  wire [6:0] opcode = im_data[6: 0];
  wire [2:0] funct3 = im_data[14:12];
  wire [6:0] funct7 = im_data[31:25];

    reg [11:0] control;

    always @* begin
        ALUsrc <= control[11];
        RegWrite <= control[10];
        MemWrite <= control[9:8];
        PCsrc <= control[7:6];
        MemtoReg <= control[5:3];
        ALUctl <= control[2:0];  
        casez ({opcode, funct3, funct7})
            17'b0110011_000_0000000: control <= 12'b0_1_00_00_000_000; //ADD

            17'b0010011_000_???????	: control <= 12'b1_1_00_00_000_000; //ADDI

            17'b0110011_000_0100000: control <= 12'b0_1_00_00_000_110; //SUB

            17'b0110011_111_0000000: control <= 12'b0_1_00_00_000_001; //AND

            17'b0010011_111_???????: control <= 12'b1_1_00_00_000_001; //ANDI

            17'b0110011_110_0000000: control <= 12'b0_1_00_00_000_010; //OR

            17'b0010011_110_???????: control <= 12'b1_1_00_00_000_010; //ORI

            17'b0110011_100_0000000: control <= 12'b0_1_00_00_000_111; //XOR

            17'b0010011_100_???????: control <= 12'b1_1_00_00_000_111; //XORI

            17'b0110011_001_0000000: control <= 12'b0_1_00_00_000_011; //SLL

            17'b0010011_001_???????: control <= 12'b1_1_00_00_000_011; //SLLI

            17'b0110011_101_0000000: control <= 12'b0_1_00_00_000_101; //SRL

            17'b0010011_101_???????: control <= 12'b1_1_00_00_000_101; //SRLI

            17'b0110011_101_0100000: control <= 12'b0_1_00_00_000_100; // SRA

            17'b0010011_101_0100000: control <= 12'b1_1_00_00_000_100; // SRAI

            17'b0110011_010_0000000: control <= 12'b0_1_00_00_111_110; // SLT
    
            17'b0010011_010_???????: control <= 12'b1_1_00_00_111_110; // SLTI
    
            17'b0000011_010_???????: control <= 12'b1_1_00_00_110_000; // LW
    
            17'b0000011_001_???????: control <= 12'b1_1_00_00_101_000; // LH
    
            17'b0000011_000_???????: control <= 12'b1_1_00_00_100_000; // LB
    
            17'b0100011_010_???????: control <= 12'b1_0_11_00_000_000; // SW
    
            17'b0100011_001_???????: control <= 12'b1_0_10_00_000_000; // SH
    
            17'b0100011_000_???????: control <= 12'b1_0_01_00_000_000; // SB
    
            17'b1100011_000_???????: control <= ALUzero ? 12'b0_0_00_01_000_110 : 12'b0_0_00_00_000_110; // BEQ

            17'b1100011_001_???????: control <= ALUzero ? 12'b0_0_00_00_000_110 : 12'b0_0_00_01_000_110; // BNE
    
            17'b1100011_101_???????: control <= (ALUzero || ~ALUneg) ? 12'b0_0_00_01_000_110 : 12'b0_0_00_00_000_110; // BGE
    
            17'b1100011_100_???????: control <= (ALUneg) ? 12'b0_0_00_01_000_110 : 12'b0_0_00_00_000_110; // BLT
    
            17'b0110111_???_???????: control <= 12'b1_1_00_00_010_000; // LUI
    
            17'b0010111_???_???????: control <= 12'b1_1_00_00_011_000; // AUIPC
    
            17'b1101111_???_???????: control <= 12'b1_1_00_01_001_000; // JAL
    
            17'b1100111_000_???????: control <= 12'b1_1_00_10_001_000; // JALR

            default: control = 0;
        endcase
    end

  // EBREAK return signal 
  wire brk = (im_data[6:0] == 7'b1110011) ? 1 : 0;


  // -- Guidelines
  // For each control signal above you can use 'assign', 'case', or 'casez', as you see want. Your possible inputs are: 'im_data' (broken into opcode, funct3 and funct7), ALUzero and ALUneg.
  // The last line (wire brk) serves to inform the testbench to evaluate a response. Please leave it unaltered.
endmodule