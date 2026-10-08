# Secure Battery Identity Chip

Chip keamanan kecil di dalam setiap baterai motor listrik untuk membuktikan bahwa baterai tersebut asli, setiap kali ditukar di stasiun penukaran baterai (SPBKLU).

Hackathon Chip 2026 · Topik 1: Secure Identity & Security Element Chip · Universitas Gadjah Mada

## Ringkasan

Di stasiun tukar baterai, pengendara menyerahkan baterai kosong dan menerima baterai penuh milik operator. Baterai yang sama berpindah dari satu pengendara ke pengendara lain, tetapi stasiun hanya dapat membaca data yang dilaporkan baterai itu sendiri. Baterai palsu dapat lolos ke jaringan. Jumlah siklus pemakaian juga dapat diputar mundur seperti odometer mobil bekas.

Proyek ini merancang chip yang ditanam di setiap baterai. Chip membaca "sidik jari" silikonnya sendiri (Ring-Oscillator PUF), menurunkan kunci dari sidik jari itu hanya saat dibutuhkan, lalu menjawab angka acak sekali pakai (nonce) dari basis data identitas dengan HMAC-SHA-256. Kunci tidak disimpan di chip, sehingga tidak ada yang dapat dibaca atau disalin. Bila casing dibuka atau clock diganggu, kunci dihapus dan chip terkunci.

Pembagian perannya tegas. Chip membuktikan identitas, stasiun mengukur kondisi sel, dan basis data identitas milik pihak tepercaya menyimpan riwayat serta memutuskan.

## Cara Kerja

![Alur autentikasi baterai di stasiun penukaran: basis data identitas mengirim nonce melalui stasiun, chip menjawab dengan respons HMAC, lalu basis data memutuskan diterima atau ditolak](docs/alur-autentikasi.png)

| Serangan | Cara ditolak |
|---|---|
| Menyalin chip atau firmware asli | Kunci berasal dari PUF dan tidak tersimpan di chip |
| Mengirim ulang respons lama | Setiap nonce hanya berlaku sekali |
| Memutar mundur jumlah siklus di BMS | Riwayat diambil dari pengukuran stasiun, bukan dari BMS |
| Membongkar casing atau mengganggu clock | Kunci dihapus, chip terkunci, ID diblokir basis data |

## Arsitektur Chip

| Modul | Tugas |
|---|---|
| bus_if | Antarmuka ke host (AXI-Lite di FPGA, I²C di ASIC) |
| auth_ctrl | Mengatur urutan perintah dan membatasi laju autentikasi |
| ro_puf | Membaca sidik jari silikon dari 1.024 ring oscillator |
| fuzzy_ext | Membuat bit PUF stabil sebelum dijadikan kunci |
| key_vault | Menyimpan kunci hanya selama respons dihitung |
| hmac_sha256 | Menghitung respons, berbasis inti SHA-256 dari Tiny Tapeout 07 |
| tamper_mon | Memantau clock dan sakelar casing, lalu memicu penghapusan kunci |

Prototipe dijalankan di FPGA DE10-Nano (Cyclone V SoC). Prosesor ARM pada board yang sama mengemulasikan BMS, stasiun, dan basis data identitas. Target ASIC adalah SkyWater SKY130. Rincian desain dan analisis keamanan ada di [proposal](proposal/main.pdf).

## Status Saat Ini

| Tahap | Status | Bukti |
|---|---|---|
| Proposal | Selesai | [proposal/main.pdf](proposal/main.pdf) |
| Model referensi Python | 9 dari 9 uji lulus: vektor SHA-256 FIPS 180-4, vektor HMAC RFC 4231, dan 7 skenario protokol | [model/](model/) |
| Vektor uji emas SHA-256 dan HMAC untuk RTL | Tersedia | [sim/vectors/](sim/vectors/) |
| Kompilasi awal di Quartus untuk DE10-Nano | 2.386 ALM (5,7%), Fmax 86,85 MHz, belum memuat seluruh blok IP | Proyek menyusul di [fpga/](fpga/) |
| RTL SHA-256 dan HMAC | Sedang dikerjakan | [rtl/](rtl/) |
| PUF, fuzzy extractor, tamper_mon | Direncanakan sebelum bootcamp | [docs/MILESTONES.md](docs/MILESTONES.md) |

## Menjalankan Model Referensi

Model hanya memakai pustaka standar Python 3.10 atau lebih baru.

```
cd model
python -m unittest -v test_battery_id.py
python gen_vectors.py
```

Perintah pertama menjalankan seluruh uji. Perintah kedua membuat ulang vektor uji emas di sim/vectors/ untuk dibandingkan dengan keluaran RTL.

## Struktur Repositori

| Folder | Isi |
|---|---|
| [proposal/](proposal/) | Sumber LaTeX dan PDF proposal |
| [model/](model/) | Model referensi Python, uji unit, dan generator vektor uji |
| [sim/](sim/) | Testbench dan vektor uji emas |
| [rtl/](rtl/) | Kode Verilog chip |
| [fpga/](fpga/) | Proyek Quartus dan Vivado |
| [docs/](docs/) | Milestone, referensi regulasi, dan datasheet Tiny Tapeout 07 |

## Tim

Tim NaS, Universitas Gadjah Mada.

| Nama | Peran |
|---|---|
| Guntur Sulistyo (ketua) | Keamanan dan koordinasi |
| Muhammad Muqtada Alhaddad | Perancang RTL |
| Dimas Eryan Ahnaf Fahrezi | Sistem dan verifikasi |
| Ir. Agus Bejo, S.T., M.Eng., D.Eng., IPM | Dosen pembimbing |

## Dokumentasi Terkait

- [Proposal lengkap (PDF)](proposal/main.pdf)
- [Milestone dan pembagian tugas](docs/MILESTONES.md)
