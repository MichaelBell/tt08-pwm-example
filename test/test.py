# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer


async def do_start(dut):
    dut._log.info("Start")

    # 50MHz clock
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.uio_in.value = 0
    dut.rst_n.value = 1
    dut.divider.value = 0
    await ClockCycles(dut.clk, 2)

    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)

    dut.rst_n.value = 1


@cocotb.test()
async def test_sine(dut):
    await do_start(dut)

    # Divider of 99 gives a frequency of 50MHz / 25600 = 1953.125Hz, a period of 512us
    dut.divider.value = 99
    await Timer(2048, "us")
