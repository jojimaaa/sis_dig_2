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
