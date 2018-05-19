module testbench();
  localparam integer PERIOD = 12000000 / 9600;

  // reg clk = 0;
  // initial #10 forever #5 clk = ~clk;

  reg clk;
  always #5 clk = (clk === 1'b0);

  reg RX = 1;
  wire TX;

  reg tx_valid=0;
  wire tx_ready;
  reg [7:0] tx_data;

  top uut (
    .clk (clk ),
    .uart_rx  (RX  ),
    .uart_tx  (TX  ),

    .spi_si(1'b0)
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

  reg [4095:0] vcdfile;

  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end

    repeat (10 * PERIOD) @(posedge clk);

    // turn all LEDs on
    send_byte(8'h01);
    send_byte("2");
    send_byte("3");
    send_byte("4");
    send_byte("5");

    // turn all LEDs off
    send_byte("1");
    send_byte("2");
    send_byte("3");
    send_byte("4");
    send_byte("5");

    #5
    tx_data = 8'h42;
    tx_valid = 1;
    #10
    tx_valid = 0;
    #300;

    repeat (100 * PERIOD) @(posedge clk);

    $finish;
  end

endmodule