module datapath
#(
  parameter W = 64,
  parameter IM_L = 16,
  parameter DM_L = 128
) (
  input clk,

  // Control Unit I/O
  input RegWrite,
  input ALUsrc,
  input PCsrc,
  input MemtoReg,
  output ALUzero,
  input  [1:0] instType,
  input  [3:0] ALUop,
  input  [$clog2(IM_L)-1:0] PC,
  output [$clog2(IM_L)-1:0] PCnext,

  // Instruction Memory I/O
  input  [31:0] im_data,
  
  // Data Memory I/O
  input  [W-1:0] dm_data_out,
  output [W-1:0] dm_data_in,
  output [$clog2(DM_L)-1:0] dm_addr
);
  // Instruction types
  localparam
    inst_R     = 2'b00,
    inst_I     = 2'b01,
    inst_S     = 2'b10,
    inst_B     = 2'b11;

  // Partition instruction
  wire [4:0] rd  = im_data[11: 7];
  wire [4:0] rs1 = im_data[19:15];
  wire [4:0] rs2 = im_data[24:20];

  // Register File Instantiation
  wire [W-1:0] rf_wd, rs1_data, rs2_data;
  registerfile #(W) RF (
    .Read1     (rs1),
    .Read2     (rs2),
    .WriteReg  (rd),
    .WriteData (rf_wd),
    .RegWrite  (RegWrite), 
    .clk       (clk),
    .Data1     (rs1_data),
    .Data2     (rs2_data)
  );



  // ALU Instantiation
  wire [W-1:0] aluA, aluB, aluout;
  alu #(W) ALU (
    .ALUctl (ALUop),
    .A      (aluA),
    .B      (aluB),
    .ALUout (aluout),
    .Zero   (ALUzero)
  );

  // Immediate generator (asynchronous)
  reg [63:0] imm;
  always@*
    case(instType)
      inst_I:  imm <= {{53{im_data[31]}},im_data[30:20]};
      inst_S:  imm <= {{53{im_data[31]}},im_data[30:25],im_data[11:7]};
      inst_B:  imm <= {{52{im_data[31]}},im_data[7],im_data[30:25],im_data[11:8],1'b0};
      default: imm <= 64'b0;
    endcase

  // Multiplexors:
  // - aluB
  // - PCnext
  // - rf_wd
  assign aluB = ALUsrc ? rs2_data : imm;
  assign PCnext = PCsrc ? PC + imm : PC + 1 ;
  assign rf_wd = MemtoReg ? dm_data_out : aluout;


  // Direct assignments:
  // - dm_addr
  // - dm_data_in
  // - aluA
  assign dm_addr  = aluout;
  assign dm_data_in = rs2_data;
  assign aluA = rs1_data;
  
endmodule

