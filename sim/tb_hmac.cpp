#include <verilated.h>
#include "Vhmac_sha256.h"
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

static void tick(Vhmac_sha256& d) { d.clk=0; d.eval(); d.clk=1; d.eval(); }
static std::string digest_hex(const Vhmac_sha256& d) {
    std::ostringstream out; out << std::hex << std::setfill('0');
    for (int i=7;i>=0;--i) out << std::setw(8) << d.hmac_out[i];
    return out.str();
}
int main(int argc,char** argv) {
    Verilated::commandArgs(argc,argv);
    if (argc < 2) { std::cerr << "expected digest argument required\n"; return 2; }
    const std::string expected=argv[1];
    Vhmac_sha256 d;
    d.clk=0; d.rst_n=0; d.start=0; d.zeroize=0;
    for(int i=0;i<8;i++) { d.key[i]=0; d.challenge[i]=0; d.data[i]=0; }
    for(int i=0;i<4;i++) d.nonce[i]=0;
    // RFC 4231 test case 1: key = 20 bytes of 0x0b, message = "Hi There".
    for(int i=7;i>=3;i--) d.key[i]=0x0b0b0b0bu;
    d.challenge[7]=0x48692054u; // "Hi T"
    d.challenge[6]=0x68657265u; // "here"
    tick(d); tick(d); d.rst_n=1; tick(d);
    d.start=1; tick(d); d.start=0;
    int cycles=0;
    while(!d.done && cycles<500) { tick(d); ++cycles; }
    const std::string actual=digest_hex(d);
    std::cout << "RTL HMAC:    " << actual << "\n";
    std::cout << "Python HMAC: " << expected << "\n";
    std::cout << "cycles: " << cycles << "\n";
    if(!d.done || actual!=expected) { std::cerr << "HMAC RTL FAIL\n"; return 1; }
    std::cout << "RFC 4231 HMAC RTL PASS\n";
    return 0;
}
