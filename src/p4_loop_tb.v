`timescale 1 ns / 10 ps
module p4_loop_tb;
reg clk, reset, irq_in;
wire [9:0] pc; wire [15:0] bus_direccion, bus_data; wire [1:0] bus_control; wire irq_ack;
cpu_ampliada uut(.clk(clk), .reset(reset), .irq_in(irq_in), .pc_out(pc),
    .bus_direccion(bus_direccion), .bus_data(bus_data),
    .bus_control(bus_control), .irq_ack(irq_ack));
defparam uut.CD.MP.MEM_FILE = "../tests/test_p4_loop.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";
initial clk = 0;
always #10 clk = ~clk;
wire [15:0] r1 = uut.CD.RF0.regb[1];
wire [15:0] r2 = uut.CD.RF0.regb[2];
wire [15:0] r3 = uut.CD.RF0.regb[3];
initial begin
    irq_in = 0; reset = 1; #25; reset = 0;
    #(200 * 20);
    $display("PC=%0d r1=%0d r2=%0d r3=%0d", pc, r1, r2, r3);
    $display("(esperado r1=0 r2=5 r3=99)");
    if (r1 == 0 && r2 == 5 && r3 == 99) $display("PASS");
    else $display("FAIL");
    $finish;
end
initial begin #50000; $finish; end
endmodule
