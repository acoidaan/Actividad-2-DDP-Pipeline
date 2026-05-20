// ============================================================
// Testbench Fase 1 pipeline
// Verifica el datapath basico (5 etapas) usando test_phase1_pipe
// que tiene NOPs intercalados para evitar hazards.
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

defparam uut.CD.MP.MEM_FILE   = "../tests/test_phase1_pipe.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

wire [15:0] r1 = uut.CD.RF0.regb[1];
wire [15:0] r2 = uut.CD.RF0.regb[2];
wire [15:0] r3 = uut.CD.RF0.regb[3];
wire [15:0] r4 = uut.CD.RF0.regb[4];
wire [15:0] r5 = uut.CD.RF0.regb[5];
wire [15:0] r6 = uut.CD.RF0.regb[6];
wire [15:0] r7 = uut.CD.RF0.regb[7];

reg fail;

initial begin
    $dumpfile("phase1.vcd");
    $dumpvars(0, phase1_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;

    #(200 * 20);

    $display("=== Resultado Fase 1 Pipeline ===");
    $display("PC = %0d", pc);
    $display("r1 = %0d  (esperado 10)", r1);  if (r1 !== 16'd10) fail=1;
    $display("r2 = %0d  (esperado 20)", r2);  if (r2 !== 16'd20) fail=1;
    $display("r3 = %0d  (esperado 25)", r3);  if (r3 !== 16'd25) fail=1;
    $display("r4 = %0d  (esperado 30)", r4);  if (r4 !== 16'd30) fail=1;
    $display("r5 = %0d  (esperado 55)", r5);  if (r5 !== 16'd55) fail=1;
    $display("r6 = %0d  (esperado 15)", r6);  if (r6 !== 16'd15) fail=1;
    $display("r7 = %0d  (esperado 4)",  r7);  if (r7 !== 16'd4)  fail=1;

    if (!fail) $display("FASE 1 PIPELINE: PASS");
    else       $display("FASE 1 PIPELINE: FAIL");
    $finish;
end

initial begin
    #(50000);
    $display("TIMEOUT");
    $finish;
end

endmodule
