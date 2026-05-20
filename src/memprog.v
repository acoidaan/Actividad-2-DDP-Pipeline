// ============================================================
// Memoria de programa (multiciclo, lectura sincrona)
//
// Lectura sincrona con un registro a la salida para que Quartus
// la infiera como M4K en Cyclone II. Esto rompe el camino critico
// PC -> memoria -> UC del single-cycle y permite subir Fmax.
//
// Latencia: 1 ciclo. La UC compensa esta latencia haciendo que
// el WB de la instruccion previa actualice memprog.a = pc_next,
// de modo que en el siguiente S_IF rd ya contiene mem[pc].
//
// El estado S_INIT (1 ciclo al salir de reset) cubre el caso del
// primer fetch.
// ============================================================

module memprog #(parameter MEM_FILE = "C:\\Users\\acoid\\Documents\\Actividad-2-DDP-Multiciclo\\src\\progfile.dat")
              (input  wire        clk,
               input  wire [9:0]  a,
               output reg  [31:0] rd);

  reg [31:0] mem[0:1023]; //memoria de 1024 palabras de 32 bits de ancho

  initial
  begin
    $readmemb(MEM_FILE, mem); // inicializa la memoria del fichero en texto binario
  end

  always @(posedge clk) rd <= mem[a];

endmodule


