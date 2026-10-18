`include "fifo_interface.sv"
`include "tb.sv"
`include "transaction_class.sv"
`include "fifo.sv"

module top;
    bit clk;
    always #5 clk = ~clk; // CLk.
    fifo_int fifo_if(clk);
    fifo DUT(fifo_if.DUT);
    tb testbench(fifo_if.TB);
endmodule