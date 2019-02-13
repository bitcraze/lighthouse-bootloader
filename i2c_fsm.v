module i2c_fsm (
    input clk,

    // Bootloader state machine interface
    input bootloader_out_valid,
    input [7:0] bootloader_out_data,
    output bootloader_out_ready,

    output bootloader_in_valid,
    output [7:0] bootloader_in_data,
    input bootloader_in_ready,

    input bootloader_busy,
    output bootloader_reset,

    // I2C slave interface
    input i2c_read_ready,
    output [7:0] i2c_read_data,
    output i2c_read_valid,

    output i2c_write_ready,
    input [7:0] i2c_write_data,
    input i2c_write_valid,

    input i2c_read,
    input i2c_write
);

localparam DEPTH = 128;

// Read buffer, cache data from the boorloader
reg [7:0] buffer[0:DEPTH-1];
reg [6:0] read_ptr = 0;
reg [6:0] write_ptr = 0;

reg i2c_status_read = 0;

// Start of write, resets the bootloader FSM
assign bootloader_reset = i2c_write;

// Connects i2c write directly to bootloader read
assign bootloader_in_valid = i2c_write_valid;
assign bootloader_in_data = i2c_write_data;
assign i2c_write_ready = bootloader_in_ready;

// We are always ready to accept data
assign bootloader_out_ready = 1;

// Data to the I2C: first the status byte then the buffer
assign i2c_read_data = (i2c_status_read==0)?{bootloader_busy, write_ptr}:buffer[read_ptr];
assign i2c_read_valid = 1'b1;

always @(posedge clk) begin
    // I2C should read buffer from the begining
    if (i2c_read) begin
        read_ptr <= 0;
        i2c_status_read <= 0;
    end
    // When I2C writes a new command, the buffer is reset
    if (i2c_write) write_ptr <= 0;

    // Buffering what comes from the bootloader
    if (bootloader_out_valid && bootloader_out_ready) begin
      buffer[write_ptr] <= bootloader_out_data;
      write_ptr <= write_ptr + 1;
    end

    // Reading from I2C
    if (i2c_read_valid && i2c_read_ready) begin
      if (!i2c_status_read) i2c_status_read <= 1;
      else read_ptr <= read_ptr + 1;
    end
end

endmodule