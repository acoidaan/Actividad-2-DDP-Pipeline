// ============================================================
// Test Fase 4 simple: saltos + flush
// ============================================================
`timescale 1 ns / 10 ps

module phase4_simple_tb;

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

defparam uut.CD.MP.MEM_FILE   = "../tests/test_phase4_pipe.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

wire [15:0] r1 = uut.CD.RF0.regb[1];
wire [15:0] r2 = uut.CD.RF0.regb[2];
wire [15:0] r3 = uut.CD.RF0.regb[3];
wire [15:0] r4 = uut.CD.RF0.regb[4];
wire [15:0] r5 = uut.CD.RF0.regb[5];

reg fail;

initial begin
    $dumpfile("phase4_simple.vcd");
    $dumpvars(0, phase4_simple_tb);

    irq_in = 0; reset = 1; fail = 0;
    #25; reset = 0;
    #(200 * 20);

    $display("=== Fase 4 (saltos + flush) ===");
    $display("PC = %0d", pc);
    $display("r1 = %0d  (esp 10)",  r1);  if (r1 !== 16'd10) fail=1;
    $display("r2 = %0d  (esp 20)",  r2);  if (r2 !== 16'd20) fail=1;
    $display("r3 = %0d  (esp 0)",   r3);  if (r3 !== 16'd0)  fail=1;
    $display("r4 = %0d  (esp 40)",  r4);  if (r4 !== 16'd40) fail=1;
    $display("r5 = %0d  (esp 0)",   r5);  if (r5 !== 16'd0)  fail=1;
    if (!fail) $display("FASE 4 SIMPLE: PASS");
    else       $display("FASE 4 SIMPLE: FAIL");
    $finish;
end

initial begin #(50000); $finish; end

endmodule
