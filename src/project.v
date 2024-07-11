/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_pwm_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

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
    .spi_select (uio_out[0]),
    .spi_mosi   (uio_out[1]),
    .spi_miso   (uio_in[2]),
    .spi_clk_out(uio_out[3]),
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

        .pwm(uio_out[7])
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

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out = 0;
  assign uio_out[2] = 0;
  assign uio_out[6:4] = 3'b100;
  assign uio_oe = rst_n ? 8'b11001011 : 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in[7:3], uio_in[1:0], 1'b0};

endmodule
