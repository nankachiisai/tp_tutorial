`timescale 1ns/1ps

module UART_Rx_test (
);
    reg CLK;
    reg RST_N;
    wire signal;
    wire [7:0] data;
    reg start;
    wire waitflg;
    reg received;

    UART_Tx ut(
        .CLK(CLK),
        .RST_N(RST_N),
        .data_i(8'haa),
        .signal_o(signal),
        .start(start),
        .waitflg(waitflg)
    );

    UART_Rx ur(
        .CLK(CLK),
        .RST_N(RST_N),
        .signal_i(signal),
        .data_o(data),
        .received(recieved)
    );

    initial begin
        $dumpfile("UART_Rx_test.vcd");
        $dumpvars(0, ur, ut);
    end

    initial begin
        CLK = 1'b1;
        RST_N = 1'b0;
        start = 1'b0;

        #10 RST_N = 1'b1;

        #3000 start = 1'b1;
        #1 start = 1'b0;

        @(posedge ur.received) $finish;
    end

    initial forever begin
        #1 CLK = ~CLK;
    end
endmodule