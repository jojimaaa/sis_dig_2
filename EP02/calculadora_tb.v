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