`timescale 1ns / 1ps

module tb_dut ();

    logic clk;
    logic reset;

    MCU DUT (.*);

    initial begin
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reset = 1'b1;
        #10;
        reset = 1'b0;
        #1000;
        $stop;
    end
endmodule
