module top(
    input btn,
    output reg led
);

  always @(posedge btn) led = ~led;

endmodule