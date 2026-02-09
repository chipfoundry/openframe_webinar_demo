// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/*
 *-------------------------------------------------------------
 *
 * counter_gpio_config_example
 *
 * Example user project demonstrating various GPIO modes using
 * the CF_gpio_config IP. Contains a 32-bit counter and
 * configures all 44 GPIOs in different modes:
 *
 *   GPIO 0-1:   INPUT mode (includes clock input on GPIO 38)
 *   GPIO 2-5:   OUTPUT mode (counter[3:0])
 *   GPIO 6-9:   INPUT mode (no pull)
 *   GPIO 10-13: INPUT_PD mode (pull-down)
 *   GPIO 14-17: INPUT_PU mode (pull-up)
 *   GPIO 18-21: BIDIR mode (bidirectional, controlled by GPIO 0)
 *   GPIO 22-37: OUTPUT mode (counter[19:4])
 *   GPIO 38-43: INPUT mode (GPIO 38 is clock)
 *
 *-------------------------------------------------------------
 */

module counter_gpio_config_example (
`ifdef USE_POWER_PINS
    inout vccd1,    // User area 1 1.8V supply
    inout vssd1,    // User area 1 digital ground
`endif

    // Reset
    input  wire resetb_l,

    // GPIO interface (directly connected to pads)
    input  wire [`OPENFRAME_IO_PADS-1:0] gpio_in,

    // GPIO data and control outputs
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_out,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_oeb,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_inp_dis,

    // GPIO pad configuration
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_ib_mode_sel,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_vtrip_sel,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_slow_sel,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_holdover,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_analog_en,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_analog_sel,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_analog_pol,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_dm2,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_dm1,
    output wire [`OPENFRAME_IO_PADS-1:0] gpio_dm0
);

    //=========================================================================
    // Mode Definitions (must match CF_gpio_config)
    //=========================================================================
    localparam [2:0] MODE_INPUT    = 3'd1;
    localparam [2:0] MODE_INPUT_PD = 3'd2;
    localparam [2:0] MODE_INPUT_PU = 3'd3;
    localparam [2:0] MODE_OUTPUT   = 3'd4;
    localparam [2:0] MODE_BIDIR    = 3'd5;

    //=========================================================================
    // Clock and Reset
    //=========================================================================
    wire clk   = gpio_in[38];
    wire rst_n = resetb_l;

    //=========================================================================
    // Counter (32-bit, used for output testing)
    //=========================================================================
    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    //=========================================================================
    // BIDIR control - directly from GPIO 0 input
    // When GPIO 0 is high, BIDIR pins output; when low, BIDIR pins input
    //=========================================================================
    wire bidir_oeb = ~gpio_in[0];  // 0=output, 1=input
    wire [3:0] bidir_out_data = counter[3:0];  // Output counter value on BIDIR

    //=========================================================================
    // GPIO 0-1: INPUT mode (clock/reset area)
    //=========================================================================
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : gpio_0_1
            wire [2:0] dm;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_INPUT)) cfg (
                .io_out(1'b0), .io_in(), .io_oeb(1'b1), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 2-5: OUTPUT mode (counter[3:0])
    //=========================================================================
    generate
        for (i = 2; i < 6; i = i + 1) begin : gpio_2_5_output
            wire [2:0] dm;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_OUTPUT)) cfg (
                .io_out(counter[i-2]), .io_in(), .io_oeb(1'b0), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 6-9: INPUT mode (no pull)
    //=========================================================================
    generate
        for (i = 6; i < 10; i = i + 1) begin : gpio_6_9_input
            wire [2:0] dm;
            wire input_val;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_INPUT)) cfg (
                .io_out(1'b0), .io_in(input_val), .io_oeb(1'b1), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 10-13: INPUT_PD mode (pull-down)
    //=========================================================================
    generate
        for (i = 10; i < 14; i = i + 1) begin : gpio_10_13_input_pd
            wire [2:0] dm;
            wire input_val;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_INPUT_PD)) cfg (
                .io_out(1'b0), .io_in(input_val), .io_oeb(1'b1), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 14-17: INPUT_PU mode (pull-up)
    //=========================================================================
    generate
        for (i = 14; i < 18; i = i + 1) begin : gpio_14_17_input_pu
            wire [2:0] dm;
            wire input_val;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_INPUT_PU)) cfg (
                .io_out(1'b0), .io_in(input_val), .io_oeb(1'b1), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 18-21: BIDIR mode (bidirectional)
    //=========================================================================
    generate
        for (i = 18; i < 22; i = i + 1) begin : gpio_18_21_bidir
            wire [2:0] dm;
            wire input_val;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_BIDIR)) cfg (
                .io_out(bidir_out_data[i-18]), .io_in(input_val), .io_oeb(bidir_oeb), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 22-37: OUTPUT mode (counter[19:4])
    //=========================================================================
    generate
        for (i = 22; i < 38; i = i + 1) begin : gpio_22_37_output
            wire [2:0] dm;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_OUTPUT)) cfg (
                .io_out(counter[i-18]), .io_in(), .io_oeb(1'b0), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

    //=========================================================================
    // GPIO 38-43: INPUT mode (clock and unused)
    //=========================================================================
    generate
        for (i = 38; i < 44; i = i + 1) begin : gpio_38_43_input
            wire [2:0] dm;
            wire out_val;
            CF_gpio_config #(.MODE(MODE_INPUT)) cfg (
                .io_out(1'b0), .io_in(), .io_oeb(1'b1), .analog(2'b00),
                .gpio_in(gpio_in[i]), .gpio_dm(dm),
                .gpio_inp_dis(gpio_inp_dis[i]), .gpio_oeb_out(gpio_oeb[i]),
                .gpio_out_val(out_val),
                .gpio_analog_en(gpio_analog_en[i]), .gpio_analog_sel(gpio_analog_sel[i]),
                .gpio_analog_pol(gpio_analog_pol[i]), .gpio_ib_mode_sel(gpio_ib_mode_sel[i]),
                .gpio_vtrip_sel(gpio_vtrip_sel[i]), .gpio_slow_sel(gpio_slow_sel[i]),
                .gpio_holdover(gpio_holdover[i])
            );
            assign {gpio_dm2[i], gpio_dm1[i], gpio_dm0[i]} = dm;
            assign gpio_out[i] = out_val;
        end
    endgenerate

endmodule

`default_nettype wire
