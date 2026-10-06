/*
 * Copyright (c) 2024 Yogesh
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// UART transmitter wrapper.
//   ui_in[0]   : i_Tx_DV   (pulse high 1 clock to send uio_in)
//   uio_in[7:0]: i_Tx_Byte (byte to send)
//   uo_out[0]  : o_Tx_Serial (UART TX line, idles high)
//   uo_out[1]  : o_Tx_Done   (1 clock pulse after stop bit)
module tt_um_uart_tx (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire tx_serial;
  wire tx_done;

  // 10 MHz clock / 115200 baud ~= 87 clocks per bit
  uart_tx #(
      .CLKS_PER_BIT(87)
  ) u_uart_tx (
      .i_Clock    (clk),
      .i_Rst_n    (rst_n),
      .i_Tx_DV    (ui_in[0]),
      .i_Tx_Byte  (uio_in),
      .o_Tx_Serial(tx_serial),
      .o_Tx_Done  (tx_done)
  );

  assign uo_out  = {6'b0, tx_done, tx_serial};
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;  // all bidirectional pins are inputs (data byte)

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:1], 1'b0};

endmodule
