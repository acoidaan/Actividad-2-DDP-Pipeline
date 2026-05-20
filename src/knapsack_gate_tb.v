`timescale 1 ns / 10 ps

// =======================================================================
// Testbench para SIMULACION GATE-LEVEL
// -----------------------------------------------------------------------
// La unica diferencia con knapsack_full_tb.v es que NO referencia
// senales internas del modulo (system.hex01_reg, system.hex23_reg),
// porque en gate-level la sintesis aplana esos nombres jerarquicos.
//
// La verificacion se hace observando solo los puertos del top:
//   - LEDG (para detectar estados 0xAA -> 0x01 -> 0x80)
//   - HEX0, HEX1 (decodificando los 7-segmentos al numero que muestran)
// =======================================================================

module knapsack_gate_tb;

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

// ---- Decodificador 7-segmentos -> digito (activo a nivel bajo) ----
function [3:0] seg_to_digit;
    input [6:0] seg;
    begin
        case (seg)
            7'b1000000: seg_to_digit = 4'd0;
            7'b1111001: seg_to_digit = 4'd1;
            7'b0100100: seg_to_digit = 4'd2;
            7'b0110000: seg_to_digit = 4'd3;
            7'b0011001: seg_to_digit = 4'd4;
            7'b0010010: seg_to_digit = 4'd5;
            7'b0000010: seg_to_digit = 4'd6;
            7'b1111000: seg_to_digit = 4'd7;
            7'b0000000: seg_to_digit = 4'd8;
            7'b0010000: seg_to_digit = 4'd9;
            7'b0001000: seg_to_digit = 4'd10;  // A
            7'b0000011: seg_to_digit = 4'd11;  // b
            7'b1000110: seg_to_digit = 4'd12;  // C
            7'b0100001: seg_to_digit = 4'd13;  // d
            7'b0000110: seg_to_digit = 4'd14;  // E
            7'b0001110: seg_to_digit = 4'd15;  // F
            default:    seg_to_digit = 4'hX;
        endcase
    end
endfunction

wire [7:0] hex01_val = {seg_to_digit(HEX1), seg_to_digit(HEX0)};

task pulsar_y_esperar;
    input [3:0]  sw_val;
    input [7:0]  esperado;
    integer i;
    begin
        SW = {6'b0, sw_val};

        // Esperar LEDG=0xAA (CPU lista)
        i = 0;
        while (LEDG !== 8'hAA && i < 20000) begin @(posedge clk); i = i + 1; end
        if (i >= 20000) begin $display("ERROR: timeout LEDG=0xAA"); $finish; end

        $display("[t=%0t]  CPU lista, pulsando KEY[1] con SW=%0d (esperado=0x%h)",
                 $time, sw_val, esperado);

        KEY = 4'b1101;
        i = 0;
        while (LEDG !== 8'h01 && i < 2000) begin @(posedge clk); i = i + 1; end
        KEY = 4'b1111;

        // Esperar LEDG=0x80 (resultado listo)
        i = 0;
        while (LEDG !== 8'h80 && i < 20000) begin @(posedge clk); i = i + 1; end
        if (i >= 20000) begin $display("ERROR: timeout LEDG=0x80"); $finish; end

        // Comparar lo que muestran los 7-segmentos
        if (hex01_val === esperado)
            $display("        OK  HEX01 muestra 0x%h (= %0d decimal)", hex01_val, hex01_val);
        else
            $display("        FAIL HEX01 muestra 0x%h, esperaba 0x%h", hex01_val, esperado);
        $display("");
    end
endtask

initial begin
    $dumpfile("knapsack_gate.vcd");
    $dumpvars(0, knapsack_gate_tb);

    KEY = 4'b1110;
    SW  = 10'b0;
    #100;             // reset largo para gate-level
    KEY = 4'b1111;

    // En gate-level la simulacion es lenta, hacemos solo 1 test
    pulsar_y_esperar(4'd6, 8'h41);    // S=6 -> 65 (0x41)

    $display("=== Gate-level test completado ===");
    $finish;
end

// Salvavidas (gate-level puede ser MUY lento)
initial begin
    #(500000*20);
    $display("TIMEOUT GLOBAL");
    $finish;
end

endmodule