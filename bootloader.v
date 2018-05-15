`include "uart.v"

module top(
    input clk,
    input uart_rx,
    output reg led
);

  wire rx_break;

  uart #(.BAUDSEL(12000000 / (2*9600))) uart (
    .clk(clk),
    .rx(uart_rx),
    .rx_break(rx_break)
  );

  always @(posedge clk) begin
    if (rx_break) led = !led;
  end

endmodule