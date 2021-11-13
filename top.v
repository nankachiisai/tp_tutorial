module top (
    CLK,
    RST_N,
    RED_N,
    GREEN_N,
    BLUE_N,

    U_TX,
    U_RX
);
    input CLK;
    input RST_N;
    output RED_N;
    output GREEN_N;
    output BLUE_N;

    output U_TX;
    input U_RX;

    wire R_o;
    wire G_o;
    wire B_o;
    reg start;
    wire waitflg;
    wire [7:0] rxtotx;
    wire recvd;

    PWM R(
        .CLK(CLK),
        .RST_N(RST_N),
        .step_i(8'hff),
        .wave_o(R_o)
    );

    PWM G(
        .CLK(CLK),
        .RST_N(RST_N),
        .step_i(8'hff),
        .wave_o(G_o)
    );

    PWM B(
        .CLK(CLK),
        .RST_N(RST_N),
        .step_i(8'h00),
        .wave_o(B_o)
    );

    UART_Tx ut(
        .CLK(CLK),
        .RST_N(RST_N),
        .data_i(rxtotx),
        .signal_o(U_TX),
        .start(start),
        .waitflg(waitflg)
    );

    UART_Rx rt(
        .CLK(CLK),
        .RST_N(RST_N),
        .signal_i(U_RX),
        .data_o(rxtotx),
        .received(recvd)
    );

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            start <= 1'b0;
        end else if (~waitflg & recvd) begin
            start <= 1'b1;
        end else begin
            start <= 1'b0;
        end
    end

    assign RED_N = ~R_o;
    assign GREEN_N = ~G_o;
    assign BLUE_N = ~B_o;
endmodule

module PWM (
    CLK,
    RST_N,
    step_i,
    wave_o
);
    input CLK;
    input RST_N;
    input [7:0] step_i;
    output wave_o;

    reg [7:0] step;
    reg [7:0] counter;

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            step <= 0;
        end else begin
            step <= step_i;
        end
    end

    assign wave_o = (counter < step) ? 1'b1 : 1'b0;
endmodule

module UART_Tx (
    CLK,
    RST_N,

    data_i,
    signal_o,

    start,
    waitflg
);
    input CLK;
    input RST_N;

    input [7:0] data_i;
    output signal_o;

    input start;
    output waitflg;

    reg state;
    reg [7:0] counter;
    reg [3:0] bits;
    reg waitflg_r;
    reg [9:0] shiftreg;
    wire en;

    parameter IDLE = 1'b0;
    parameter SEND = 1'b1;
    parameter boudrate = 208; // 115200bps @ 25MHz Clock

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            state <= IDLE;
        end else if (start) begin
            state <= SEND;
        end else if (bits > 0 && (bits < 10 || bits == 10)) begin
            state <= SEND;
        end else begin
            state <= IDLE;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            counter <= 0;
        end else if (state == SEND) begin
            if (counter == boudrate) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            bits <= 0;
        end else if (start) begin
            bits <= 1;
        end else if (state == SEND) begin
            if (en) begin
                if (bits == 10) begin
                    bits <= 0;
                end else begin
                    bits <= bits + 1;
                end
            end else begin
                ;
            end
        end else begin
            bits <= 0;
        end

    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            waitflg_r <= 1'b0;
        end else if (state == SEND) begin
            waitflg_r <= 1'b1;
        end else if (state == IDLE) begin
            waitflg_r <= 1'b0;
        end else begin
            waitflg_r <= 1'b0;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            shiftreg <= 10'h3ff;
        end else if (start) begin
            shiftreg <= {1'b1, data_i, 1'b0};
        end else if (en && state == SEND) begin
            shiftreg <= {1'b1, shiftreg[9:1]};
        end else if (state == SEND) begin
            ;
        end else begin
            shiftreg <= 10'h3ff;
        end
    end

    assign en = (counter == boudrate) ? 1'b1 : 1'b0;
    assign waitflg = waitflg_r;
    assign signal_o = shiftreg[0];
endmodule

module UART_Rx (
    CLK,
    RST_N,

    signal_i,
    data_o,

    received
);
    input CLK;
    input RST_N;

    input signal_i;
    output [7:0] data_o;

    output received;

    reg [1:0] state;
    reg [7:0] counter;
    reg [7:0] fetch_counter;
    reg fetch_counter2;
    reg [3:0] bits;
    reg [9:0] shiftreg;
    reg prevsig;
    wire en;
    wire fetch_en;

    parameter IDLE = 2'b00;
    parameter RECEIVE = 2'b01;
    parameter DONE = 2'b10;
    parameter boudrate = 208; // 115200bps @ 25MHz Clock

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            state <= IDLE;
        end else if (state == IDLE && ~signal_i && prevsig) begin
            state <= RECEIVE;
        end else if (bits == 10) begin
            state <= DONE;
        end else if (state == DONE) begin
            state <= IDLE;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            counter <= 0;
        end else if (state == RECEIVE) begin
            if (counter == boudrate) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            fetch_counter <= boudrate >> 1;
        end else if (state == RECEIVE) begin
            if (fetch_counter != 0) begin
                fetch_counter <= fetch_counter - 1;
            end else begin
                fetch_counter <= boudrate >> 1;
            end
        end else begin
            fetch_counter <= boudrate >> 1;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            fetch_counter2 <= 0;
        end else if (state == RECEIVE) begin
            if (fetch_counter == 0) begin
                fetch_counter2 <= fetch_counter2 + 1;
            end
        end else begin
            fetch_counter2 <= 0;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            bits <= 0;
        end else if (fetch_en) begin
            bits <= bits + 1;
        end else if (bits == 10) begin
            bits <= 0;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            shiftreg <= 10'h3ff;
        end else if (fetch_en) begin
            shiftreg <= {signal_i, shiftreg[9:1]};
        end else begin
            ;
        end
    end

    always @(posedge CLK or negedge RST_N) begin
        if (~RST_N) begin
            prevsig <= 1'b1;
        end else begin
            prevsig <= signal_i;
        end
    end

    assign en = (counter == boudrate) ? 1'b1 : 1'b0;
    assign fetch_en = ((fetch_counter == boudrate >> 1) & (fetch_counter2 == 1)) ? 1'b1 : 1'b0;
    assign data_o = shiftreg[8:1];
    assign received = (state == DONE) ? 1'b1 : 1'b0;
endmodule
