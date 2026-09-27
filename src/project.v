`timescale 1ns/1ps

module heart_rate_monitor #(
    parameter integer CLOCK_FREQ_HZ = 1000
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       heartbeat,

    output reg [7:0]  bpm,
    output reg [1:0]  status
);

    reg heartbeat_d;

    reg [31:0] clock_counter;
    reg [31:0] last_beat_time;

    reg        first_beat;

    reg [63:0] interval;

    wire heartbeat_rising = heartbeat & ~heartbeat_d;

    wire [31:0] beat_interval = clock_counter - last_beat_time;
    wire [63:0] bpm_calc      = (beat_interval == 32'd0) ? 64'd0 :
                                 (64'd60 * CLOCK_FREQ_HZ) / beat_interval;

    always @(posedge clk) begin

        if (reset) begin
            heartbeat_d    <= 1'b0;
            clock_counter  <= 32'd0;
            last_beat_time <= 32'd0;
            first_beat     <= 1'b1;
            bpm            <= 8'd0;
            status         <= 2'b00;
            interval       <= 64'd0;
        end
        else begin

            heartbeat_d   <= heartbeat;
            clock_counter <= clock_counter + 1'b1;

            if (heartbeat_rising) begin

                if (first_beat) begin
                    first_beat     <= 1'b0;
                    last_beat_time <= clock_counter;
                    status         <= 2'b01;   // Measuring
                end
                else begin
                    last_beat_time <= clock_counter;
                    interval       <= beat_interval;

                    if (bpm_calc >= 64'd30 && bpm_calc <= 64'd200) begin
                        bpm    <= bpm_calc[7:0];
                        status <= 2'b10; // Valid
                    end
                    else begin
                        bpm    <= 8'd0;
                        status <= 2'b11; // Invalid
                    end
                end
            end
        end
    end

endmodule
