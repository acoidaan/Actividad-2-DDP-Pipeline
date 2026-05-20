module DE1_System(
    input wire CLOCK_50,
    input wire [3:0] KEY,
    input wire [9:0] SW,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3,
    output wire [9:0] LEDR,
    output wire [7:0] LEDG
);

    // Reset activo bajo: pulsar KEY[0] resetea la CPU
    wire reset = ~KEY[0]; 
    wire [9:0]  pc;
    wire [15:0] bus_direccion, bus_data;
    wire [1:0]  bus_control;
    wire        irq_ack, irq_line;

    // CPU
    cpu_ampliada CPU(
        .clk(CLOCK_50), .reset(reset), .irq_in(irq_line),
        .pc_out(pc), .bus_direccion(bus_direccion),
        .bus_data(bus_data), .bus_control(bus_control),
        .irq_ack(irq_ack)
    );

    // Decodificador
    wire cs_mem, cs_sw, cs_key, cs_ledr, cs_ledg, cs_hex01, cs_hex23;
    wire cs_timer_top, cs_timer_cnt;
    addr_decoder DECODER(bus_direccion, cs_mem, cs_sw, cs_key,
                         cs_ledr, cs_ledg, cs_hex01, cs_hex23,
                         cs_timer_top, cs_timer_cnt);

    // Memoria de datos
    memdata MEMD(.clk(CLOCK_50), .cs(cs_mem), .ctrl(bus_control),
                 .addr(bus_direccion[9:0]), .data_bus(bus_data));

    // Periféricos entrada
    periferico_in P_SW (.cs(cs_sw),  .ctrl(bus_control), .valor_in({6'b0, SW}),   .data_bus(bus_data));
    periferico_in P_KEY(.cs(cs_key), .ctrl(bus_control), .valor_in({12'b0, ~KEY}), .data_bus(bus_data));

    // Periféricos salida
    wire [9:0] ledr_reg; wire [7:0] ledg_reg;
    wire [15:0] hex01_reg, hex23_reg;

    //periferico_out #(10) P_LEDR (.clk(CLOCK_50), .reset(reset), .cs(cs_ledr), .ctrl(bus_control), .data_bus(bus_data), .valor_out(ledr_reg));
    periferico_out #(8)  P_LEDG (.clk(CLOCK_50), .reset(reset), .cs(cs_ledg),
        .ctrl(bus_control), .data_bus(bus_data), .valor_out(ledg_reg));
    periferico_out #(16) P_HEX01(.clk(CLOCK_50), .reset(reset), .cs(cs_hex01),
        .ctrl(bus_control), .data_bus(bus_data), .valor_out(hex01_reg));
    periferico_out #(16) P_HEX23(.clk(CLOCK_50), .reset(reset), .cs(cs_hex23),
        .ctrl(bus_control), .data_bus(bus_data), .valor_out(hex23_reg));

    assign LEDR = pc;
    assign LEDG = ledg_reg;
    hexdec H0(hex01_reg[3:0], HEX0); hexdec H1(hex01_reg[7:4], HEX1);
    hexdec H2(hex23_reg[3:0], HEX2); hexdec H3(hex23_reg[7:4], HEX3);

    // Timer con interrupción
    timer TIMER0(
        .clk(CLOCK_50), .reset(reset),
        .cs_top(cs_timer_top), .cs_cnt(cs_timer_cnt),
        .ctrl(bus_control), .irq_ack(irq_ack),
        .data_bus(bus_data), .irq_out(irq_line)
    );

endmodule
