module rom_8 (
    input [2:0] addr,
    input OE,
    output reg [31:0] out
);

    reg [31:0] data [7:0];

    initial begin
        data[0] = 32'h0986ab68;
        data[1] = 32'h10385ba9;
        data[2] = 32'b0_01111111_00000000000000000000000; //1 decimal
        data[3] = 32'b0_01111101_00000000000000000000000; //0.01 binario = 0,25 decimal
        data[4] = 32'b0_10000000_10000000000000000000000; //3 decimal
        data[5] = 32'b0_10000010_01000000000000000000000; //10 decimal
        data[6] = 32'b0_01111101_01000000000000000000000; //0.3125 decimal
        data[7] = 32'b0_01111110_11000000000000000000000; //0.875 decimal
    end

    always @(addr, OE) begin
        if (OE == 1'b1)
            out = data[addr];
        else
            out = 32'bz;
    end

endmodule


module ram_4 (
    input [31:0] in,
    input [1:0] addr,
    input RW, OE,
    output reg [31:0] out
);

    reg [31:0] data [3:0];

    always @(in, addr, RW, OE) begin
        if (RW == 1'b0 && OE == 1'b1)
            out = data[addr];
        else
            out = 32'bz;
        
        if (RW == 1'b1)
            data[addr] = in;
    end
endmodule

//fpa module will read two rom values, use adder module to add them and put the result in ram module
//ram_RW = 1 - write, 0 - read
module fpa(ram_addr, ram_out, done);
    input [1:0] ram_addr;
    output reg done;
    output [31:0] ram_out;

    reg clk = 1'b1;
    always #1 clk = ~clk;

    reg [2:0] rom_addr = 3'b000;
    wire [31:0] ram_in;
    wire [1:0] ram_addr_mux;
    wire [31:0] rom_out1, rom_out2;
    reg ram_RW;
    reg rom_OE;
    reg ram_OE;
    reg adder_en;
    reg [1:0] addr_counter;

    assign ram_addr_mux = (ram_RW ? addr_counter : ram_addr);

    rom_8 rom1 (.addr(rom_addr), .OE(rom_OE), .out(rom_out1));
    rom_8 rom2 (.addr(rom_addr + 1'b1), .OE(rom_OE), .out(rom_out2));
    ram_4 ram (.in(ram_in), .addr(ram_addr_mux), .RW(ram_RW), .OE(ram_OE), .out(ram_out));
    adder adder (.operand_1(rom_out1), .operand_2(rom_out2), .clk(clk), .en(adder_en), .sum(ram_in));

    initial begin
        rom_addr = 3'b000;
        addr_counter = 2'b00;
        rom_OE = 1'b1;

        for (addr_counter = 2'b00; addr_counter < 2'b11 ; addr_counter = addr_counter + 1'b1) begin
            adder_en = 1'b1;
            ram_RW = 1'b1;
            #50 rom_addr = rom_addr + 2'b10;
            #50 ram_RW = 1'b0;
            #50 adder_en = 1'b0;
        end
        done = 1'b1;
        ram_OE = 1'b1;
        ram_RW = 1'b0;
    end

endmodule


//=================================================================================================================================================================================================
//This module compares the exponent of both inputs and shifts the mantissa of the smaller number to make the exponents equal.
module compandshift(
  input [23:0] cas_mantissa_1, cas_mantissa_2,
  input [7:0] cas_exponent_1, cas_exponent_2,
  input clk, reset,
  output reg [23:0] cas_shifted_mantissa_1, cas_shifted_mantissa_2,
  output reg [7:0] cas_new_exponent,
  output reg done_1=0
);
  reg [7:0] diff;
  always @(posedge clk)
  begin
      if(cas_exponent_1 == cas_exponent_2)
      begin
          cas_shifted_mantissa_1<=cas_mantissa_1;
          cas_shifted_mantissa_2<=cas_mantissa_2;
          cas_new_exponent<=cas_exponent_1+1'b1;
          done_1<=1;
      end
      else if(cas_exponent_1>cas_exponent_2)
      begin
          diff=cas_exponent_1-cas_exponent_2;
          cas_shifted_mantissa_1<=cas_mantissa_1;
          cas_shifted_mantissa_2<=(cas_mantissa_2>>diff);
          cas_new_exponent<=cas_exponent_1+1'b1;
          done_1<=1;
      end
      else if(cas_exponent_2>cas_exponent_1)
      begin
          diff=cas_exponent_2-cas_exponent_1;
          cas_shifted_mantissa_2<=cas_mantissa_2;
          cas_shifted_mantissa_1<=(cas_mantissa_1>>diff);
          cas_new_exponent<=cas_exponent_2+1'b1;
          done_1<=1;
      end
  end
endmodule

//=============================================================================================================================================================================================
//This module adds shifted mantissas
module addition(
  input [23:0] shifted_mantissa_1,
  input [23:0] shifted_mantissa_2,
  input [7:0] tmp_new_exponent,
  input clk,reset,
  output reg [24:0] mantissa_sum,
  output reg [7:0] add_new_exponent,
  output reg done_2=0
);
  always @(posedge clk)
  begin
      mantissa_sum<=shifted_mantissa_1+shifted_mantissa_2;
      add_new_exponent<=tmp_new_exponent;
      if(mantissa_sum==(shifted_mantissa_1+shifted_mantissa_2))
      begin
          done_2<=1;
      end
  end
endmodule

//==============================================================================================================================================================================================
//This module normalises the output mantissa
module normalisation(
  input [24:0] mantissa_sum,
  input [7:0] new_exponent,
  input clk,reset,
  output reg [23:0] mantissa_final,
  output reg [7:0] exponent_final,
  output reg done_3=0
);
  reg rst=0;
  always @(posedge clk)
  begin
      if(rst==0)
      begin
          mantissa_final<=mantissa_sum[24:1];
          exponent_final<=new_exponent;
          if(mantissa_final==mantissa_sum[24:1])
          begin
              rst<=1;
          end
      end
      else begin
          repeat(24) begin
              if(mantissa_final[23]==0)
              begin
                  mantissa_final<=(mantissa_final<<1'b1);
                  exponent_final<=exponent_final-1'b1;
              end
              else begin
                  done_3<=1;
                  rst<=0;
              end
          end
    end
end
endmodule
//=====================================================================================================================================================================================

module adder(
  input [31:0] operand_1, operand_2,
  input clk, en,
  output reg [31:0] sum = 32'bz
);
  wire reset;
  reg  busy_1=0, busy_2=0, busy_3=0;
  reg  [7:0]  exponent_1, exponent_2, new_exponent, tmp_new_exponent;
  reg  [23:0] mantissa_1, mantissa_2, shifted_mantissa_1, shifted_mantissa_2;
  wire [7:0]  exponent_final, add_new_exponent, cas_new_exponent;
  wire [23:0] mantissa_final, cas_shifted_mantissa_1, cas_shifted_mantissa_2;
  reg  [24:0] mantissa_sum;
  wire [24:0] add_mantissa_sum;

  compandshift cas(mantissa_1,mantissa_2,exponent_1,exponent_2,clk,reset,cas_shifted_mantissa_1,cas_shifted_mantissa_2,cas_new_exponent,done_1);
  addition add(shifted_mantissa_1,shifted_mantissa_2,tmp_new_exponent,clk,reset,add_mantissa_sum,add_new_exponent,done_2); 
  normalisation normalise(mantissa_sum,new_exponent,clk,reset,mantissa_final,exponent_final,done_3);

  always @(posedge clk)
  begin
      if (operand_1 === 32'b0)
      begin
        sum <= operand_2;
      end
      else if (operand_2 === 32'b0)
      begin
        sum <= operand_1;
      end

      else if(busy_1==0 & en==1)
      begin
          exponent_1<=operand_1[30:23];
          exponent_2<=operand_2[30:23];
          mantissa_1<={1'b1,operand_1[22:0]};
          mantissa_2<={1'b1,operand_2[22:0]};
          busy_1<=1;    
      end
      else if (done_1==1 && busy_2==0)
      begin
          shifted_mantissa_1<=cas_shifted_mantissa_1;
          shifted_mantissa_2<=cas_shifted_mantissa_2;
          tmp_new_exponent<=cas_new_exponent;
          busy_1<=0;
          busy_2<=1;
      end
      else if(done_2==1 && busy_3==0)
      begin
          mantissa_sum <= add_mantissa_sum;
          new_exponent <= add_new_exponent;
          busy_2<=0;
          busy_3<=1;
      end
      else if(done_3==1)
      begin
          sum<={operand_1[31],exponent_final,mantissa_final[22:0]};
          busy_3<=0;
          $display("sum:%b",sum);
      end
  end
endmodule


//write a testbench for the fpa module to gtk wave
module fpa_tb;
    reg clk;
    wire done;
    wire [31:0] ram_out;
    reg [1:0] ram_addr;
    fpa fpa1(ram_addr, ram_out, done);
    initial begin
        clk = 1'b0;
        forever #1 clk = ~clk;
    end
    initial begin
        $dumpfile("fpa_tb.vcd");
        $dumpvars(0, fpa_tb);
        #500 $finish;
    end
endmodule