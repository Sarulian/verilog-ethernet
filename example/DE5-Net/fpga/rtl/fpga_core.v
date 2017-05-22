/*

Copyright (c) 2016 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * FPGA core logic
 */
module fpga_core
(
    /*
     * Clock: 156.25MHz
     * Synchronous reset
     */
    input  wire        clk,
    input  wire        rst,

    /*
     * GPIO
     */
    input  wire [3:0]  btn,
    input  wire [3:0]  sw,
    output wire [3:0]  led,
    output wire [3:0]  led_bkt,
    output wire [6:0]  led_hex0_d,
    output wire        led_hex0_dp,
    output wire [6:0]  led_hex1_d,
    output wire        led_hex1_dp,

    /*
     * 10G Ethernet
     */
    output wire [63:0] sfp_a_txd,
    output wire [7:0]  sfp_a_txc,
    input  wire [63:0] sfp_a_rxd,
    input  wire [7:0]  sfp_a_rxc,
    output wire [63:0] sfp_b_txd,
    output wire [7:0]  sfp_b_txc,
    input  wire [63:0] sfp_b_rxd,
    input  wire [7:0]  sfp_b_rxc,
    output wire [63:0] sfp_c_txd,
    output wire [7:0]  sfp_c_txc,
    input  wire [63:0] sfp_c_rxd,
    input  wire [7:0]  sfp_c_rxc,
    output wire [63:0] sfp_d_txd,
    output wire [7:0]  sfp_d_txc,
    input  wire [63:0] sfp_d_rxd,
    input  wire [7:0]  sfp_d_rxc
);

// AXI between MAC and Ethernet modules
wire [63:0] rx_axis_tdata;
wire [7:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [63:0] tx_axis_tdata;
wire [7:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;

// Generate control idles
wire [63:0] idle_axis_tdata;
wire [7:0] idle_axis_tkeep;
wire idle_axis_tvalid;
wire idle_axis_tready;
wire idle_axis_tlast;
wire idle_axis_tuser;

assign idle_axis_tdata = 64'h7777777777777777;
assign idle_axis_tvalid = 1'b1;
// assign idle_axis_tready = 1'b1;
assign idle_axis_tlast = 1'b1;

// Place first payload byte onto LEDs
reg valid_last = 0;
reg [7:0] led_reg = 0;

always @(posedge clk) begin
    if (rst) begin
        led_reg <= 0;
    end else begin
        valid_last <= rx_axis_tvalid;
        if (rx_axis_tvalid & ~valid_last) begin
            led_reg <= rx_axis_tdata;
        end
    end
end

//assign led = sw;
assign led = led_reg;
assign led_bkt = led_reg;
assign led_hex0_d = 7'h00;
assign led_hex0_dp = 1'b0;
assign led_hex1_d = 7'h00;
assign led_hex1_dp = 1'b0;

assign sfp_b_txd = 64'h0707070707070707;
assign sfp_b_txc = 8'hff;
assign sfp_c_txd = 64'h0707070707070707;
assign sfp_c_txc = 8'hff;
assign sfp_d_txd = 64'h0707070707070707;
assign sfp_d_txc = 8'hff;

eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_ADDR_WIDTH(9),
    .RX_FIFO_ADDR_WIDTH(9)
)
eth_mac_10g_fifo_inst (
    .rx_clk(clk),
    .rx_rst(rst),
    .tx_clk(clk),
    .tx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    // axis input
    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    // axis output
    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    // xgmii input
    .xgmii_rxd(sfp_a_rxd),
    .xgmii_rxc(sfp_a_rxc),

    // xgmii output
    .xgmii_txd(sfp_a_txd),
    .xgmii_txc(sfp_a_txc),
    
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),

    .ifg_delay(8'd12)
);

/*
axis_fifo_64 #(
    .ADDR_WIDTH(10),
    .DATA_WIDTH(64)
)
input_fifo (
    .clk(clk),
    .rst(rst),

    // AXIS input
    .input_axis_tdata(rx_axis_tdata),
    .input_axis_tkeep(rx_axis_tkeep),
    .input_axis_tvalid(rx_axis_tvalid),
    .input_axis_tready(rx_axis_tready),
    .input_axis_tlast(rx_axis_tlast),
    .input_axis_tuser(rx_axis_tuser),

    // AXIS output
    .output_axis_tdata(tx_axis_tdata),
    .output_axis_tkeep(tx_axis_tkeep),
    .output_axis_tvalid(tx_axis_tvalid),
    .output_axis_tready(tx_axis_tready),
    .output_axis_tlast(tx_axis_tlast),
    .output_axis_tuser(tx_axis_tuser)
);
*/

axis_arb_mux_64_4 #(
    .DATA_WIDTH(64)
)
output_mux (
    .clk(clk),
    .rst(rst),

    // AXIS input
    .input_0_axis_tdata(rx_axis_tdata),
    .input_0_axis_tkeep(rx_axis_tkeep),
    .input_0_axis_tvalid(rx_axis_tvalid),
    .input_0_axis_tready(rx_axis_tready),
    .input_0_axis_tlast(rx_axis_tlast),
    .input_0_axis_tuser(rx_axis_tuser),

    // Control idle chars
    .input_1_axis_tdata(idle_axis_tdata),
    .input_1_axis_tkeep(idle_axis_tkeep),
    .input_1_axis_tvalid(idle_axis_tvalid),
    .input_1_axis_tready(idle_axis_tready),
    .input_1_axis_tlast(idle_axis_tlast),
    .input_1_axis_tuser(idle_axis_tuser),

    // Disable other 2 inputs
    .input_2_axis_tdata(),
    .input_2_axis_tkeep(),
    .input_2_axis_tvalid(1'b0),
    .input_2_axis_tready(),
    .input_2_axis_tlast(),
    .input_2_axis_tuser(),   

    .input_3_axis_tdata(),
    .input_3_axis_tkeep(),
    .input_3_axis_tvalid(1'b0),
    .input_3_axis_tready(),
    .input_3_axis_tlast(),
    .input_3_axis_tuser(),

    // AXIS output
    .output_axis_tdata(tx_axis_tdata),
    .output_axis_tkeep(tx_axis_tkeep),
    .output_axis_tvalid(tx_axis_tvalid),
    .output_axis_tready(tx_axis_tready),
    .output_axis_tlast(tx_axis_tlast),
    .output_axis_tuser(tx_axis_tuser)

);

endmodule
