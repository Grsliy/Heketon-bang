# Simulasi RTL

Testbench C++ dengan Verilator untuk RTL di [rtl/](../rtl/), dibantu skrip Python yang menghitung nilai acuan dengan hashlib dan hmac.

## Prasyarat

Verilator, make, kompilator C++, dan Python 3. Di Windows semuanya tersedia melalui OSS CAD Suite atau WSL.

## Menjalankan

```
make test_sha test_puf test_fsm test_hmac test_integration
```

| Target | File | Yang diuji |
|---|---|---|
| test_sha | tb_sha256.cpp | SHA-256 dengan pesan kosong, "abc", dan "hello" |
| test_puf | tb_puf.cpp | Model PUF perilaku: reset, challenge, dan zeroize |
| test_fsm | tb_control_fsm.cpp | FSM autentikasi: reset, autentikasi gagal, fault, pengulangan, dan START saat BUSY |
| test_hmac | tb_hmac.cpp, test_hmac.py | HMAC RTL dibandingkan dengan RFC 4231 kasus 1 dari Python |
| test_integration | tb_integration.cpp, test_integration.py | Alur lengkap melalui AXI: tag cocok diterima, tag salah ditolak, dan zeroize |

Uji PUF hanya memeriksa model LFSR deterministik, bukan sifat ring oscillator fisik.

## Vektor Uji Emas

Folder [vectors/](vectors/) berisi vektor uji yang dibuat oleh [model/gen_vectors.py](../model/gen_vectors.py).

| File | Isi per baris |
|---|---|
| sha256_blocks.hex | H awal (256 bit), blok (512 bit), H akhir (256 bit), untuk menguji inti kompresi per blok |
| sha256_msgs.txt | Pesan dan digest SHA-256 |
| hmac_auth.hex | K (256 bit), nonce (256 bit), ID (64 bit), respons (256 bit), dengan respons = HMAC(K, nonce \|\| ID) |
| hmac_debug.txt | Nilai antara HMAC untuk melacak kesalahan |

Vektor ini belum dipakai oleh testbench di atas. Penggunaannya direncanakan untuk menguji sha256_core dengan 7 blok dan hmac_sha256 dengan 16 vektor sesuai format pesan nonce || ID.
