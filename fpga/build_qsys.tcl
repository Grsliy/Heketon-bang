package require -exact qsys 16.1

create_system soc_system
set_project_property DEVICE_FAMILY {Cyclone V}
set_project_property DEVICE 5CSEBA6U23I7

# Add HPS
add_instance hps_0 altera_hps
set_instance_parameter_value hps_0 {F2SCLK_COLDRST_Enable} {1}
set_instance_parameter_value hps_0 {F2SCLK_DBGRST_Enable} {1}
set_instance_parameter_value hps_0 {F2SCLK_WARMRST_Enable} {1}
set_instance_parameter_value hps_0 {HLGPI_Enable} {0}
set_instance_parameter_value hps_0 {HPS_PROTOCOL} {DDR3}
set_instance_parameter_value hps_0 {MEM_ASR} {Manual}
set_instance_parameter_value hps_0 {MEM_ATCL} {Disabled}
set_instance_parameter_value hps_0 {MEM_CLK_FREQ} {400.0}
set_instance_parameter_value hps_0 {MEM_CLK_FREQ_MAX} {400.0}
set_instance_parameter_value hps_0 {MEM_COL_ADDR_WIDTH} {10}
set_instance_parameter_value hps_0 {MEM_DQ_WIDTH} {32}
set_instance_parameter_value hps_0 {MEM_ROW_ADDR_WIDTH} {15}
set_instance_parameter_value hps_0 {MEM_TREFI_US} {7.8}
set_instance_parameter_value hps_0 {MEM_TRCD_NS} {13.75}
set_instance_parameter_value hps_0 {MEM_TRP_NS} {13.75}
set_instance_parameter_value hps_0 {MEM_TWR_NS} {15.0}
set_instance_parameter_value hps_0 {MEM_VOLTAGE} {1.5V}
set_instance_parameter_value hps_0 {MEM_WTCL} {7}
set_instance_parameter_value hps_0 {S2FCLK_USER0CLK_Enable} {1}
set_instance_parameter_value hps_0 {S2FCLK_USER0CLK_FREQ} {50.0}
set_instance_parameter_value hps_0 {F2S_Width} {0}
set_instance_parameter_value hps_0 {LWH2F_Enable} {1}

# Basic SD, UART, USB, I2C, EMAC pins for DE10-Nano
set_instance_parameter_value hps_0 {SDIO_Mode} {4-bit Data}
set_instance_parameter_value hps_0 {SDIO_PinMuxing} {HPS I/O Set 0}
set_instance_parameter_value hps_0 {UART0_Mode} {No Flow Control}
set_instance_parameter_value hps_0 {UART0_PinMuxing} {HPS I/O Set 0}
set_instance_parameter_value hps_0 {USB1_Mode} {SDR}
set_instance_parameter_value hps_0 {USB1_PinMuxing} {HPS I/O Set 0}
set_instance_parameter_value hps_0 {EMAC1_Mode} {RGMII}
set_instance_parameter_value hps_0 {EMAC1_PinMuxing} {HPS I/O Set 0}
set_instance_parameter_value hps_0 {I2C0_Mode} {I2C}
set_instance_parameter_value hps_0 {I2C0_PinMuxing} {HPS I/O Set 0}
set_instance_parameter_value hps_0 {I2C1_Mode} {I2C}
set_instance_parameter_value hps_0 {I2C1_PinMuxing} {HPS I/O Set 0}

# Add Heketon
add_instance heketon_0 heketon

# Connections
add_connection hps_0.h2f_user0_clock heketon_0.clock
add_connection hps_0.h2f_user0_clock hps_0.h2f_lw_axi_clock
add_connection hps_0.h2f_reset heketon_0.reset
add_connection hps_0.h2f_lw_axi_master heketon_0.axi4lite

# Base Addresses
set_connection_parameter_value hps_0.h2f_lw_axi_master/heketon_0.axi4lite baseAddress {0x0000}

# Export
add_interface memory conduit end
set_interface_property memory EXPORT_OF hps_0.memory
add_interface hps_io conduit end
set_interface_property hps_io EXPORT_OF hps_0.hps_io

save_system soc_system.qsys
