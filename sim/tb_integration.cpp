#include <verilated.h>
#include "Vheketon_top.h"
#include "Vheketon_top___024root.h"
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <string>

static void tick(Vheketon_top& d) { d.S_AXI_ACLK=0; d.eval(); d.S_AXI_ACLK=1; d.eval(); }
static void write_reg(Vheketon_top& d, uint8_t addr, uint32_t value) {
    d.S_AXI_AWADDR=addr; d.S_AXI_AWPROT=0; d.S_AXI_AWVALID=1;
    d.S_AXI_WDATA=value; d.S_AXI_WSTRB=0xF; d.S_AXI_WVALID=1; d.S_AXI_BREADY=1;
    tick(d); tick(d);
    d.S_AXI_AWVALID=0; d.S_AXI_WVALID=0;
    tick(d);
}
static uint32_t read_reg(Vheketon_top& d, uint8_t addr) {
    d.S_AXI_ARADDR=addr; d.S_AXI_ARPROT=0; d.S_AXI_ARVALID=1; d.S_AXI_RREADY=0;
    tick(d); tick(d);
    const uint32_t value=d.S_AXI_RDATA;
    d.S_AXI_ARVALID=0; d.S_AXI_RREADY=1; tick(d);
    return value;
}
static uint32_t poll_status(Vheketon_top& d) {
    for(int i=0;i<1500;i++) { tick(d); uint32_t status=read_reg(d,0x04); if(status & 0x2) return status; }
    return read_reg(d,0x04);
}
int main(int argc,char** argv) {
    Verilated::commandArgs(argc,argv);
    if(argc<2) { std::cerr << "expected Python-generated HMAC tag required\n"; return 2; }
    const std::string tag=argv[1];
    if(tag.size()!=64) { std::cerr << "expected 64 hex-character tag\n"; return 2; }
    Vheketon_top d;
    d.S_AXI_ACLK=0; d.S_AXI_ARESETN=0;
    d.S_AXI_AWADDR=0; d.S_AXI_AWPROT=0; d.S_AXI_AWVALID=0;
    d.S_AXI_WDATA=0; d.S_AXI_WSTRB=0; d.S_AXI_WVALID=0; d.S_AXI_BREADY=1;
    d.S_AXI_ARADDR=0; d.S_AXI_ARPROT=0; d.S_AXI_ARVALID=0; d.S_AXI_RREADY=1;
    tick(d); tick(d); d.S_AXI_ARESETN=1; tick(d);

    for(int i=0;i<8;i++) write_reg(d,static_cast<uint8_t>(0x10+4*i),static_cast<uint32_t>(i+1));
    for(int i=0;i<4;i++) write_reg(d,static_cast<uint8_t>(0x30+4*i),static_cast<uint32_t>(0x10+i));
    for(int i=0;i<8;i++) write_reg(d,static_cast<uint8_t>(0x40+4*i),static_cast<uint32_t>(0x20+i));
    for(int i=0;i<8;i++) write_reg(d,static_cast<uint8_t>(0x80+4*i),static_cast<uint32_t>(std::stoul(tag.substr(i*8,8),nullptr,16)));

    write_reg(d,0x00,0x4);
    for(int i=0;i<5;i++) tick(d);
    uint32_t status=poll_status(d);
    std::cout << "success status=0x" << std::hex << status << std::dec << "\n";
    if(!(status&0x2) || !(status&0x4) || (status&0x8)) {
        std::cerr << "actual tag=";
        for(int i=7;i>=0;--i) std::cerr << std::hex << std::setw(8) << std::setfill('0') << d.rootp->heketon_top__DOT__hmac_out[i];
        std::cerr << "\nregs=";
        for(int i=0;i<8;++i) std::cerr << std::hex << d.rootp->heketon_top__DOT__reg_challenge[i] << ",";
        std::cerr << "\nfull RTL valid authentication FAIL\n"; return 1;
    }
    std::cout << "full RTL valid authentication PASS\n";

    // Keep the inputs but replace the expected tag with zero; this must reject.
    for(int i=0;i<8;i++) write_reg(d,static_cast<uint8_t>(0x80+4*i),0);
    write_reg(d,0x00,0x4);
    for(int i=0;i<5;i++) tick(d);
    status=poll_status(d);
    std::cout << "rejection status=0x" << std::hex << status << std::dec << "\n";
    if(!(status&0x2) || (status&0x4) || !(status&0x8)) { std::cerr << "full RTL invalid authentication FAIL\n"; return 1; }
    std::cout << "full RTL invalid authentication PASS\n";

    write_reg(d,0x00,0x8);
    for(int i=0;i<5;i++) tick(d);
    status=read_reg(d,0x04);
    bool secrets_cleared=true;
    for(int i=0;i<8;i++) {
        secrets_cleared &= d.rootp->heketon_top__DOT__puf_key[i]==0;
        secrets_cleared &= d.rootp->heketon_top__DOT__fsm_inst__DOT__internal_key[i]==0;
        secrets_cleared &= d.rootp->heketon_top__DOT__hmac_inst__DOT__inner_hash_reg[i]==0;
        secrets_cleared &= d.rootp->heketon_top__DOT__hmac_out[i]==0;
        secrets_cleared &= d.rootp->heketon_top__DOT__reg_expected[i]==0;
    }
    if(!(status&0x20) || !secrets_cleared) { std::cerr << "full RTL zeroize FAIL status=0x" << std::hex << status << "\n"; return 1; }
    std::cout << "full RTL zeroize clears PUF/FSM/HMAC/tag state PASS status=0x" << std::hex << status << std::dec << "\n";
    return 0;
}
