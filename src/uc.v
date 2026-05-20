// ============================================================
// Unidad de control multiciclo
// FSM: S_INIT -> S_IF -> S_ID -> S_EX -> S_MEM -> S_WB
//
// S_INIT existe solo para cebar memprog (lectura sincrona)
// el primer ciclo tras reset. Despues, el FSM circula entre
// S_IF y S_WB siempre.
//
// El prefetch al final de S_WB hace que memprog reciba pc_next
// como direccion durante WB, de modo que en el siguiente S_IF
// rd ya contenga mem[pc].
//
// FASE 1a/1b: solo NOP, LI, J, JZ, JNZ tienen comportamiento
// arquitectonico definido. Otros opcodes recorren la FSM como
// NOP (PCWrite=1, PCSrc=00 en WB) hasta fases 2-4.
// ============================================================

module uc(
    input  wire        clk, reset,
    input  wire [5:0]  opcode,
    input  wire        z, ie, irq_in,

    // PC
    output reg         PCWrite,
    output reg  [1:0]  PCSrc,          // 00=PC+1, 01=jump_addr, 10=stack_top

    // IR
    output reg         IRWrite,

    // RF / write-back
    output reg  [1:0]  s_we3,
    output reg  [1:0]  s_wd3,

    // ALU
    output reg  [1:0]  s_alu_imm,
    output reg  [2:0]  op_alu,
    output reg         wez,
    output reg         ALUOutWrite,

    // Memoria externa
    output reg  [1:0]  bus_control,
    output reg         MDRWrite,
    output reg         IorD,

    // Pila e interrupciones
    output reg  [1:0]  s_bat,
    output reg  [1:0]  s_int,
    output reg         s_irq,
    output reg         irq_ack,

    // Observabilidad
    output wire [2:0]  state_out
);

localparam S_INIT = 3'd0,
           S_IF   = 3'd1,
           S_ID   = 3'd2,
           S_EX   = 3'd3,
           S_MEM  = 3'd4,
           S_WB   = 3'd5,
           S_IRQ  = 3'd6;

reg [2:0] state, next_state;
assign state_out = state;

// --------------------------------------------------------
// Registro de estado
// --------------------------------------------------------
always @(posedge clk or posedge reset) begin
    if (reset) state <= S_INIT;
    else       state <= next_state;
end

