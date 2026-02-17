`timescale 1ns / 1ps

module tb_top_secure_sensor;

reg clk;
reg rst;
wire dht_data;
wire uart_tx;

// Simulated DHT line control
reg dht_drive;
reg dht_value;

assign dht_data = dht_drive ? dht_value : 1'bz;

// Instantiate DUT
top_secure_sensor uut (
    .clk(clk),
    .rst(rst),
    .dht_data(dht_data),
    .uart_tx(uart_tx)
);

// Clock generation (100MHz -> 10ns)
always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    dht_drive = 0;
    dht_value = 1;

    #50;
    rst = 0;

    // Wait for START pulse from FPGA
    wait(dht_data == 0);

    // Simulate DHT11 response
    #100;
    send_dht_byte(8'd0);     // Humidity int
    send_dht_byte(8'd0);     // Humidity dec
    send_dht_byte(8'd25);    // Temp int (25°C)
    send_dht_byte(8'd0);     // Temp dec
    send_dht_byte(8'd25);    // Checksum

    #1000;
    $stop;
end

// -----------------------------
// Task to send one byte
// -----------------------------
task send_dht_byte;
    input [7:0] data;
    integer i;
    begin
        for (i=7; i>=0; i=i-1) begin
            // LOW start
            dht_drive = 1;
            dht_value = 0;
            #20;

            // HIGH pulse
            dht_value = 1;
            if (data[i])
                #50;   // long pulse = 1
            else
                #20;   // short pulse = 0

            dht_drive = 0;
            #20;
        end
    end
endtask

endmodule
