# Model Referensi

Model Python protokol autentikasi SeBatt pada tingkat chip, stasiun, dan basis data identitas. Kunci PUF diganti kunci tetap per chip. Respons yang dihitung model menjadi acuan untuk RTL.

| File | Isi |
|---|---|
| battery_id.py | Fungsi ID, penurunan kunci, respons HMAC(K, nonce \|\| ID), serta kelas Chip dan Database |
| test_battery_id.py | Uji unit: vektor SHA-256 FIPS 180-4, vektor HMAC RFC 4231, dan 7 skenario protokol |
| gen_vectors.py | Pembuat vektor uji emas untuk RTL di [sim/vectors/](../sim/vectors/) |

## Menjalankan

Hanya memakai pustaka standar Python 3.10 atau lebih baru. Dari folder ini:

```
python -m unittest -v test_battery_id.py
python gen_vectors.py
```

Perintah pertama menjalankan 9 uji. Perintah kedua membuat ulang vektor uji dengan seed tetap, sehingga isinya selalu sama.

## Skenario Protokol

| Skenario | Hasil yang diharapkan |
|---|---|
| Baterai asli | Diterima |
| Chip dengan sidik jari berbeda (kloning) | Ditolak |
| Respons lama dikirim ulang (replay) | Ditolak |
| Helper data diubah | Ditolak |
| Chip di-tamper | Terkunci, ID diblokir |
| Kapasitas naik tidak wajar | Ditolak |
| Respons sama dengan definisi HMAC | Cocok |

Contoh pemakaian interaktif:

```
import os
from battery_id import Chip, Database, swap

db = Database()
helper = os.urandom(64)
chip = Chip(stable_bits=os.urandom(32))
db.enroll(chip, helper, capacity_ah=30.0)
swap(db, chip, helper, 29.5)    # True, baterai asli diterima
```
