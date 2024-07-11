/*
 * Copyright (c) 2024 Michael Bell
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module pwm_audio_top (
        input clk,
        input rst_n,

        output spi_cs,
        output spi_mosi,
        input spi_miso,
        output spi_clk,

        output cs1,

        output pwm

);
    assign cs1 = 1'b1;

  wire [7:0] spi_data;
  wire spi_busy;
  reg spi_start_read;
  reg spi_continue_read;

  spi_flash_controller #(
    .DATA_WIDTH_BYTES(1),
    .ADDR_BITS(24),
    .CLK_DIV_BITS(3)
  ) i_spi (
    .clk        (clk),
    .rstn       (rst_n),
    .spi_select (spi_cs),
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso),
    .spi_clk_out(spi_clk),
    .addr_in    (24'h0),
    .start_read (spi_start_read),
    .stop_read  (1'b0),
    .continue_read(spi_continue_read),
    .data_out   (spi_data),
    .busy       (spi_busy)
  );  

  reg [7:0] sample;
  pwm_audio i_pwm(
        .clk(clk),
        .rst_n(rst_n),

        .sample(sample),

        .pwm(pwm)
  );

  // Assume 57.6MHz project clock and 48kHz sample data
  reg spi_started;
  reg [10:0] counter;
  always @(posedge clk) begin
    if (!rst_n) begin
      spi_started <= 0;
      spi_start_read <= 0;
      spi_continue_read <= 0;
      
      counter <= 0;
      sample <= 8'h80;
    end else begin
      spi_continue_read <= 0;
      spi_start_read <= 0;
      counter <= counter + 1;

      if (counter == 11'd1199) begin
        if (spi_started) spi_continue_read <= 1;
        else spi_start_read <= 1;
        spi_started <= 1;
        counter <= 0;
      end

      if (!spi_busy && spi_started) sample <= spi_data;
    end
  end

endmodule
