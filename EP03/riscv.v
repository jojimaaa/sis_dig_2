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
    end

    always @* begin
        casez ({opcode, funct3, funct7})
            17'b0110011_000_0000000: control <= 12'b0_1_00_00_000_000; //ADD

            17'b0110011_000_0100000: control <= 12'b0_1_00_00_000_110; //SUB

            17'b0110011_111_0000000: control <= 12'b0_1_00_00_000_001; //AND

            17'b0110011_110_0000000: control <= 12'b0_1_00_00_000_010; //OR

            17'b0110011_100_0000000: control <= 12'b0_1_00_00_000_111; //XOR

            17'b0110011_001_0000000: control <= 12'b0_1_00_00_000_011; //SLL

            17'b0110011_101_0000000: control <= 12'b0_1_00_00_000_101; //SRL

            17'b0110011_101_0100000: control <= 12'b0_1_00_00_000_100; // SRA

            17'b0010011_101_0100000: control <= 12'b1_1_00_00_000_100; // SRAI

            17'b0110011_010_0000000: control <= 12'b0_1_00_00_111_110; // SLT

            17'b0010011_000_???????	: control <= 12'b1_1_00_00_000_000; //ADDI

            17'b0010011_111_???????: control <= 12'b1_1_00_00_000_001; //ANDI

            17'b0010011_110_???????: control <= 12'b1_1_00_00_000_010; //ORI

            17'b0010011_100_???????: control <= 12'b1_1_00_00_000_111; //XORI

            17'b0010011_001_???????: control <= 12'b1_1_00_00_000_011; //SLLI

            17'b0010011_101_???????: control <= 12'b1_1_00_00_000_101; //SRLI
    
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
    
            17'b1100111_000_???????: control <= 12'b1_1_00_10_001_000; // JALR
    
            17'b0110111_???_???????: control <= 12'b1_1_00_00_010_000; // LUI
    
            17'b0010111_???_???????: control <= 12'b1_1_00_00_011_000; // AUIPC
    
            17'b1101111_???_???????: control <= 12'b1_1_00_01_001_000; // JAL

            default: control = 0;
        endcase
    end

  // Define ALUsrc (1 bit)

  // Define RegWrite (1 bit)

  // Define MemWrite (2 bit)

  // Define PCsrc (2 bits)

  // Define MemtoReg (3 bits)

  // Define ALUctl (3 bits)

  // EBREAK return signal 
  wire brk = (im_data[6:0] == 7'b1110011) ? 1 : 0;


  // -- Guidelines
  // For each control signal above you can use 'assign', 'case', or 'casez', as you see want. Your possible inputs are: 'im_data' (broken into opcode, funct3 and funct7), ALUzero and ALUneg.
  // The last line (wire brk) serves to inform the testbench to evaluate a response. Please leave it unaltered.
endmodule



module datapath
#(
  parameter W = 32,
  parameter IM_L = 16,
  parameter DM_L = 64
) (
  input  clk, rst, run,

  // Control Unit I/O
  input RegWrite,
  input ALUsrc,
  input [1:0] PCsrc,
  input [2:0] MemtoReg,
  input [2:0] ALUctl,
  output ALUzero, ALUneg,

  // Instruction Memory I/O
  input  [31:0] im_data,
  output [$clog2(IM_L*4)-1:0] im_addr,
  
  // Data Memory I/O
  input  [W-1:0] dm_data_out,
  output [W-1:0] dm_data_in,
  output [$clog2(DM_L*(W/8))-1:0] dm_addr
);
  
  // Instruction formats
  localparam
    fmt_R  = 3'b000,
    fmt_I  = 3'b001,
    fmt_S  = 3'b010,
    fmt_SB = 3'b011,
    fmt_U  = 3'b100,
    fmt_UJ = 3'b101;

  // Partition instruction
  wire [6:0] opcode = im_data[ 6: 0];
  wire [4:0] rd     = im_data[11: 7];
  wire [2:0] funct3 = im_data[14:12];
  wire [4:0] rs1    = im_data[19:15];
  wire [4:0] rs2    = im_data[24:20];
  wire [6:0] funct7 = im_data[31:25];

  // Register File Instantiation
  wire [W-1:0] rs1_data, rs2_data;
  reg  [W-1:0] rf_wdata;
  registerfile #(W) RF (
    .Read1     (rs1),
    .Read2     (rs2),
    .WriteReg  (rd),
    .WriteData (rf_wdata),
    .RegWrite  (RegWrite),
    .clk       (clk),
    .Data1     (rs1_data),
    .Data2     (rs2_data)
  );

  // ALU Instantiation
  wire [W-1:0] aluA, aluB, aluout;
  alu #(W) ALU (
    .ALUctl (ALUctl),
    .A      (aluA),
    .B      (aluB),
    .ALUout (aluout),
    .Zero   (ALUzero),
    .Neg    (ALUneg)
  );

  // Format associator (auxiliary variable)
  // Note that 'format', as well as 'imm' below, are not real registers, despite being defined as 'reg'. They will only be synthesized as registers if they are sensitive to a signal's edge (posedge or negedge). As such, both 'always' are combinatory circuits.
  reg [2:0] format;
  always@*
    casez(opcode)
      // accounts for all A&L instructions
      7'b0110011         // ADD
        : format <= fmt_R; 

      // accounts for all A&L immediate instructions
      7'b0010011, // ADDI
      7'b1100111, // JALR
      // accounts for all load instructions EXCEPT lui
      7'b0000011, // LW       
      // accounts EBREAK
      7'b1110011  // EBREAK
        : format <= fmt_I;

      // accounts for all store instructions
      7'b0100011  // SW          
        : format <= fmt_S;

      // accounts for all branch instructions
      7'b1100011 // BEQ
        : format <= fmt_SB;

      7'b0010111, // AUIPC
      7'b0110111  // LUI
        : format <= fmt_U;

      7'b1101111 // JAL
        : format <= fmt_UJ;

      default: format <= 3'b111;    
    endcase

  // Immediate generator
  reg [31:0] imm;
  always@*
    case(format)
      fmt_I:   imm <= {{21{im_data[31]}}, im_data[30:20]};
      fmt_S:   imm <= {{21{im_data[31]}}, im_data[30:25], im_data[11:7]};
      fmt_SB:  imm <= {{20{im_data[31]}}, im_data[7], im_data[30:25], im_data[11:8], 1'b0};
      fmt_U:   imm <= {im_data[31:12], {12{1'b0}}};
      fmt_UJ:  imm <= {{11{im_data[31]}}, im_data[19:12], im_data[20], im_data[30:21], 1'b0};
      default: imm <= 32'b0;
    endcase

  // Direct assignments
  assign aluA = rs1_data;
  assign dm_addr = aluout[6:0];
  assign im_addr = PC;

  // Program Counter -> Synchronous Assignment
  reg [$clog2(IM_L*4)-1:0] PC;
  always@(posedge clk) begin
    if (rst)
      PC <= 0;
    else if (run) begin // Note: Whether PC remains in its defined range has to be ensured by the assembly code and testbench

  // PC multiplexor
        case (PCsrc)
            2'b00: PC <= PC + 4;
            2'b01: PC <= PC + imm;
            2'b10: PC <= rs1_data + imm; //JALR 
        endcase
    end
  end

  // rf_wdata multiplexor
    always @* begin
        rf_wdata <= (MemtoReg == 3'b000) ? aluout :
                    (MemtoReg == 3'b001) ? PC+4 : // JAL e JALR
                    (MemtoReg == 3'b010) ? imm : //LUI
                    (MemtoReg == 3'b011) ? PC+imm : //AUIPC
                    (MemtoReg == 3'b100) ? {{24{dm_data_out[7]}}, dm_data_out[7:0]} : //LB
                    (MemtoReg == 3'b101) ? {{16{dm_data_out[15]}}, dm_data_out[15:0]} : //LH
                    (MemtoReg == 3'b110) ? dm_data_out[31:0] : //LW
                    (MemtoReg == 3'b111 && ALUneg) ? 1 : 0; //SLT e SLTI
    end

  // aluB multiplexor
    assign aluB = (ALUsrc) ? imm : rs2_data;

  // dm_data_in multiplexor
    assign dm_data_in = rs2_data;

  // -- Guidelines
  // For each signal above you can use 'assign', 'case', or 'casez', as you see fit. HOWEVER, if you define a clock-sensitive process, such as 'always(posedge clk)', it may cause timing issues. If you use 'case', then use 'always*'.
  // For similar reasons, remember to use '<=' inside synchronous statements.
endmodule


module riscv
#(
  parameter W = 32, IM_L = 16, DM_L = 64
) (
  input clk, rst, run
);
  // Instruction Memory
  wire [31:0] im_data;
  wire [$clog2(IM_L*4)-1:0] im_addr;
  rom #(IM_L) instructionMem(
    .addr (im_addr),
    .oe   (1'b1),
    .data (im_data)
  );

  // Data Memory
  wire [1:0] MemWrite;
  wire [W-1:0] dm_data_in, dm_data_out;
  wire [$clog2(DM_L*(W/8))-1:0] dm_addr;
  ram #(W, DM_L) dataMem(
    .addr     (dm_addr),
    .data_in  (dm_data_in),
    .clk      (clk),
    .oe       (1'b1),
    .w_mode   (MemWrite),
    .data_out (dm_data_out)
  );

  // Control Unit and Datapath
  wire RegWrite, ALUsrc, ALUzero, ALUneg; 
  wire [1:0] PCsrc;
  wire [2:0] ALUctl, MemtoReg;
  control_unit control(.*);
  datapath #(W, IM_L, DM_L) dp(.*);
endmodule