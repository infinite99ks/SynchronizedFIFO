class fifo_transaction;
    rand bit wr_en, rd_en;
    randc bit [7: 0] data_in;

    constraint read_write {
        wr_en dist {0:/40, 1:/60};
        rd_en dist {0:/60, 1:/40};
    }
endclass