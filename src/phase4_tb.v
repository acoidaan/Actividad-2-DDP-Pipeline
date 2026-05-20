// ============================================================
// Testbench Fase 4 pipeline
// Knapsack completo: requiere LOAD/STORE/CALL/RET + saltos (J,
// JZ, JNZ) con flush correcto. Reutiliza knapsack_full.mem que
// venia del multiciclo.
// ============================================================
`timescale 1 ns / 10 ps

module phase4_tb;

reg        clk;
reg  [3:0] KEY;
reg  [9:0] SW;
wire [6:0] HEX0, HEX1, HEX2, HEX3;
wire [9:0] LEDR;
wire [7:0] LEDG;

initial clk = 1'b0;
always  #10 clk = ~clk;

DE1_System system (
    .CLOCK_50(clk), .KEY(KEY), .SW(SW),
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
    .LEDR(LEDR), .LEDG(LEDG)
);

defparam system.CPU.CD.MP.MEM_FILE   = "../tests/knapsack_full.mem";
defparam system.CPU.CD.RF0.INIT_FILE = "regfile.dat";

wire [15:0] hex01 = system.hex01_reg;
wire [15:0] hex23 = system.hex23_reg;

reg fail;

task pulsar_y_esperar;
    input [3:0]  sw_val;
    input [15:0] esperado;
    integer i;
    begin
        SW = {6'b0, sw_val};

        i = 0;
        while (LEDG !== 8'hAA && i < 30000) begin @(posedge clk); i = i + 1; end
        if (i >= 30000) begin
            $display("ERROR: timeout esperando LEDG=0xAA con SW=%0d", sw_val);
            fail = 1'b1;
        end else begin
            $display("[t=%0t] CPU lista, SW=%0d, esperado=%0d",
                     $time, sw_val, esperado);

            KEY = 4'b1101;

            i = 0;
            while (LEDG !== 8'h01 && i < 5000) begin @(posedge clk); i = i + 1; end

            KEY = 4'b1111;

            i = 0;
            while (LEDG !== 8'h80 && i < 50000) begin @(posedge clk); i = i + 1; end
            if (i >= 50000) begin
                $display("        ERROR: timeout esperando LEDG=0x80");
                fail = 1'b1;
            end else if (hex01 == esperado) begin
                $display("        OK   HEX01=%0d (0x%h)  HEX23=%0d ciclos",
                         hex01, hex01, hex23);
            end else begin
                $display("        FAIL HEX01=%0d esperaba %0d  HEX23=%0d",
                         hex01, esperado, hex23);
                fail = 1'b1;
            end
            $display("");
        end
    end
endtask

initial begin
    $dumpfile("phase4.vcd");
    $dumpvars(0, phase4_tb);

    fail = 1'b0;
    KEY  = 4'b1110;
    SW   = 10'b0;
    #40;
    KEY  = 4'b1111;

    pulsar_y_esperar(4'd6, 16'd65);
    pulsar_y_esperar(4'd5, 16'd55);
    pulsar_y_esperar(4'd4, 16'd50);
    pulsar_y_esperar(4'd3, 16'd40);

    if (!fail) $display("=== FASE 4 PIPELINE: PASS ===");
    else       $display("=== FASE 4 PIPELINE: FAIL ===");
    $finish;
end

initial begin
    #(800000 * 20);
    $display("TIMEOUT GLOBAL");
    $finish;
end

endmodule
