#include <verilated.h>
#include "Vro_puf.h"
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

static void tick(Vro_puf& dut) { dut.clk=0; dut.eval(); dut.clk=1; dut.eval(); }
static std::string response_hex(const Vro_puf& dut) {
    std::ostringstream out; out << std::hex << std::setfill('0');
    for (int i=7; i>=0; --i) out << std::setw(8) << dut.puf_response[i];
    return out.str();
}
static std::string query(Vro_puf& dut, uint32_t low_word) {
    for (int i=0; i<8; ++i) dut.challenge[i]=0;
    dut.challenge[0]=low_word;
    dut.start=1; tick(dut); dut.start=0; dut.zeroize=0;
    int cycles=0;
    while (!dut.done && cycles < 260) { tick(dut); ++cycles; }
    if (!dut.done || cycles != 256) {
        std::cerr << "PUF timeout/latency failure: done=" << int(dut.done) << " cycles=" << cycles << "\n";
        return "";
    }
    const std::string response=response_hex(dut);
    tick(dut);
    return response;
}
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vro_puf dut;
    dut.clk=0; dut.rst_n=0; dut.start=0;
    for (int i=0; i<8; ++i) dut.challenge[i]=0;
    tick(dut); tick(dut);
    if (dut.done || response_hex(dut) != std::string(64,'0')) {
        std::cerr << "PUF reset behavior FAIL\n"; return 1;
    }
    dut.rst_n=1; tick(dut);
    const std::string a1=query(dut, 0x12345678u);
    const std::string b=query(dut, 0x12345679u);
    const std::string a2=query(dut, 0x12345678u);
    std::cout << "challenge A response: " << a1 << "\n";
    std::cout << "challenge B response: " << b << "\n";
    if (a1.empty() || a1 != a2) { std::cerr << "same challenge reproducibility FAIL\n"; return 1; }
    if (a1 == b) { std::cerr << "different challenge variation FAIL\n"; return 1; }
    dut.zeroize=1; tick(dut); dut.zeroize=0; tick(dut);
    if (dut.done || response_hex(dut) != std::string(64,'0')) {
        std::cerr << "PUF zeroize behavior FAIL\n"; return 1;
    }
    std::cout << "PUF reset, zeroize, deterministic response, and challenge variation PASS\n";
    return 0;
}
