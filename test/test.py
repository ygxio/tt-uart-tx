# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

CLKS_PER_BIT = 87  # must match tt_um_uart_tx


async def reset(dut):
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())  # 10 MHz
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    assert dut.uo_out.value[0] == 1, "line must idle high after reset"
    assert dut.uo_out.value[1] == 0, "done must be low after reset"


async def send_and_check(dut, byte):
    dut.uio_in.value = byte
    dut.ui_in.value = 1  # DV
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    dut.uio_in.value = 0  # DUT must have latched the byte

    # wait for start bit
    for _ in range(4):
        await RisingEdge(dut.clk)
        if dut.uo_out.value[0] == 0:
            break
    else:
        assert False, "start bit never seen"

    # sample mid-bit: start, 8 data (LSB first), stop
    await ClockCycles(dut.clk, CLKS_PER_BIT // 2)
    assert dut.uo_out.value[0] == 0, "start bit"

    received = 0
    for i in range(8):
        await ClockCycles(dut.clk, CLKS_PER_BIT)
        received |= int(dut.uo_out.value[0]) << i

    await ClockCycles(dut.clk, CLKS_PER_BIT)
    assert dut.uo_out.value[0] == 1, "stop bit"
    assert received == byte, f"got {received:#04x}, expected {byte:#04x}"

    # done pulses once, then line stays idle
    for _ in range(CLKS_PER_BIT):
        await RisingEdge(dut.clk)
        if dut.uo_out.value[1] == 1:
            break
    else:
        assert False, "o_Tx_Done never asserted"
    await ClockCycles(dut.clk, 3)
    assert dut.uo_out.value[0] == 1
    assert dut.uo_out.value[1] == 0


@cocotb.test()
async def test_single_byte(dut):
    await reset(dut)
    await send_and_check(dut, 0xA5)


@cocotb.test()
async def test_multiple_bytes(dut):
    await reset(dut)
    for b in (0x00, 0xFF, 0x01, 0x80, 0x3C):
        await send_and_check(dut, b)
