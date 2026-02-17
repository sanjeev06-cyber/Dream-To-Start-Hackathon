module uart_tx (
    input clk,
    input rst,
    input start,
    input [7:0] data,
    output reg tx,
    output reg busy
);

parameter BAUD_DIV = 10416; // 100MHz / 9600

reg [13:0] baud_cnt;
reg baud_tick;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_cnt <= 0;
        baud_tick <= 0;
    end else begin
        baud_cnt <= (baud_cnt == BAUD_DIV-1) ? 0 : baud_cnt + 1;
        baud_tick <= (baud_cnt == BAUD_DIV-1);
    end
end

reg [3:0] bit_cnt;
reg [9:0] shift_reg;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx <= 1;
        busy <= 0;
        bit_cnt <= 0;
    end else if (start && !busy) begin
        shift_reg <= {1'b1, data, 1'b0};
        busy <= 1;
        bit_cnt <= 0;
    end else if (baud_tick && busy) begin
        tx <= shift_reg[0];
        shift_reg <= shift_reg >> 1;
        bit_cnt <= bit_cnt + 1;
        if (bit_cnt == 9) begin
            busy <= 0;
            tx <= 1;
        end
    end
end

endmodule
