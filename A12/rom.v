module rom
#(parameter L=32)
(
  input  [$clog2(L)-1:0] addr,
  input  oe,
  output [31:0] data
);

  reg [31:0] mem[L-1:0];
  
  assign data = (oe) ? mem[addr] : 32'bz;

  initial begin
      mem[00] = 32'b00000000000000000000000010010011; //addi x1, x0, 0;
      mem[01] = 32'b00000000011100000000000100010011; //addi x2, x0, 7;
      mem[02] = 32'b00000101000000000000001000010011; //addi x4, x0, 0x50
      mem[03] = 32'b00000000000000100010000110000011; // lw x3, 0(x4)
      mem[04] = 32'b0000000_00011_00010_001_00111_1100011; // LOOP: bne x3, x2, EXIT (12'd7)** | imm[11:5]_rs2_rs1_funct3_imm[4:0]_oppcode
      mem[05] = 32'b00000000000100011000001010110011; // add x5, x3, x1
      mem[06] = 32'b00000000000100001000000010010011; // addi x1, x1, 1
      mem[07] = 32'b00000000000100100010000110000011; // lw x3, 1(x4)
      mem[08] = 32'b00000000000100100000001000010011; // addi x4, x4, 1
      mem[09] = 32'b00000100010100000010000000100011; // sw x5, 0x40(x0)
      mem[10] = 32'b1111111_00000_00000_000_11010_1100011; // beq x0, x0, LOOP (12'd-6)
      mem[11] = 32'h10500073;
      mem[12] = 32'h10500073;
      mem[13] = 32'h10500073;
      mem[14] = 32'h10500073;
      mem[15] = 32'h10500073;
      mem[16] = 32'h10500073;
      mem[17] = 32'h10500073;
      mem[18] = 32'h10500073;
      mem[19] = 32'h10500073;
      mem[20] = 32'h10500073;
      mem[21] = 32'h10500073;
      mem[22] = 32'h10500073;
      mem[23] = 32'h10500073;
      mem[24] = 32'h10500073;
      mem[25] = 32'h10500073;
      mem[26] = 32'h10500073;
      mem[27] = 32'h10500073;
      mem[28] = 32'h10500073;
      mem[29] = 32'h10500073;
      mem[30] = 32'h10500073;
      mem[31] = 32'h10500073; // wfi
  end
    
endmodule
