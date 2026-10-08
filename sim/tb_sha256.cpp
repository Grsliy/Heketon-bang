#include <verilated.h>
#include "Vsha256_core.h"
#include <array>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>

static void tick(Vsha256_core& dut) {
    dut.clk = 0; dut.eval();
    dut.clk = 1; dut.eval();
}

static std::string digest_hex(const Vsha256_core& dut) {
    std::ostringstream out;
    out << std::hex << std::setfill('0');
    for (int i = 7; i >= 0; --i) out << std::setw(8) << dut.digest[i];
    return out.str();
}

static bool run_vector(Vsha256_core& dut, const std::string& name,
                       const std::array<uint32_t, 16>& words,
                       const std::string& expected) {
    for (int i = 0; i < 16; ++i) dut.block[i] = words[15 - i];
    dut.init = 1;
    tick(dut);
    dut.init = 0;

    int cycles = 0;
    while (!dut.valid && cycles < 70) { tick(dut); ++cycles; }
    const std::string actual = digest_hex(dut);
    std::cout << name << " computed: " << actual << "\n";
    std::cout << name << " expected: " << expected << "\n";
    if (!dut.valid || actual != expected) {
        std::cerr << name << " FAIL (valid=" << int(dut.valid) << ", cycles=" << cycles << ")\n";
        return false;
    }
    std::cout << name << " PASS\n";
    tick(dut);
    return true;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vsha256_core dut;
    dut.clk = 0; dut.rst_n = 0; dut.init = 0; dut.next = 0;
    for (int i = 0; i < 16; ++i) dut.block[i] = 0;
    tick(dut); tick(dut);
    dut.rst_n = 1; tick(dut);

    std::array<uint32_t,16> empty{};
    empty[0] = 0x80000000u;
    bool ok = run_vector(dut, "empty", empty,
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");

    std::array<uint32_t,16> abc{};
    abc[0] = 0x61626380u; abc[15] = 24u;
    ok = run_vector(dut, "abc", abc,
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad") && ok;

    std::array<uint32_t,16> hello{};
    hello[0] = 0x68656c6cu; hello[1] = 0x6f800000u; hello[15] = 40u;
    ok = run_vector(dut, "hello", hello,
        "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824") && ok;

    return ok ? 0 : 1;
}
