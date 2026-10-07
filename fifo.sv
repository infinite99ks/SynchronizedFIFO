`include "fifo_interface.sv"

module fifo(fifo_int.DUT dut);

    reg[7: 0] mem [0:3]; // 4 slots of 8-bit elements.
    // Since we got 4 slots, then we need a 2 bits,
    // and so that we can detect if we are full or not, we would an extra bit.
    reg[2: 0] wr_ptr, rd_ptr;

    always@(posedge dut.clk) begin
        if(!dut.rst_n) begin
            dut.data_out <= 'b0;
            wr_ptr <= 'b0;
            rd_ptr <= 'b0;
        end
        else begin
            // Simulataneous read & write thus if statements.
            if(dut.wr_en && !dut.full) begin
                mem[wr_ptr[1: 0]] <= dut.data_in;
                wr_ptr <= wr_ptr +1;
            end
            
            if(dut.rd_en && !dut.empty) begin
                dut.data_out <= mem[rd_ptr[1: 0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Combinational flags.
    assign dut.empty = (rd_ptr == wr_ptr) ? 'b1:'b0;
    assign dut.full = ((rd_ptr[1: 0] == wr_ptr[1: 0]) && (rd_ptr[2] != wr_ptr[2])) ? 'b1: 'b0;
endmodule