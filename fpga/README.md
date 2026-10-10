# FPGA

Proyek Quartus Prime untuk DE10-Nano (Cyclone V SoC, 5CSEBA6U23I7). Blok SeBatt (nama internal heketon) dipasang sebagai IP di Platform Designer dan dihubungkan ke HPS melalui lightweight HPS-to-FPGA bridge.

## Isi Folder

| File | Fungsi |
|---|---|
| heketon.qpf, heketon.qsf | Proyek Quartus. Top-level entity soc_system, sumber RTL diambil dari [rtl/](../rtl/) |
| soc_system.qsys | Sistem Platform Designer berisi HPS, bridge, dan IP heketon |
| build_qsys.tcl | Skrip pembentuk sistem soc_system |
| heketon_hw.tcl | Deskripsi komponen IP heketon untuk Platform Designer |
| tcl_preset.tcl | Setelan HPS untuk DE10-Nano (DDR3 dan clock) |

## Membangun Proyek

Folder soc_system/ hasil generate tidak ikut disimpan di repo, jadi HDL sistem dibuat ulang lebih dulu.

```
qsys-generate soc_system.qsys --synthesis=VERILOG
quartus_sh --flow compile heketon
```

Kompilasi awal berhasil hingga tahap Assembler dengan 2.386 ALM (5,7%) dan Fmax 86,85 MHz pada clock h2f_user0_clk. Constraint timing belum final, sehingga angka ini adalah hasil awal prototipe.
