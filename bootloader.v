`include "spi_bootloader.v"
`include "uart.v"
`include "i2c.v"
`include "i2c_fsm.v"

module top(
    input clk,

    input uart0_rx,
    output uart0_tx,

    input uart1_rx,
    output uart1_tx,

    inout i2c_sda,
    input i2c_scl,

`ifdef HAS_LED
    output reg led,
`endif

    output led_red,
    output led_yellow,
    output led_green,

    output spi_sck,
    output spi_so,
    input spi_si,
    output spi_ss
);

  localparam CLK_FREQ = 12000000;
  localparam UART_BAUDRATE = 115200;
  localparam MAGIC_BYTE = 8'hbc;

  wire boot;
  wire bootloader_busy;

  // UART to Crazyflie
  wire uart0_rx_valid;
  wire [7:0] uart0_rx_data;
  wire uart0_rx_ready;

  wire uart0_tx_valid;
  wire [7:0] uart0_tx_data;
  wire uart0_tx_ready;

  wire uart0_rx_break;

  wire uart0_tx_out0;

  reg uart0_enabled = 0;
  reg uart0_reset_bootloader = 0;

  uart #(
    .BAUDSEL(CLK_FREQ / (2*UART_BAUDRATE))
  ) uart0 (
    .clk(clk),

    .rx(uart0_rx),
    .tx(uart0_tx_out0),

    .rx_valid(uart0_rx_valid),
    .rx_data(uart0_rx_data),
    .rx_ready(uart0_rx_ready),

    .rx_break(uart0_rx_break),

    .tx_valid(uart0_tx_valid),
    .tx_data(uart0_tx_data),
    .tx_ready(uart0_tx_ready)
  );

  always @(posedge clk) begin
    uart0_reset_bootloader <= 0;
    if (!uart0_enabled) begin
      if (uart0_rx_valid && uart0_rx_data == MAGIC_BYTE) begin
        uart0_enabled <= 1;
        uart0_reset_bootloader <= 1;
      end
    end else begin
      if (uart0_rx_break) uart0_reset_bootloader <= 1;
    end
  end

  // Uart0 TX is completly disabled until the magic byte is received
  SB_IO #(
      .PIN_TYPE(6'b1010_01)  // Output tristate
  ) uart0_io (
      .PACKAGE_PIN(uart0_tx),
      .D_OUT_0(uart0_tx_out0),
      .OUTPUT_ENABLE(uart0_enabled)
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

  reg uart1_enabled = 0;
  reg uart1_reset_bootloader = 0;

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

  always @(posedge clk) begin
    uart1_reset_bootloader <= 0;
    if (uart1_enabled == 0) begin
      if (uart1_rx_valid && uart1_rx_data == MAGIC_BYTE) begin
        uart1_enabled <= 1;
        uart1_reset_bootloader <= 1;
      end else begin
        if (uart1_rx_break) uart1_reset_bootloader <= 1;
      end
    end
  end

  // Enable Pull-up on RX pin
  SB_IO #(
      .PIN_TYPE(6'b0000_01),
      .PULLUP(1'b1)
  ) uart1_io (
      .PACKAGE_PIN(uart1_rx),
      .D_IN_0(uart1_rx_in0)
  );

  

  // I2C port
  wire i2c_sda_i;
  wire i2c_sda_o;
  wire i2c_scl;

  wire i2c_write;
  wire i2c_write_ready;
  wire [7:0] i2c_write_data;
  wire i2c_write_valid;

  wire i2c_read;
  wire i2c_read_ready;
  wire [7:0] i2c_read_data;
  wire i2c_read_valid;
  i2c i2c (
    .clk(clk),

    .scl(i2c_scl),
    .sda_i(i2c_sda_i),
    .sda_o(i2c_sda_o),

    .read(i2c_read),
    .write(i2c_write),

    .read_ready(i2c_read_ready),
    .read_data(i2c_read_data),
    .read_valid(i2c_read_valid),

    .write_ready(i2c_write_ready),
    .write_data(i2c_write_data),
    .write_valid(i2c_write_valid)
  );

  // SDA as open collector output/registered input
  SB_IO #(
    .PIN_TYPE(6'b1010_00)
  ) i2c_sda_io (
    .PACKAGE_PIN(i2c_sda),
    .INPUT_CLK(clk),
    .CLOCK_ENABLE(1'b1),
    .D_IN_0(i2c_sda_i),
    .D_OUT_0(1'b0),              // Fix output to 0
    .OUTPUT_ENABLE(~i2c_sda_o)   // Enabled to outputing 0 when sda_o should be 0
  );

  // I2C <-> Bootloader FSM
  wire i2c_out_ready;
  wire [7:0] i2c_out_data;
  wire i2c_out_valid;
  wire i2c_in_ready;
  wire [7:0] i2c_in_data;
  wire i2c_in_valid;
  wire i2c_bootloader_reset;

  i2c_fsm i2c_fsm(
    .clk(clk),

    .bootloader_out_valid(i2c_in_valid),
    .bootloader_out_data(i2c_in_data),
    .bootloader_out_ready(i2c_in_ready),

    .bootloader_in_valid(i2c_out_valid),
    .bootloader_in_data(i2c_out_data),
    .bootloader_in_ready(i2c_out_ready),

    .bootloader_busy(bootloader_busy),
    .bootloader_reset(i2c_bootloader_reset),

    .i2c_read(i2c_read),
    .i2c_write(i2c_write),

    .i2c_read_ready(i2c_read_ready),
    .i2c_read_data(i2c_read_data),
    .i2c_read_valid(i2c_read_valid),

    .i2c_write_ready(i2c_write_ready),
    .i2c_write_data(i2c_write_data),
    .i2c_write_valid(i2c_write_valid)
  );


  // Routing UARTs/I2C <=> bootloader
  wire bootloader_in_valid = uart0_enabled?uart0_rx_valid:
                             uart1_enabled?uart1_rx_valid:
                                           i2c_out_valid;
  wire bootloader_in_ready;
  assign uart0_rx_ready = bootloader_in_ready | ~uart0_enabled;
  assign uart1_rx_ready = bootloader_in_ready | ~uart1_enabled;
  assign i2c_out_ready = bootloader_in_ready;
  wire [7:0] bootloader_in = uart0_enabled?uart0_rx_data:
                             uart1_enabled?uart1_rx_data:
                                           i2c_out_data;

  wire bootloader_out_valid;
  assign uart0_tx_valid = uart0_enabled & bootloader_out_valid;
  assign uart1_tx_valid = uart1_enabled & bootloader_out_valid;
  assign i2c_in_valid = bootloader_out_valid;
  wire bootloader_out_ready = uart0_enabled?uart0_tx_ready:
                              uart1_enabled?uart1_tx_ready:
                                            i2c_in_ready;
  wire [7:0] bootloader_out;
  assign uart0_tx_data = bootloader_out;
  assign uart1_tx_data = bootloader_out;
  assign i2c_in_data = bootloader_out;

  wire bootloader_reset = uart0_reset_bootloader| uart1_reset_bootloader | i2c_bootloader_reset;


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

    .busy(bootloader_busy),
    .boot(boot)
  );

  SB_WARMBOOT WB (
    .BOOT(boot),
    .S1(1'b 0),
    .S0(1'b 1)
  );

  // Leds
  assign led_red = 0;
  assign led_yellow = ~bootloader_busy;
  assign led_green = 1;


endmodule