# Proposal

Proposal SeBatt untuk Hackathon Chip 2026 dalam LaTeX, mengikuti format [template resmi](template-proposal-hackathon-chip-2026.pdf). Bab 1–5 (Executive Summary, Problem Statement, Proposed Chip, Technical Design, Security Design) dibatasi 6 halaman di luar cover, daftar pustaka, dan lampiran.

| File | Isi |
|---|---|
| main.tex | Sumber proposal, termasuk lampiran teknis, tim, luaran, dan rencana bootcamp |
| main.pdf | Hasil kompilasi |
| figures/ | Cuplikan Quartus untuk lampiran teknis |
| urutkan_referensi.py | Mengurutkan daftar pustaka sesuai urutan kutipan pertama |

## Kompilasi

```
pdflatex main.tex
pdflatex main.tex
```

Kompilasi dua kali agar nomor gambar dan referensi benar. Setelah menambah atau memindah sitasi, jalankan python urutkan_referensi.py sebelum kompilasi.
