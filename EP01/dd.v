module double_dabble (
    clk, 
    rst, 
    start, 
    binary, 
    done, 
    bcd
);

parameter W = 18;

input clk, rst, start;
input [W-1:0] binary;

output done;
output [4* $ceil(W/3.0)-1:0] bcd;

//meu código
reg [W-1:0] Rbin;
reg [4* $ceil(W/3.0)-1:0] Rbcd;
reg doneControl;
parameter maxBcd = ($ceil(W/3.0));
wire [3:0] addOut [$ceil(W/3.0):0];

assign bcd = Rbcd;
assign done = doneControl;


reg [1:0] state;
localparam alocState = 2'b00;
localparam shiftState = 2'b01;
localparam correctiontState = 2'b10;
localparam doneState = 2'b11;

//wire [3:0] addOut;
reg [4* $ceil(W/3.0)-1:0] temp;

genvar maxBcd_g;
generate
    for (maxBcd_g = 0; maxBcd_g < $ceil(W/3.0); maxBcd_g = maxBcd_g+1) begin
        add3or0 add3or0_0 (
            .bcd_i(Rbcd[4*maxBcd_g+3:4*maxBcd_g]), 
            .bcd_o(addOut[maxBcd_g])
        );
    end
endgenerate


integer j = 0;
integer i = 0;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        doneControl = 1'b0;
        state = alocState;
    end
    case (state)
        alocState: begin
            Rbin = binary;
            Rbcd = 0;
            i = 0;
        end

        shiftState: begin
            Rbcd <= {Rbcd[24-2:0], Rbin[W-1]};
            Rbin <= Rbin << 1;
        end

        correctiontState: begin
            for(j = maxBcd; j >= 0; j = j-1) begin
                temp = {temp, addOut[j]};
            end
            Rbcd = temp;
        end
        doneState: begin
            doneControl = 1'b1;
        end
        default: state = alocState;
    endcase
end

always @(state or posedge clk) begin
    if(rst) state = alocState;
    case (state)
        alocState: begin
            if(start) begin
                state = shiftState;
            end
        end
        shiftState: begin
            i = i+1;
            if (i == W) begin
                state = doneState;
            end
            else begin
                state = correctiontState;
            end
        end
        correctiontState: begin
                state = shiftState;
        end
        doneState: begin
            if(!start)begin
                state = alocState;
            end
        end
        default: state = alocState; 
    endcase
end

endmodule


module add3or0 (
    bcd_i, 
    bcd_o
);

input [3:0] bcd_i;
output [3:0] bcd_o;

assign bcd_o = (bcd_i < 5) ? bcd_i : bcd_i + 4'b0011;
endmodule


/*
//Testbench
module tb_double_dabble;

parameter W = 18;

reg clk;
reg rst;
reg start;
reg [W-1:0] binary;

wire done;
wire [4* $ceil(W/3.0)-1:0] bcd;

double_dabble dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .binary(binary),
    .done(done),
    .bcd(bcd)
);


always #1 clk = ~clk;

initial begin
    $dumpfile("tb_double_dabble.vcd");
    $dumpvars(0, tb_double_dabble);
    clk = 1'b0;
    #10;
    rst = 0;
    #10;
    binary = 12895;
    start = 1;
    #100;
    start = 0;
    binary = 54345;
    #15 start = 1;
    #100;
    $finish;
end

endmodule
*/