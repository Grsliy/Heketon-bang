`timescale 1ns / 1ps

module heketon_axi_ctrl #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
    // System signals
    input  logic                                S_AXI_ACLK,
    input  logic                                S_AXI_ARESETN,

    // AXI4-Lite Slave Interface
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_AWADDR,
    input  logic [2:0]                          S_AXI_AWPROT,
    input  logic                                S_AXI_AWVALID,
    output logic                                S_AXI_AWREADY,

    input  logic [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_WDATA,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]   S_AXI_WSTRB,
    input  logic                                S_AXI_WVALID,
    output logic                                S_AXI_WREADY,

    output logic [1:0]                          S_AXI_BRESP,
    output logic                                S_AXI_BVALID,
    input  logic                                S_AXI_BREADY,

    input  logic [C_S_AXI_ADDR_WIDTH-1:0]       S_AXI_ARADDR,
    input  logic [2:0]                          S_AXI_ARPROT,
    input  logic                                S_AXI_ARVALID,
    output logic                                S_AXI_ARREADY,

    output logic [C_S_AXI_DATA_WIDTH-1:0]       S_AXI_RDATA,
    output logic [1:0]                          S_AXI_RRESP,
    output logic                                S_AXI_RVALID,
    input  logic                                S_AXI_RREADY,

    // Hardware interface (Outputs to internal logic)
    output logic                                ctrl_start,
    output logic                                ctrl_reset,
    output logic                                ctrl_auth_start,
    output logic                                ctrl_zeroize,

    output logic [31:0]                         reg_challenge [0:7],
    output logic [31:0]                         reg_nonce     [0:3],
    output logic [31:0]                         reg_data      [0:7],
    output logic [31:0]                         reg_expected  [0:7],

    // Hardware interface (Inputs from internal logic)
    input  logic                                stat_busy,
    input  logic                                stat_done,
    input  logic                                stat_auth_ok,
    input  logic                                stat_error,
    input  logic                                stat_fault,
    input  logic                                stat_zeroized,

    input  logic [31:0]                         reg_response  [0:7]
);

    // AXI4-Lite internal signals
    logic aw_en;
    logic axi_awready;
    logic axi_wready;
    logic axi_bvalid;
    logic axi_arready;
    logic axi_rvalid;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00; // OKAY
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = 2'b00; // OKAY
    assign S_AXI_RVALID  = axi_rvalid;

    // Register mapping based on AGENTS.md
    // 0x00 CONTROL
    // 0x04 STATUS
    // 0x10-0x2C CHALLENGE_0-7
    // 0x30-0x3C NONCE_0-3
    // 0x40-0x5C DATA_0-7
    // 0x60-0x7C RESPONSE_0-7
    // 0x80-0x9C EXPECTED_HMAC_0-7 (write-only authentication tag)

    // Write-address latch and acknowledge
    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
                axi_awaddr <= S_AXI_AWADDR;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Write-data latch and acknowledge
    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Write response
    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // Register Write Logic
    logic slv_reg_wren;
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // Pulse registers for CONTROL
    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            ctrl_start <= 1'b0;
            ctrl_reset <= 1'b0;
            ctrl_auth_start <= 1'b0;
            ctrl_zeroize <= 1'b0;
            for (int i=0; i<8; i++) reg_challenge[i] <= 0;
            for (int i=0; i<4; i++) reg_nonce[i] <= 0;
            for (int i=0; i<8; i++) reg_data[i] <= 0;
            for (int i=0; i<8; i++) reg_expected[i] <= 0;
        end else begin
            // Default to 0 for pulses
            ctrl_start <= 1'b0;
            ctrl_reset <= 1'b0;
            ctrl_auth_start <= 1'b0;
            ctrl_zeroize <= 1'b0;

            if (slv_reg_wren && axi_awaddr[7:2] == 6'h00 && S_AXI_WSTRB[0] && S_AXI_WDATA[3])
                for (int i=0; i<8; i++) reg_expected[i] <= 0;

            if (slv_reg_wren) begin
                case (axi_awaddr[7:2])
                    6'h00: begin // 0x00 CONTROL
                        if (S_AXI_WSTRB[0]) begin
                            ctrl_start      <= S_AXI_WDATA[0];
                            ctrl_reset      <= S_AXI_WDATA[1];
                            ctrl_auth_start <= S_AXI_WDATA[2];
                            ctrl_zeroize    <= S_AXI_WDATA[3];
                        end
                    end
                    // 0x10 to 0x2C CHALLENGE
                    6'h04, 6'h05, 6'h06, 6'h07, 6'h08, 6'h09, 6'h0A, 6'h0B: begin
                        if (S_AXI_WSTRB[0]) reg_challenge[axi_awaddr[4:2] ^ 3'b100][7:0]   <= S_AXI_WDATA[7:0];
                        if (S_AXI_WSTRB[1]) reg_challenge[axi_awaddr[4:2] ^ 3'b100][15:8]  <= S_AXI_WDATA[15:8];
                        if (S_AXI_WSTRB[2]) reg_challenge[axi_awaddr[4:2] ^ 3'b100][23:16] <= S_AXI_WDATA[23:16];
                        if (S_AXI_WSTRB[3]) reg_challenge[axi_awaddr[4:2] ^ 3'b100][31:24] <= S_AXI_WDATA[31:24];
                    end
                    // 0x30 to 0x3C NONCE
                    6'h0C, 6'h0D, 6'h0E, 6'h0F: begin
                        if (S_AXI_WSTRB[0]) reg_nonce[axi_awaddr[3:2]][7:0]   <= S_AXI_WDATA[7:0];
                        if (S_AXI_WSTRB[1]) reg_nonce[axi_awaddr[3:2]][15:8]  <= S_AXI_WDATA[15:8];
                        if (S_AXI_WSTRB[2]) reg_nonce[axi_awaddr[3:2]][23:16] <= S_AXI_WDATA[23:16];
                        if (S_AXI_WSTRB[3]) reg_nonce[axi_awaddr[3:2]][31:24] <= S_AXI_WDATA[31:24];
                    end
                    // 0x80 to 0x9C expected HMAC tag (write-only)
                    6'h20, 6'h21, 6'h22, 6'h23, 6'h24, 6'h25, 6'h26, 6'h27: begin
                        if (S_AXI_WSTRB[0]) reg_expected[axi_awaddr[4:2]][7:0]   <= S_AXI_WDATA[7:0];
                        if (S_AXI_WSTRB[1]) reg_expected[axi_awaddr[4:2]][15:8]  <= S_AXI_WDATA[15:8];
                        if (S_AXI_WSTRB[2]) reg_expected[axi_awaddr[4:2]][23:16] <= S_AXI_WDATA[23:16];
                        if (S_AXI_WSTRB[3]) reg_expected[axi_awaddr[4:2]][31:24] <= S_AXI_WDATA[31:24];
                    end
                    // 0x40 to 0x5C DATA
                    6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16, 6'h17: begin
                        if (S_AXI_WSTRB[0]) reg_data[axi_awaddr[4:2]][7:0]   <= S_AXI_WDATA[7:0];
                        if (S_AXI_WSTRB[1]) reg_data[axi_awaddr[4:2]][15:8]  <= S_AXI_WDATA[15:8];
                        if (S_AXI_WSTRB[2]) reg_data[axi_awaddr[4:2]][23:16] <= S_AXI_WDATA[23:16];
                        if (S_AXI_WSTRB[3]) reg_data[axi_awaddr[4:2]][31:24] <= S_AXI_WDATA[31:24];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Read address latch
    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Read valid and data
    logic slv_reg_rden;
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always_ff @(posedge S_AXI_ACLK) begin
        if (~S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rdata  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;

                // Read data multiplexer
                axi_rdata <= 32'h0;
                case (axi_araddr[7:2])
                    6'h00: axi_rdata[3:0] <= {ctrl_zeroize, ctrl_auth_start, ctrl_reset, ctrl_start};
                    6'h01: axi_rdata[5:0] <= {stat_zeroized, stat_fault, stat_error, stat_auth_ok, stat_done, stat_busy};

                    // 0x10 to 0x2C CHALLENGE
                    6'h04, 6'h05, 6'h06, 6'h07, 6'h08, 6'h09, 6'h0A, 6'h0B:
                        axi_rdata <= reg_challenge[axi_araddr[4:2] ^ 3'b100];

                    // 0x30 to 0x3C NONCE
                    6'h0C, 6'h0D, 6'h0E, 6'h0F:
                        axi_rdata <= reg_nonce[axi_araddr[3:2]];

                    // 0x80 to 0x9C expected HMAC tag (write-only)
                    6'h20, 6'h21, 6'h22, 6'h23, 6'h24, 6'h25, 6'h26, 6'h27: begin
                        if (S_AXI_WSTRB[0]) reg_expected[axi_awaddr[4:2]][7:0]   <= S_AXI_WDATA[7:0];
                        if (S_AXI_WSTRB[1]) reg_expected[axi_awaddr[4:2]][15:8]  <= S_AXI_WDATA[15:8];
                        if (S_AXI_WSTRB[2]) reg_expected[axi_awaddr[4:2]][23:16] <= S_AXI_WDATA[23:16];
                        if (S_AXI_WSTRB[3]) reg_expected[axi_awaddr[4:2]][31:24] <= S_AXI_WDATA[31:24];
                    end
                    // 0x40 to 0x5C DATA
                    6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15, 6'h16, 6'h17:
                        axi_rdata <= reg_data[axi_araddr[4:2]];

                    // 0x60 to 0x7C RESPONSE
                    6'h18, 6'h19, 6'h1A, 6'h1B, 6'h1C, 6'h1D, 6'h1E, 6'h1F:
                        axi_rdata <= reg_response[axi_araddr[4:2]];

                    default: axi_rdata <= 32'h0;
                endcase
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
