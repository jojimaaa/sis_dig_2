/*
    module mfp_tb;

        reg [1:0] ram_addr_juiz;
        wire [31:0] ram_out_juiz;
        wire done;

        fpm dut (
            .ram_addr_juiz(ram_addr_juiz),
            .ram_out_juiz(ram_out_juiz),
            .done(done)
        );

        reg clk = 1'b0;
        always #1 clk = ~clk;

        initial begin
            // Initialize inputs
            ram_addr_juiz = 2'b00;
        end

        integer i;
        always @(posedge clk) begin
            if(done) begin
              for (i = 0; i < 4 ; i++) begin
                ram_addr_juiz = i[1:0];
                #1;
              end
              #100 $finish;
            end
        end

        // Add GTKWave support
        initial begin
            $dumpfile("mfp_tb.vcd");
            $dumpvars(0, mfp_tb);
        end
    endmodule
    */
module fpm(
  input  [1:0]  ram_addr_juiz,
  output [31:0] ram_out_juiz,
  output reg    done
);
  // Variaveis da ROM e RAM
  reg  [2:0]  rom_addr;
  reg  [1:0]  ram_addr;
  wire [31:0] rom_out, ram_in;
  reg         ram_RW, rom_OE, ram_OE;

  // Variaveis do multiplicador
  reg  [31:0] mul_a, mul_b;
  reg         mul_en, mul_rst, mul_clk=0;
  wire        mul_done;
  wire [31:0] mul_z;

  // Clock para o multiplicador
  always
    #1 mul_clk = ~mul_clk;

  // Multiplexador para o juiz
  wire [1:0] ram_addr_mux;
  assign ram_addr_mux = (ram_RW ? ram_addr : ram_addr_juiz);

    reg[2:0] state;
    localparam aloc1 = 3'd0;
    localparam aloc2 = 3'd1;
    localparam waitMul = 3'd2;
    localparam alocRam = 3'd3;
    localparam Done = 3'd4; 


rom_8 rom (.addr(rom_addr), .OE(rom_OE), .out(rom_out));
ram_4 ram (.in(ram_in), .addr(ram_addr_mux), .RW(ram_RW), .OE(ram_OE), .out(ram_out_juiz));
fp_mult mult (.input_a(mul_a), .input_b(mul_b), .en(mul_en), .rst(mul_rst), .clk(mul_clk), .done(mul_done), .output_z(mul_z));

assign ram_in = mul_z;

initial begin
  ram_addr = 2'b00;
  rom_OE = 1'b1;
  rom_addr = 3'b000;
  ram_RW = 1'b1;
