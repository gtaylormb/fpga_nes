/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: nes_zybo_wrapper.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 25 Sept 2015
#
#   DESCRIPTION:
#
#   CHANGE HISTORY:
#   25 Sept 2015        Greg Taylor
#       Initial version
#
#   Copyright (C) 2015 Greg Taylor <gtaylor@sonic.net>
#   
#******************************************************************************/

`timescale 1ns / 1ps
`default_nettype none  // disable implicit net type declarations
 
module nes_zybo_wrapper (
    input wire clk125,
    input wire [3:0] btn,
    input wire [3:0] sw,
    input wire uart_rx,   // Digilent PmodUSBUART on XADC pmod (JA)
    output wire uart_tx,
    input wire nes_joypad_data1, // Digilent PmodBB on standard pmod (JE)
    input wire nes_joypad_data2,
    output wire nes_joypad_clk,
    output wire nes_joypad_latch,
    output wire vga_hs,
    output wire vga_vs,
    output logic [4:0] vga_r,
    output logic [5:0] vga_g,
    output logic [4:0] vga_b,
    output wire i2s_sclk,
    output wire i2s_ws,
    output wire i2s_sd,
    output logic ac_mute_n,
    output logic ac_mclk,
    
    inout wire [14:0]DDR_addr,
    inout wire [2:0]DDR_ba,
    inout wire DDR_cas_n,
    inout wire DDR_ck_n,
    inout wire DDR_ck_p,
    inout wire DDR_cke,
    inout wire DDR_cs_n,
    inout wire [3:0]DDR_dm,
    inout wire [31:0]DDR_dq,
    inout wire [3:0]DDR_dqs_n,
    inout wire [3:0]DDR_dqs_p,
    inout wire DDR_odt,
    inout wire DDR_ras_n,
    inout wire DDR_reset_n,
    inout wire DDR_we_n,
    inout wire FIXED_IO_ddr_vrn,
    inout wire FIXED_IO_ddr_vrp,
    inout wire [53:0]FIXED_IO_mio,
    inout wire FIXED_IO_ps_clk,
    inout wire FIXED_IO_ps_porb,
    inout wire FIXED_IO_ps_srstb,    
    inout wire iic_0_scl_io,
    inout wire iic_0_sda_io    
    
);
    localparam DAC_MASTER_CLK_FREQ = 12.288e6;
    localparam DAC_SAMPLE_CLK_FREQ = 48e3;
    
    wire clk100;
    wire clk12;
    wire locked;
    wire sample_clk_en;
    wire [5:0] sample_100;
    logic [5:0] sample_100_r0;
    logic sample_100_update = 0;
    wire [5:0] sample_12;
    wire sample_12_update;
    wire fifo_input_ready;
        
    mmcm mmcm (
        .reset(btn[0]),
        .*
    );

    nes_top nes (
        .CLK_100MHZ(clk100),        // 100MHz system clock signal
        .BTN_SOUTH(!locked),         // reset push button
        .BTN_EAST(btn[1]),          // console reset
        .RXD(uart_rx),               // rs-232 rx signal
        .SW(sw),                // switches
        .NES_JOYPAD_DATA1(nes_joypad_data1),  // joypad 1 input signal
        .NES_JOYPAD_DATA2(nes_joypad_data2),  // joypad 2 input signal
        .TXD(uart_tx),               // rs-232 tx signal
        .VGA_HSYNC(vga_hs),         // vga hsync signal
        .VGA_VSYNC(vga_vs),         // vga vsync signal
        .VGA_RED(vga_r[4:2]),           // vga red signal
        .VGA_GREEN(vga_g[5:3]),         // vga green signal
        .VGA_BLUE(vga_b[4:2]),          // vga blue signal
        .NES_JOYPAD_CLK(nes_joypad_clk),    // joypad output clk signal
        .NES_JOYPAD_LATCH(nes_joypad_latch),  // joypad output latch signal
        .AUDIO(),              // pwm output audio channel
        .DAC_AUDIO(sample_100)
    );
    
    /*
     * Video outputs use more bits than the NES can provide.
     * Assign 0s to lower unused bits.
     */
    always_comb begin
        vga_r[1:0] = 0;
        vga_g[2:0] = 0;
        vga_b[1:0] = 0;
    end
    
    /*
     * Generate the 12.288MHz/256 sample clock enable
     */
    clk_div #(
        .INPUT_CLK_FREQ(DAC_MASTER_CLK_FREQ),       
        .OUTPUT_CLK_EN_FREQ(DAC_SAMPLE_CLK_FREQ) 
    ) sample_clk_gen (
        .clk(clk12),
        .clk_en(sample_clk_en),
        .*
    );
    
    always_ff @(posedge clk100)
        sample_100_r0 <= sample_100;
    
    /*
     * Detect updates on audio sample
     */    
    always_ff @(posedge clk100)
        sample_100_update <= sample_100_r0 != sample_100;
    
    /*
     * We must cross audio samples over from 100MHz clock domain to 12MHz clock
     * domain for outputting to DAC
     */    
    cdc_syncfifo #(
        .dat_t(logic [5:0])
    ) audio_cdc_fifo (
        .wdata(sample_100_r0),
        .wrdy(fifo_input_ready),
        .wput(sample_100_update && fifo_input_ready),
        .wclk(clk100),
        .rdata(sample_12),
        .rrdy(sample_12_update),
        .rget(sample_12_update),
        .rclk(clk12)
    );
    
    i2s i2s (
        .clk(clk12), 
        .reset(!locked),
        .sample_clk_en,
        .left_channel({sample_12, 10'h0}),
        .right_channel({sample_12, 10'h0}),
        .*
    );
    
    always_comb ac_mute_n = 1;
    always_comb ac_mclk = clk12;
    
    logic I2C0_SDA_I;
    wire I2C0_SDA_O;
    wire I2C0_SDA_T;
    logic I2C0_SCL_I;
    wire I2C0_SCL_O;
    wire I2C0_SCL_T;
    
    /*
     * Infer tri-state buffers for I2C
     */
    assign iic_0_scl_io = I2C0_SCL_T ? I2C0_SCL_O : 1'bZ;
    assign iic_0_sda_io = I2C0_SDA_T ? I2C0_SDA_O : 1'bZ;   
    always_comb I2C0_SCL_I = iic_0_scl_io;
    always_comb I2C0_SDA_I = iic_0_sda_io;
    
    /*
     * We only use the ARM CPU to configure the DAC via I2C
     */
    processing_system7_0 arm_cpu (
        .ENET0_PTP_DELAY_REQ_RX(),
        .ENET0_PTP_DELAY_REQ_TX(),
        .ENET0_PTP_PDELAY_REQ_RX(),
        .ENET0_PTP_PDELAY_REQ_TX(),
        .ENET0_PTP_PDELAY_RESP_RX(),
        .ENET0_PTP_PDELAY_RESP_TX(),
        .ENET0_PTP_SYNC_FRAME_RX(),
        .ENET0_PTP_SYNC_FRAME_TX(),
        .ENET0_SOF_RX(),
        .ENET0_SOF_TX(),
        .I2C0_SDA_I,
        .I2C0_SDA_O,
        .I2C0_SDA_T,
        .I2C0_SCL_I,
        .I2C0_SCL_O,
        .I2C0_SCL_T,
        .SDIO0_WP(1'b0),
        .USB0_PORT_INDCTL(),
        .USB0_VBUS_PWRSELECT(),
        .USB0_VBUS_PWRFAULT(1'b0),
        .M_AXI_GP0_ARVALID(),
        .M_AXI_GP0_AWVALID(),
        .M_AXI_GP0_BREADY(),
        .M_AXI_GP0_RREADY(),
        .M_AXI_GP0_WLAST(),
        .M_AXI_GP0_WVALID(),
        .M_AXI_GP0_ARID(),
        .M_AXI_GP0_AWID(),
        .M_AXI_GP0_WID(),
        .M_AXI_GP0_ARBURST(),
        .M_AXI_GP0_ARLOCK(),
        .M_AXI_GP0_ARSIZE(),
        .M_AXI_GP0_AWBURST(),
        .M_AXI_GP0_AWLOCK(),
        .M_AXI_GP0_AWSIZE(),
        .M_AXI_GP0_ARPROT(),
        .M_AXI_GP0_AWPROT(),
        .M_AXI_GP0_ARADDR(),
        .M_AXI_GP0_AWADDR(),
        .M_AXI_GP0_WDATA(),
        .M_AXI_GP0_ARCACHE(),
        .M_AXI_GP0_ARLEN(),
        .M_AXI_GP0_ARQOS(),
        .M_AXI_GP0_AWCACHE(),
        .M_AXI_GP0_AWLEN(),
        .M_AXI_GP0_AWQOS(),
        .M_AXI_GP0_WSTRB(),
        .M_AXI_GP0_ACLK(1'b0),
        .M_AXI_GP0_ARREADY(1'b0),
        .M_AXI_GP0_AWREADY(1'b0),
        .M_AXI_GP0_BVALID(1'b0),
        .M_AXI_GP0_RLAST(1'b0),
        .M_AXI_GP0_RVALID(1'b0),
        .M_AXI_GP0_WREADY(1'b0),
        .M_AXI_GP0_BID(12'b0),
        .M_AXI_GP0_RID(12'b0),
        .M_AXI_GP0_BRESP(2'b0),
        .M_AXI_GP0_RRESP(2'b0),
        .M_AXI_GP0_RDATA(32'b0),
        .FCLK_RESET0_N(),
        .MIO(FIXED_IO_mio[53:0]),       
        .DDR_Addr(DDR_addr[14:0]),
        .DDR_BankAddr(DDR_ba[2:0]),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm[3:0]),
        .DDR_DQ(DDR_dq[31:0]),
        .DDR_DQS(DDR_dqs_p[3:0]),
        .DDR_DQS_n(DDR_dqs_n[3:0]),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),        
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb)
    );

endmodule
`default_nettype wire  // re-enable implicit net type declarations

