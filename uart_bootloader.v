`include "uart.v"
`include "spi.v"

module uart_bootloader #(
  parameter CLK_FREQ = 12000000,
  parameter UART_BAUDRATE = 115200,
  parameter SPI_FREQ = 4000000
) (
  input clk,

  input uart_rx,
  output uart_tx,

  input spi_si,
  output spi_so,
  output spi_sck,
  output reg spi_ss,

  output led,

  output boot
);

  // communication ports
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

  wire spi_rx_valid;
  wire [7:0] spi_rx_data;
  wire spi_rx_ready;

  wire spi_tx_valid;
  wire [7:0] spi_tx_data;
  wire spi_tx_ready;

  spi #(
    .HALF_PERIOD(CLK_FREQ / (2*SPI_FREQ))
  ) spi (
    .clk(clk),

    .si(spi_si),
    .so(spi_so),
    .sck(spi_sck),

    .rx_valid(spi_rx_valid),
    .rx_data(spi_rx_data),
    .rx_ready(spi_rx_ready),

    .tx_valid(spi_tx_valid),
    .tx_data(spi_tx_data),
    .tx_ready(spi_tx_ready)
  );

  // Protocol implementation
  localparam STATE_CMD = 0;
  localparam STATE_BOOT = 1;
  localparam STATE_TXLENLOW = 2;
  localparam STATE_TXLENHIGH = 3;
  localparam STATE_RXLENLOW = 4;
  localparam STATE_RXLENHIGH = 5;
  localparam STATE_TX = 6;  // Sending on SPI
  localparam STATE_RX = 7;  // Receiving from SPI

  reg [3:0] state = STATE_CMD;

  reg [15:0] rxLen = 0;
  reg [15:0] txLen = 0;
  reg [15:0] currentLen = 0;

  always @(posedge clk) begin
    spi_ss <= 1;
    // UART break condition is used as a state machine reset
    if (uart_rx_break) begin
      state <= STATE_CMD;
    end else begin
      case (state)
        STATE_CMD: begin
          if (uart_rx_valid == 1) begin
            case (uart_rx_data)
              0: state <= STATE_BOOT;
              1: state <= STATE_TXLENLOW;
            endcase 
          end
        end
        STATE_TXLENLOW: begin
          if (uart_rx_valid == 1) begin
            txLen[7:0] <= uart_rx_data;
            state <= STATE_TXLENHIGH;
          end
        end
        STATE_TXLENHIGH: begin
          if (uart_rx_valid == 1) begin
            txLen[15:8] <= uart_rx_data;
            state <= STATE_RXLENLOW;
          end
        end
        STATE_RXLENLOW: begin
          if (uart_rx_valid == 1) begin
            rxLen[7:0] <= uart_rx_data;
            state <= STATE_RXLENHIGH;
          end
        end
        STATE_RXLENHIGH: begin
          if (uart_rx_valid == 1) begin
            rxLen[15:8] <= uart_rx_data;
            state <= STATE_TX;
            currentLen <= 0;
          end
        end
        STATE_TX: begin
          spi_ss <= 0;
          if (spi_rx_valid) begin
            currentLen <= currentLen + 1;
            if (currentLen == txLen-1) begin
              state <= STATE_RX;
              currentLen <= 0;
            end
          end
        end
        STATE_RX: begin
          spi_ss <= 0;
          if (uart_tx_ready && uart_tx_valid) begin
            currentLen <= currentLen + 1;
            if (currentLen == rxLen-1) begin
              state <= STATE_CMD;
              currentLen <= 0;
            end
          end
        end
      endcase
    end
  end

  // communication flow control
  assign uart_rx_ready = (state == STATE_TX)?spi_tx_ready:1;
  assign uart_tx_valid = (state == STATE_RX)?spi_rx_valid:0;

  assign spi_rx_ready = (state == STATE_RX)?uart_tx_ready:1;
  assign spi_tx_valid = (state == STATE_TX)?uart_rx_valid:(state == STATE_RX)?1:0;

  assign spi_tx_data = uart_rx_data;
  assign uart_tx_data = spi_rx_data;

  // status
  assign led = state != STATE_CMD;

  // Boot signal
  assign boot = state == STATE_BOOT;

endmodule