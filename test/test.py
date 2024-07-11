# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer

async def expect_read_cmd(dut, addr):
    assert dut.spi_cs.value == 1
    await FallingEdge(dut.spi_cs)
    assert dut.uio_oe.value == 0b11001011

    assert dut.spi_mosi.value == 0
    
    cmd = 0x03
    for i in range(8):
        await ClockCycles(dut.spi_clk, 1)
        assert dut.spi_mosi.value == (1 if cmd & 0x80 else 0)
        assert dut.spi_cs.value == 0
        cmd <<= 1

    for i in range(24):
        await ClockCycles(dut.spi_clk, 1)
        assert dut.spi_mosi.value == (1 if addr & 0x800000 else 0)
        assert dut.spi_cs.value == 0
        addr <<= 1

    await FallingEdge(dut.spi_clk)

async def spi_send_data(dut, data):
    assert dut.spi_cs.value == 0

    for i in range(8):
        await Timer(1, "ns")
        dut.spi_miso.value = (data >> 7) & 1
        assert dut.spi_cs.value == 0
        await FallingEdge(dut.spi_clk)
        data <<= 1

    await Timer(1, "ns")

@cocotb.test()
async def test_read(dut):
    dut._log.info("Start")

    # 57.6MHz clock
    clock = Clock(dut.clk, 17.36, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.spi_miso.value = 0
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    assert dut.uio_oe.value == 0b11001011

    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    assert dut.uio_oe.value == 0

    dut.rst_n.value = 1

    await expect_read_cmd(dut, 0)

    for i in range(256):
        await spi_send_data(dut, i)
        # TODO actually verify the PWM output
