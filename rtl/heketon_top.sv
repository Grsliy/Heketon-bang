`timescale 1ns / 1ps

module heketon_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
    input  logic                                S_AXI_ACLK,
    input  logic                                S_AXI_ARESETN,

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
    input  logic                                S_AXI_RREADY
);

    logic ctrl_start, ctrl_reset, ctrl_auth_start, ctrl_zeroize;
    logic [31:0] reg_challenge [0:7];
    logic [31:0] reg_nonce     [0:3];
    logic [31:0] reg_data      [0:7];
    logic [31:0] reg_expected  [0:7];
    logic [31:0] reg_response  [0:7];

    logic stat_busy, stat_done, stat_auth_ok, stat_error, stat_fault, stat_zeroized;

    heketon_axi_ctrl #(
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) axi_ctrl_inst (
        .S_AXI_ACLK(S_AXI_ACLK), .S_AXI_ARESETN(S_AXI_ARESETN),
        .S_AXI_AWADDR(S_AXI_AWADDR), .S_AXI_AWPROT(S_AXI_AWPROT), .S_AXI_AWVALID(S_AXI_AWVALID), .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA), .S_AXI_WSTRB(S_AXI_WSTRB), .S_AXI_WVALID(S_AXI_WVALID), .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP), .S_AXI_BVALID(S_AXI_BVALID), .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR), .S_AXI_ARPROT(S_AXI_ARPROT), .S_AXI_ARVALID(S_AXI_ARVALID), .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA), .S_AXI_RRESP(S_AXI_RRESP), .S_AXI_RVALID(S_AXI_RVALID), .S_AXI_RREADY(S_AXI_RREADY),
        .ctrl_start(ctrl_start), .ctrl_reset(ctrl_reset), .ctrl_auth_start(ctrl_auth_start), .ctrl_zeroize(ctrl_zeroize),
        .reg_challenge(reg_challenge), .reg_nonce(reg_nonce), .reg_data(reg_data), .reg_expected(reg_expected),
        .stat_busy(stat_busy), .stat_done(stat_done), .stat_auth_ok(stat_auth_ok),
        .stat_error(stat_error), .stat_fault(stat_fault), .stat_zeroized(stat_zeroized),
        .reg_response(reg_response)
    );

    logic puf_start, puf_done;
    logic [255:0] puf_key;

    logic hmac_start, hmac_ready, hmac_done;
    logic [255:0] hmac_out;
    logic [255:0] hmac_challenge;
    logic [127:0] hmac_nonce;
    logic [255:0] hmac_data;
    logic [255:0] hmac_key;

    control_fsm fsm_inst (
        .clk(S_AXI_ACLK), .rst_n(S_AXI_ARESETN),
        .ctrl_auth_start(ctrl_auth_start), .ctrl_reset(ctrl_reset), .ctrl_zeroize(ctrl_zeroize),
        .stat_busy(stat_busy), .stat_done(stat_done), .stat_auth_ok(stat_auth_ok),
        .stat_error(stat_error), .stat_fault(stat_fault), .stat_zeroized(stat_zeroized),
        .reg_challenge(reg_challenge), .reg_nonce(reg_nonce), .reg_data(reg_data), .reg_expected(reg_expected), .reg_response(reg_response),
        .puf_start(puf_start), .puf_done(puf_done), .puf_key(puf_key),
        .hmac_start(hmac_start), .hmac_done(hmac_done), .hmac_out(hmac_out),
        .hmac_challenge(hmac_challenge), .hmac_nonce(hmac_nonce), .hmac_data(hmac_data), .hmac_key(hmac_key)
    );

    ro_puf puf_inst (
        .clk(S_AXI_ACLK), .rst_n(S_AXI_ARESETN),
        .start(puf_start), .zeroize(ctrl_zeroize), .challenge(hmac_challenge),
        .done(puf_done), .puf_response(puf_key)
    );

    hmac_sha256 hmac_inst (
        .clk(S_AXI_ACLK), .rst_n(S_AXI_ARESETN),
        .start(hmac_start), .zeroize(ctrl_zeroize), .key(hmac_key),
        .challenge(hmac_challenge), .nonce(hmac_nonce), .data(hmac_data),
        .ready(hmac_ready), .done(hmac_done), .hmac_out(hmac_out)
    );

endmodule
