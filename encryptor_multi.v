module encryptor_multi (
    input  [7:0] data_in,
    output [7:0] cipher_out
);

parameter KEY1 = 8'hA5;
parameter KEY2 = 8'h3C;

wire [7:0] s1, s2, s3, rot;

assign s1 = data_in ^ KEY1;
assign s2 = {s1[6:0], s1[7]} ^ 8'h5A;
assign s3 = {s2[2], s2[5], s2[7], s2[1],
             s2[3], s2[0], s2[6], s2[4]};
assign rot = {s3[4:0], s3[7:5]};
assign cipher_out = rot + KEY2;

endmodule
