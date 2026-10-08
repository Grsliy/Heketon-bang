`timescale 1ns / 1ps

module control_fsm (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         ctrl_auth_start,
    input  logic         ctrl_reset,
    input  logic         ctrl_zeroize,
    output logic         stat_busy,
    output logic         stat_done,
    output logic         stat_auth_ok,
    output logic         stat_error,
    output logic         stat_fault,
    output logic         stat_zeroized,
    input  logic [31:0]  reg_challenge [0:7],
    input  logic [31:0]  reg_nonce     [0:3],
    input  logic [31:0]  reg_data      [0:7],
    input  logic [31:0]  reg_expected [0:7],
    output logic [31:0]  reg_response [0:7],
    output logic         puf_start,
    input  logic         puf_done,
    input  logic [255:0] puf_key,
    output logic         hmac_start,
    input  logic         hmac_done,
    input  logic [255:0] hmac_out,
    output logic [255:0] hmac_challenge,
    output logic [127:0] hmac_nonce,
    output logic [255:0] hmac_data,
    output logic [255:0] hmac_key
);
    typedef enum logic [3:0] {
        IDLE, PUF_START, PUF_WAIT, HMAC_START, HMAC_WAIT,
        FINISH_AUTH, ZEROIZE_STATE
    } state_t;
    state_t state;
    logic [255:0] internal_key;
    logic [255:0] expected_hmac;

    always_comb begin
        for (int i=0; i<8; i++) begin
            hmac_challenge[i*32 +: 32] = reg_challenge[7-i];
            hmac_data[i*32 +: 32] = reg_data[7-i];
            expected_hmac[i*32 +: 32] = reg_expected[7-i];
        end
        for (int i=0; i<4; i++) hmac_nonce[i*32 +: 32] = reg_nonce[3-i];
    end
    assign hmac_key = internal_key;

    always_ff @(posedge clk) begin
        if (!rst_n || ctrl_reset) begin
            state <= IDLE;
            stat_busy <= 1'b0;
            stat_done <= 1'b0;
            stat_auth_ok <= 1'b0;
            stat_error <= 1'b0;
            stat_fault <= 1'b0;
            stat_zeroized <= 1'b0;
            puf_start <= 1'b0;
            hmac_start <= 1'b0;
            internal_key <= 256'b0;
            for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
        end else if (ctrl_zeroize) begin
            state <= ZEROIZE_STATE;
            internal_key <= 256'b0;
            stat_zeroized <= 1'b1;
            stat_busy <= 1'b1;
            stat_done <= 1'b0;
            stat_auth_ok <= 1'b0;
            puf_start <= 1'b0;
            hmac_start <= 1'b0;
            for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    puf_start <= 1'b0;
                    hmac_start <= 1'b0;
                    if (ctrl_auth_start) begin
                        stat_busy <= 1'b1;
                        stat_done <= 1'b0;
                        stat_auth_ok <= 1'b0;
                        stat_error <= 1'b0;
                        stat_fault <= 1'b0;
                        stat_zeroized <= 1'b0;
                        state <= PUF_START;
                        for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
                    end
                end
                PUF_START: begin
                    puf_start <= 1'b1;
                    state <= PUF_WAIT;
                end
                PUF_WAIT: begin
                    if (puf_done) begin
                        puf_start <= 1'b0;
                        internal_key <= puf_key;
                        state <= HMAC_START;
                    end
                end
                HMAC_START: begin
                    hmac_start <= 1'b1;
                    state <= HMAC_WAIT;
                end
                HMAC_WAIT: begin
                    if (hmac_done) begin
                        hmac_start <= 1'b0;
                        if (hmac_out == expected_hmac) begin
                            for (int i=0; i<8; i++) reg_response[7-i] <= hmac_out[i*32 +: 32];
                            state <= FINISH_AUTH;
                        end else begin
                            stat_done <= 1'b1;
                            stat_busy <= 1'b0;
                            stat_auth_ok <= 1'b0;
                            stat_error <= 1'b1;
                            internal_key <= 256'b0;
                            for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
                            state <= IDLE;
                        end
                    end
                end
                FINISH_AUTH: begin
                    stat_done <= 1'b1;
                    stat_busy <= 1'b0;
                    stat_auth_ok <= 1'b1;
                    internal_key <= 256'b0;
                    state <= IDLE;
                end
                ZEROIZE_STATE: begin
                    stat_busy <= 1'b0;
                    internal_key <= 256'b0;
                    for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
                end
                default: begin
                    // An impossible FSM encoding is treated as a fault and zeroizes state.
                    stat_fault <= 1'b1;
                    stat_error <= 1'b1;
                    stat_done <= 1'b1;
                    stat_auth_ok <= 1'b0;
                    stat_busy <= 1'b0;
                    internal_key <= 256'b0;
                    puf_start <= 1'b0;
                    hmac_start <= 1'b0;
                    for (int i=0; i<8; i++) reg_response[i] <= 32'b0;
                    state <= ZEROIZE_STATE;
                end
            endcase
        end
    end
endmodule
