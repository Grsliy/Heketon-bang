`timescale 1ns / 1ps

module hmac_sha256 #(parameter integer MESSAGE_BYTES = 80) (
    input  logic         clk,
    input  logic         rst_n,

    input  logic         start,
    input  logic         zeroize,
    input  logic [255:0] key,
    input  logic [255:0] challenge,
    input  logic [127:0] nonce,
    input  logic [255:0] data,

    output logic         ready,
    output logic         done,
    output logic [255:0] hmac_out
);

    typedef enum logic [3:0] {
        IDLE,
        WAIT_CORE_READY,
        INNER_KEY,
        WAIT_INNER_KEY,
        INNER_M1,
        WAIT_INNER_M1,
        INNER_M2_PAD,
        WAIT_INNER_M2,
        OUTER_KEY,
        WAIT_OUTER_KEY,
        OUTER_HASH_PAD,
        WAIT_OUTER_HASH,
        DONE
    } state_t;

    state_t state;

    logic         sha_init;
    logic         sha_next;
    logic [511:0] sha_block;
    logic         sha_ready;
    logic [255:0] sha_digest;
    logic         sha_valid;
    logic         sha_rst_n;
    assign sha_rst_n = rst_n && !zeroize;

    logic [255:0] inner_hash_reg;

    sha256_core sha256_inst (
        .clk(clk),
        .rst_n(sha_rst_n),
        .init(sha_init),
        .next(sha_next),
        .block(sha_block),
        .ready(sha_ready),
        .digest(sha_digest),
        .valid(sha_valid)
    );

    // K ^ ipad = key padded to 512 bits XOR 0x3636...
    logic [511:0] k_ipad;
    assign k_ipad = {key, 256'b0} ^ {16{32'h36363636}};

    // K ^ opad = key padded to 512 bits XOR 0x5c5c...
    logic [511:0] k_opad;
    assign k_opad = {key, 256'b0} ^ {16{32'h5c5c5c5c}};

    // Message M = Challenge (256) || Nonce (128) || Data (256)
    logic [639:0] full_message;
    assign full_message = {challenge, nonce, data};

    function automatic logic [511:0] make_inner_block(
        input logic [639:0] msg_in,
        input integer byte_offset,
        input integer message_bytes
    );
        logic [511:0] result_block;
        integer source_byte;
        begin
            result_block = '0;
            for (int byte_index=0; byte_index<64; byte_index++) begin
                source_byte = byte_offset + byte_index;
                if (source_byte < message_bytes)
                    result_block[511 - byte_index*8 -: 8] = msg_in[639 - source_byte*8 -: 8];
                else if (source_byte == message_bytes)
                    result_block[511 - byte_index*8 -: 8] = 8'h80;
            end
            if (byte_offset + 64 >= message_bytes)
                result_block[63:0] = 64'(512 + message_bytes*8);
            make_inner_block = result_block;
        end
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || zeroize) begin
            state <= IDLE;
            ready <= 1'b1;
            done  <= 1'b0;
            sha_init <= 1'b0;
            sha_next <= 1'b0;
            sha_block <= '0;
            inner_hash_reg <= '0;
            hmac_out <= '0;
        end else begin
            sha_init <= 1'b0;
            sha_next <= 1'b0;

            case(state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        ready <= 1'b0;
                        if (sha_ready) begin
                            state <= INNER_KEY;
                        end else begin
                            state <= WAIT_CORE_READY;
                        end
                    end else begin
                        ready <= 1'b1;
                    end
                end

                WAIT_CORE_READY: begin
                    if (sha_ready) state <= INNER_KEY;
                end

                // --- INNER HASH ---
                INNER_KEY: begin
                    sha_init <= 1'b1;
                    sha_block <= k_ipad;
                    state <= WAIT_INNER_KEY;
                end

                WAIT_INNER_KEY: begin
                    if (sha_ready && sha_valid) state <= INNER_M1;
                end

                INNER_M1: begin
                    sha_next <= 1'b1;
                    sha_block <= make_inner_block(full_message, 0, MESSAGE_BYTES);
                    if (MESSAGE_BYTES <= 64) state <= WAIT_INNER_M2;
                    else state <= WAIT_INNER_M1;
                end

                WAIT_INNER_M1: begin
                    if (sha_ready && sha_valid) state <= INNER_M2_PAD;
                end

                INNER_M2_PAD: begin
                    sha_next <= 1'b1;
                    // Second message block for payloads longer than 64 bytes.
                    sha_block <= make_inner_block(full_message, 64, MESSAGE_BYTES);
                    state <= WAIT_INNER_M2;
                end

                WAIT_INNER_M2: begin
                    if (sha_ready && sha_valid) begin
                        inner_hash_reg <= sha_digest;
                        state <= OUTER_KEY;
                    end
                end

                // --- OUTER HASH ---
                OUTER_KEY: begin
                    sha_init <= 1'b1;
                    sha_block <= k_opad;
                    state <= WAIT_OUTER_KEY;
                end

                WAIT_OUTER_KEY: begin
                    if (sha_ready && sha_valid) state <= OUTER_HASH_PAD;
                end

                OUTER_HASH_PAD: begin
                    sha_next <= 1'b1;
                    // Inner hash (256) + '1' + 0s + 64-bit length
                    // Length = 512 (key) + 256 (hash) = 768 bits = 0x300
                    sha_block <= {inner_hash_reg, 1'b1, 191'b0, 64'h300};
                    state <= WAIT_OUTER_HASH;
                end

                WAIT_OUTER_HASH: begin
                    if (sha_ready && sha_valid) begin
                        hmac_out <= sha_digest;
                        done <= 1'b1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    ready <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
