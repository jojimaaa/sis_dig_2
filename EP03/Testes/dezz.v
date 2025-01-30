// Judge will use Verilog 2012 (iverilog -g 2012)
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
  wire [6:0] opcode = im_data[6:0];
  wire [2:0] funct3 = im_data[14:12];
  wire [6:0] funct7 = im_data[31:25];

  // Operation codes
  localparam
    op_R       = 7'b0110011,
    op_I       = 7'b0010011,
    op_lw      = 7'b0000011,
    op_sw      = 7'b0100011,
    op_branch  = 7'b1100011,
    op_lui     = 7'b0110111,
    op_auipc   = 7'b0010111,
    op_jal     = 7'b1101111,
    op_jalr    = 7'b1100111,
    op_ebreak  = 7'b1110011;

  /* 
  MemWrite: 0 -> read   1 -> SB   2 -> SH   3-> SW
  PCsrc: 0 -> PC+4   1 -> branch   2 -> JALR
  MemtoReg: 0 -> ALU   1 -> JAL/JALR   2 -> LUI   3 -> AUIPC   4 -> LB   5 -> LH   6 -> LW   7 -> SLT/SLTI
  */

  // Operation Control
  always @(*) begin
    // Default values
    RegWrite <= 0;
    ALUsrc <= 0;
    PCsrc <= 2'b00;
    MemWrite <= 2'b00;
    ALUctl <= op_add;
    MemtoReg <= 3'b000;

    case(opcode)
      op_R: begin // R-Type operations
        case(funct3)
          3'b000: ALUctl <= (funct7 == 7'b0000000) ? op_add : op_sub; 
          3'b001: ALUctl <= op_sl; 
          3'b010: begin
            ALUctl <= op_sub;
            MemtoReg <= 3'b111;
          end
          3'b100: ALUctl <= op_xor; 
          3'b101: ALUctl <= (funct7 == 7'b0000000) ? op_srl : op_sra; 
          3'b110: ALUctl <= op_or; 
          3'b111: ALUctl <= op_and; 
        endcase
        ALUsrc   <= 1'b0;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
      end

      op_I: begin // I-type arithmetical-logical operations 
        case(funct3)
          3'b000: ALUctl <= op_add;
          3'b001: ALUctl <= op_sl;
          3'b010: begin
            ALUctl <= op_sub;
            MemtoReg <= 3'b111;
          end
          3'b100: ALUctl <= op_xor;
          3'b101: ALUctl <= (funct7 == 7'b0000000) ? op_srl : op_sra;
          3'b110: ALUctl <= op_or;
          3'b111: ALUctl <= op_and;
        endcase 
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
      end

      op_lw: begin // Load-Word-type operations
        case(funct3)
          3'b010: begin  // LW
            ALUctl <= op_add;
            MemtoReg <= 3'b110;
          end
          3'b001: begin  // LH
            ALUctl <= op_add;
            MemtoReg <= 3'b101;
          end
          3'b000: begin  // LB
            ALUctl <= op_add;
            MemtoReg <= 3'b100;
          end
        endcase
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
      end

      op_sw: begin // Save-Word-type operations
        case(funct3)
          3'b000: MemWrite <= 2'b01; // SB
          3'b001: MemWrite <= 2'b10; // SH
          3'b010: MemWrite <= 2'b11; // SW
        endcase
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b0;
        PCsrc    <= 2'b00;
        MemtoReg <= 3'b000;
        ALUctl   <= op_add;
      end

      op_branch: begin // Branch-type operations 
        case(funct3)
          3'b000: begin // BEQ
            ALUctl <= op_sub;
            PCsrc <= (ALUzero) ? 2'b01 : 2'b00;
          end
          3'b001: begin // BNE
            ALUctl <= op_sub;
            PCsrc <= (!ALUzero) ? 2'b01 : 2'b00;
          end
          3'b100: begin // BLT
            ALUctl <= op_sub;
            PCsrc <= (ALUneg) ? 2'b01 : 2'b00;
          end
          3'b101: begin // BGE
            ALUctl <= op_sub;
            PCsrc <= (!ALUneg) ? 2'b01 : 2'b00;
          end
        endcase
        ALUsrc   <= 1'b0;
        RegWrite <= 1'b0;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b000;
      end

      op_lui: begin
        ALUsrc   <= 1'b0;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b010;
        ALUctl   <= op_add;
      end

      op_auipc: begin
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b011;
        ALUctl   <= op_add;
      end

      op_jal: begin 
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b001;
        ALUctl   <= op_add;
      end

      op_jalr: begin
        ALUsrc   <= 1'b1;
        RegWrite <= 1'b1;
        PCsrc    <= 2'b10;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b001;
        ALUctl   <= op_add;
      end

      op_ebreak: begin 
        ALUsrc   <= 1'b0;
        RegWrite <= 1'b0;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b000;
        ALUctl   <= op_add;
      end

      default: begin
        ALUsrc   <= 1'b0;
        RegWrite <= 1'b0;
        PCsrc    <= 2'b00;
        MemWrite <= 2'b00;
        MemtoReg <= 3'b000;
        ALUctl   <= op_add;
      end
    endcase
  end

  // EBREAK return signal
  wire brk = (im_data[6:0] == 7'b1110011) ? 1 : 0;

endmodule