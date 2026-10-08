# Milestone Proyek

Rencana kerja dari pendaftaran sampai final. Centang `[x]` setiap tugas yang selesai dan isi kolom PIC (penanggung jawab).

**Peran yang dipakai di bawah:**
- **RTL**: perancang Verilog (Muqtada)
- **VER**: verifikasi (cocotb, model Python)
- **SEC**: analis keamanan, uji serangan (Guntur)
- **SYS**: sistem, bisnis, dan dokumen (Dimas)

| # | Milestone | Tenggat | Hasil akhir |
|---|---|---|---|
| M0 | Persiapan & registrasi | 7 Okt | Tim terdaftar, repo aktif |
| M1 | Proposal terkirim | 8 Okt, 23.59 | PDF proposal, Bab 1–5 maksimal 6 halaman |
| M2 | Fondasi teknis | 12 Okt | HMAC kunci tetap lolos simulasi dan jalan di FPGA tim melalui UART |
| M3 | Pengumuman Top 5 | 13 Okt | Keputusan lanjut |
| M4 | Integrasi pra-bootcamp | 17 Okt | PUF + fuzzy extractor + tamper jalan, siap dipindah ke DE10-Nano |
| M5 | Bootcamp | 18–20 Okt | Demo lengkap di DE10-Nano, metrik R1–R5 terukur |
| M6 | Final & presentasi | 21–22 Okt | Pitch, demo live, video cadangan |

Prinsip urutan kerja: **jalur kritis dulu**. Demo dengan kunci tetap (tanpa PUF) harus sudah jalan sebelum PUF dikerjakan, sehingga selalu ada demo yang dapat ditunjukkan.

---

## M0 — Persiapan & registrasi (7 Okt)

| Tugas | PIC | Selesai |
|---|---|---|
| Tim dan dosen pembimbing lengkap | SYS | [x] |
| Repo GitHub aktif tanpa kontributor Claude | SYS | [x] |
| Isi formulir registrasi | SYS | [ ] |
| Tanyakan ke panitia: format file, board yang disediakan, boleh tidaknya kode disiapkan sebelum bootcamp, rubrik penilaian | SYS | [ ] |

## M1 — Proposal terkirim (8 Okt, 23.59)

| Tugas | PIC | Selesai |
|---|---|---|
| Executive Summary, Problem Statement, Proposed Chip, Technical Design, Security Design | Semua | [x] |
| Bab 1–5 pas 6 halaman | SYS | [x] |
| Isi nama tim di cover (sama persis dengan formulir pendaftaran) | SYS | [ ] |
| Putuskan tautan GitHub di lampiran: cantumkan (repo publik) atau hapus | SYS | [ ] |
| Pilih angka kapasitas register DE10-Nano di Tabel 1 (template 415.000 atau Intel 166.036) | RTL | [ ] |
| Cek judul datasheet bq26100 dan DS28E38 di situs vendor | SEC | [ ] |
| Baca ulang sekali dari cover sampai lampiran | Semua | [ ] |
| Kirim PDF dan simpan bukti pengiriman | SYS | [ ] |

## M2 — Fondasi teknis (9–12 Okt)

Jangan menunggu pengumuman Top 5. Semua pekerjaan memakai board milik tim (Artix-7 dan Cmod S7) dengan PC sebagai stasiun dan basis data melalui UART. RTL ditulis netral vendor agar mudah dipindah ke Quartus.

| Tugas | PIC | Selesai |
|---|---|---|
| Model Python: HMAC(K, nonce ‖ ID), basis data identitas, dan stasiun | VER | [ ] |
| SHA-256 lolos simulasi dengan vektor uji FIPS 180-4 | RTL, VER | [ ] |
| Wrapper HMAC lolos vektor uji RFC 4231 | RTL, VER | [ ] |
| `bus_if` (UART untuk prototipe) dan `auth_ctrl` (`GET_ID`, `AUTH`, `STATUS`, pembatas laju) | RTL | [ ] |
| Demo jalur kritis di Artix-7: kunci tetap, PC mengirim *nonce*, respons dicek model Python | RTL, VER | [ ] |
| Uji *replay*: *nonce* lama ditolak basis data | SEC | [ ] |

## M3 — Pengumuman Top 5 (13 Okt)

- [ ] Kalau lolos, lanjut ke M4.
- [ ] Kalau tidak lolos, rapikan repo sebagai portofolio dan tulis catatan pembelajaran.

## M4 — Integrasi pra-bootcamp (13–17 Okt)

| Tugas | PIC | Selesai |
|---|---|---|
| `ro_puf`: baca bit mentah, ukur *bit error rate* (BER) pada beberapa lokasi dan dua board | RTL, SEC | [ ] |
| Tentukan parameter `fuzzy_ext` (jumlah pembacaan, panjang kode) dari BER terukur | SEC | [ ] |
| `fuzzy_ext` + penurunan kunci K = SHA-256(bit stabil ‖ *helper data*), kunci sama ≥1.000 kali (R1) | RTL, VER | [ ] |
| `key_vault`: kunci dihapus setelah respons, tidak terbaca dari bus | RTL | [ ] |
| `tamper_mon`: monitor clock dan pin sakelar casing → hapus kunci dan *lock* (R4) | RTL, SEC | [ ] |
| Dua *bitstream*: pabrik (dengan `ENROLL`) dan lapangan (tanpa jalur ekspor kunci) | RTL | [ ] |
| Skenario basis data: riwayat dari hasil ukur stasiun, ID terkunci diblokir (R3) | VER | [ ] |
| Simulasi top-level lengkap dengan cocotb | VER | [ ] |
| Siapkan proyek Quartus untuk DE10-Nano (port `bus_if` ke AXI-Lite, emulasi di HPS) | RTL | [ ] |
| **Rencana cadangan:** mode kunci tetap bila PUF belum stabil (disampaikan terbuka) | RTL | [ ] |
| Draf slide presentasi | SYS | [ ] |

## M5 — Bootcamp (18–20 Okt)

| Hari | Fokus | Hasil |
|---|---|---|
| 1 | Pindah ke DE10-Nano, jalur kritis kunci tetap | Demo dasar stabil di board resmi |
| 2 | PUF dan metrik | Hamming distance antar-lokasi dan reliabilitas (R1), latensi <50 ms (R2), resource dan Fmax (R5) |
| 3 | Serangan dan finalisasi | Demo kloning ditolak, *replay* ditolak, *glitch* clock dan casing memicu *lock*; video demo, repo rapi |

- [ ] Hari 1 selesai
- [ ] Hari 2 selesai
- [ ] Hari 3 selesai

## M6 — Final & presentasi (21–22 Okt)

| Tugas | PIC | Selesai |
|---|---|---|
| Pitch deck: masalah → solusi → demo → metrik → peran pihak tepercaya → rencana ASIC | SYS | [ ] |
| Daftar jawaban tanya-jawab: beda dengan DS28E38 dan OPTIGA, risiko HSM dan rencana ECC, PUF terhadap suhu, side-channel, biaya per chip | SEC, SYS | [ ] |
| Gladi presentasi minimal 2 kali, dengan waktu dihitung | Semua | [ ] |
| Video demo cadangan, untuk berjaga kalau board bermasalah saat live | VER | [ ] |
| Board, kabel, dan laptop dicek H-1 | RTL | [ ] |
