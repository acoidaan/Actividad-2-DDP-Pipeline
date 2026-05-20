`timescale 1 ns / 10 ps

module knapsack_full_tb;

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

wire [15:0] hex01 = system.hex01_reg;
wire [15:0] hex23 = system.hex23_reg;

task pulsar_y_esperar;
    input [3:0]  sw_val;
    input [15:0] esperado;
    integer i;
    begin
        SW = {6'b0, sw_val};

        // 1. Esperar a que la CPU este en estado "listo" (LEDG = 0xAA)
        i = 0;
        while (LEDG !== 8'hAA && i < 10000) begin @(posedge clk); i = i + 1; end
        if (i >= 10000) begin $display("ERROR: timeout esperando LEDG=0xAA"); $finish; end

        $display("[t=%0t]  CPU lista (LEDG=0xAA), pulsando KEY[1] con SW=%0d (esperado=%0d)",
                 $time, sw_val, esperado);

        // 2. Pulsar KEY[1]
        KEY = 4'b1101;

        // 3. Esperar a que la CPU detecte la pulsacion (LEDG pasa a 0x01)
        i = 0;
        while (LEDG !== 8'h01 && i < 1000) begin @(posedge clk); i = i + 1; end

        // 4. Soltar KEY[1]
        KEY = 4'b1111;

        // 5. Esperar a que termine (LEDG = 0x80)
        i = 0;
        while (LEDG !== 8'h80 && i < 10000) begin @(posedge clk); i = i + 1; end
        if (i >= 10000) begin $display("ERROR: timeout esperando LEDG=0x80"); $finish; end

        // 6. Reportar
        if (hex01 == esperado)
            $display("        OK  HEX01=%0d (0x%h)   HEX23=%0d ciclos",
                     hex01, hex01, hex23);
        else
            $display("        FAIL HEX01=%0d esperaba %0d   HEX23=%0d ciclos",
                     hex01, esperado, hex23);
        $display("");
    end
endtask

initial begin
    $dumpfile("knapsack_full.vcd");
    $dumpvars(0, knapsack_full_tb);

    KEY = 4'b1110;
    SW  = 10'b0;
    #40;
    KEY = 4'b1111;

    pulsar_y_esperar(4'd6, 16'd65);    // S=6: 3 items,        65
    pulsar_y_esperar(4'd5, 16'd55);    // S=5: items 1+2,      55
    pulsar_y_esperar(4'd4, 16'd50);    // S=4: items 0+2,      50
    pulsar_y_esperar(4'd3, 16'd40);    // S=3: solo item 2,    40

    $display("=== Tests completados ===");
    $finish;
end

initial begin
    #(200000*20);
    $display("TIMEOUT GLOBAL");
    $finish;
end

endmodule
