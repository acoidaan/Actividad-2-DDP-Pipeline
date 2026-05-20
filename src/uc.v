// ============================================================
// Unidad de control PIPELINE
//
// A diferencia del multiciclo, ya no hay FSM con estados. La UC
// es un decodificador combinacional puro: a partir del opcode de
// la instruccion en ID, genera todas las senales de control que
// luego se propagan por los stage registers ID/EX, EX/MEM, MEM/WB
// hasta donde cada senal se consume.
//
// Senales y cuando se consumen:
//   EX:  s_alu_imm, op_alu, wez, Branch, Call, Ret
//   MEM: MemRead, MemWrite
//   WB:  RegWrite, s_wd3
// ============================================================

module uc(
    input  wire [5:0]  opcode,

    // --- Control para EX ---
    output reg  [1:0]  s_alu_imm,      // 00=B, 01=imm16, 10=desp_ext
    output reg  [2:0]  op_alu,
    output reg         wez,            // capturar flag Z en EX
    output reg         Branch,         // J / JZ / JNZ
    output reg  [1:0]  BranchType,     // 00=J(siempre), 01=JZ, 10=JNZ
    output reg         Call,           // CALL: tomado siempre + PUSH
    output reg         Ret,            // RET: PC <= stack_top + POP
    output reg         Reti,           // RETI: como RET pero rehabilita IE

    // --- Control para MEM ---
    output reg         MemRead,        // LOAD
    output reg         MemWrite,       // STORE

    // --- Control para WB ---
    output reg         RegWrite,       // escribe en banco de registros
    output reg  [1:0]  s_wd3,          // 00=ALUOut, 01=MDR, 11=imm16

    // --- Interrupciones (intercambio con flag IE) ---
    output reg  [1:0]  s_int           // 00=NOP, 01=EI, 10=DI
);

always @* begin
    // Defaults: instruccion-NOP (no hace nada)
    s_alu_imm  = 2'b00;
    op_alu     = 3'b000;
    wez        = 1'b0;
    Branch     = 1'b0;
    BranchType = 2'b00;
    Call       = 1'b0;
    Ret        = 1'b0;
    Reti       = 1'b0;
    MemRead    = 1'b0;
    MemWrite   = 1'b0;
    RegWrite   = 1'b0;
    s_wd3      = 2'b00;
    s_int      = 2'b00;

    casez (opcode)
        // --- Saltos incondicionales ---
        6'b000000: begin                  // J
            Branch     = 1'b1;
            BranchType = 2'b00;
        end

        // --- Saltos condicionales ---
        6'b000001: begin                  // JZ
            Branch     = 1'b1;
            BranchType = 2'b01;
        end

        6'b000010: begin                  // JNZ
            Branch     = 1'b1;
            BranchType = 2'b10;
        end

        // --- Subrutinas ---
        6'b000011: begin                  // CALL
            Call = 1'b1;
        end

        6'b000100: begin                  // RET
            Ret = 1'b1;
        end

        // --- Interrupciones (control de flag IE) ---
        6'b000101: begin                  // EI
            s_int = 2'b01;
        end

        6'b000110: begin                  // DI
            s_int = 2'b10;
        end

        6'b000111: begin                  // RETI
            Reti  = 1'b1;
            s_int = 2'b01;
        end

        // --- LI ---
        6'b01????: begin
            RegWrite = 1'b1;
            s_wd3    = 2'b11;             // imm16
        end

        // --- ALU (reg-reg y reg-imm) ---
        6'b10????: begin
            s_alu_imm = {1'b0, opcode[0]}; // 00=reg, 01=imm
            op_alu    = opcode[3:1];
            wez       = 1'b1;
            RegWrite  = 1'b1;
            s_wd3     = 2'b00;             // ALUOut
        end

        // --- LOAD ---
        6'b11??01: begin
            s_alu_imm = 2'b10;             // desp_ext
            op_alu    = 3'b010;            // ADD
            MemRead   = 1'b1;
            RegWrite  = 1'b1;
            s_wd3     = 2'b01;             // MDR
        end

        // --- STORE ---
        6'b11??10: begin
            s_alu_imm = 2'b10;             // desp_ext
            op_alu    = 3'b010;            // ADD
            MemWrite  = 1'b1;
        end

        // NOP (001111) y resto: defaults (todo desactivado)
        default: ;
    endcase
end

endmodule
