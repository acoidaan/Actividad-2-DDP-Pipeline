`timescale 1 ns / 10 ps
module p4_storeloop_tb;
reg clk, reset, irq_in;
wire [9:0] pc; wire [15:0] bus_direccion, bus_data; wire [1:0] bus_control; wire irq_ack;
cpu_ampliada uut(.clk(clk), .reset(reset), .irq_in(irq_in), .pc_out(pc),
    .bus_direccion(bus_direccion), .bus_data(bus_data),
    .bus_control(bus_control), .irq_ack(irq_ack));
// memoria de datos minimal: cs si addr < 0x100
wire cs_mem = (bus_direccion < 16'h0100);
// Inicializar memoria con valor no-cero antes para comprobar que se sobreescribe
initial begin
    #1;
    MEMD.mem[10] = 16'hFFFF;
    MEMD.mem[11] = 16'hFFFF;
    MEMD.mem[12] = 16'hFFFF;
    MEMD.mem[13] = 16'hFFFF;
    MEMD.mem[14] = 16'hFFFF;
    MEMD.mem[15] = 16'hABCD;
end
memdata MEMD(.clk(clk), .cs(cs_mem), .ctrl(bus_control),
             .addr(bus_direccion[9:0]), .data_bus(bus_data));
defparam uut.CD.MP.MEM_FILE = "../tests/test_p4_storeloop.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";
initial clk = 0;
always #10 clk = ~clk;
wire [15:0] r5 = uut.CD.RF0.regb[5];
wire [15:0] r6 = uut.CD.RF0.regb[6];
wire [15:0] r9 = uut.CD.RF0.regb[9];
initial begin
    irq_in = 0; reset = 1; #25; reset = 0;
    #(300 * 20);
    $display("PC=%0d r5=%0d r6=%0d r9=%0d", pc, r5, r6, r9);
    $display("mem[10..15] = %0d %0d %0d %0d %0d %0d",
        MEMD.mem[10], MEMD.mem[11], MEMD.mem[12], MEMD.mem[13], MEMD.mem[14], MEMD.mem[15]);
    $display("(esperado r5=15 r6=0 r9=99, mem[10..14]=0,0,0,0,0 mem[15]=43981)");
    if (r5 == 15 && r6 == 0 && r9 == 99) $display("PASS");
    else $display("FAIL");
    $finish;
end
initial begin #50000; $finish; end
endmodule
