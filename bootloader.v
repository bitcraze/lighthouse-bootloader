`include "spi_bootloader.v"
`include "uart.v"

module top(
    input clk,
    input uart_rx,
    output uart_tx,

`ifdef HAS_LED
    output reg led,
`endif

    output spi_sck,
    output spi_so,
    input spi_si,
    output spi_ss
);

  localparam CLK_FREQ = 12000000;
  localparam UART_BAUDRATE = 115200;

  wire boot;

  // UART to Crazyflie
  wire uart_rx_valid;
  wire [7:0] uart_rx_data;
  wire uart_rx_ready;

  wire uart_tx_valid;
  wire [7:0] uart_tx_data;
  wire uart_tx_ready;

  wire uart_rx_break;

  uart #(
    .BAUDSEL(CLK_FREQ / (2*UART_BAUDRATE))
  ) uart (
    .clk(clk),

    .rx(uart_rx),
    .tx(uart_tx),

    .rx_valid(uart_rx_valid),
    .rx_data(uart_rx_data),
    .rx_ready(uart_rx_ready),

    .rx_break(uart_rx_break),

    .tx_valid(uart_tx_valid),
    .tx_data(uart_tx_data),
    .tx_ready(uart_tx_ready)
  );

  spi_bootloader #(
    .CLK_FREQ(CLK_FREQ)
  ) bootloader (
    .clk(clk),
    
    .reset(uart_rx_break),

    .data_in_valid(uart_rx_valid),
    .data_in(uart_rx_data),
    .data_in_ready(uart_rx_ready),

    .data_out_valid(uart_tx_valid),
    .data_out(uart_tx_data),
    .data_out_ready(uart_tx_ready),

    .spi_sck(spi_sck),
    .spi_so(spi_so),
    .spi_si(spi_si),
    .spi_ss(spi_ss),

`ifdef HAS_LED
    .led(led),
`endif

    .boot(boot)
  );

  // SB_WARMBOOT WB (
  //   .BOOT(boot),
  //   .S1(1'b 0),
  //   .S0(1'b 1)
  // );


endmodule