package require -exact qsys 16.1
proc apply_de10_nano_hps { hps_name } {
    set_instance_parameter_value $hps_name {F2SCLK_COLDRST_Enable} {1}
    set_instance_parameter_value $hps_name {F2SCLK_DBGRST_Enable} {1}
    set_instance_parameter_value $hps_name {F2SCLK_WARMRST_Enable} {1}
    set_instance_parameter_value $hps_name {HPS_PROTOCOL} {DDR3}
    set_instance_parameter_value $hps_name {MEM_ASR} {Manual}
    set_instance_parameter_value $hps_name {MEM_CLK_FREQ} {400.0}
    set_instance_parameter_value $hps_name {MEM_COL_ADDR_WIDTH} {10}
    set_instance_parameter_value $hps_name {MEM_DQ_WIDTH} {32}
    set_instance_parameter_value $hps_name {MEM_ROW_ADDR_WIDTH} {15}
    set_instance_parameter_value $hps_name {MEM_TREFI_US} {7.8}
    set_instance_parameter_value $hps_name {MEM_TRCD_NS} {13.75}
    set_instance_parameter_value $hps_name {MEM_TRP_NS} {13.75}
    set_instance_parameter_value $hps_name {MEM_TWR_NS} {15.0}
    set_instance_parameter_value $hps_name {MEM_VOLTAGE} {1.5V}
    set_instance_parameter_value $hps_name {MEM_WTCL} {7}
    set_instance_parameter_value $hps_name {SDIO_Mode} {4-bit Data}
    set_instance_parameter_value $hps_name {SDIO_PinMuxing} {HPS I/O Set 0}
    set_instance_parameter_value $hps_name {UART0_Mode} {No Flow Control}
    set_instance_parameter_value $hps_name {UART0_PinMuxing} {HPS I/O Set 0}
    set_instance_parameter_value $hps_name {USB1_Mode} {SDR}
    set_instance_parameter_value $hps_name {USB1_PinMuxing} {HPS I/O Set 0}
    set_instance_parameter_value $hps_name {EMAC1_Mode} {RGMII}
    set_instance_parameter_value $hps_name {EMAC1_PinMuxing} {HPS I/O Set 0}
    set_instance_parameter_value $hps_name {I2C0_Mode} {I2C}
    set_instance_parameter_value $hps_name {I2C0_PinMuxing} {HPS I/O Set 0}
    set_instance_parameter_value $hps_name {I2C1_Mode} {I2C}
    set_instance_parameter_value $hps_name {I2C1_PinMuxing} {HPS I/O Set 0}
}
