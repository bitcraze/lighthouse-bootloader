module spi #(
    parameter HALF_PERIOD = 10
) (
    input clk,

    output sck,
    output reg so,
    input si,

    input tx_valid,
    input [7:0] tx_data,
    output tx_ready,

    output rx_valid,
    output [7:0] rx_data,
    input rx_ready
);

  reg transfering = 0;
  reg [7:0] shift_register = 0;
  reg [3:0] bit_counter = 0;
  reg [$clog2(3*HALF_PERIOD):0] clock_divider;
  reg phase = 0;

  // Missing: Bit counter and stop. Also need to check bit direction

  initial so = 0;

  always @(posedge clk) begin
    if (!transfering) begin
      if (tx_valid) begin
        transfering <= 1;
        shift_register <= {tx_data[6:0], 1'b0};
        clock_divider <= 0;
        bit_counter <= 0;
        phase <= 0;
        so <= tx_data[7];
      end
    end else begin
      if (bit_counter != 8) begin
        clock_divider <= clock_divider + 1;
        if (clock_divider == HALF_PERIOD-1) begin
          clock_divider <= 0;
          phase <= ~phase;

          if (phase) begin
            if (bit_counter != 7)
              shift_register <= {shift_register[6:0], 1'b0};
            bit_counter <= bit_counter + 1;
            so <= shift_register[7];
          end else begin
            shift_register[0] <= si;
          end
        end 
      end else begin
        if (rx_ready) transfering <= 0;
      end
    end
  end

  assign tx_ready = ~transfering;
  //assign so = transfering?shift_register[7]:0;
  assign sck = phase;

  assign rx_valid = (bit_counter == 8) && transfering;
  assign rx_data = shift_register;
endmodule