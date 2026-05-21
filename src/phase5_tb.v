// ============================================================
// Testbench Fase 5 pipeline: interrupciones
// ============================================================
`timescale 1 ns / 10 ps
module phase5_tb;

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
    .bus_direccion(bus_direccion), .bus_data(bus_data),
    .bus_control(bus_control), .irq_ack(irq_ack)
);

defparam uut.CD.MP.MEM_FILE   = "../tests/test_irq.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

wire [15:0] r1  = uut.CD.RF0.regb[1];
wire [15:0] r10 = uut.CD.RF0.regb[10];

// Generador de IRQ: pulsos cada cierto numero de ciclos
reg [15:0] counter;
always @(posedge clk) begin
    if (reset) begin
        counter <= 16'b0;
    end else begin
        counter <= counter + 1;
        if (counter == 16'd200 || counter == 16'd400 ||
            counter == 16'd600 || counter == 16'd800)
            irq_in <= 1'b1;
        if (irq_ack) irq_in <= 1'b0;
    end
end

reg fail;
initial begin
    $dumpfile("phase5.vcd");
    $dumpvars(0, phase5_tb);
    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;
    #(1500 * 20);

    $display("=== Fase 5 (interrupciones) ===");
    $display("PC  = %0d", pc);
    $display("r1  = %0d (contador principal, debe ser >> 0)", r1);
    $display("r10 = %0d (IRQs atendidas, esperado 4)", r10);
    if (r10 == 16'd4 && r1 > 16'd10) $display("FASE 5 PIPELINE: PASS");
    else                              $display("FASE 5 PIPELINE: FAIL");
    $finish;
end
initial begin #(200000); $finish; end
endmodule
