module registerfile
  #(parameter W = 32)
(
  input  [  4:0] Read1, Read2, WriteReg,
  input  [W-1:0] WriteData,
  input          RegWrite, clk,
  output [W-1:0] Data1, Data2
);
  reg [W-1:0] RF [31:0];

  assign Data1 = (Read1) ? RF[Read1] : {W{1'b0}};
  assign Data2 = (Read2) ? RF[Read2] : {W{1'b0}};

  always @(posedge clk)
    if (RegWrite && WriteReg!=0)
      RF[WriteReg] = WriteData;
endmodule