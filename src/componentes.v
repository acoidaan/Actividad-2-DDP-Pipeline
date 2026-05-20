//Componentes varios

// Banco de registros para el pipeline.
// Lectura combinacional en ID, escritura sincrona en WB.
// Ya no necesita conducir el bus de datos para STORE: en pipeline el
// dato del STORE viaja por los stage registers ID/EX_B -> EX/MEM_B y
// el cd lo conduce al bus en MEM.
module regfile #(parameter INIT_FILE = "C:\\Users\\acoid\\Documents\\Actividad-2-DDP-Multiciclo\\src\\regfile.dat")
              (input  wire        clk,
               input  wire        RegWrite,
               input  wire [3:0]  ra1, ra2, wa3,
               input  wire [15:0] wd3,
               output wire [15:0] rd1, rd2);

  reg [15:0] regb[0:15];

  initial begin
    $readmemb(INIT_FILE, regb);
  end

  always @(posedge clk)
    if (RegWrite && (wa3 != 4'b0000)) regb[wa3] <= wd3;

  // Registro 0 siempre devuelve 0
  assign rd1 = (ra1 != 0) ? regb[ra1] : 16'b0;
  assign rd2 = (ra2 != 0) ? regb[ra2] : 16'b0;

endmodule

//modulo sumador
module sum(input  wire [9:0] a, b,
             output wire [9:0] y);

  assign y = a + b;

endmodule

//modulo registro para modelar el PC, cambia en cada flanco de subida de reloj o de reset
module registro #(parameter WIDTH = 8)
              (input wire             clk, reset,
               input wire [WIDTH-1:0] d,
               output reg [WIDTH-1:0] q);

  always @(posedge clk, posedge reset)
    if (reset) q <= {WIDTH{1'b0}};
    else       q <= d;

endmodule

// Registro con habilitacion de carga (en=1 carga d, en=0 mantiene)
module registro_en #(parameter WIDTH = 8)
                  (input wire             clk, reset, en,
                   input wire [WIDTH-1:0] d,
                   output reg [WIDTH-1:0] q);

  always @(posedge clk, posedge reset)
    if (reset)   q <= {WIDTH{1'b0}};
    else if (en) q <= d;

endmodule

//modulo multiplexor, si s=1 sale d1, s=0 sale d0
module mux2 #(parameter WIDTH = 8)
             (input  wire [WIDTH-1:0] d0, d1,
              input  wire             s,
              output wire [WIDTH-1:0] y);

  assign y = s ? d1 : d0;

endmodule


// modulo multiplexor de 4 entradas
// s = 00 -> sale d0
// s = 01 -> sale d1
// s = 10 -> sale d2
// s = 11 -> sale d3
module mux4 #(parameter WIDTH = 8)
             (input  wire [WIDTH-1:0] d0, d1, d2, d3,
              input  wire [1:0]       s,
              output wire [WIDTH-1:0] y);

  assign y = (s == 2'b00) ? d0 :
             (s == 2'b01) ? d1 :
             (s == 2'b10) ? d2 :
                            d3;

endmodule


//Biestable para el flag de cero
//Biestable tipo D síncrono con reset asíncrono por flanco y entrada de habilitación de carga
module ffd(input wire clk, reset, d, carga, output reg q);

  always @(posedge clk, posedge reset)
    if (reset)
	    q <= 1'b0;
	  else
	    if (carga)
	      q <= d;

endmodule


// =======================================================
// Pila (stack) para CALL / RET / RETI
// =======================================================
// s_bat:
//   00 -> NOP
//   01 -> PUSH (guardar pc+1)
//   10 -> POP  (sacar direccion)
//   11 -> no definido (NOP)
// =======================================================

module stack(
  input  wire        clk,
  input  wire        reset,
  input  wire [1:0]  s_bat,
  input  wire [9:0]  din,
  output wire [9:0]  dout
);

  reg [9:0] stack_mem [0:15];
  reg [3:0] sp;

  assign dout = (sp == 0) ? 10'b0 : stack_mem[sp - 1];

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sp <= 4'b0;
    end else begin
      case (s_bat)
        2'b01: begin   // PUSH
          stack_mem[sp] <= din;
          sp <= sp + 4'b1;
        end
        2'b10: begin   // POP
          if (sp != 0)
            sp <= sp - 4'b1;
        end
        default: ;
      endcase
    end
  end

endmodule
