module alu
#(parameter W = 32) 
(   input [3 :0] ALUctl, 
    input [W-1:0] A, B, 
    output [W-1:0]ALUout, 
    output Overflow, Zero);
    
    reg[W-1:0] out;
    reg[W:0] temp;
    reg ovf;
    integer i;

    always @(A, B, ALUctl) begin
        case(ALUctl)
            4'd0: begin    
                out = A & B;
            end
            4'd1: begin    
                out = A | B;
            end
            4'd2: begin
                out = A + B;
                ovf = ((A[W-1] == B[W-1]) && (B[W-1] != out[W-1]));
            end
            4'd6: begin
                out = A - B;
                ovf = ((A[W-1] != B[W-1]) && (B[W-1] == out[W-1]));
            end
            4'd7: begin
                out = ($signed(A)<$signed(B));
            end
            4'd12: begin
                out[i] = ~(A | B);            
            end
            default: begin
                out = 32'b0;
            end

        endcase
    end

    assign Overflow = ((ovf) && ((ALUctl == 4'd6) || (ALUctl == 4'd2))); 
    assign ALUout = out;
    assign Zero = (ALUout==0);

endmodule

module registerfile 
#( parameter W = 32) 
(   input [4 :0] Read1, Read2, WriteReg, 
    input [W-1:0] WriteData, 
    input RegWrite, 
    output [W-1:0] Data1, Data2, 
    input clock);

reg [W-1:0] registers[31:0];
reg [W-1:0] out1, out2;

always @ (posedge clock) begin
    if((RegWrite) && (WriteReg != 0)) begin
        registers[WriteReg] = WriteData;
    end
end

always @ (Read1, Read2, posedge clock) begin
    if (Read1 > 0) out1 = registers[Read1]; 
    else out1 = 0;
    if(Read2 > 0) out2 = registers[Read2]; 
    else out2 = 0;
end

assign Data1 = out1;
assign Data2 = out2;

endmodule

module calculadora 
#( parameter W = 32 ) 
(   input clock, reset, opera, 
    input [4:0] read, 
    output [W-1:0] data);

wire [3:0] op_ula;
reg [4:0] addr_w;
reg [W-1:0] out_data;

wire [4:0] op;
wire rw, ze, ovf;
wire [4:0] w_addr, read1, read2;
wire [W-1:0] rf_out1, rf_out2, in_a, in_b, ula_out; 
wire [31:0] rom_out;

// Modules
alu #(W) ULA(op_ula, in_a, in_b, ula_out, ovf, ze);
registerfile #(W) RF(read1, read2, w_addr, ula_out, opera, rf_out1, rf_out2, clock);
rom #(.W(32), .L(16)) ROM(i[3:0], 1'b1, rom_out);

// Wiring
assign in_a = rf_out1;
assign in_b = (~rom_out[5]) ? rom_out[31:20] : rf_out2;

assign op = rom_out[14:12];
assign op_ula = (4'd6) * ((op == 0) && (rom_out[5] && rom_out[30])) + (4'd2) * ((op == 0) && ~(rom_out[5] && rom_out[30])) + 
(4'd7) * (op == 4'd2) + (4'd1) * (op == 4'd6) + (4'd0)*(op==4'd7) ;  

assign w_addr = rom_out[11:7];

assign read1 = rom_out[19:15];
assign read2 = (opera) ? $signed(rom_out[24:20]) : read;
assign data = rf_out2;

// Rom reading
integer i = 0;

always @ (posedge clock) begin
    if (reset) begin
        i = 0;
    end
    if (opera && i < 16) begin
        i = i + 1;
    end
end   

endmodule