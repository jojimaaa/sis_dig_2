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