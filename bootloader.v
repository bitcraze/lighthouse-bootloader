`include "uart_bootloader.v"

module top(
    input clk,
    input uart_rx,
    output uart_tx,
    output reg led,

    output spi_sck,
    output spi_so,
    input spi_si,
    output spi_ss
);

  wire boot;

  uart_bootloader bootloader (
    .clk(clk),
    
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    
    .spi_sck(spi_sck),
    .spi_so(spi_so),
    .spi_si(spi_si),
    .spi_ss(spi_ss),

    .led(led),

    .boot(boot)
  );

  SB_WARMBOOT WB (
    .BOOT(boot),
    .S1(1'b 0),
    .S0(1'b 1)
  );


endmodule