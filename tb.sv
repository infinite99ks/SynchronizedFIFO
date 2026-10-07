`include "fifo_interface.sv"
`include "transaction_class.sv"
`include "fifo.sv"

// STILL A WIP.
program tb(fifo_int.TB testbench);
    fifo_transaction t;
    logic[7: 0] golden_queue[$];
    logic[7: 0] expected_out, prv_data;
    bit check_rd;

    initial begin
        t = new();
        // Resetting our DUT.
        testbench.cb.rst_n <= 'b0;
        testbench.cb.wr_en <= 'b0;
        testbench.cb.rd_en <= 'b0;
        testbench.cb.data_in <= 'b0;
        repeat(2) @(testbench.cb);
        
        testbench.cb.rst_n <= 'b1; // Raising our reset.
        @(testbench.cb);
        
        repeat(5) begin

            // Passing our random values to our testbench.
            assert (t.randomize()) else $fatal(0, "randomize failed");
            testbench.cb.wr_en <= t.wr_en;
            testbench.cb.rd_en <= t.rd_en;
            testbench.cb.data_in <= t.data_in;

            @(testbench.cb); // Advancing our clock.


            // since we sample the TB input (data_out) a whole step before the clock edge,
            // the clock needs to be advanced twice.
            if (check_rd) begin
                assert (testbench.cb.data_out == expected_out)
                else $error("MISMATCH exp=%0h got=%0h", expected_out, testbench.cb.data_out);
                check_rd = 0;   
            end
            
            // Pushing the data into our golden model.
            if(t.rd_en && !testbench.cb.empty) begin
                if(golden_queue.size() == 0) $error("The golden queue is empty");
                else begin
                    expected_out = golden_queue.pop_front();
                    check_rd = 1;
                end
            end

            if(t.wr_en && !testbench.cb.full) begin
                golden_queue.push_back(t.data_in);
            end
        end
    end
endprogram