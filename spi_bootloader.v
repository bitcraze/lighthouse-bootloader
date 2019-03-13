`include "spi.v"

module spi_bootloader #(
  parameter CLK_FREQ = 12000000,
  parameter SPI_FREQ = 4000000
) (
  input clk,

  input reset,

  input data_in_valid,
  input [7:0] data_in,
  output data_in_ready,

  output data_out_valid,
  output [7:0] data_out,
  input data_out_ready,


  input spi_si,
  output spi_so,
  output spi_sck,
  output reg spi_ss,
  output led,

  output busy,
  output boot
);

  // communication ports
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
  localparam STATE_VERSION = 8;

  localparam VERSION = 8'h02;

  reg [3:0] state = STATE_CMD;

  assign busy = state != STATE_CMD;  // Busy when not waiting for a commmand

  reg [15:0] rxLen = 0;
  reg [15:0] txLen = 0;
  reg [15:0] currentLen = 0;

  always @(posedge clk) begin
    spi_ss <= 1;
    // UART break condition is used as a state machine reset
    if (reset) begin
      state <= STATE_CMD;
    end else begin
      case (state)
        STATE_CMD: begin
          if (data_in_valid == 1) begin
            case (data_in)
              0: state <= STATE_BOOT;
              1: state <= STATE_TXLENLOW;
              2: state <= STATE_VERSION;
            endcase 
          end
        end
        STATE_TXLENLOW: begin
          if (data_in_valid == 1) begin
            txLen[7:0] <= data_in;
            state <= STATE_TXLENHIGH;
          end
        end
        STATE_TXLENHIGH: begin
          if (data_in_valid == 1) begin
            txLen[15:8] <= data_in;
            state <= STATE_RXLENLOW;
          end
        end
        STATE_RXLENLOW: begin
          if (data_in_valid == 1) begin
            rxLen[7:0] <= data_in;
            state <= STATE_RXLENHIGH;
          end
        end
        STATE_RXLENHIGH: begin
          if (data_in_valid == 1) begin
            rxLen[15:8] <= data_in;
            if (txLen != 0) state <= STATE_TX;
            else if (rxLen != 0) state <= STATE_RX;
            else state <= STATE_CMD;
            currentLen <= 0;
          end
        end
        STATE_TX: begin
          spi_ss <= 0;
          if (spi_rx_valid) begin
            currentLen <= currentLen + 1;
            if (currentLen == txLen-1) begin
              if (rxLen != 0) state <= STATE_RX;
              else state <= STATE_CMD;
              currentLen <= 0;
            end
          end
        end
        STATE_RX: begin
          spi_ss <= 0;
          if (data_out_ready && data_out_valid) begin
            currentLen <= currentLen + 1;
            if (currentLen == rxLen-1) begin
              state <= STATE_CMD;
              currentLen <= 0;
            end
          end
        end
        STATE_VERSION: begin
          if (data_out_ready && data_out_valid) begin
            state <= STATE_CMD;
          end
        end
      endcase
    end
  end

  // communication flow control
  assign data_in_ready = (state == STATE_TX)?spi_tx_ready:1;
  assign data_out_valid = (state == STATE_RX)?spi_rx_valid:(state == STATE_VERSION)?1:0;

  assign spi_rx_ready = (state == STATE_RX)?data_out_ready:1;
  assign spi_tx_valid = (state == STATE_TX)?data_in_valid:(state == STATE_RX)?1:0;

  assign spi_tx_data = data_in;
  assign data_out = (state == STATE_VERSION)?VERSION:spi_rx_data;

  // status
  assign led = state != STATE_CMD;

  // Boot signal
  assign boot = state == STATE_BOOT;

endmodule