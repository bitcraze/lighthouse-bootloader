module testbench;

  localparam PERIOD = 10;

  reg clk;
  always #5 clk = (clk === 1'b0);

  reg sda_i = 1;
  wire sda_o;
  reg scl = 1;

  wire sda;
  assign sda = sda_i & sda_o;

  i2c uut (
    .clk(clk),
    
    .sda_i(sda_i),
    .sda_o(sda_o),
    .scl(scl),

    .write_ready(1'b1),

    .read_data(8'h42),
    .read_valid(1'b1)
  );

  reg [4095:0] vcdfile;

  integer i;
  reg [6:0] slave_address = 7'b0101_111;
  reg [7:0] data = 8'haa;

  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end

    // Generating a simple I2C transaction
    // Start
    repeat (PERIOD) @(posedge clk);
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Address
    for (i = 0; i < 7; i = i + 1) begin
      sda_i = slave_address[6-i];
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end

    // Write
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);


    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Data
    for (i = 0; i < 8; i = i + 1) begin
      sda_i = data[7-i];
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Data
    for (i = 0; i < 8; i = i + 1) begin
      sda_i = ~data[7-i];
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Stop
    repeat (PERIOD) @(posedge clk);
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    sda_i = 1;
    repeat (PERIOD) @(posedge clk);

    // Start
    repeat (PERIOD) @(posedge clk);
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Address
    for (i = 0; i < 7; i = i + 1) begin
      sda_i = slave_address[6-i];
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end

    // read
    sda_i = 1;
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);


    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Data
    for (i = 0; i < 8; i = i + 1) begin
      sda_i = 1;
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Data
    for (i = 0; i < 8; i = i + 1) begin
      sda_i = 1;
      repeat (PERIOD) @(posedge clk);
      scl = 1;
      repeat (PERIOD) @(posedge clk);
      repeat (PERIOD) @(posedge clk);
      scl = 0;
      repeat (PERIOD) @(posedge clk);
    end
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    repeat (PERIOD) @(posedge clk);
    scl = 0;
    repeat (PERIOD) @(posedge clk);

    // Stop
    repeat (PERIOD) @(posedge clk);
    sda_i = 0;
    repeat (PERIOD) @(posedge clk);
    scl = 1;
    repeat (PERIOD) @(posedge clk);
    sda_i = 1;
    repeat (PERIOD) @(posedge clk);


    repeat (10 * PERIOD) @(posedge clk);

    $finish;
  end

endmodule