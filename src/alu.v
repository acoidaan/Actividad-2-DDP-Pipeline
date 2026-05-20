module alu(input wire [15:0] a, b,
           input wire [2:0] op_alu,
           output wire [15:0] y,
           output wire zero);

reg [15:0] s;		   
		   
always @(a, b, op_alu)
begin
  case (op_alu)
  /*
  * - 0: Deja igual el operando a
  * - 1: Invierta los bits del operando a
  * - 2: Suma a + b
  * - 3: Resta a - b
  * - 4: Bitwise AND entre a y b
  * - 5: Bitwise OR entre a y b
  * - 6: Convierte a en -a
  * - 7: Convierte b en -b
  */              
    3'b000: s = a;
    3'b001: s = ~a;
    3'b010: s = a + b;
    3'b011: s = a - b;
    3'b100: s = a & b;
    3'b101: s = a | b;
    3'b110: s = -a;
    3'b111: s = -b;
	default: s = 16'b0; //desconocido en cualquier otro caso (x o z), por si se modifica el código
  endcase
end

assign y = s;

//Calculo del flag de cero
assign zero = ~(|y);   //operador de reducción |y hace la or de los bits del vector 'y' y devuelve 1 bit resultado
		   
endmodule
