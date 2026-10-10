# RTL

Prototipe RTL SeBatt dalam SystemVerilog. Nama heketon pada file dan register adalah nama internal blok top-level SeBatt.

## Pemetaan Modul

Proposal memakai nama modul desain. Tabel berikut menunjukkan file RTL yang mengimplementasikannya.

| Modul desain | File RTL | Status |
|---|---|---|
| bus_if | [heketon_axi_ctrl.sv](heketon_axi_ctrl.sv) | Ada. Register AXI4-Lite untuk HPS |
| auth_ctrl | [control_fsm.sv](control_fsm.sv) | Ada. FSM autentikasi, fault pada encoding status yang tidak sah, dan zeroize |
| ro_puf | [ro_puf.sv](ro_puf.sv) | Model perilaku. LFSR deterministik untuk simulasi, belum ring oscillator fisik |
| fuzzy_ext | — | Direncanakan setelah BER PUF fisik diukur |
| key_vault | Register kunci di dalam control_fsm.sv | Sebagian. Kunci dikosongkan oleh zeroize |
| hmac_sha256 | [hmac_sha256.sv](hmac_sha256.sv), [sha256_core.sv](sha256_core.sv) | Ada. Inti SHA-256 iteratif dan wrapper HMAC |
| tamper_mon | — | Direncanakan. Zeroize saat ini dipicu melalui register CONTROL |
| top-level | [heketon_top.sv](heketon_top.sv) | Ada. Menghubungkan seluruh blok di atas |

Untuk keperluan pengujian, prototipe ini membandingkan HMAC hasil hitungan dengan tag yang ditulis ke register EXPECTED_HMAC. Pada desain proposal, chip hanya mengirim respons dan pemeriksaan dilakukan basis data identitas.

## Register Map

| Alamat | Register | Isi |
|---|---|---|
| 0x00 | CONTROL | bit 0 START, bit 1 RESET, bit 2 AUTH_START, bit 3 ZEROIZE |
| 0x04 | STATUS | bit 0 BUSY, bit 1 DONE, bit 2 AUTH_OK, bit 3 ERROR, bit 4 FAULT, bit 5 ZEROIZED |
| 0x10–0x2C | CHALLENGE_0–7 | Tantangan untuk PUF |
| 0x30–0x3C | NONCE_0–3 | Nonce |
| 0x40–0x5C | DATA_0–7 | Data pesan |
| 0x60–0x7C | RESPONSE_0–7 | Keluaran HMAC |
| 0x80–0x9C | EXPECTED_HMAC_0–7 | Tag pembanding (hanya tulis) |

AUTH_OK hanya aktif setelah PUF selesai, HMAC selesai, dan seluruh 256 bit HMAC cocok dengan tag pembanding. Bila tidak cocok, DONE dan ERROR aktif dan register keluaran dikosongkan. ZEROIZE mengosongkan respons PUF, kunci di FSM, state antara HMAC dan SHA-256, register respons, dan register tag.

## Simulasi

Testbench Verilator ada di [sim/](../sim/). Dari folder tersebut jalankan:

```
make test_sha test_puf test_fsm test_hmac test_integration
```
