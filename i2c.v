module i2c #(
    parameter SLAVE_ADDRESS = 7'b0101_111
  ) (
    input clk,

    input sda_i,
    output reg sda_o,
    input scl,

    // state flags, says up for one clock only
    output reg start,
    output reg stop,
    output reg read,
    output reg write,

    // Data transfers
    input read_valid,
    input [7:0] read_data,
    output reg read_ready,

    output reg write_valid,
    output [7:0] write_data,
    input write_ready
);

  initial sda_o = 1;
  initial write_valid = 0;
  initial read_ready = 0;

  localparam IDLE = 0;
  localparam ADDRESS = 1;
  localparam ADDRESS_ACK = 2;
  localparam READ = 3;
  localparam WRITE = 5;

  reg [2:0] state = IDLE;
  reg [3:0] bitCounter = 0;
  reg [6:0] slave_address = SLAVE_ADDRESS;
  reg rw = 0;

  reg [7:0] buffer = 8'h55;
  assign write_data = buffer;

  reg prev_sda = 1;
  reg prev_scl = 1;

  // Edge detection
  assign rising_sda = !prev_sda && sda_i;
  assign falling_sda = prev_sda && !sda_i;
  assign rising_scl = !prev_scl && scl;

  always @(posedge clk) begin
    prev_sda <= sda_i;
    prev_scl <= scl;

    start <= 0;
    stop <= 0;
    read <= 0;
    write <= 0;

    // Stateless cases
    // Start
    if (falling_sda && scl) begin
      state <= ADDRESS;
      bitCounter <= 0;
      start <= 1;
    end
    // Stop
    if (rising_sda && scl) begin
      state <= IDLE;
      stop <= 1;
    end

    // Clocked cases
    if (rising_scl) begin
      case (state)
        ADDRESS: begin
          bitCounter <= bitCounter + 1;
          if (bitCounter != 7 && sda_i != slave_address[6-bitCounter]) state <= IDLE;
          else if (bitCounter == 7) begin
            rw <= sda_i;
            if (rw) read <= 1;
            else write <= 1;
          end else if (bitCounter == 8) begin
            if (rw) begin
              state <= READ;
              read_ready <= 1;
            end else begin
              state <= WRITE;
            end
            bitCounter <= 0;
          end
        end
        READ: begin
          bitCounter <= bitCounter + 1;
          if (bitCounter == 8) begin
            bitCounter <= 0;
            if (sda_i) state <= IDLE;
            else read_ready <= 1;
          end
        end
        WRITE: begin
          bitCounter <= bitCounter + 1;
          if (bitCounter == 8) begin
            bitCounter <= 0;
            write_valid <= 1;
          end else begin
            buffer[7-bitCounter] <= sda_i;
          end
        end
        
      endcase
    end

    // Data out
    if (scl == 0) begin
      if (bitCounter == 8 && (state == ADDRESS || state == WRITE)) sda_o <= 0;
      else if (bitCounter < 8 && state == READ) sda_o <= buffer[7-bitCounter];
      else sda_o <= 1;
    end


    // Pipe management
    if (write_valid && write_ready) write_valid <= 0;
    if (read_valid && read_ready) begin
      buffer <= read_data;
      read_ready <= 0;
    end
  end

endmodule