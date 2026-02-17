`timescale 1ns / 1ps

module dht11_receiver (
    input  wire clk,          // 100 MHz
    input  wire rst,
    inout  wire dht_data,
    output reg  [7:0] temp_out,
    output reg  data_valid
);

// ======================================================
// Synchronizer (Prevents metastability)
// ======================================================
reg dht_sync1, dht_sync2;
always @(posedge clk) begin
    dht_sync1 <= dht_data;
    dht_sync2 <= dht_sync1;
end

// ======================================================
// Bidirectional Control
// ======================================================
reg data_out_en;
reg data_out;
assign dht_data = data_out_en ? data_out : 1'bz;

// ======================================================
// Internal Registers
// ======================================================
reg [31:0] counter;
reg [31:0] delay_cnt;
reg [5:0]  bit_count;
reg [39:0] shift_reg;
reg        dht_prev;

// ======================================================
// FSM States
// ======================================================
localparam IDLE        = 3'd0,
           START       = 3'd1,
           WAIT_LOW    = 3'd2,
           WAIT_HIGH   = 3'd3,
           READ_BITS   = 3'd4,
           DONE        = 3'd5;

reg [2:0] state;

// ======================================================
// Timing Parameters (100 MHz Clock)
// ======================================================
localparam ONE_SEC     = 100_000_000;  // 1 second delay
localparam START_COUNT = 1_800_000;    // 18 ms
localparam THRESHOLD   = 4_000;        // 40 us
localparam TIMEOUT     = 10_000_000;   // 100 ms safety

// ======================================================
// FSM
// ======================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= IDLE;
        counter     <= 0;
        delay_cnt   <= 0;
        bit_count   <= 0;
        shift_reg   <= 0;
        temp_out    <= 0;
        data_valid  <= 0;
        data_out_en <= 0;
        data_out    <= 1'b1;
        dht_prev    <= 1'b1;
    end
    else begin
        case (state)

        // ------------------------------------------
        // Wait 1 second between reads
        // ------------------------------------------
        IDLE: begin
            data_valid <= 0;
            if (delay_cnt < ONE_SEC)
                delay_cnt <= delay_cnt + 1;
            else begin
                delay_cnt <= 0;
                counter   <= 0;
                state     <= START;
            end
        end

        // ------------------------------------------
        // Send start signal (18ms LOW)
        // ------------------------------------------
        START: begin
            data_out_en <= 1;
            data_out    <= 0;

            if (counter < START_COUNT)
                counter <= counter + 1;
            else begin
                counter     <= 0;
                data_out_en <= 0;
                state       <= WAIT_LOW;
            end
        end

        // ------------------------------------------
        // Wait for sensor response LOW
        // ------------------------------------------
        WAIT_LOW: begin
            counter <= counter + 1;

            if (dht_sync2 == 0) begin
                counter <= 0;
                state   <= WAIT_HIGH;
            end
            else if (counter > TIMEOUT)
                state <= IDLE;
        end

        // ------------------------------------------
        // Wait for sensor response HIGH
        // ------------------------------------------
        WAIT_HIGH: begin
            counter <= counter + 1;

            if (dht_sync2 == 1) begin
                counter   <= 0;
                bit_count <= 0;
                state     <= READ_BITS;
            end
            else if (counter > TIMEOUT)
                state <= IDLE;
        end

        // ------------------------------------------
        // Read 40 bits
        // ------------------------------------------
        READ_BITS: begin
            dht_prev <= dht_sync2;
            counter  <= counter + 1;

            // Rising edge → reset counter
            if (dht_prev == 0 && dht_sync2 == 1)
                counter <= 0;

            // Falling edge → decide 0 or 1
            if (dht_prev == 1 && dht_sync2 == 0) begin
                shift_reg <= {shift_reg[38:0],
                              (counter > THRESHOLD)};
                bit_count <= bit_count + 1;
                counter   <= 0;

                if (bit_count == 39)
                    state <= DONE;
            end
        end

        // ------------------------------------------
        // Data ready
        // ------------------------------------------
        DONE: begin
            temp_out   <= shift_reg[23:16];  // Temperature integer
            data_valid <= 1'b1;
            state      <= IDLE;
        end

        default:
            state <= IDLE;

        endcase
    end
end

endmodule
