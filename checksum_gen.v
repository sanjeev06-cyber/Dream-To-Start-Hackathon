module checksum_gen (
    input  [7:0] plain,
    input  [7:0] cipher,
    output [7:0] checksum
);

assign checksum = plain ^ cipher;

endmodule