// --------------------------------------------------------
// Logica de proximo estado
// --------------------------------------------------------
always @* begin
    case (state)
        S_INIT: next_state = S_IF;
        S_IF:   next_state = S_ID;

        S_ID: begin
            casez (opcode)
                6'b10????: next_state = S_EX;   // ALU
                6'b11????: next_state = S_EX;   // LOAD/STORE
                default:   next_state = S_WB;   // control + LI
            endcase
        end

        S_EX:  next_state = (opcode[5:4] == 2'b11) ? S_MEM : S_WB;
        S_MEM: next_state = S_WB;

        S_WB:  next_state = (ie_post_wb && irq_in) ? S_IRQ : S_IF;
        S_IRQ: next_state = S_IF;

        default: next_state = S_INIT;
    endcase
end

// Calcula la IE que tendra el sistema DESPUES de este WB. Asi
// detectamos la IRQ al final de un EI o RETI, no solo cuando el
// flag ya estaba a 1.
wire ie_post_wb =
    (opcode == 6'b000101) ? 1'b1 :   // EI
    (opcode == 6'b000110) ? 1'b0 :   // DI
    (opcode == 6'b000111) ? 1'b1 :   // RETI
    ie;

// --------------------------------------------------------
// Logica de salida
// --------------------------------------------------------
always @* begin
    PCWrite     = 1'b0;
    PCSrc       = 2'b00;
    IRWrite     = 1'b0;
    s_we3       = 2'b00;
    s_wd3       = 2'b00;
    s_alu_imm   = 2'b00;
    op_alu      = 3'b000;
    wez         = 1'b0;
    ALUOutWrite = 1'b0;
    bus_control = 2'b00;
    MDRWrite    = 1'b0;
    IorD        = 1'b0;
    s_bat       = 2'b00;
    s_int       = 2'b00;
    s_irq       = 1'b0;
    irq_ack     = 1'b0;

    case (state)
        S_INIT: begin
            // Cycle de cebado: memprog recibe addr=pc=0, latcheara
            // mem[0] en su registro de salida.
        end

        S_IF: begin
            // rd_reg de memprog ya tiene mem[pc]. Latch en IR.
            IRWrite = 1'b1;
        end

        S_ID: begin
            // A, B se cargan incondicionalmente en cd.
        end

        S_EX: begin
            casez (opcode)
                // --- ALU: op_alu = opcode[3:1], imm/reg = opcode[0] ---
                6'b10????: begin
                    s_alu_imm   = {1'b0, opcode[0]};  // 00=B, 01=imm16
                    op_alu      = opcode[3:1];
                    wez         = 1'b1;               // capturar Z
                    ALUOutWrite = 1'b1;
                end

                // --- LOAD/STORE: calculo de direccion efectiva (fase 3) ---
                6'b11????: begin
                    s_alu_imm   = 2'b10;              // desp_ext
                    op_alu      = 3'b010;             // ADD
                    ALUOutWrite = 1'b1;
                end

                default: ;
            endcase
        end

        S_MEM: begin
            IorD = 1'b1;     // bus_direccion = ALUOut
            casez (opcode)
                // --- LOAD: leer bus_data en MDR ---
                6'b11??01: begin
                    bus_control = 2'b01;
                    MDRWrite    = 1'b1;
                end
                // --- STORE: el banco drive bus_data con regb[wa3] ---
                6'b11??10: begin
                    bus_control = 2'b10;
                    s_we3       = 2'b10;
                end
                default: ;
            endcase
        end

        S_WB: begin
            // Por defecto: avanzar PC y prefetcher mem[pc+1]
            PCWrite = 1'b1;
            PCSrc   = 2'b00;

            casez (opcode)
                // --- J ---
                6'b000000: begin
                    PCSrc = 2'b01;
                end

                // --- JZ ---
                6'b000001: begin
                    if (z) PCSrc = 2'b01;
                end

                // --- JNZ ---
                6'b000010: begin
                    if (!z) PCSrc = 2'b01;
                end

                // --- LI ---
                6'b01????: begin
                    s_we3 = 2'b01;
                    s_wd3 = 2'b11;       // imm16
                end

                // --- ALU (reg-reg y reg-imm) ---
                6'b10????: begin
                    s_we3 = 2'b01;
                    s_wd3 = 2'b00;       // ALUOut
                end

                // --- LOAD ---
                6'b11??01: begin
                    s_we3 = 2'b01;
                    s_wd3 = 2'b01;       // MDR
                end

                // --- STORE: nada que escribir en RF (PC avanza por defecto) ---
                6'b11??10: ;

                // --- CALL ---
                6'b000011: begin
                    PCSrc = 2'b01;       // jump_addr
                    s_bat = 2'b01;       // PUSH pc_inc (direccion de retorno)
                end

                // --- RET ---
                6'b000100: begin
                    PCSrc = 2'b10;       // stack_top
                    s_bat = 2'b10;       // POP
                end

                // --- EI ---
                6'b000101: begin
                    s_int = 2'b01;       // IE <= 1
                end

                // --- DI ---
                6'b000110: begin
                    s_int = 2'b10;       // IE <= 0
                end

                // --- RETI ---
                6'b000111: begin
                    PCSrc = 2'b10;       // stack_top
                    s_bat = 2'b10;       // POP
                    s_int = 2'b01;       // IE <= 1
                end

                // NOP y resto: solo avance lineal (PCWrite=1, PCSrc=00)
                default: ;
            endcase
        end

        // Atencion de IRQ: ocurre justo despues de un WB que dejaba
        // IE=1 con irq_in activo. Push del PC interrumpido, salto al
        // vector 0x010, DI automatico, ack al periferico.
        S_IRQ: begin
            s_irq    = 1'b1;             // MUX_VECTOR -> 0x010
                                         // MUX_STACK_DIN -> pc (la
                                         // instruccion que se iba a
                                         // ejecutar)
            PCWrite  = 1'b1;
            PCSrc    = 2'b01;            // pc <= jump_addr = vector
            s_bat    = 2'b01;            // PUSH pc
            s_int    = 2'b10;            // DI automatico
            irq_ack  = 1'b1;
        end

        default: ;
    endcase
end

endmodule
