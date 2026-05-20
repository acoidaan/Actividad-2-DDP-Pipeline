module memdata(
    input  wire        clk,
    input  wire        cs,
    input  wire [1:0]  ctrl,
    input  wire [9:0]  addr,
    inout  wire [15:0] data_bus
);
    // Memoria reducida de 1024 a 256 palabras para caber en la EP2C20.
    // Como la memoria no se infiere como M4K (porque la lectura es
    // asincrona, exigida por el LOAD de un ciclo), se implementa con
    // flip-flops sueltos. Reducir el tamano ahorra unos 12000 LEs.
    //
    // Solo se usan los 8 bits bajos de la direccion. Si un programa
    // accede a una direccion >= 256 dentro del rango de memdata, el
    // acceso se envuelve fisicamente a los 8 bits bajos.
    reg [15:0] mem [0:255];
    reg [15:0] data_out;
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 16'b0;
    end
    always @(posedge clk) begin
        if (cs && ctrl == 2'b10) mem[addr[7:0]] <= data_bus;
    end
    always @(*) begin
        if (cs && ctrl == 2'b01) data_out = mem[addr[7:0]];
        else data_out = 16'b0;
    end
    assign data_bus = (cs && ctrl == 2'b01) ? data_out : 16'bz;
endmodule


// Decodificador de direcciones
// 0x0000-0x00FF  Memoria datos (reducida de 0x3FF a 0xFF)
// 0x0400  Switches    0x0401  Keys
// 0x0402  LEDR        0x0403  LEDG
// 0x0404  HEX01       0x0405  HEX23
// 0x0406  TIMER_TOP   0x0407  TIMER_COUNT
//
// Mantenemos el decodificador original que cubre hasta 0x3FF para
// memdata: no hace falta cambiarlo, aunque la memoria fisica solo
// tenga 256 palabras. Las direcciones 0x100-0x3FF seguiran activando
// cs_mem y accederan fisicamente al rango 0x00-0xFF por wraparound.
// Esto no afecta a los programas que se mantengan dentro de 0-255.

module addr_decoder(
    input  wire [15:0] bus_dir,
    output wire cs_mem, cs_sw, cs_key, cs_ledr, cs_ledg,
    output wire cs_hex01, cs_hex23, cs_timer_top, cs_timer_cnt
);
    assign cs_mem       = (bus_dir[15:10] == 6'b000000);
    assign cs_sw        = (bus_dir == 16'h0400);
    assign cs_key       = (bus_dir == 16'h0401);
    assign cs_ledr      = (bus_dir == 16'h0402);
    assign cs_ledg      = (bus_dir == 16'h0403);
    assign cs_hex01     = (bus_dir == 16'h0404);
    assign cs_hex23     = (bus_dir == 16'h0405);
    assign cs_timer_top = (bus_dir == 16'h0406);
    assign cs_timer_cnt = (bus_dir == 16'h0407);
endmodule


module periferico_in(
    input  wire        cs,
    input  wire [1:0]  ctrl,
    input  wire [15:0] valor_in,
    inout  wire [15:0] data_bus
);
    assign data_bus = (cs && ctrl == 2'b01) ? valor_in : 16'bz;
endmodule


module periferico_out #(parameter WIDTH = 16)(
    input  wire            clk,
    input  wire            reset,
    input  wire            cs,
    input  wire [1:0]      ctrl,
    input  wire [15:0]     data_bus,
    output reg [WIDTH-1:0] valor_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) valor_out <= {WIDTH{1'b0}};
        else if (cs && ctrl == 2'b10) valor_out <= data_bus[WIDTH-1:0];
    end
endmodule