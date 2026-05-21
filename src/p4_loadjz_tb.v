`timescale 1 ns / 10 ps
module p4_loadjz_tb;
reg clk, reset, irq_in;
wire [9:0] pc; wire [15:0] bus_direccion, bus_data; wire [1:0] bus_control; wire irq_ack;
cpu_ampliada uut(.clk(clk), .reset(reset), .irq_in(irq_in), .pc_out(pc),
    .bus_direccion(bus_direccion), .bus_data(bus_data),
    .bus_control(bus_control), .irq_ack(irq_ack));
wire cs_mem = (bus_direccion < 16'h0100);
memdata MEMD(.clk(clk), .cs(cs_mem), .ctrl(bus_control),
             .addr(bus_direccion[9:0]), .data_bus(bus_data));
defparam uut.CD.MP.MEM_FILE = "../tests/test_p4_loadjz.mem";
defparam uut.CD.RF0.INIT_FILE = "regfile.dat";
initial clk = 0;
always #10 clk = ~clk;
wire [15:0] r7 = uut.CD.RF0.regb[7];
wire [15:0] r8 = uut.CD.RF0.regb[8];
wire [15:0] r9 = uut.CD.RF0.regb[9];
initial begin
    irq_in = 0; reset = 1; #25; reset = 0;
    #(300 * 20);
    $display("PC=%0d r7=%0d r8=%0d r9=%0d", pc, r7, r8, r9);
    $display("(esperado r7=77 r8=0 r9=0)");
    if (r7 == 77 && r8 == 0 && r9 == 0)
        $display("LOAD-JZ: PASS");
    else
        $display("LOAD-JZ: FAIL");
    $finish;
end
initial begin #50000; $finish; end
endmodule