end

  always @(mul_clk) begin
    case(state)
      aloc1: begin
        mul_rst = 1'b0;
        rom_addr = ram_addr + ram_addr;
        rom_OE = 1'b1;
        #1; mul_a = rom_out;
        #1; rom_OE = 1'b0;
        #1; state = aloc2;
      end
      aloc2: begin
        rom_addr = ram_addr + ram_addr + 1'b1;
        rom_OE = 1'b1;
        #1; mul_b = rom_out;
        mul_en = 1'b1;
        #1; rom_OE = 1'b0;
        #1; state = waitMul;
      end
      waitMul: begin
        if(mul_done) begin
          #1; state = alocRam;
          #1; mul_en = 1'b0;
        end
      end
      alocRam: begin
        //ram_RW = 1'b1;
        ram_OE = 1'b0;
        //#1; ram_RW = 1'b0;
        if(ram_addr == 2'd3) begin
          #1; state = Done;
        end
        else begin
        mul_rst = 1'b1;
          ram_addr = ram_addr + 1'b1;
          #1; state = aloc1;
          #1; mul_rst = 1'b0;
        end
      end
      Done: begin
        done = 1'b1;
        ram_OE = 1'b1;
        ram_RW = 1'b0;
      end
      default: begin
        state = aloc1;
      end
    endcase
  end


endmodule
/*
module ram_4(
  input [31:0] in,
  input [1:0] addr,
  input RW, OE,
  output reg [31:0] out
);
  reg [31:0] data[3:0];
  always @(in, addr, RW, OE)
  begin
    if(RW==1'b0 & OE==1'b1)
      out=data[addr];
    else
      out=32'bz;
    if(RW==1'b1)
      data[addr]=in;
  end
endmodule

module rom_8(
  input [2:0] addr,
  input OE,
  output reg [31:0] out
);
  reg [31:0] data[7:0];
  
  initial begin
    data[0] = 32'h15350076;
    data[1] = 32'h5952599f;
    data[2] = 32'h3f800000;
    data[3] = 32'h3e800000;
    data[4] = 32'h40400000;
    data[5] = 32'h41200000;
    data[6] = 32'h3ea00000;
    data[7] = 32'h3f600000;
  end

  always @(addr, OE)
    if (OE==1'b1)
      out=data[addr];
    else
      out=32'bz;
endmodule

module fp_mult(
  input  [31:0] input_a, input_b,
  input         en, rst, clk,
  output        done,
  output [31:0] output_z
);
  reg    [31:0] s_output_z;
  reg           s_en = 0, s_done = 0;
  reg    [3:0]  state = 0;
  reg    [31:0] a, b, z;
  reg    [23:0] a_m, b_m, z_m;
  reg    [9:0]  a_e, b_e, z_e;
  reg           a_s, b_s, z_s;
  reg           guard, round_bit, sticky;
  reg    [47:0] product;

  assign output_z = s_output_z;
  assign done = s_done;

  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            normalise_a   = 4'd4,
            normalise_b   = 4'd5,
            multiply_0    = 4'd6,
            multiply_1    = 4'd7,
            normalise_1   = 4'd8,
            normalise_2   = 4'd9,
            round         = 4'd10,
            pack          = 4'd11,
            put_z         = 4'd12;
  
  always @(posedge clk)
  begin

    case(state)

      get_a:
      begin
        if (en) begin
          s_done <= 0;
          a <= input_a;
          state <= get_b;
        end
      end

      get_b:
      begin
        if (en) begin
          b <= input_b;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= a[22 : 0];
        b_m <= b[22 : 0];
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22] <= 1;
          z[21:0] <= 0;
          state <= put_z;
        //if a is inf return inf
        end else if (a_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if b is zero return NaN
          if (($signed(b_e) == -127) && (b_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        //if b is inf return inf
        end else if (b_e == 128) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 255;
          z[22:0] <= 0;
          //if a is zero return NaN
          if (($signed(a_e) == -127) && (a_m == 0)) begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
          end
          state <= put_z;
        //if a is zero return zero
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        //if b is zero return zero
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z[31] <= a_s ^ b_s;
          z[30:23] <= 0;
          z[22:0] <= 0;
          state <= put_z;
        end else begin
          //Denormalised Number
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[23] <= 1;
          end
          //Denormalised Number
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[23] <= 1;
          end
          state <= normalise_a;
        end
      end

      normalise_a:
      begin
        if (a_m[23]) begin
          state <= normalise_b;
        end else begin
          a_m <= a_m << 1;
          a_e <= a_e - 1;
        end
      end

      normalise_b:
      begin
        if (b_m[23]) begin
          state <= multiply_0;
        end else begin
          b_m <= b_m << 1;
          b_e <= b_e - 1;
        end
      end

      multiply_0:
      begin
        z_s <= a_s ^ b_s;
        z_e <= a_e + b_e + 1;
        product <= a_m * b_m;
        state <= multiply_1;
      end

      multiply_1:
      begin
        z_m <= product[47:24];
        guard <= product[23];
        round_bit <= product[22];
        sticky <= (product[21:0] != 0);
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z <= z;
        s_done <= 1;
        if (en) begin
          state <= get_a;
        end
      end

    endcase

    if (rst == 1) begin
      state <= get_a;
      s_done <= 0;
    end

  end

endmodule
*/