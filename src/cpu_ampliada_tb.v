`timescale 1 ns / 10 ps

module cpu_tb;


reg clk, reset;


// generación de reloj clk
always //siempre activo, no hay condición de activación
begin
  clk = 1'b1;
  #10;
  clk = 1'b0;
  #10;
end

// instanciación del procesador
cpu micpu(clk, reset);

initial
begin
  $dumpfile("cpu_ampliada_tb.vcd");
  $dumpvars;
  reset = 1;  //a partir del flanco de subida del reset empieza el funcionamiento normal
  #5;
  reset = 0;  //bajamos el reset 
end

initial
begin

  #(9*20);  //Esperamos 9 ciclos o 9 instrucciones
  $finish;
end

endmodule