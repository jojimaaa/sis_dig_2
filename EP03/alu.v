module alu
  #(parameter W = 32)
(
  input  [ 2: 0] ALUctl,
  input  [W-1:0] A, B,
  output [W-1:0] ALUout,
  output Zero, Neg
);
  wire [W-1:0] result =
    (ALUctl==0) ? (A + B)  :
    (ALUctl==1) ? (A & B)  :
    (ALUctl==2) ? (A | B)  :
    (ALUctl==3) ? (A << B) :
    (ALUctl==4) ? ($signed($signed(A) >>> B[4:0])) :
    (ALUctl==5) ? (A >> B[4:0]) :
    (ALUctl==6) ? ($signed(A) - $signed(B)) :
    (ALUctl==7) ? (A ^ B)  :
    0;
  assign ALUout = result;
  assign Zero = (result==0);
  assign Neg = ($signed(result) < 0);

endmodule