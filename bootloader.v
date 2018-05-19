`include "uart.v"
`include "spi.v"

module top(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg led,

    output spi_sck,
    output spi_so,
    input spi_si,
    output reg spi_ss
);

  wire uart_rx_break;
  wire uart_rx_ready;
  wire uart_rx_valid;
  wire [7:0] uart_rx_data;
  wire uart_tx_ready;
  wire uart_tx_valid;
  wire [7:0] uart_tx_data;

  // assign tx_data = rx_data ^ 8'h20;  // Switch case of alpha characters

  uart #(.BAUDSEL(12000000 / (2*9600))) uart (
    .clk(clk),  

    .rx(uart_rx),
    .tx(uart_tx),

    .rx_break(uart_rx_break),
    .rx_ready(uart_rx_ready),
    .rx_valid(uart_rx_valid),
    .rx_data(uart_rx_data),

    .tx_ready(uart_tx_ready),
    .tx_valid(uart_tx_valid),
    .tx_data(uart_tx_data)
  );

  // wire sloop;

  spi #(.HALF_PERIOD(120)) spi (
    .clk(clk),

    .sck(spi_sck),
    .so(spi_so),
    .si(spi_si),
    .tx_valid(uart_rx_valid),
    .tx_data(uart_rx_data),
    .tx_ready(uart_rx_ready),

    .rx_valid(uart_tx_valid),
    .rx_data(uart_tx_data),
    .rx_ready(uart_tx_ready)
  );

  initial spi_ss = 1;

  always @(posedge clk) begin
    if (uart_rx_break) led = !led;
    if (uart_rx_break) spi_ss = !spi_ss;
  end

endmodule