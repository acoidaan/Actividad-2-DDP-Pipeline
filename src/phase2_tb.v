// ============================================================
// Testbench Fase 2 pipeline: forwarding
// Verifica que el forwarding EX/MEM->EX y MEM/WB->EX resuelve
// los hazards RAW sin necesidad de NOPs entre instrucciones.
// ============================================================
`timescale 1 ns / 10 ps

module phase2_tb;

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

defparam uut.CD.MP.MEM_FILE   = "../tests/test_phase2_pipe.mem";
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
    $dumpfile("phase2.vcd");
    $dumpvars(0, phase2_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;

    #(100 * 20);

    $display("=== Resultado Fase 2 Pipeline (forwarding) ===");
    $display("PC = %0d", pc);
    $display("r1 = %0d  (esperado 5)",  r1);  if (r1 !== 16'd5)  fail=1;
    $display("r2 = %0d  (esperado 10)", r2);  if (r2 !== 16'd10) fail=1;
    $display("r3 = %0d  (esperado 15)", r3);  if (r3 !== 16'd15) fail=1;
    $display("r4 = %0d  (esperado 30)", r4);  if (r4 !== 16'd30) fail=1;
    $display("r5 = %0d  (esperado 45)", r5);  if (r5 !== 16'd45) fail=1;
    $display("r6 = %0d  (esperado 2)",  r6);  if (r6 !== 16'd2)  fail=1;
    $display("r7 = %0d  (esperado 26)", r7);  if (r7 !== 16'd26) fail=1;

    if (!fail) $display("FASE 2 PIPELINE: PASS");
    else       $display("FASE 2 PIPELINE: FAIL");
    $finish;
end

initial begin
    #(50000);
    $display("TIMEOUT");
    $finish;
end

endmodule
