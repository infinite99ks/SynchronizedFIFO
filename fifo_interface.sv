interface fifo_int(input clk); // An interface for our fifo.
    logic rst_n, wr_en, rd_en, full, empty;
    logic [7: 0] data_out, data_in;

    clocking cb @(posedge clk);
        default input #1step output #2ns;
        output wr_en, rd_en, rst_n;
        output negedge data_in;
        input full, empty, data_out;
    endclocking

    // Organizing the ports for the TB and the DUT via modports
    modport DUT(input clk, rst_n, wr_en, rd_en, data_in,
                output data_out, full, empty);
    modport TB(clocking cb);

    // Our assertions.
    property check_flags;
        @(posedge clk) !rst_n |=> empty && !full;
    endproperty
    assert property (check_flags);

    // If wr_en stays on for 4 consecutive writes with no read,
    // full must be on on the next clock edge.
    property check_full;
        disable iff (!rst_n)
        @(posedge clk) (empty ##0 (wr_en && !rd_en)[*4]) |=> full;    
        endproperty
    assert property(check_full);

    // If empty and wr_en, the empty flag should be down the consequent cycle.
    property check_fall;
        disable iff (!rst_n)
        @(posedge clk) (empty && wr_en) |=> !empty;
    endproperty
    assert property(check_fall);

    // Overflow protection
    property overflow;
        disable iff (!rst_n)
        @(posedge clk) (full && wr_en && !rd_en) |=> full;
    endproperty
    assert property (overflow);

    // Underflow protection
    property underflow;
        disable iff (!rst_n)
        @(posedge clk) (empty && rd_en && !wr_en) |=> empty;
    endproperty
    assert property (underflow);    

endinterface