// ============================================================
// Camino de datos PIPELINE de 5 etapas
//
//   IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
//
// Cada etapa avanza en cada flanco de reloj (sin stalls en Fase 1).
// La UC es combinacional sobre el opcode de IF/ID y produce las
// senales de control que viajan por los stage registers hasta su
// etapa de consumo.
//
// FASE 1: NO hay forwarding, NO hay stalls, NO hay flush. Solo el
// datapath limpio. Los programas de test deben separar instrucciones
// con dependencias por al menos 3 NOPs para evitar hazards RAW.
// ============================================================

module cd(
    input  wire        clk, reset,

    // Salidas a top-level
    output wire [9:0]  pc_out,
    input  wire [15:0] bus_data_in,
    output wire [15:0] bus_data_out,
    output wire [15:0] bus_direccion,
    output wire [1:0]  bus_control,

    // Interrupciones
    input  wire        irq_in,
    output wire        irq_ack
);

// ============================================================
// ETAPA IF: fetch de instruccion
// ============================================================
reg  [9:0]  pc;
wire [9:0]  pc_inc;
wire [9:0]  pc_next;
wire [31:0] instr;

sum SUM_PC (pc, 10'd1, pc_inc);

// memprog: lectura sincrona (M4K). Direccion = pc_next para que en
// el flanco siguiente IR ya tenga la instruccion correcta.
memprog MP (clk, pc_next, instr);

// PC: por defecto incrementa, pero los saltos lo sobreescriben.
// Detallaremos pc_next mas abajo despues de instanciar la unidad de
// resolucion de saltos en EX.

// ============================================================
// REGISTRO IF/ID
// ============================================================
reg [31:0] IF_ID_IR;
reg [9:0]  IF_ID_PC;  // PC+1 de la instruccion (direccion de retorno
                      // para CALL)

always @(posedge clk or posedge reset) begin
    if (reset) begin
        IF_ID_IR <= 32'b0;
        IF_ID_PC <= 10'b0;
    end else begin
        IF_ID_IR <= instr;
        IF_ID_PC <= pc_inc;
    end
end

// ============================================================
// ETAPA ID: decode + lectura de registros
// ============================================================
wire [5:0]  id_opcode    = IF_ID_IR[31:26];
wire [3:0]  id_wa3       = IF_ID_IR[25:22];
wire [3:0]  id_ra1       = IF_ID_IR[21:18];
wire [3:0]  id_ra2       = IF_ID_IR[17:14];
wire [15:0] id_imm16     = IF_ID_IR[17:2];
wire [15:0] id_desp_ext  = {6'b0, IF_ID_IR[11:2]};
wire [9:0]  id_jump_addr = IF_ID_IR[9:0];

// Decodificacion combinacional
wire [1:0]  id_s_alu_imm;
wire [2:0]  id_op_alu;
wire        id_wez;
wire        id_Branch;
wire [1:0]  id_BranchType;
wire        id_Call, id_Ret, id_Reti;
wire        id_MemRead, id_MemWrite;
wire        id_RegWrite;
wire [1:0]  id_s_wd3;
wire [1:0]  id_s_int;

uc UC (
    .opcode(id_opcode),
    .s_alu_imm(id_s_alu_imm), .op_alu(id_op_alu), .wez(id_wez),
    .Branch(id_Branch), .BranchType(id_BranchType),
    .Call(id_Call), .Ret(id_Ret), .Reti(id_Reti),
    .MemRead(id_MemRead), .MemWrite(id_MemWrite),
    .RegWrite(id_RegWrite), .s_wd3(id_s_wd3),
    .s_int(id_s_int)
);

// Banco de registros (lectura combinacional en ID, escritura en WB)
wire [15:0] rd1, rd2;
wire [3:0]  wb_wa3;
wire [15:0] wb_wd3;
wire        wb_RegWrite;

regfile RF0 (
    .clk(clk),
    .RegWrite(wb_RegWrite),
    .ra1(id_ra1), .ra2(id_ra2), .wa3(wb_wa3),
    .wd3(wb_wd3),
    .rd1(rd1), .rd2(rd2)
);

// ============================================================
// REGISTRO ID/EX
// ============================================================
reg [15:0] ID_EX_A, ID_EX_B;
reg [15:0] ID_EX_imm16, ID_EX_desp_ext;
reg [3:0]  ID_EX_wa3, ID_EX_ra1, ID_EX_ra2;
reg [5:0]  ID_EX_opcode;
reg [9:0]  ID_EX_PC;
reg [9:0]  ID_EX_jump_addr;
// Control EX
reg [2:0]  ID_EX_op_alu;
reg [1:0]  ID_EX_s_alu_imm;
reg        ID_EX_wez;
reg        ID_EX_Branch;
reg [1:0]  ID_EX_BranchType;
reg        ID_EX_Call, ID_EX_Ret, ID_EX_Reti;
// Control MEM
reg        ID_EX_MemRead, ID_EX_MemWrite;
// Control WB
reg        ID_EX_RegWrite;
reg [1:0]  ID_EX_s_wd3;
// Interrupciones
reg [1:0]  ID_EX_s_int;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ID_EX_A           <= 16'b0;
        ID_EX_B           <= 16'b0;
        ID_EX_imm16       <= 16'b0;
        ID_EX_desp_ext    <= 16'b0;
        ID_EX_wa3         <= 4'b0;
        ID_EX_ra1         <= 4'b0;
        ID_EX_ra2         <= 4'b0;
        ID_EX_opcode      <= 6'b001111;   // NOP
        ID_EX_PC          <= 10'b0;
        ID_EX_jump_addr   <= 10'b0;
        ID_EX_op_alu      <= 3'b0;
        ID_EX_s_alu_imm   <= 2'b0;
        ID_EX_wez         <= 1'b0;
        ID_EX_Branch      <= 1'b0;
        ID_EX_BranchType  <= 2'b0;
        ID_EX_Call        <= 1'b0;
        ID_EX_Ret         <= 1'b0;
        ID_EX_Reti        <= 1'b0;
        ID_EX_MemRead     <= 1'b0;
        ID_EX_MemWrite    <= 1'b0;
        ID_EX_RegWrite    <= 1'b0;
        ID_EX_s_wd3       <= 2'b0;
        ID_EX_s_int       <= 2'b0;
    end else begin
        ID_EX_A           <= rd1;
        ID_EX_B           <= rd2;
        ID_EX_imm16       <= id_imm16;
        ID_EX_desp_ext    <= id_desp_ext;
        ID_EX_wa3         <= id_wa3;
        ID_EX_ra1         <= id_ra1;
        ID_EX_ra2         <= id_ra2;
        ID_EX_opcode      <= id_opcode;
        ID_EX_PC          <= IF_ID_PC;
        ID_EX_jump_addr   <= id_jump_addr;
        ID_EX_op_alu      <= id_op_alu;
        ID_EX_s_alu_imm   <= id_s_alu_imm;
        ID_EX_wez         <= id_wez;
        ID_EX_Branch      <= id_Branch;
        ID_EX_BranchType  <= id_BranchType;
        ID_EX_Call        <= id_Call;
        ID_EX_Ret         <= id_Ret;
        ID_EX_Reti        <= id_Reti;
        ID_EX_MemRead     <= id_MemRead;
        ID_EX_MemWrite    <= id_MemWrite;
        ID_EX_RegWrite    <= id_RegWrite;
        ID_EX_s_wd3       <= id_s_wd3;
        ID_EX_s_int       <= id_s_int;
    end
end

// ============================================================
// ETAPA EX: forwarding + ALU + decision de salto
// ============================================================

// --- Logica de forwarding (FASE 2) ---
// Prioridad: EX/MEM (mas reciente) > MEM/WB > stage register.
// NOTA: para LOAD (EX_MEM_MemRead=1) el dato aun no esta en
// EX_MEM_WBData (solo la direccion en ALUOut). Por eso este
// forwarding NO cubre LOAD-use, que se trata con stall en Fase 3.
wire [1:0] forwardA =
    (EX_MEM_RegWrite && (EX_MEM_wa3 != 4'b0) && (EX_MEM_wa3 == ID_EX_ra1) && !EX_MEM_MemRead) ? 2'b10 :
    (MEM_WB_RegWrite && (MEM_WB_wa3 != 4'b0) && (MEM_WB_wa3 == ID_EX_ra1))                    ? 2'b01 :
    2'b00;

wire [1:0] forwardB =
    (EX_MEM_RegWrite && (EX_MEM_wa3 != 4'b0) && (EX_MEM_wa3 == ID_EX_ra2) && !EX_MEM_MemRead) ? 2'b10 :
    (MEM_WB_RegWrite && (MEM_WB_wa3 != 4'b0) && (MEM_WB_wa3 == ID_EX_ra2))                    ? 2'b01 :
    2'b00;

// Operandos A y B con forwarding aplicado
wire [15:0] ex_A_fwd =
    (forwardA == 2'b10) ? EX_MEM_WBData :
    (forwardA == 2'b01) ? wb_wd3        :
    ID_EX_A;

wire [15:0] ex_B_fwd =
    (forwardB == 2'b10) ? EX_MEM_WBData :
    (forwardB == 2'b01) ? wb_wd3        :
    ID_EX_B;

// Mux que selecciona la entrada B del ALU (B o imm16 o desp_ext)
wire [15:0] ex_alu_b;
wire [15:0] ex_alu_out;
wire        ex_zero;

mux4 #(16) MUX_ALU_B (
    ex_B_fwd, ID_EX_imm16, ID_EX_desp_ext, 16'b0,
    ID_EX_s_alu_imm,
    ex_alu_b
);

alu ALU0 (
    ex_A_fwd, ex_alu_b, ID_EX_op_alu,
    ex_alu_out, ex_zero
);

// Valor que esta instruccion escribira en RF (combinacional en EX):
//   * ALU/LOAD direccion: ex_alu_out
//   * LI:                 ID_EX_imm16
// Se latchea en EX_MEM_WBData para que las instrucciones
// posteriores puedan forwardear desde aqui.
wire [15:0] ex_wb_data =
    (ID_EX_s_wd3 == 2'b11) ? ID_EX_imm16 : ex_alu_out;

// Flag Z: ahora se escribe directamente desde EX (wez de la instr
// que acaba de ejecutar en la ALU). En las fases siguientes habra
// que tener cuidado con que las dependencias entre flag-setter y
// flag-reader se resuelvan en orden correcto.
wire flag_z;
ffd FZ (clk, reset, ex_zero, ID_EX_wez, flag_z);

// Decision de salto (combinacional en EX)
//   Branch + BranchType:
//     00 -> J   siempre tomado
//     01 -> JZ  tomado si flag_z=1
//     10 -> JNZ tomado si flag_z=0
wire ex_BranchTaken =
    ID_EX_Branch && (
        (ID_EX_BranchType == 2'b00) ||
        (ID_EX_BranchType == 2'b01 && flag_z) ||
        (ID_EX_BranchType == 2'b10 && !flag_z)
    );

// Saltos que cambian PC: J/JZ tomado/JNZ tomado/CALL/RET/RETI
wire ex_PCChange = ex_BranchTaken || ID_EX_Call || ID_EX_Ret || ID_EX_Reti;

// ============================================================
// PILA (manejo de CALL / RET / RETI)
// ============================================================
// PUSH cuando hay CALL en EX (push PC+1 de la instruccion CALL, que
// era IF_ID_PC en su momento, ahora esta en ID_EX_PC).
// POP cuando hay RET o RETI en EX.
wire [1:0]  s_bat;
assign s_bat = ID_EX_Call ? 2'b01 :
               (ID_EX_Ret || ID_EX_Reti) ? 2'b10 :
               2'b00;
wire [9:0] stack_top;
stack PILA (clk, reset, s_bat, ID_EX_PC, stack_top);

// ============================================================
// Direccion de salto: jump_addr de instr o stack_top para RET
// ============================================================
wire [9:0] ex_jump_target =
    (ID_EX_Ret || ID_EX_Reti) ? stack_top : ID_EX_jump_addr;

// ============================================================
// Actualizacion de PC (en IF)
//   Por defecto: PC <= pc_inc (PC+1).
//   Si hay salto en EX: PC <= ex_jump_target.
// ============================================================
assign pc_next = ex_PCChange ? ex_jump_target : pc_inc;

always @(posedge clk or posedge reset) begin
    if (reset) pc <= 10'b0;
    else       pc <= pc_next;
end

// ============================================================
// REGISTRO EX/MEM
// ============================================================
reg [15:0] EX_MEM_ALUOut;
reg [15:0] EX_MEM_B;          // dato a STORE (ya con forwarding)
reg [15:0] EX_MEM_imm16;      // para LI write-back
reg [15:0] EX_MEM_WBData;     // dato que escribira RF (para forwarding)
reg [3:0]  EX_MEM_wa3;
reg [5:0]  EX_MEM_opcode;
reg        EX_MEM_MemRead, EX_MEM_MemWrite;
reg        EX_MEM_RegWrite;
reg [1:0]  EX_MEM_s_wd3;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        EX_MEM_ALUOut   <= 16'b0;
        EX_MEM_B        <= 16'b0;
        EX_MEM_imm16    <= 16'b0;
        EX_MEM_WBData   <= 16'b0;
        EX_MEM_wa3      <= 4'b0;
        EX_MEM_opcode   <= 6'b001111;
        EX_MEM_MemRead  <= 1'b0;
        EX_MEM_MemWrite <= 1'b0;
        EX_MEM_RegWrite <= 1'b0;
        EX_MEM_s_wd3    <= 2'b0;
    end else begin
        EX_MEM_ALUOut   <= ex_alu_out;
        EX_MEM_B        <= ex_B_fwd;      // STORE usa B con forwarding
        EX_MEM_imm16    <= ID_EX_imm16;
        EX_MEM_WBData   <= ex_wb_data;
        EX_MEM_wa3      <= ID_EX_wa3;
        EX_MEM_opcode   <= ID_EX_opcode;
        EX_MEM_MemRead  <= ID_EX_MemRead;
        EX_MEM_MemWrite <= ID_EX_MemWrite;
        EX_MEM_RegWrite <= ID_EX_RegWrite;
        EX_MEM_s_wd3    <= ID_EX_s_wd3;
    end
end

// ============================================================
// ETAPA MEM: acceso a memoria de datos / perifericos
// ============================================================
assign bus_direccion = EX_MEM_ALUOut;
assign bus_control   = EX_MEM_MemRead  ? 2'b01 :
                       EX_MEM_MemWrite ? 2'b10 :
                       2'b00;
// El bus de datos se conduce con EX_MEM_B en STORE (lo gestiona
// cpu_ampliada via la senal mem_drive_bus)
assign bus_data_out  = EX_MEM_B;

// ============================================================
// REGISTRO MEM/WB
// ============================================================
reg [15:0] MEM_WB_ALUOut;
reg [15:0] MEM_WB_MDR;
reg [15:0] MEM_WB_imm16;
reg [3:0]  MEM_WB_wa3;
reg        MEM_WB_RegWrite;
reg [1:0]  MEM_WB_s_wd3;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        MEM_WB_ALUOut   <= 16'b0;
        MEM_WB_MDR      <= 16'b0;
        MEM_WB_imm16    <= 16'b0;
        MEM_WB_wa3      <= 4'b0;
        MEM_WB_RegWrite <= 1'b0;
        MEM_WB_s_wd3    <= 2'b0;
    end else begin
        MEM_WB_ALUOut   <= EX_MEM_ALUOut;
        MEM_WB_MDR      <= bus_data_in;
        MEM_WB_imm16    <= EX_MEM_imm16;
        MEM_WB_wa3      <= EX_MEM_wa3;
        MEM_WB_RegWrite <= EX_MEM_RegWrite;
        MEM_WB_s_wd3    <= EX_MEM_s_wd3;
    end
end

// ============================================================
// ETAPA WB: write-back al banco de registros
// ============================================================
mux4 #(16) MUX_WD3 (
    MEM_WB_ALUOut, MEM_WB_MDR, 16'b0, MEM_WB_imm16,
    MEM_WB_s_wd3,
    wb_wd3
);

assign wb_wa3      = MEM_WB_wa3;
assign wb_RegWrite = MEM_WB_RegWrite;

// ============================================================
// Flag IE (placeholder - interrupciones en fase 5)
// ============================================================
wire ie_load;
assign ie_load = ID_EX_s_int[0] | ID_EX_s_int[1];
wire ie_out;
ffd FIE (clk, reset, ID_EX_s_int[0], ie_load, ie_out);

assign irq_ack = 1'b0;     // todavia no implementado

// ============================================================
// Salidas
// ============================================================
assign pc_out = pc;

endmodule
