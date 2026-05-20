// ============================================================
// Testbench Fase 3 pipeline: LOAD/STORE + stall LOAD-use
//
// Conecta cpu_ampliada con una memdata minimal (sin perifericos,
// sin addr_decoder: cs activa si addr < 0x100).
// ============================================================
`timescale 1 ns / 10 ps

module phase3_tb;

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

// memdata minimal: cs activa si addr en rango bajo
wire cs_mem = (bus_direccion < 16'h0100);
memdata MEMD (
    .clk(clk), .cs(cs_mem), .ctrl(bus_control),
    .addr(bus_direccion[9:0]), .data_bus(bus_data)
);

defparam uut.CD.MP.MEM_FILE   = "../tests/test_phase3_pipe.mem";
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
    $dumpfile("phase3.vcd");
    $dumpvars(0, phase3_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;

    #(150 * 20);

    $display("=== Resultado Fase 3 Pipeline (LOAD/STORE + stall) ===");
    $display("PC = %0d", pc);
    $display("r1 = %0d  (esperado 100)", r1);  if (r1 !== 16'd100) fail=1;
    $display("r2 = %0d  (esperado 5)",   r2);  if (r2 !== 16'd5)   fail=1;
    $display("r3 = %0d  (esperado 100)", r3);  if (r3 !== 16'd100) fail=1;
    $display("r4 = %0d  (esperado 200)", r4);  if (r4 !== 16'd200) fail=1;
    $display("r5 = %0d  (esperado 101)", r5);  if (r5 !== 16'd101) fail=1;
    $display("mem[5] = %0d  (esperado 100)", MEMD.mem[5]);

    if (!fail) $display("FASE 3 PIPELINE: PASS");
    else       $display("FASE 3 PIPELINE: FAIL");
    $finish;
end

initial begin
    #(50000);
    $display("TIMEOUT");
    $finish;
end

endmodule
