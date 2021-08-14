`timescale 1ns/1ps

module UART_Tx_test (
);
    reg CLK;
    reg RST_N;
    wire signal;
    reg start;
    wire waitflg;

    UART_Tx ut(
        .CLK(CLK),
        .RST_N(RST_N),
        .data_i(8'haa),
        .signal_o(signal),
        .start(start),
        .waitflg(waitflg)
    );

    initial begin
        $dumpfile("UART_Tx_test.vcd");
        $dumpvars(0, ut);
    end

    initial begin
        CLK = 1'b1;
        RST_N = 1'b0;
        start = 1'b0;

        #10 RST_N = 1'b1;

        #3000 start = 1'b1;
        #1 start = 1'b0;

        #100000 $finish;
    end

    initial forever begin
        #1 CLK = ~CLK;
    end
endmodule