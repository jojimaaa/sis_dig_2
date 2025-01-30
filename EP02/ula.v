module alu
#(parameter W = 32)
(
    input [3:0] ALUctl,
    input [W-1:0] A, B,
    output [W-1:0] ALUout,
    output Overflow, Zero
);

    assign Zero = (ALUout == 0);
    assign Overflow = (ALUctl == 2) ? ((A[W-1] == B[W-1] && A[W-1] != AluOut[W-1])) ? 1 : 0 : ((A[W-1] != B[W-1] && A[W-1] != AluOut[W-1])) ? 1 : 0;

    assign ALUout =
        AluCtl == 0 ? (A & B) :
        AluCtl == 1 ? (A | B) :
        AluCtl == 2 ? (A + B) :
        AluCtl == 6 ? (A - B) :
        AluCtl == 7 ? ($signed(A) < $signed(B)) :
        AluCtl == 12 ? (~(A | B)) :
        0;
endmodule