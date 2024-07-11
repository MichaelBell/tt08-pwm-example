/* Copyright 2023-2024 (c) Michael Bell
   SPDX-License-Identifier: Apache-2.0

   A simple SPI RAM controller
   
   To perform a read:
   - Set addr_in and set start_read high for 1 cycle
   - Wait for busy to go low
   - The read data is now available on data_out

   If the controller is configured to transfer multiple bytes, then
   note that the word transferred in data_in/data_out is in big
   endian order, i.e. the byte with the lowest address is aligned to 
   the MSB of the word. 
   */
module spi_flash_controller #(parameter DATA_WIDTH_BYTES=4, parameter ADDR_BITS=16, parameter CLK_DIV_BITS=3) (
    input clk,
    input rstn,

    // External SPI interface
    input  spi_miso,
    output spi_select,
    output reg spi_clk_out,
    output spi_mosi,

    // Internal interface for reading data
    input [ADDR_BITS-1:0]           addr_in,
    input                           start_read,
    input                           stop_read,
    input                           continue_read,    
    output [DATA_WIDTH_BYTES*8-1:0] data_out,
    output                          busy
);

`define max(a, b) (a > b) ? a : b

    localparam DATA_WIDTH_BITS = DATA_WIDTH_BYTES * 8;

    localparam FSM_IDLE = 1;
    localparam FSM_CMD  = 5;
    localparam FSM_ADDR = 6;
    localparam FSM_DATA = 7;
    localparam FSM_HOLD = 0;

    reg [2:0] fsm_state;
    reg [ADDR_BITS-1:0]       addr;
    reg [DATA_WIDTH_BITS-1:0] data;
    reg [$clog2(`max(DATA_WIDTH_BITS,ADDR_BITS))-1:0] bits_remaining;
    reg [CLK_DIV_BITS-1:0] count;

    assign data_out = data;
    assign busy = fsm_state[2];

    always @(posedge clk) begin
        if (!rstn) begin
            fsm_state <= FSM_IDLE;
            bits_remaining <= 0;
            count <= 0;
        end else begin
            count <= count + 1;
            if (count == 0) begin
                if (fsm_state == FSM_IDLE) begin
                    if (start_read) begin
                        fsm_state <= FSM_CMD;
                        bits_remaining <= 8-1;
                    end
                end else if (fsm_state == FSM_HOLD) begin
                    if (stop_read) fsm_state <= FSM_IDLE;
                    if (continue_read) begin
                        fsm_state <= FSM_DATA;
                        bits_remaining <= DATA_WIDTH_BITS-1;
                    end                    
                end else begin
                    if (bits_remaining == 0) begin
                        fsm_state <= fsm_state + 1;
                        if (fsm_state == FSM_CMD)       bits_remaining <= ADDR_BITS-1;
                        else if (fsm_state == FSM_ADDR) bits_remaining <= DATA_WIDTH_BITS-1;
                    end else begin
                        bits_remaining <= bits_remaining - 1;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (fsm_state[2] == 0) begin
            spi_clk_out <= 0;
        end else if (count[CLK_DIV_BITS-2:0] == 0) begin
            spi_clk_out <= ~spi_clk_out;
        end
    end

    always @(posedge clk) begin
        if (count == 0) begin
            if (fsm_state == FSM_IDLE && start_read) begin
                addr <= addr_in;
            end else if (fsm_state == FSM_ADDR) begin
                addr <= {addr[ADDR_BITS-2:0], 1'b0};
            end

            if (fsm_state == FSM_DATA) begin
                data <= {data[DATA_WIDTH_BITS-2:0], spi_miso};
            end
        end
    end

    assign spi_select = fsm_state == FSM_IDLE;

    assign spi_mosi = fsm_state == FSM_CMD  ? (bits_remaining[2:1] == 2'b00) :
                      fsm_state == FSM_ADDR ? addr[ADDR_BITS-1] :
                                              1'b0;

endmodule
