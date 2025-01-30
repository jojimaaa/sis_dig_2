module calculadora 
#(parameter W = 32) (
    input clock, reset, opera,
    input [4:0] read,
    output [W-1:0] data
);

wire [31:0] romOut;
wire [W-1:0] regOut1, regOut2;
wire [W-1:0] AluBMUX, AluOut;
wire [4:0] regRead1Mux;

reg [$clog2(16)-1:0] romAddr = 0;
reg romOE = 1'b1;

assign data = regOut1;
assign AluBMUX = romOut[5] ? regOut2 : romOut[31:20];
assign regRead1Mux = opera ? romOut[19:15] : read;

registerfile #(W) rf (
    .Read1(regRead1Mux),
    .Read2(romOut[24:20]),
    .WriteReg(romOut[11:7]),
    .WriteData(AluOut),
    .RegWrite(opera),
    .Data1(regOut1),
    .Data2(regOut2),
    .clock(clock)
);

alu #(W) alu (
    .ALUctl(AluCtl),
    .A(regOut1),
    .B(AluBMUX),
    .ALUout(AluOut),
    .Zero(),
    .Overflow()
);

rom #(32, 16) rom (
    .address(romAddr),
    .oe(romOE),
    .data(romOut)
);



reg [3:0] AluCtl;
localparam AandB = 4'b0000;
localparam AorB = 4'b0001;
localparam AplusB = 4'b0010;
localparam AminusB = 4'b0110;
localparam AlessthanB = 4'b0111;
localparam AnorB = 4'b1100;


initial begin
    romAddr = 0;
    romOE = 1;
end

always @(posedge clock or reset) begin
    if(reset) begin
        romAddr <= 0;
        romOE <= 1;
    end
    else begin
        if(opera && romAddr < 16) begin
            romAddr <= romAddr + 1;
        end
        else begin

        end
    end
end

always @(romOut) begin
    if(romOut[5] == 1) begin
        case(romOut[14:12])
            3'b000: begin 
                if (romOut[30] == 0) begin
                    AluCtl = AplusB;
                end
                else begin
                    AluCtl = AminusB;
                end
            end
            3'b110: AluCtl = AorB;
            3'b111: AluCtl = AandB;
            3'b010: AluCtl = AlessthanB;
        endcase
    end
    if(romOut[5] == 0) begin
        case(romOut[14:12])
            3'b000: AluCtl = AplusB;
            3'b110: AluCtl = AorB;
            3'b111: AluCtl = AandB;
            3'b010: AluCtl = AlessthanB;
        endcase
    end
end

endmodule
//registerfile ========================================================================

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

//ULA ===================================================================================
module alu
#(parameter W = 32)
(
    input [3:0] ALUctl,
    input [W-1:0] A, B,
    output [W-1:0] ALUout,
    output Overflow, Zero
);

    reg [W-1:0] outreg;
    reg overf;
    assign Zero = (ALUout == 0);
    assign ALUout = outreg;
    assign Overflow = (ALUctl == 4'b0010) ? ((A[W-1] == B[W-1] && A[W-1] != outreg[W-1])) ? 1 : 0 : ((A[W-1] != B[W-1] && A[W-1] != outreg[W-1])) ? 1 : 0;
    always @(*) begin
        case (ALUctl)
            4'b0000: outreg = A & B; // AND operation
            4'b0001: outreg = A | B; // OR operation
            4'b0010: outreg = A + B; // Addition
            4'b0110: outreg = A-B; // Subtraction
            4'b0111: outreg = $signed(A) < $signed(B); // Less than
            4'b1100: outreg = ~(A | B); // NOR operation
        endcase
    end
endmodule

//Testbench ===================================================================================
module calculadora_tb;

  localparam W = 32;  // Teste com Ws diferentes!

  reg          reset, opera, clock = 0;
  reg  [4:0]   read;
  wire [W-1:0] data;
  
  calculadora #(W) dut(.*);

  always #1 clock = ~clock;

  initial begin
    
    $dumpfile ("calculadora_tb2.vcd");
    $dumpvars(0, calculadora_tb);

    read <= 1'b0;
    opera <= 1'b0;
    reset <= 1'b1;
    #1 reset <= 1'b0;

    #3;

    // Teste instrução 1 -> addi x0, x0, 1     00100013
    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 0;
    #1 if (data==0)
      $display("Acerto: RF[%d] = %h, esperado 0.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 1;
    #1 if (data==1)
      $display("Acerto: RF[%d] = %h, esperado 1.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 1.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 1;
    #1 if (data==2)
      $display("Acerto: RF[%d] = %h, esperado 2.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 2.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 2;
    #1 if (data==2)
      $display("Acerto: RF[%d] = %h, esperado 2.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 2.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 3;
    #1 if (data==4)
      $display("Acerto: RF[%d] = %h, esperado 4.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 4.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 4;
    #1 if (data==1)
      $display("Acerto: RF[%d] = %h, esperado 1.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 1.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 5;
    #1 if (data==3)
      $display("Acerto: RF[%d] = %h, esperado 3.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 3.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 6;
    #1 if (data==7)
      $display("Acerto: RF[%d] = %h, esperado 7.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 7.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 7;
    #1 if (data==1)
      $display("Acerto: RF[%d] = %h, esperado 1.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 1.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 7;
    #1 if (data==4095)
      $display("Acerto: RF[%d] = %h, esperado 0x00000fff.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0x00000fff.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 8;
    #1 if (data==0)
      $display("Acerto: RF[%d] = %h, esperado 0.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 9;
    #1 if (data==1)
      $display("Acerto: RF[%d] = %h, esperado 1.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 1.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 10;
    #1 if (data==4096)
      $display("Acerto: RF[%d] = %h, esperado 0x00001000.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0x00001000.", read, data);


    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 10;
    #1 if (data==4096)
      $display("Acerto: RF[%d] = %h, esperado 0x00001000.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0x00001000.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 10;
    #1 if (data==1)
      $display("Acerto: RF[%d] = %h, esperado 1.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 1.", read, data);

    opera <= 1'b1; #2; opera <= 1'b0;
    read <= 10;
    #1 if (data== -4094)
      $display("Acerto: RF[%d] = %h, esperado 0xfffff002.", read, data);
    else
      $display("Erro: RF[%d] = %h, esperado 0xfffff002.", read, data);

    $finish;
  end
endmodule

module rom
    #( parameter W = 32,
       parameter L = 16)
     ( input  [$clog2(L)-1:0] address,
       input  oe,
       output [W-1:0] data
     );

    reg [W-1:0] mem[L-1:0];
    
    assign data = (oe) ? mem[address] : {W{1'bZ}};

    initial begin
        $readmemh("rom.hex",mem,0,L-1);
    end
endmodule
