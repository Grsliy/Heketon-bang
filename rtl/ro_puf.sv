`timescale 1ns / 1ps

// Deterministic behavioral model for simulation only.
// This module is not a physical ring-oscillator PUF and provides no measured
// physical uniqueness, entropy, or reliability claims.
module ro_puf (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         start,
    input  logic         zeroize,
    input  logic [255:0] challenge,
    output logic         done,
    output logic [255:0] puf_response
);
    typedef enum logic {IDLE, GENERATE} state_t;
    state_t state;
    logic [31:0] lfsr;
    logic [8:0] bit_count;

    function automatic logic [31:0] challenge_seed(input logic [255:0] challenge_in);
        logic [31:0] seed;
        begin
            seed = 32'h6d2b79f5;
            for (int i = 0; i < 8; i++) begin
                seed = {seed[26:0], seed[31:27]} ^ challenge_in[i*32 +: 32];
                seed = {seed[30:0], seed[31] ^ seed[21] ^ seed[1] ^ seed[0]};
            end
            if (seed == 32'b0) seed = 32'h1;
            challenge_seed = seed;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            puf_response <= 256'b0;
            lfsr <= 32'h1;
            bit_count <= 0;
        end else if (zeroize) begin
            state <= IDLE;
            done <= 1'b0;
            puf_response <= 256'b0;
            lfsr <= 32'h1;
            bit_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        lfsr <= challenge_seed(challenge);
                        puf_response <= 256'b0;
                        bit_count <= 0;
                        state <= GENERATE;
                    end
                end
                GENERATE: begin
                    puf_response <= {puf_response[254:0], lfsr[0]};
                    lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
                    if (bit_count == 9'd255) begin
                        done <= 1'b1;
                        state <= IDLE;
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end
                default: begin
                    state <= IDLE;
                    done <= 1'b0;
                end
            endcase
        end
    end
endmodule
