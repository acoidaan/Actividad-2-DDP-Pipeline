// ============================================================
// Testbench Fase 1a multiciclo
// Verifica NOP, LI, J, JZ, JNZ ejecutando test_phase1.mem
// ============================================================
`timescale 1 ns / 10 ps

module phase1_tb;

reg         clk;
reg         reset;
reg         irq_in;
wire [9:0]  pc;
wire [15:0] bus_direccion;
wire [15:0] bus_data;
wire [1:0]  bus_control;
wire        irq_ack;

cpu_ampliada uut(
    .clk(clk), .reset(reset), .irq_in(irq_in),
    .pc_out(pc),
    .bus_direccion(bus_direccion),
    .bus_data(bus_data),
    .bus_control(bus_control),
    .irq_ack(irq_ack)
);

// Overrides para usar ficheros locales en simulacion
defparam uut.CD.MP.MEM_FILE  = "../tests/test_phase1.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

// Helper: leer registro arquitectonico (no expuesto)
wire [15:0] r1 = uut.CD.RF0.regb[1];
wire [15:0] r2 = uut.CD.RF0.regb[2];
wire [15:0] r3 = uut.CD.RF0.regb[3];
wire [15:0] r4 = uut.CD.RF0.regb[4];
wire [15:0] r5 = uut.CD.RF0.regb[5];
wire [15:0] r6 = uut.CD.RF0.regb[6];

// Estado del FSM
wire [2:0] state_dbg = uut.UC.state;
reg [31:0] cycles;

always @(posedge clk) cycles <= reset ? 32'b0 : cycles + 1;

initial begin
    $dumpfile("phase1.vcd");
    $dumpvars(0, phase1_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    cycles = 32'b0;
    #25;
    reset  = 1'b0;

    // Ejecutar suficientes ciclos para llegar a "fin" estable
    // 8 instrucciones ejecutadas * ~3 ciclos cada una = ~24 ciclos
    // mas margen
    #(50 * 20);

    $display("=== Resultado Fase 1a ===");
    $display("PC en muestra = %0d (esperado en bucle fin: {9,10,11})", pc);
    $display("r1 = %0d  (esperado 10)", r1);
    $display("r2 = %0d  (esperado 20)", r2);
    $display("r3 = %0d  (esperado 0)",  r3);
    $display("r4 = %0d  (esperado 30)", r4);
    $display("r5 = %0d  (esperado 40)", r5);
    $display("r6 = %0d  (esperado 0)",  r6);
    $display("Ciclos = %0d", cycles);

    if (r1 == 16'd10 && r2 == 16'd20 && r3 == 16'd0 &&
        r4 == 16'd30 && r5 == 16'd40 && r6 == 16'd0 &&
        (pc == 10'd9 || pc == 10'd10 || pc == 10'd11))
        $display("FASE 1a: PASS");
    else
        $display("FASE 1a: FAIL");

    $finish;
end

// Watchdog
initial begin
    #(10000);
    $display("TIMEOUT");
    $finish;
end

endmodule
