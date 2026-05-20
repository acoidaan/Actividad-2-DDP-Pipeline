// ============================================================
// Camino de datos multiciclo
//
// Anade registros intermedios sobre la base single-cycle:
//   IR      (32b) : instruccion latcheada al final de IF
//   A, B    (16b) : RF[ra1], RF[ra2] latcheados al final de ID
//   ALUOut  (16b) : resultado de la ALU latcheado al final de EX
//   MDR     (16b) : dato leido del bus latcheado al final de MEM
//
// memprog sigue siendo asincrono en fase 1a (se pasara a BRAM
// sincrona en fase 1b).
// ============================================================

module cd(
    input  wire        clk, reset,

    // Senales de la UC
    input  wire        PCWrite,
    input  wire [1:0]  PCSrc,
    input  wire        IRWrite,
    input  wire [1:0]  s_we3,
    input  wire [1:0]  s_wd3,
    input  wire [1:0]  s_alu_imm,
    input  wire [2:0]  op_alu,
    input  wire        wez,
    input  wire        ALUOutWrite,
    input  wire        MDRWrite,
    input  wire        IorD,
    input  wire [1:0]  s_bat,
    input  wire [1:0]  s_int,
    input  wire        s_irq,

    // Estado arquitectonico expuesto a la UC
    output wire        z, ie_out,
    output wire [5:0]  opcode,

    // Salidas a top-level
    output wire [9:0]  pc_out,
    input  wire [15:0] bus_data_in,
    output wire [15:0] bus_data_out,
    output wire [15:0] bus_direccion
);

// ============================================================
// PC
// ============================================================
wire [9:0] pc;
wire [9:0] pc_inc;
wire [9:0] jump_addr;
wire [9:0] stack_top;
wire [9:0] pc_next;

sum SUM1 (pc, 10'd1, pc_inc);

// PC con habilitacion (PCWrite, solo asertado en S_WB)
registro_en #(10) PCREG (clk, reset, PCWrite, pc_next, pc);

// MUX_PC: 00=PC+1, 01=jump_addr, 10=stack_top, 11=0
mux4 #(10) MUX_PC (pc_inc, jump_addr, stack_top, 10'b0, PCSrc, pc_next);

// ============================================================
// Memoria de programa (lectura sincrona, latencia 1)
//
// Durante S_WB drive addr=pc_next (prefetch del siguiente fetch).
// Resto de estados: addr=pc (estable). Esto se logra usando
// PCWrite como selector ya que PCWrite=1 solo en S_WB.
// ============================================================
wire [9:0]  mp_addr = PCWrite ? pc_next : pc;
wire [31:0] instr;
memprog MP (clk, mp_addr, instr);

// ============================================================
// IR
// ============================================================
reg [31:0] IR;
always @(posedge clk or posedge reset) begin
    if (reset)        IR <= 32'b0;
    else if (IRWrite) IR <= instr;
end

assign opcode = IR[31:26];
wire [3:0]  wa3        = IR[25:22];
wire [3:0]  ra1        = IR[21:18];
wire [3:0]  ra2        = IR[17:14];
wire [15:0] imm16      = IR[17:2];
wire [15:0] desp_ext   = {6'b0, IR[11:2]};
wire [9:0]  instr_addr = IR[9:0];

// ============================================================
// Pila + IRQ (no usados en fase 1a, pero el cableado se mantiene)
// ============================================================
// Vector de IRQ
mux2 #(10) MUX_VECTOR (instr_addr, 10'h010, s_irq, jump_addr);

// En este multiciclo el PC se actualiza solo en S_WB. Durante S_WB
// pc aun vale la direccion de la instruccion actual; el siguiente
// PC (pc_inc) es la direccion de retorno para CALL. Para IRQ se
// pushea pc (la instruccion interrumpida).
wire [9:0] stack_din;
mux2 #(10) MUX_STACK_DIN (pc_inc, pc, s_irq, stack_din);
stack PILA (clk, reset, s_bat, stack_din, stack_top);

// ============================================================
// Banco de registros + registros A, B
// ============================================================
wire [15:0] rd1, rd2, wd3;
regfile RF0 (clk, s_we3, ra1, ra2, wa3, wd3, rd1, rd2, bus_data_out);

reg [15:0] A, B;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        A <= 16'b0;
        B <= 16'b0;
    end else begin
        // Carga incondicional cada ciclo. En S_ID quedan latcheados
        // los valores correctos para usar en S_EX/S_MEM.
        A <= rd1;
        B <= rd2;
    end
end

// ============================================================
// ALU + ALUOut
// ============================================================
wire [15:0] alu_b, alu_out;
wire zero_comb;

mux4 #(16) MUX_ALU_B (B, imm16, desp_ext, 16'b0, s_alu_imm, alu_b);
alu ALU0 (A, alu_b, op_alu, alu_out, zero_comb);

reg [15:0] ALUOut;
always @(posedge clk or posedge reset) begin
    if (reset)            ALUOut <= 16'b0;
    else if (ALUOutWrite) ALUOut <= alu_out;
end

// ============================================================
// Direccion al bus externo y MDR
// ============================================================
// IorD=0: el bus no se usa (IF). IorD=1: direccion = ALUOut (MEM).
// Se deja ALUOut siempre cableado; el control del bus se hace via
// bus_control desde la UC (00 = idle).
assign bus_direccion = ALUOut;

reg [15:0] MDR;
always @(posedge clk or posedge reset) begin
    if (reset)         MDR <= 16'b0;
    else if (MDRWrite) MDR <= bus_data_in;
end

// ============================================================
// MUX write-back: 00=ALUOut, 01=MDR (LOAD), 10=0, 11=imm16 (LI)
// ============================================================
mux4 #(16) MUX_WD3 (ALUOut, MDR, 16'b0, imm16, s_wd3, wd3);

// ============================================================
// Flags
// ============================================================
ffd FZ (clk, reset, zero_comb, wez, z);

wire ie_load = s_int[0] | s_int[1];
ffd FIE (clk, reset, s_int[0], ie_load, ie_out);

// ============================================================
// Salidas
// ============================================================
assign pc_out = pc;

endmodule
