// UART serial transmitter implementation
// reference - https://nandland.com/uart-serial-port-module/
// Logic and understanding

// For how much time i should hold a particular bit on my output serial port
// UART defines BAUD rate i.e. number of bits per second on the output
// so if BAUD rate =  115200 so each bit stays on the line for 1/BAUD = 8.68 mus
// but for a device everything is in form of clock cycles we want number of clock cycles
// we handle the same state, so for a 10 MHz clock which is 1 million clock cycles per second
// so 1 clock cycle is 100 ns, now for 8.68 mus number of clock cycles would be 8.68mus/100ns = 87
// so each bit stays for approxx 87 clock cycles which is CLKS_PER_BIT that we defined

// UART can exsist in several states
//      1. s_IDLE  - idle state means output signal is high
//      2. s_START - UART needs to send a start bit
//                   To do this first the signal has to be held from high to low
//                   this indicates start of the signal.
//      3. s_DATA  - we transfer bit by bit, maintain internal counter of how which bits have been sent
//                   hold each bit for CLKS_PER_BIT, once data transfer is done we move to indicate STOP
//      4. s_STOP  - This is indicated by making the serial output signal high for CLKS_PER_BIT number of
//                   cycles
//

module uart_tx #(
    parameter CLKS_PER_BIT = 87
) (
    input  wire       i_Clock,
    input  wire       i_Rst_n,
    input  wire       i_Tx_DV,
    input  wire [7:0] i_Tx_Byte,
    output reg        o_Tx_Serial,
    output            o_Tx_Done
);

    localparam s_IDLE  = 3'b000;
    localparam s_START = 3'b001;
    localparam s_DATA  = 3'b010;
    localparam s_STOP  = 3'b011;

    reg [2:0]  r_SM_State;
    reg [15:0] r_Clock_Count;
    reg [2:0]  r_Data_Index;
    reg [7:0]  r_Tx_Data;
    reg        r_Tx_Done;

    assign o_Tx_Done = r_Tx_Done;

    always @(posedge i_Clock) begin
        if (!i_Rst_n) begin
            r_SM_State    <= s_IDLE;
            r_Clock_Count <= 0;
            r_Data_Index  <= 0;
            r_Tx_Data     <= 0;
            r_Tx_Done     <= 1'b0;
            o_Tx_Serial   <= 1'b1;
        end
        else case (r_SM_State)

        s_IDLE: begin
            o_Tx_Serial   <= 1'b1;
            r_Tx_Done     <= 1'b0;
            r_Clock_Count <= 0;
            r_Data_Index  <= 0;

            if (i_Tx_DV == 1'b1) begin
                r_Tx_Data  <= i_Tx_Byte;   // latch byte, input may change later
                r_SM_State <= s_START;
            end
            else begin
                r_SM_State <= s_IDLE;
            end
        end

        s_START: begin
            o_Tx_Serial <= 1'b0;

            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_State    <= s_START;
            end
            else begin
                r_Clock_Count <= 0;
                r_SM_State    <= s_DATA;
            end
        end

        s_DATA: begin
            o_Tx_Serial <= r_Tx_Data[r_Data_Index];

            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_State    <= s_DATA;
            end
            else begin
                r_Clock_Count <= 0;

                if (r_Data_Index < 7) begin
                    r_Data_Index <= r_Data_Index + 1;
                    r_SM_State   <= s_DATA;
                end
                else begin
                    r_Data_Index <= 0;
                    r_SM_State   <= s_STOP;
                end
            end
        end

        s_STOP: begin
            o_Tx_Serial <= 1'b1;

            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_State    <= s_STOP;
            end
            else begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_State    <= s_IDLE;
            end
        end

        default: begin
            r_SM_State <= s_IDLE;
        end

        endcase
    end

endmodule
