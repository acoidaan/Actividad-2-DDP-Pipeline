// =======================================================
// Timer con interrupción
// =======================================================
// Mapa:
//   0x0406 (cs_top)  : TIMER_TOP  - escritura → valor de comparación
//                                   lectura  → valor actual de TOP
//                       Escribir también resetea el contador y arranca.
//                       Escribir 0 para el timer.
//   0x0407 (cs_cnt)  : TIMER_COUNT - lectura  → contador actual
//
// Funcionamiento:
//   Cuenta de 0 hasta TOP-1. Al llegar a TOP:
//     - Resetea contador a 0
//     - Activa irq_out (se mantiene hasta irq_ack)
//   Escribir TOP=0 detiene el timer.
//
// irq_out se limpia con el pulso irq_ack de la CPU.

module timer(
    input  wire        clk,
    input  wire        reset,
    input  wire        cs_top,       // chip select para TIMER_TOP
    input  wire        cs_cnt,       // chip select para TIMER_COUNT
    input  wire [1:0]  ctrl,         // bus_control: 01=LOAD, 10=STORE
    input  wire        irq_ack,      // pulso de acknowledge de la CPU
    inout  wire [15:0] data_bus,
    output reg         irq_out
);

    reg [15:0] top_reg;    // valor de comparación
    reg [15:0] counter;    // contador
    wire       enabled;

    assign enabled = (top_reg != 16'b0);

    // ---- Escritura de TOP (STORE) ----
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            top_reg <= 16'b0;
            counter <= 16'b0;
        end else begin
            // Escribir TOP: cargar valor, resetear contador
            if (cs_top && ctrl == 2'b10) begin
                top_reg <= data_bus;
                counter <= 16'b0;
            end
            // Contar
            else if (enabled) begin
                if (counter >= top_reg - 16'd1)
                    counter <= 16'b0;
                else
                    counter <= counter + 16'd1;
            end
        end
    end

    // ---- IRQ: activar al llegar a TOP, limpiar con irq_ack ----
    always @(posedge clk or posedge reset) begin
        if (reset)
            irq_out <= 1'b0;
        else if (irq_ack)
            irq_out <= 1'b0;
        else if (enabled && counter == top_reg - 16'd1)
            irq_out <= 1'b1;
    end

    // ---- Lectura (LOAD) ----
    wire [15:0] read_data;
    assign read_data = cs_top ? top_reg :
                       cs_cnt ? counter :
                       16'b0;

    assign data_bus = ((cs_top || cs_cnt) && ctrl == 2'b01) ? read_data : 16'bz;

endmodule