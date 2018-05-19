module testbench;

  localparam PERIOD = 10;

  reg clk;
  always #5 clk = (clk === 1'b0);

  reg rx_ready = 0;
  wire sloop;

  spi #(.HALF_PERIOD(PERIOD/2)) uut (
    .clk(clk),

    .si(sloop),
    .so(sloop),

    .tx_valid(1),
    .tx_data(8'h01),
    .rx_ready(rx_ready)
  );

  reg [4095:0] vcdfile;

  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end

    repeat (10 * PERIOD) @(posedge clk);
    rx_ready = 1;
    repeat (3 * PERIOD) @(posedge clk);;
    // rx_ready = 0;
    repeat (10 * PERIOD) @(posedge clk);

    $finish;
  end

endmodule