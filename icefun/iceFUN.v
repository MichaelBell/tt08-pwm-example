/*
 * Copyright (c) 2024 Michael Bell
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pwm_audio_top (
        input clk12MHz,

        output pwm

);
    wire locked;
    wire clk;

    // 50.25 MHz PLL
    SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'b0000),         // DIVR =  0
    .DIVF(7'b1000010),      // DIVF = 66
    .DIVQ(3'b100),          // DIVQ =  4
    .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
    ) uut (
    .LOCK(locked),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .REFERENCECLK(clk12MHz),
    .PLLOUTCORE(clk)
    );

  pwm_sine i_sine(
        .clk(clk),
        .rst_n(locked),

        //.divider({ui_in, uio_in[3:0]}),
        .divider(12'd747),

        .pwm(pwm)
  );

endmodule