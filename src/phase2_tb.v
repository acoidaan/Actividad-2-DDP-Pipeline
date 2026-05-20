// ============================================================
// Testbench Fase 2 multiciclo
// Verifica ALU (reg-reg + reg-imm) + control basico usando
// tests/test.asm/test.mem
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

defparam uut.CD.MP.MEM_FILE   = "../tests/test.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

// Helper para leer cualquier registro
wire [15:0] r1  = uut.CD.RF0.regb[1];
wire [15:0] r2  = uut.CD.RF0.regb[2];
wire [15:0] r3  = uut.CD.RF0.regb[3];
wire [15:0] r4  = uut.CD.RF0.regb[4];
wire [15:0] r5  = uut.CD.RF0.regb[5];
wire [15:0] r6  = uut.CD.RF0.regb[6];
wire [15:0] r7  = uut.CD.RF0.regb[7];
wire [15:0] r8  = uut.CD.RF0.regb[8];
wire [15:0] r9  = uut.CD.RF0.regb[9];
wire [15:0] r10 = uut.CD.RF0.regb[10];
wire [15:0] r11 = uut.CD.RF0.regb[11];
wire [15:0] r12 = uut.CD.RF0.regb[12];
wire [15:0] r13 = uut.CD.RF0.regb[13];
wire [15:0] r14 = uut.CD.RF0.regb[14];
wire [15:0] r15 = uut.CD.RF0.regb[15];

reg fail;

initial begin
    $dumpfile("phase2.vcd");
    $dumpvars(0, phase2_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;

    // 18 instrucciones * 4 ciclos (3-cycle simples, 4-cycle ALU)
    // ~72 ciclos + margen
    #(200 * 20);

    $display("=== Resultado Fase 2 ===");
    $display("r1=%0d (esp 10)", r1);  if (r1!=16'd10) fail=1;
    $display("r2=%0d (esp 3)",  r2);  if (r2!=16'd3)  fail=1;
    $display("r3=%0d (esp 17)", r3);  if (r3!=16'd17) fail=1;
    $display("r4=%0d (esp 10)", r4);  if (r4!=16'd10) fail=1;
    $display("r5=%0d (esp 6)",  r5);  if (r5!=16'd6)  fail=1;
    $display("r6=%0d (esp 0)",  r6);  if (r6!=16'd0)  fail=1;
    $display("r7=%0d (esp 2)",  r7);  if (r7!=16'd2)  fail=1;
    $display("r8=%0d (esp 10)", r8);  if (r8!=16'd10) fail=1;
    $display("r9=%0d (esp 15)", r9);  if (r9!=16'd15) fail=1;
    $display("r10=%0d (esp 15)",r10); if (r10!=16'd15)fail=1;
    $display("r11=%0d (esp 13)",r11); if (r11!=16'd13)fail=1;
    $display("r12=%0d (esp 7)", r12); if (r12!=16'd7) fail=1;
    $display("r13=%0d (esp 2)", r13); if (r13!=16'd2) fail=1;
    $display("r14=%0d (esp 11)",r14); if (r14!=16'd11)fail=1;
    $display("r15=%0d (esp 10)",r15); if (r15!=16'd10)fail=1;

    if (!fail) $display("FASE 2: PASS");
    else       $display("FASE 2: FAIL");

    $finish;
end

initial begin
    #(50000);
    $display("TIMEOUT");
    $finish;
end

endmodule
