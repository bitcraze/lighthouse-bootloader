module testbench;
  localparam integer PERIOD = 12000000 / 115200;

  // reg clk = 0;
  // initial #10 forever #5 clk = ~clk;

  localparam I2C_ADDRESS = 7'h2f;
  localparam I2C_READ = 1'b1;
  localparam I2C_WRITE = 1'b0;

  reg clk;
  always #5 clk = (clk === 1'b0);

  reg RX = 1;

  wire sda;
  assign (pull1,highz0)sda = 1;
  reg sda_drive = 1;
  assign (highz1, strong0)sda = sda_drive;

  reg scl = 1;

  top #(
    .CLK_FREQ(12000000),
    .UART_BAUDRATE(115200)  
  ) uut(
    .clk(clk),
    .uart0_rx(RX),
    .spi_si(1'b0),
    .i2c_sda(sda),
    .i2c_scl(scl)
  );

  task send_byte;
    input [7:0] c;
    integer i;
    begin
      RX <= 0;
      repeat (PERIOD) @(posedge clk);

      for (i = 0; i < 8; i = i+1) begin
        RX <= c[i];
        repeat (PERIOD) @(posedge clk);
      end

      RX <= 1;
      repeat (PERIOD) @(posedge clk);
    end
  endtask

  task i2c_start;
    begin
      sda_drive = 0;
      repeat (PERIOD) @(posedge clk);

      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
  endtask

  task i2c_stop;
    begin
      sda_drive = 0;
      repeat (PERIOD) @(posedge clk);

      scl = 1;
      repeat (PERIOD) @(posedge clk);

      sda_drive = 1;
      repeat (PERIOD) @(posedge clk);
    end
  endtask

  task i2c_write;
    input [7:0] data;
    integer i;
    begin
      for (i = 0; i < 8; i = i + 1) begin
        sda_drive = data[7-i];
        repeat (PERIOD) @(posedge clk);
        scl = 1;
        repeat (PERIOD) @(posedge clk);
        repeat (PERIOD) @(posedge clk);
        scl = 0;
        repeat (PERIOD) @(posedge clk);
      end
      sda_drive = 1;
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
  endtask

  task i2c_read;
    integer i;
    begin
      for (i = 0; i < 8; i = i + 1) begin
        sda_drive = 1;
        repeat (PERIOD) @(posedge clk);
        scl = 1;
        repeat (PERIOD) @(posedge clk);
        repeat (PERIOD) @(posedge clk);
        scl = 0;
        repeat (PERIOD) @(posedge clk);
      end
      sda_drive = 0;
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
  endtask

  integer i;

  reg [4095:0] vcdfile;

  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end

    repeat (10 * PERIOD) @(posedge clk);


    // i2c  test (read flash ID)
    i2c_start();
    i2c_write({I2C_ADDRESS, I2C_WRITE});
    
    i2c_write(8'h01);
    i2c_write(8'h02);
    i2c_write(8'h00);
    i2c_write(8'h05);
    i2c_write(8'h02);
    i2c_write(8'h9F);
    i2c_write(8'h00);
    i2c_stop();

    i2c_start();
    i2c_write({I2C_ADDRESS, I2C_READ});

    for (i=0; i < 'h205; i = i + 1) begin
          i2c_read();
    end

    // i2c_read();
    // i2c_read();
    // i2c_read();
    // i2c_read();
    // i2c_read();
    // i2c_stop();


    repeat (10 * PERIOD) @(posedge clk);

    // i2c  test (read flash ID)
    i2c_start();
    i2c_write({I2C_ADDRESS, I2C_WRITE});
    
    i2c_write(8'h01);
    i2c_write(8'h02);
    i2c_write(8'h00);
    i2c_write(8'h05);
    i2c_write(8'h00);
    i2c_write(8'h9F);
    i2c_write(8'h00);
    i2c_stop();

    i2c_start();
    i2c_write({I2C_ADDRESS, I2C_READ});

    i2c_read();
    i2c_read();
    i2c_read();
    i2c_read();
    i2c_read();
    i2c_stop();


    repeat (10 * PERIOD) @(posedge clk);

    // Initialize/enable the UART
    // Break
    RX = 0;
    repeat (19 * PERIOD) @(posedge clk);
    RX = 1;
    repeat (PERIOD) @(posedge clk);
    send_byte(8'hbc);

    // Transfers of 1 tx and 5 rx
    send_byte(8'h01);
    send_byte(8'h02);
    send_byte(8'h00);
    send_byte(8'h05);
    send_byte(8'h00);
    send_byte(8'h9F);
    send_byte(8'h00);

    repeat (100 * PERIOD) @(posedge clk);

    // Aborted transferts then transfers
    send_byte(8'h01);
    send_byte(8'h02);
    send_byte(8'h00);
    // Break
    RX = 0;
    repeat (19 * PERIOD) @(posedge clk);
    RX = 1;
    repeat (PERIOD) @(posedge clk);

    send_byte(8'h01);
    send_byte(8'h02);
    send_byte(8'h00);
    send_byte(8'h05);
    send_byte(8'h00);
    send_byte(8'h9F);
    send_byte(8'h00);

    repeat (100 * PERIOD) @(posedge clk);

    // 1 byte out 0 byte in transfer dirrectly followed by another transfer
    send_byte(8'h01);
    send_byte(8'h01);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h06);

    send_byte(8'h01);
    send_byte(8'h04);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'hD8);
    send_byte(8'h02);
    send_byte(8'h00);
    send_byte(8'h00);

    repeat (100 * PERIOD) @(posedge clk);

    // Receive and do not send
    send_byte(8'h01);
    send_byte(8'h00);
    send_byte(8'h00);
    send_byte(8'h01);
    send_byte(8'h00);

    repeat (100 * PERIOD) @(posedge clk);

    // Boot!
    //send_byte(8'h00);

    repeat (10 * PERIOD) @(posedge clk);


    $finish;
  end

endmodule