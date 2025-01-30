module control_unit
#(
  parameter W = 64,
  parameter IM_L = 16
) (
  input [31:0] im_data,
  input ALUzero,
  output reg
    RegWrite,
    ALUsrc,
    PCsrc,
    MemtoReg,
    ALUctl,
    MemWrite
);
  // Operation codes
  localparam
    op_add_sub = 7'b0110011,
    op_addi    = 7'b0010011,
    op_lw      = 7'b0000011,
    op_sw      = 7'b0100011,
    op_beq_bne = 7'b1100011;
  
  // Partition instruction
  wire [6:0] opcode = im_data[ 6: 0];
  wire [4:0] rd     = im_data[11: 7];
  wire [2:0] funct3 = im_data[14:12];
  wire [4:0] rs1    = im_data[19:15];
  wire [4:0] rs2    = im_data[24:20];
  wire [6:0] funct7 = im_data[31:25];

  // ALU Control
  reg ALUop;ja
  always@*
    casez({ALUop, funct7[5]}) // Hint: this is a 'casez' statement. What is the difference between it and 'case'?
      3'b100: ALUctl = 0;
      3'b101: ALUctl = 1; 
      3'b01?: ALUctl = 1;
      3'b00?: ALUctl = 0;
      default: ALUctl = 0;
    endcase

  // PC Control
  reg branch;
  always@*
    case({branch, ALUzero, funct3[0]})
        3'b110: PCsrc = 1; //BEQ
        3'b101: PCsrc = 1; //BNE
      default: 
        PCsrc = 0;
    endcase

  // Operation Control
  always@*
    case(opcode)
      op_add_sub:
      begin
        ALUop <= 2'b10;
        MemtoReg <= 0;
        ALUsrc <= 0;
        RegWrite <= 1;
        MemWrite <= 0;
        branch <= 0;
      end
      op_addi:
      begin
        ALUop <= 2'b10;
        MemtoReg <= 0;
        ALUsrc <= 1;
        RegWrite <= 1;
        MemWrite <= 0;
        branch <= 0;
      end
      op_lw:
      begin
        ALUop <= 2'b0;
        MemtoReg <= 1;
        ALUsrc <= 1;
        RegWrite <= 1;
        MemWrite <= 0;
        branch <= 0;
      end
      op_sw:
      begin
        ALUop <= 2'b0;
        MemtoReg <= 0;
        ALUsrc <= 1;
        RegWrite <= 0;
        MemWrite <= 1;
        branch <= 0;
      end
      op_beq_bne:
      begin
        ALUop <= 2'b01;
        MemtoReg <= 0;
        ALUsrc <= 0;
        RegWrite <= 0;
        MemWrite <= 0;
        branch <= 1;
      end

      default:
      begin
        ALUop    <= 2'b0;
        MemtoReg <= 0;
        ALUsrc   <= 0;
        RegWrite <= 0;
        MemWrite <= 0;
        branch   <= 0;
      end
    endcase

endmodule