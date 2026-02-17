module top_secure_sensor(
    input clk,
    input rst,
    inout dht_data,
    output uart_tx,
    output data_valid
);

wire [7:0] temp_data;
wire [7:0] cipher_data;
wire [7:0] checksum_data;
wire dht_valid;
wire uart_busy;

reg uart_start;
reg [7:0] uart_data;

// DHT
dht11_receiver dht_inst(
    .clk(clk),
    .rst(rst),
    .dht_data(dht_data),
    .temp_out(temp_data),
    .data_valid(dht_valid)
);

// Encrypt
encryptor_multi enc_inst(
    .data_in(temp_data),
    .cipher_out(cipher_data)
);

// Checksum
checksum_gen chk_inst(
    .plain(temp_data),
    .cipher(cipher_data),
    .checksum(checksum_data)
);

// UART
uart_tx uart_inst(
    .clk(clk),
    .rst(rst),
    .start(uart_start),
    .data(uart_data),
    .tx(uart_tx),
    .busy(uart_busy)
);

assign data_valid = dht_valid;

// Packet FSM
localparam IDLE=0, SEND1=1, SEND2=2;
reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        uart_start <= 0;
    end else begin
        uart_start <= 0;

        case(state)

        IDLE:
            if (dht_valid)
                state <= SEND1;

        SEND1:
            if (!uart_busy) begin
                uart_data <= cipher_data;
                uart_start <= 1;
                state <= SEND2;
            end

        SEND2:
            if (!uart_busy)
                state <= IDLE;

        endcase
    end
end

endmodule
