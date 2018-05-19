module testbench;
  localparam integer PERIOD = 12000000 / 9600;

  // reg clk = 0;
  // initial #10 forever #5 clk = ~clk;

  reg clk;
  always #5 clk = (clk === 1'b0);

  reg RX = 1;

  uart_bootloader uut(
    .clk(clk),
    .uart_rx(RX),
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

    // Transfers of 1 tx and 5 rx
    send_byte(8'h01);
    send_byte(8'h02);
    send_byte(8'h00);
    send_byte(8'h05);
    send_byte(8'h00);
    send_byte(8'h9F);
    send_byte(8'h00);

    repeat (100 * PERIOD) @(posedge clk);

    $finish;
  end

endmodule