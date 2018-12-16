`include "spi_bootloader.v"
`include "uart.v"

module top(
    input clk,

    input uart0_rx,
    output uart0_tx,

    input uart1_rx,
    output uart1_tx,

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
  wire uart0_rx_valid;
  wire [7:0] uart0_rx_data;
  wire uart0_rx_ready;

  wire uart0_tx_valid;
  wire [7:0] uart0_tx_data;
  wire uart0_tx_ready;

  wire uart0_rx_break;

  wire uart0_rx_in0;

  uart #(
    .BAUDSEL(CLK_FREQ / (2*UART_BAUDRATE))
  ) uart0 (
    .clk(clk),

    .rx(uart0_rx_in0),
    .tx(uart0_tx),

    .rx_valid(uart0_rx_valid),
    .rx_data(uart0_rx_data),
    .rx_ready(uart0_rx_ready),

    .rx_break(uart0_rx_break),

    .tx_valid(uart0_tx_valid),
    .tx_data(uart0_tx_data),
    .tx_ready(uart0_tx_ready)
  );

  // Enable Pull-up on RX pin
  SB_IO #(
      .PIN_TYPE(6'b0000_01),
      .PULLUP(1'b1)
  ) uart0_io (
      .PACKAGE_PIN(uart0_rx),
      .D_IN_0(uart0_rx_in0)
  );

  // UART to Pin header
  wire uart1_rx_valid;
  wire [7:0] uart1_rx_data;
  wire uart1_rx_ready;

  wire uart1_tx_valid;
  wire [7:0] uart1_tx_data;
  wire uart1_tx_ready;

  wire uart1_rx_break;

  wire uart1_rx_in0;

  uart #(
    .BAUDSEL(CLK_FREQ / (2*UART_BAUDRATE))
  ) uart1 (
    .clk(clk),

    .rx(uart1_rx_in0),
    .tx(uart1_tx),

    .rx_valid(uart1_rx_valid),
    .rx_data(uart1_rx_data),
    .rx_ready(uart1_rx_ready),

    .rx_break(uart1_rx_break),

    .tx_valid(uart1_tx_valid),
    .tx_data(uart1_tx_data),
    .tx_ready(uart1_tx_ready)
  );

  // Enable Pull-up on RX pin
  SB_IO #(
      .PIN_TYPE(6'b0000_01),
      .PULLUP(1'b1)
  ) uart1_io (
      .PACKAGE_PIN(uart1_rx),
      .D_IN_0(uart1_rx_in0)
  );

  // Routing UARTs <=> bootloader
  wire bootloader_in_valid = uart0_rx_valid | uart1_rx_valid;
  wire bootloader_in_ready;
  assign uart0_rx_ready = bootloader_in_ready;
  assign uart1_rx_ready = bootloader_in_ready;
  wire [7:0] bootloader_in = uart0_rx_valid?uart0_rx_data:(uart1_rx_valid?uart1_rx_data:0);

  wire bootloader_out_valid;
  assign uart0_tx_valid = bootloader_out_valid;
  assign uart1_tx_valid = bootloader_out_valid;
  wire bootloader_out_ready = uart0_tx_ready & uart1_tx_ready;
  wire [7:0] bootloader_out;
  assign uart0_tx_data = bootloader_out;
  assign uart1_tx_data = bootloader_out;

  wire bootloader_reset = uart0_rx_break | uart1_rx_break;


  // SPI bootloader
  spi_bootloader #(
    .CLK_FREQ(CLK_FREQ)
  ) bootloader (
    .clk(clk),
    
    .reset(bootloader_reset),

    .data_in_valid(bootloader_in_valid),
    .data_in(bootloader_in),
    .data_in_ready(bootloader_in_ready),

    .data_out_valid(bootloader_out_valid),
    .data_out(bootloader_out),
    .data_out_ready(bootloader_out_ready),

    .spi_sck(spi_sck),
    .spi_so(spi_so),
    .spi_si(spi_si),
    .spi_ss(spi_ss),

`ifdef HAS_LED
    .led(led),
`endif

    .boot(boot)
  );

  SB_WARMBOOT WB (
    .BOOT(boot),
    .S1(1'b 0),
    .S0(1'b 1)
  );


endmodule