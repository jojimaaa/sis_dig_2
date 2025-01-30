module registerfile
    #(parameter W = 32)
    (  input [4:0] Read1, Read2, WriteReg,
       input [W-1:0] WriteData,
       input RegWrite,
       output [W-1:0] Data1, Data2,
       input clock
    );

reg [W-1:0] regfile[31:0];

initial begin
    regfile[0] = 32'b0;
end

assign Data1 = regfile[Read1];
assign Data2 = regfile[Read2];

always @(posedge clock) begin
    if (RegWrite && (WriteReg != 4'b0000)) begin
        regfile[WriteReg] = WriteData;
    end
end
endmodule