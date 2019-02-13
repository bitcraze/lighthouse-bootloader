module testbench();

reg clk = 0;
always #10 clk <= !clk;

reg bootloader_out_valid = 0;
reg [7:0] bootloader_out_data = 0;
reg bootloader_busy = 0;
reg i2c_read_ready = 0;
reg i2c_write_valid = 0;
reg [7:0] i2c_write_data = 0;
reg i2c_read = 0;
reg i2c_write = 0;
reg bootloader_in_ready = 1;

i2c_fsm uut (
    .clk(clk),

    .bootloader_out_valid(bootloader_out_valid),
    .bootloader_out_data(bootloader_out_data),

    .bootloader_in_ready(bootloader_in_ready),

    .bootloader_busy(bootloader_busy),

    .i2c_read_ready(i2c_read_ready),

    .i2c_write_valid(i2c_write_valid),
    .i2c_write_data(i2c_write_data),

    .i2c_read(i2c_read),
    .i2c_write(i2c_write)
);

integer i;

reg [4095:0] vcdfile;

initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
    $dumpfile(vcdfile);
    $dumpvars(0, testbench);
    end

    for (i=0; i<2; i++) begin
        // Commands from i2c
        i2c_write = 1;
        #20 i2c_write = 0;
        #20;
        i2c_write_data = 8'h42;
        i2c_write_valid = 1'b1;
        #20 i2c_write_valid = 1'b0;

        // Now buzy
        bootloader_busy = 1;
        #20;

        // Read from I2C
        i2c_read = 1;
        #20 i2c_read = 0;
        i2c_read_ready = 1;
        #20 i2c_read_ready = 0;

        // Some data from the bootloader
        bootloader_out_data = 8'hbc;
        bootloader_out_valid = 1;
        #20 bootloader_out_valid = 0;

        // read from I2C
        i2c_read = 1;
        #20 i2c_read = 0;
        i2c_read_ready = 1;
        #20 i2c_read_ready = 0;

        // bootloader finished
        bootloader_out_data = 8'hcf;
        bootloader_out_valid = 1;
        #20 bootloader_out_valid = 0;

        bootloader_busy = 0;
        #20;

        // Read from I2C
        i2c_read = 1;
        #20 i2c_read = 0;
        i2c_read_ready = 1;
        #20 i2c_read_ready = 0;
        i2c_read_ready = 1;
        #20 i2c_read_ready = 0;
        i2c_read_ready = 1;
        #20 i2c_read_ready = 0;

        #100;
    end

    $finish;
end

endmodule