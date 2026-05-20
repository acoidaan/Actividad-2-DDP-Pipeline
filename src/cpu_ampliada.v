// ============================================================
// CPU multiciclo - top de la CPU
//
// Instancia la unidad de control (FSM de 5 estados) y el camino
// de datos con registros intermedios IR/A/B/ALUOut/MDR.
// ============================================================

module cpu_ampliada(input wire clk, reset, irq_in,
                    output wire [9:0] pc_out,
                    output wire [15:0] bus_direccion,
                    inout wire [15:0] bus_data,
                    output wire [1:0] bus_control,
                    output wire irq_ack);

// --- Senales internas UC <-> CD ---
wire        PCWrite, IRWrite, ALUOutWrite, MDRWrite, IorD, wez, s_irq;
wire [1:0]  PCSrc;
wire [1:0]  s_we3, s_wd3, s_alu_imm, s_bat, s_int;
wire [2:0]  op_alu;
wire [2:0]  state_dbg;

wire        z, ie;
wire [5:0]  opcode;

// --- Bus tri-state externo ---
wire [15:0] bus_data_in, bus_data_out;
assign bus_data_in = bus_data;
assign bus_data    = (s_we3 == 2'b10) ? bus_data_out : 16'bz;

// --- Unidad de control ---
uc UC (
    .clk(clk), .reset(reset),
    .opcode(opcode),
    .z(z), .ie(ie), .irq_in(irq_in),
    .PCWrite(PCWrite), .PCSrc(PCSrc),
    .IRWrite(IRWrite),
    .s_we3(s_we3), .s_wd3(s_wd3),
    .s_alu_imm(s_alu_imm), .op_alu(op_alu), .wez(wez), .ALUOutWrite(ALUOutWrite),
    .bus_control(bus_control), .MDRWrite(MDRWrite), .IorD(IorD),
    .s_bat(s_bat), .s_int(s_int), .s_irq(s_irq), .irq_ack(irq_ack),
    .state_out(state_dbg)
);

// --- Camino de datos ---
cd CD (
    .clk(clk), .reset(reset),
    .PCWrite(PCWrite), .PCSrc(PCSrc),
    .IRWrite(IRWrite),
    .s_we3(s_we3), .s_wd3(s_wd3),
    .s_alu_imm(s_alu_imm), .op_alu(op_alu), .wez(wez), .ALUOutWrite(ALUOutWrite),
    .MDRWrite(MDRWrite), .IorD(IorD),
    .s_bat(s_bat), .s_int(s_int), .s_irq(s_irq),
    .z(z), .ie_out(ie),
    .opcode(opcode),
    .pc_out(pc_out),
    .bus_data_in(bus_data_in), .bus_data_out(bus_data_out),
    .bus_direccion(bus_direccion)
);

endmodule
