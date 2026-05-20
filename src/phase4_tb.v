// ============================================================
// Testbench Fase 4 multiciclo
// Verifica EI, DI, RETI y la atencion de IRQ con el programa
// tests/test_irq.asm:
//   - main: incrementa r1 en bucle
//   - ISR (0x010): incrementa r10, reti
// Inyectamos irq_in periodicamente y comprobamos que r10 crece.
// ============================================================
`timescale 1 ns / 10 ps

module phase4_tb;

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

defparam uut.CD.MP.MEM_FILE   = "../tests/test_irq.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";

initial clk = 1'b0;
always #10 clk = ~clk;

wire [15:0] r1  = uut.CD.RF0.regb[1];
wire [15:0] r10 = uut.CD.RF0.regb[10];
wire        ie  = uut.CD.FIE.q;

// Generador de IRQ: pulsos cada cierto numero de ciclos
// Se desactiva en cuanto irq_ack se asiente para evitar IRQs
// re-encadenadas dentro del mismo nivel.
reg [15:0] counter;
always @(posedge clk) begin
    if (reset) begin
        counter <= 16'b0;
    end else begin
        counter <= counter + 1;
        // Levanta irq_in cada 200 ciclos
        if (counter == 16'd200 || counter == 16'd400 ||
            counter == 16'd600 || counter == 16'd800) begin
            irq_in <= 1'b1;
        end
        if (irq_ack) irq_in <= 1'b0;
    end
end

reg fail;

initial begin
    $dumpfile("phase4.vcd");
    $dumpvars(0, phase4_tb);

    irq_in = 1'b0;
    reset  = 1'b1;
    fail   = 1'b0;
    #25;
    reset  = 1'b0;

    // Esperar a que r10 alcance 4 (cuatro interrupciones)
    // o agotar tiempo
    #(1500 * 20);

    $display("=== Resultado Fase 4 ===");
    $display("r1  = %0d  (deberia ser grande, bucle principal)", r1);
    $display("r10 = %0d  (esperado 4 interrupciones atendidas)", r10);
    $display("PC  = %0d", pc);

    if (r10 >= 16'd4 && r1 > 16'd10)
        $display("FASE 4: PASS");
    else begin
        $display("FASE 4: FAIL");
        fail = 1'b1;
    end

    $finish;
end

initial begin
    #(200000);
    $display("TIMEOUT");
    $finish;
end

endmodule
