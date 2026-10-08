#include <verilated.h>
#include "Vcontrol_fsm.h"
#include "Vcontrol_fsm___024root.h"
#include <cstdint>
#include <iostream>
#include <string>

static void tick(Vcontrol_fsm& d) { d.clk=0; d.eval(); d.clk=1; d.eval(); }
static void reset(Vcontrol_fsm& d) {
    d.rst_n=0; d.ctrl_reset=0; d.ctrl_auth_start=0; d.ctrl_zeroize=0;
    d.puf_done=0; d.hmac_done=0; for (int i=0;i<8;i++) { d.puf_key[i]=0; d.hmac_out[i]=0; } d.puf_key[0]=0x12345678;
    for (int i=0;i<8;i++) { d.reg_challenge[i]=0; d.reg_data[i]=0; d.reg_expected[i]=0; }
    for (int i=0;i<4;i++) d.reg_nonce[i]=0;
    tick(d); tick(d); d.rst_n=1; tick(d);
}
static bool key_is_zero(const Vcontrol_fsm& d) { for (int i=0;i<8;i++) if (d.hmac_key[i]) return false; return true; }
static uint32_t fake_hmac(const Vcontrol_fsm& d) {
    uint32_t v=0x811c9dc5u;
    for (int i=0;i<8;i++) { v=(v^d.reg_challenge[i])*16777619u; v=(v^d.reg_data[i])*16777619u; }
    for (int i=0;i<4;i++) v=(v^d.reg_nonce[i])*16777619u;
    v^=static_cast<uint32_t>(d.puf_key[0]);
    return v ? v : 1u;
}
static void set_tag(Vcontrol_fsm& d, uint32_t tag) {
    for (int i=0;i<8;i++) d.reg_expected[i]=(i==7)?tag:0;
}
static bool authenticate(Vcontrol_fsm& d, bool busy_start=false) {
    d.ctrl_auth_start=1; tick(d); d.ctrl_auth_start=0;
    if (!d.stat_busy || d.stat_auth_ok) return false;
    if (busy_start) { d.ctrl_auth_start=1; tick(d); d.ctrl_auth_start=0; }
    int n=0; while (!d.puf_start && n++<10) tick(d);
    if (!d.puf_start) return false;
    d.puf_done=1; tick(d); d.puf_done=0;
    n=0; while (!d.hmac_start && n++<10) tick(d);
    if (!d.hmac_start) return false;
    d.hmac_out[0]=d.hmac_out[0]; // retain the driven test digest
    d.hmac_done=1; tick(d); d.hmac_done=0;
    n=0; while (!d.stat_done && n++<10) tick(d);
    return d.stat_done;
}
static bool check_auth(Vcontrol_fsm& d, uint32_t tag, bool expect_ok, const std::string& label, bool busy_start=false) {
    set_tag(d,tag);
    for (int i=0;i<8;i++) d.hmac_out[i]=0;
    // The fake digest is also placed in the low word so expected-tag equality is exercised.
    const uint32_t output=fake_hmac(d);
    d.hmac_out[0]=output;
    set_tag(d, expect_ok ? output : tag);
    const bool completed=authenticate(d,busy_start);
    const bool pass=completed && (bool(d.stat_auth_ok)==expect_ok) && (bool(d.stat_error)!=expect_ok);
    std::cout << label << (pass ? " PASS\n" : " FAIL\n");
    return pass;
}
int main(int argc,char** argv) {
    Verilated::commandArgs(argc,argv);
    Vcontrol_fsm d; d.clk=0; reset(d);
    bool ok=true;
    ok &= !d.stat_busy && !d.stat_done && !d.stat_auth_ok;
    std::cout << "reset safe IDLE " << (ok?"PASS":"FAIL") << "\n";

    // Baseline data, expected digest is derived from the complete presented input.
    d.reg_challenge[0]=0x11; d.reg_nonce[0]=0x22; d.reg_data[0]=0x33;
    uint32_t valid_tag=fake_hmac(d);
    ok &= check_auth(d,valid_tag,true,"valid authentication");

    reset(d); d.reg_challenge[0]=0x11; d.reg_nonce[0]=0x22; d.reg_data[0]=0x33; valid_tag=fake_hmac(d);
    d.reg_challenge[0]^=1;
    ok &= check_auth(d,valid_tag,false,"wrong challenge");
    reset(d); d.reg_challenge[0]=0x11; d.reg_nonce[0]=0x22; d.reg_data[0]=0x33; valid_tag=fake_hmac(d);
    d.reg_nonce[0]^=1;
    ok &= check_auth(d,valid_tag,false,"wrong nonce");
    reset(d); d.reg_challenge[0]=0x11; d.reg_nonce[0]=0x22; d.reg_data[0]=0x33; valid_tag=fake_hmac(d);
    d.reg_data[0]^=1;
    ok &= check_auth(d,valid_tag,false,"wrong data");

    reset(d); d.rootp->control_fsm__DOT__state=15; tick(d);
    ok &= d.stat_fault && !d.stat_auth_ok;
    std::cout << "illegal-state fault " << ((d.stat_fault && !d.stat_auth_ok)?"PASS":"FAIL") << "\n";

    reset(d); d.reg_challenge[0]=1; d.reg_nonce[0]=2; d.reg_data[0]=3;
    uint32_t ztag=fake_hmac(d); set_tag(d,ztag); d.hmac_out[0]=ztag;
    d.ctrl_auth_start=1; tick(d); d.ctrl_auth_start=0;
    for(int i=0;i<3;i++) tick(d);
    d.ctrl_zeroize=1; tick(d); d.ctrl_zeroize=0; tick(d);
    ok &= d.stat_zeroized && key_is_zero(d) && !d.stat_auth_ok;
    std::cout << "zeroization clears key/status " << ((d.stat_zeroized && key_is_zero(d) && !d.stat_auth_ok)?"PASS":"FAIL") << "\n";

    reset(d); d.reg_challenge[0]=1; d.reg_nonce[0]=2; d.reg_data[0]=3;
    d.ctrl_auth_start=1; tick(d); d.ctrl_auth_start=0; tick(d); tick(d);
    d.ctrl_reset=1; tick(d); d.ctrl_reset=0;
    ok &= !d.stat_busy && !d.stat_auth_ok && key_is_zero(d);
    std::cout << "reset during authentication " << ((!d.stat_busy && !d.stat_auth_ok && key_is_zero(d))?"PASS":"FAIL") << "\n";

    reset(d); d.reg_challenge[0]=0x44; d.reg_nonce[0]=0x55; d.reg_data[0]=0x66;
    valid_tag=fake_hmac(d);
    ok &= check_auth(d,valid_tag,true,"repeated authentication 1");
    ok &= check_auth(d,valid_tag,true,"repeated authentication 2");
    reset(d); d.reg_challenge[0]=0x77; d.reg_nonce[0]=0x88; d.reg_data[0]=0x99;
    valid_tag=fake_hmac(d);
    ok &= check_auth(d,valid_tag,true,"START while BUSY ignored",true);
    return ok ? 0 : 1;
}
