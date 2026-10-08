package require -exact qsys 16.1

set_module_property DESCRIPTION "Heketon Hardware Security IP"
set_module_property NAME heketon
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR "Heketon"
set_module_property DISPLAY_NAME "Heketon Security IP"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL heketon_top
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file heketon_top.sv SYSTEM_VERILOG PATH ../rtl/heketon_top.sv TOP_LEVEL_FILE
add_fileset_file heketon_axi_ctrl.sv SYSTEM_VERILOG PATH ../rtl/heketon_axi_ctrl.sv
add_fileset_file control_fsm.sv SYSTEM_VERILOG PATH ../rtl/control_fsm.sv
add_fileset_file ro_puf.sv SYSTEM_VERILOG PATH ../rtl/ro_puf.sv
add_fileset_file hmac_sha256.sv SYSTEM_VERILOG PATH ../rtl/hmac_sha256.sv
add_fileset_file sha256_core.sv SYSTEM_VERILOG PATH ../rtl/sha256_core.sv

add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""
add_interface_port clock S_AXI_ACLK clk Input 1

add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""
add_interface_port reset S_AXI_ARESETN reset_n Input 1

add_interface axi4lite axi4lite end
set_interface_property axi4lite associatedClock clock
set_interface_property axi4lite associatedReset reset
set_interface_property axi4lite readAcceptanceCapability 1
set_interface_property axi4lite writeAcceptanceCapability 1
set_interface_property axi4lite combinedAcceptanceCapability 1
set_interface_property axi4lite readDataReorderingDepth 1
set_interface_property axi4lite bridgesToMaster ""
set_interface_property axi4lite ENABLED true
set_interface_property axi4lite EXPORT_OF ""
set_interface_property axi4lite PORT_NAME_MAP ""
set_interface_property axi4lite CMSIS_SVD_VARIABLES ""
set_interface_property axi4lite SVD_ADDRESS_GROUP ""

add_interface_port axi4lite S_AXI_AWADDR awaddr Input 8
add_interface_port axi4lite S_AXI_AWPROT awprot Input 3
add_interface_port axi4lite S_AXI_AWVALID awvalid Input 1
add_interface_port axi4lite S_AXI_AWREADY awready Output 1
add_interface_port axi4lite S_AXI_WDATA wdata Input 32
add_interface_port axi4lite S_AXI_WSTRB wstrb Input 4
add_interface_port axi4lite S_AXI_WVALID wvalid Input 1
add_interface_port axi4lite S_AXI_WREADY wready Output 1
add_interface_port axi4lite S_AXI_BRESP bresp Output 2
add_interface_port axi4lite S_AXI_BVALID bvalid Output 1
add_interface_port axi4lite S_AXI_BREADY bready Input 1
add_interface_port axi4lite S_AXI_ARADDR araddr Input 8
add_interface_port axi4lite S_AXI_ARPROT arprot Input 3
add_interface_port axi4lite S_AXI_ARVALID arvalid Input 1
add_interface_port axi4lite S_AXI_ARREADY arready Output 1
add_interface_port axi4lite S_AXI_RDATA rdata Output 32
add_interface_port axi4lite S_AXI_RRESP rresp Output 2
add_interface_port axi4lite S_AXI_RVALID rvalid Output 1
add_interface_port axi4lite S_AXI_RREADY rready Input 1
