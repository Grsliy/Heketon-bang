`timescale 1ns / 1ps

module sha256_core (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         init,
    input  logic         next,
    input  logic [511:0] block,
    output logic         ready,
    output logic [255:0] digest,
    output logic         valid
);

    typedef enum logic [1:0] {IDLE, ROUNDS, FINISH} state_t;
    state_t state;
    logic [5:0] round;

    logic [31:0] a, b, c, d, e, f, g, h;
    logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
    logic [31:0] w [0:15];
    logic [31:0] K [0:63];
    logic [31:0] word_t, t1, t2;

    initial begin
        K[0]=32'h428a2f98; K[1]=32'h71374491; K[2]=32'hb5c0fbcf; K[3]=32'he9b5dba5;
        K[4]=32'h3956c25b; K[5]=32'h59f111f1; K[6]=32'h923f82a4; K[7]=32'hab1c5ed5;
        K[8]=32'hd807aa98; K[9]=32'h12835b01; K[10]=32'h243185be; K[11]=32'h550c7dc3;
        K[12]=32'h72be5d74; K[13]=32'h80deb1fe; K[14]=32'h9bdc06a7; K[15]=32'hc19bf174;
        K[16]=32'he49b69c1; K[17]=32'hefbe4786; K[18]=32'h0fc19dc6; K[19]=32'h240ca1cc;
        K[20]=32'h2de92c6f; K[21]=32'h4a7484aa; K[22]=32'h5cb0a9dc; K[23]=32'h76f988da;
        K[24]=32'h983e5152; K[25]=32'ha831c66d; K[26]=32'hb00327c8; K[27]=32'hbf597fc7;
        K[28]=32'hc6e00bf3; K[29]=32'hd5a79147; K[30]=32'h06ca6351; K[31]=32'h14292967;
        K[32]=32'h27b70a85; K[33]=32'h2e1b2138; K[34]=32'h4d2c6dfc; K[35]=32'h53380d13;
        K[36]=32'h650a7354; K[37]=32'h766a0abb; K[38]=32'h81c2c92e; K[39]=32'h92722c85;
        K[40]=32'ha2bfe8a1; K[41]=32'ha81a664b; K[42]=32'hc24b8b70; K[43]=32'hc76c51a3;
        K[44]=32'hd192e819; K[45]=32'hd6990624; K[46]=32'hf40e3585; K[47]=32'h106aa070;
        K[48]=32'h19a4c116; K[49]=32'h1e376c08; K[50]=32'h2748774c; K[51]=32'h34b0bcb5;
        K[52]=32'h391c0cb3; K[53]=32'h4ed8aa4a; K[54]=32'h5b9cca4f; K[55]=32'h682e6ff3;
        K[56]=32'h748f82ee; K[57]=32'h78a5636f; K[58]=32'h84c87814; K[59]=32'h8cc70208;
        K[60]=32'h90befffa; K[61]=32'ha4506ceb; K[62]=32'hbef9a3f7; K[63]=32'hc67178f2;
    end

    function automatic logic [31:0] rotr(input logic [31:0] val_in, input int shift_in);
        rotr = (val_in >> shift_in) | (val_in << (32 - shift_in));
    endfunction
    function automatic logic [31:0] big_sigma0(input logic [31:0] x_in);
        big_sigma0 = rotr(x_in,2) ^ rotr(x_in,13) ^ rotr(x_in,22);
    endfunction
    function automatic logic [31:0] big_sigma1(input logic [31:0] x_in);
        big_sigma1 = rotr(x_in,6) ^ rotr(x_in,11) ^ rotr(x_in,25);
    endfunction
    function automatic logic [31:0] small_sigma0(input logic [31:0] x_in);
        small_sigma0 = rotr(x_in,7) ^ rotr(x_in,18) ^ (x_in >> 3);
    endfunction
    function automatic logic [31:0] small_sigma1(input logic [31:0] x_in);
        small_sigma1 = rotr(x_in,17) ^ rotr(x_in,19) ^ (x_in >> 10);
    endfunction
    function automatic logic [31:0] choose(input logic [31:0] e_in, input logic [31:0] f_in, input logic [31:0] g_in);
        choose = (e_in & f_in) ^ (~e_in & g_in);
    endfunction
    function automatic logic [31:0] majority(input logic [31:0] a_in, input logic [31:0] b_in, input logic [31:0] c_in);
        majority = (a_in & b_in) ^ (a_in & c_in) ^ (b_in & c_in);
    endfunction

    always_comb begin
        if (round < 16)
            word_t = w[round[3:0]];
        else
            word_t = small_sigma1(w[(round - 2) & 6'h0f]) + w[(round - 7) & 6'h0f]
                   + small_sigma0(w[(round - 15) & 6'h0f]) + w[(round - 16) & 6'h0f];
        t1 = h + big_sigma1(e) + choose(e,f,g) + K[round] + word_t;
        t2 = big_sigma0(a) + majority(a,b,c);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            round <= 0;
            valid <= 1'b0;
            H0 <= 32'h6a09e667; H1 <= 32'hbb67ae85;
            H2 <= 32'h3c6ef372; H3 <= 32'ha54ff53a;
            H4 <= 32'h510e527f; H5 <= 32'h9b05688c;
            H6 <= 32'h1f83d9ab; H7 <= 32'h5be0cd19;
            a <= 0; b <= 0; c <= 0; d <= 0;
            e <= 0; f <= 0; g <= 0; h <= 0;
            for (int i=0; i<16; i++) w[i] <= 0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: if (init || next) begin
                    round <= 0;
                    state <= ROUNDS;
                    if (init) begin
                        H0 <= 32'h6a09e667; H1 <= 32'hbb67ae85;
                        H2 <= 32'h3c6ef372; H3 <= 32'ha54ff53a;
                        H4 <= 32'h510e527f; H5 <= 32'h9b05688c;
                        H6 <= 32'h1f83d9ab; H7 <= 32'h5be0cd19;
                        a <= 32'h6a09e667; b <= 32'hbb67ae85;
                        c <= 32'h3c6ef372; d <= 32'ha54ff53a;
                        e <= 32'h510e527f; f <= 32'h9b05688c;
                        g <= 32'h1f83d9ab; h <= 32'h5be0cd19;
                    end else begin
                        a <= H0; b <= H1; c <= H2; d <= H3;
                        e <= H4; f <= H5; g <= H6; h <= H7;
                    end
                    for (int i=0; i<16; i++) w[i] <= block[511 - 32*i -: 32];
                end
                ROUNDS: begin
                    w[round[3:0]] <= word_t;
                    h <= g; g <= f; f <= e; e <= d + t1;
                    d <= c; c <= b; b <= a; a <= t1 + t2;
                    if (round == 63) state <= FINISH;
                    else round <= round + 1'b1;
                end
                FINISH: begin
                    H0 <= H0 + a; H1 <= H1 + b; H2 <= H2 + c; H3 <= H3 + d;
                    H4 <= H4 + e; H5 <= H5 + f; H6 <= H6 + g; H7 <= H7 + h;
                    state <= IDLE;
                    valid <= 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end

    assign digest = {H0,H1,H2,H3,H4,H5,H6,H7};
    assign ready = (state == IDLE);
endmodule
