`timescale 1ns/1ps

module top_test (
);
    reg CLK;
    reg RST_N;
    wire RED_N;
    wire GREEN_N;
    wire BLUE_N;
    wire U_TX;
    reg U_RX;
    reg [9:0] shiftreg;
    reg [9:0] tmpreg;

    parameter CLK_T = 40;
    parameter BOUDRATE = 2604;

    top t(
        .CLK(CLK),
        .RST_N(RST_N),
        .RED_N(RED_N),
        .GREEN_N(GREEN_N),
        .BLUE_N(BLUE_N),
    
        .U_TX(U_TX),
        .U_RX(U_RX)
    );

    initial begin
        $dumpfile("top_test.vcd");
        $dumpvars(0, t);
    end

    initial begin
        shiftreg = 10'b0101010101;

        CLK = 1'b1;
        RST_N = 1'b0;
        U_RX = 1'b1;

        #10 RST_N = 1'b1;


        // RX Test
        repeat (1000) @(posedge CLK);
        U_RX = shiftreg[9];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[8];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[7];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[6];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[5];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[4];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[3];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[2];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[1];

        repeat(BOUDRATE) @(posedge CLK);
        U_RX = shiftreg[0];

        // TX Test
        repeat(BOUDRATE) @(posedge CLK);
        repeat(BOUDRATE / 2) @(posedge CLK);
        tmpreg[9] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[8] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[7] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[6] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[5] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[4] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[3] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[2] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[1] = U_TX;

        repeat(BOUDRATE) @(posedge CLK);
        tmpreg[0] = U_TX;

        @(negedge t.waitflg);
        if (shiftreg[8:1] == tmpreg[8:1]) begin
            $display("passed!");
        end else begin
            $display("failed! 0x%03x 0x%03x", shiftreg[8:1], tmpreg);
        end

        $finish;
    end

    initial forever begin
        #CLK_T CLK = ~CLK;
    end
endmodule