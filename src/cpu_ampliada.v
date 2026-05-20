// ============================================================
// CPU pipeline - top
//
// El camino de datos en pipeline contiene la UC internamente como
// decodificador combinacional, asi que aqui solo hay que cablear
// el bus externo (tri-state) y exponer las senales al DE1_System.
// ============================================================

module cpu_ampliada(input wire clk, reset, irq_in,
                    output wire [9:0] pc_out,
                    output wire [15:0] bus_direccion,
                    inout wire [15:0] bus_data,
                    output wire [1:0] bus_control,
                    output wire irq_ack);

wire [15:0] bus_data_in;
wire [15:0] bus_data_out;

assign bus_data_in = bus_data;
// El CPU conduce el bus solo cuando hace STORE (bus_control=10)
assign bus_data = (bus_control == 2'b10) ? bus_data_out : 16'bz;

cd CD (
    .clk(clk), .reset(reset),
    .pc_out(pc_out),
    .bus_data_in(bus_data_in),
    .bus_data_out(bus_data_out),
    .bus_direccion(bus_direccion),
    .bus_control(bus_control),
    .irq_in(irq_in),
    .irq_ack(irq_ack)
);

endmodule
