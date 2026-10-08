VERILATOR = verilator

test_sha:
	$(VERILATOR) -Wall --trace --cc ../rtl/sha256_core.sv --exe tb_sha256.cpp
	make -j -C obj_dir -f Vsha256_core.mk Vsha256_core
	./obj_dir/Vsha256_core

clean:
	rm -rf obj_dir *.vcd

test_puf:
	$(VERILATOR) -Wall --cc ../rtl/ro_puf.sv --exe tb_puf.cpp --Mdir obj_puf
	make -j -C obj_puf -f Vro_puf.mk Vro_puf
	./obj_puf/Vro_puf

test_fsm:
	$(VERILATOR) -Wall --cc ../rtl/control_fsm.sv --exe tb_control_fsm.cpp --Mdir obj_fsm --public-flat-rw
	make -j -C obj_fsm -f Vcontrol_fsm.mk Vcontrol_fsm
	./obj_fsm/Vcontrol_fsm

test_hmac:
	$(VERILATOR) -Wall --cc ../rtl/sha256_core.sv ../rtl/hmac_sha256.sv --top-module hmac_sha256 -GMESSAGE_BYTES=8 --exe tb_hmac.cpp --Mdir obj_hmac
	make -j -C obj_hmac -f Vhmac_sha256.mk Vhmac_sha256
	python3 test_hmac.py ./obj_hmac/Vhmac_sha256

test_integration:
	$(VERILATOR) --cc ../rtl/heketon_top.sv ../rtl/heketon_axi_ctrl.sv ../rtl/control_fsm.sv ../rtl/ro_puf.sv ../rtl/hmac_sha256.sv ../rtl/sha256_core.sv --top-module heketon_top --exe tb_integration.cpp --Mdir obj_integration --public-flat-rw
	make -j -C obj_integration -f Vheketon_top.mk Vheketon_top
	python3 test_integration.py ./obj_integration/Vheketon_top
