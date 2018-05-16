`include "uart.v"

module top(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg led
);

  wire rx_break;
  wire rx_ready;
  wire rx_valid;
  wire [7:0] rx_data;
  wire [7:0] tx_data;

  assign tx_data = rx_data ^ 8'h20;  // Switch case of alpha characters

  uart #(.BAUDSEL(12000000 / (2*9600))) uart (
    .clk(clk),
    .rx(uart_rx),
    .tx(uart_tx),
    .rx_break(rx_break),
    .rx_ready(rx_ready),
    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .tx_ready(rx_ready),
    .tx_valid(rx_valid),
    .tx_data(tx_data)
  );

  always @(posedge clk) begin
    if (rx_break) led = !led;
  end

endmodule