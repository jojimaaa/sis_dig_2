 module rom_16 ( out , addr , CS);
    input [3:0] addr ;
    input CS;
    output reg [15:0] out ;
    reg [15:0] data [15:0];
    integer i;
    initial
    begin
    for (i = 0; i < 15; i++)
        data [i] = i[15:0];
        data [15] = 16'h69 ;
    end
    always @( addr , CS)
        out = data [ addr ];
 endmodule

module ram_4 (out, in, addr , RW, CS);
    input [15:0] in;
    input [1:0] addr ;
    input RW, CS;
    output reg [15:0] out ;
    reg [15:0] data [3:0];
    integer i;
    initial
        for (i = 0; i < 4; i++)
            data [i] = 16'b0 ;
    always @( addr , CS, RW)
        if(RW== 1'b0 )
            out = data [ addr ];
        else
            if(RW== 1'b1 )
                data [ addr ]=in;
            else
                out= 16'bz ;
endmodule


module romram1(out, done);
    output [15:0] out;
    output reg done;

    wire [15:0] w1;
    reg rw; //0 = read, 1 = write

    rom_16 rom (w1, 4'd15, 1'b1);

    ram_4 ram (out, w1, 2'd3, rw, 1'b1);
    
    initial begin
        #1 rw = 1'b1;
        #1 rw = 1'b0;
        #1 done = 1'b1;
        #1 $display("romram1: out=0x%0h, done=0x%0h", out, done);
    end
endmodule


module romram2(soma, comp, done);
    output reg [15:0] soma;
    output reg comp, done;

    wire [15:0] outrom;
    wire [15:0] outram;
    reg rw;
    reg [15:0] aux;
    reg [3:0] i;

    rom_16 rom (.out(outrom), .addr(i), .CS(1'b1));
    ram_4 ram (.out(outram), .in(aux), .addr(2'b01), .RW(rw), .CS(1'b1));

    initial begin
        aux = 16'h0000;
        #1 rw = 1;
        #1 rw = 0;
        for (i = 0; i <= 14 ; i = i+1) begin
            #1 aux = outrom + outram;
            #1 rw = 1;
            #1 rw = 0;
        end

        #1 i = 15;
        if(outram == outrom) begin
            comp = 1'b1;
            #1 done = 1'b1;
        end

        soma = outram;

        #10 $display("romram2: soma=0x%0h, comp=0x%0h, done=0x%0h", soma, comp, done);
    end
endmodule