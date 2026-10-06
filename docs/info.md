<!---
Project datasheet source.
-->

## How it works

An 8N1 UART transmitter. A small state machine (IDLE, START, DATA, STOP) holds each bit on the
line for `CLKS_PER_BIT` clock cycles (87 = 10 MHz clock / 115200 baud). The byte is latched when
`i_Tx_DV` is pulsed, sent LSB first, and `o_Tx_Done` pulses for one clock after the stop bit.
The line idles high. `rst_n` (active low) resets the state machine.

## How to test

1. Apply a 10 MHz clock and pulse `rst_n` low, then high.
2. Put a byte on `uio[7:0]`.
3. Pulse `ui[0]` high for one clock cycle.
4. Read the serial frame (start bit, 8 data bits LSB first, stop bit) on `uo[0]` at 115200 baud.
   `uo[1]` pulses high when the frame is finished.

Simulation: `cd test && make` (cocotb + Icarus Verilog).

## External hardware

A USB-UART adapter (or any 3.3 V UART receiver) connected to `uo[0]`.
