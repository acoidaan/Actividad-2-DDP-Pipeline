`timescale 1 ns / 10 ps

module DE1_System_tb;

// ---------------------------------------------------------
// Señales del testbench
// ---------------------------------------------------------
// KEY y SW son las entradas "físicas" del sistema, así que
// tienen que ser reg para poder controlarlas desde initial.
reg        clk;
reg  [3:0] KEY;
reg  [9:0] SW;
wire [6:0] HEX0, HEX1, HEX2, HEX3;
wire [9:0] LEDR;
wire [7:0] LEDG;

// ---------------------------------------------------------
// Reloj de 50 MHz (periodo 20 ns)
// ---------------------------------------------------------
initial clk = 1'b0;
always  #10 clk = ~clk;

// ---------------------------------------------------------
// Instanciación del sistema completo.
// Conexión por nombre: mas robusta si cambia el orden
// de los puertos del top.
// ---------------------------------------------------------
DE1_System system (
    .CLOCK_50(clk),
    .KEY(KEY),
    .SW(SW),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .LEDR(LEDR),
    .LEDG(LEDG)
);

// ---------------------------------------------------------
// Estímulos: reset y datos de entrada
// ---------------------------------------------------------
// Recordatorio: en el top, reset = ~KEY[0]. Por tanto:
//   KEY[0] = 0  ->  reset = 1  (CPU en reset)
//   KEY[0] = 1  ->  reset = 0  (CPU ejecutando)
initial begin
    $dumpfile("DE1_System_tb.vcd");
    $dumpvars;

    // Arranque con reset activo y switches a 0
    KEY = 4'b1110;   // KEY[0]=0 -> reset=1
    SW  = 10'b0;

    // Mantener el reset durante varios ciclos para que
    // se propague a todos los flip-flops del sistema
    #40;

    // Soltar el reset: la CPU empieza a ejecutar
    KEY = 4'b1111;   // KEY[0]=1 -> reset=0
end

// ---------------------------------------------------------
// Duración de la simulación
// ---------------------------------------------------------
// 400 ciclos de reloj deberían ser suficientes para
// programas cortos. Ajustar si el programa es mas largo.
initial begin
    #(400*20);
    $display("HEX01 = %0d (0x%h)", system.hex01_reg, system.hex01_reg);
    $display("LEDG = %b", LEDG);
    $finish;
end

endmodule
