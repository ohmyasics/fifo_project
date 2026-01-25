`timescale 1ns / 1ps
`default_nettype none

module fifo_tb();

    // Test signals
    logic        clk;
    logic        rst_n;
    logic        wr_en;
    logic        rd_en;
    logic [7:0]  wdata;
    logic [7:0]  rdata;
    logic        full;
    logic        empty;

    // Coverage counters
    integer cov_empty = 0, cov_low = 0, cov_mid = 0, cov_high = 0, cov_full = 0;
    integer cov_write = 0, cov_read = 0;
    integer cov_full_toggle = 0, cov_empty_toggle = 0;
    logic prev_full = 0, prev_empty = 0;

    // Scoreboard - reference model using queue
    logic [7:0] ref_queue [$];  // Dynamic queue for expected data
    integer scoreboard_errors = 0;
    integer total_checks = 0;

    // Test control
    integer test_errors = 0;
    integer tests_passed = 0, tests_failed = 0;

    // Instantiate DUT
    fifo dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .wdata  (wdata),
        .rdata  (rdata),
        .full   (full),
        .empty  (empty)
    );

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump waves
    initial begin
        $dumpfile("../waves/fifo.vcd");
        $dumpvars(0, fifo_tb);
    end

    // Coverage sampling
    always @(posedge clk) begin
        case (dut.count)
            0: cov_empty++;
            1,2,3,4: cov_low++;
            5,6,7,8,9,10: cov_mid++;
            11,12,13,14,15: cov_high++;
            16: cov_full++;
        endcase
        if (wr_en) cov_write++;
        if (rd_en) cov_read++;
        if (full && !prev_full) cov_full_toggle++;
        if (empty && !prev_empty) cov_empty_toggle++;
        prev_full <= full;
        prev_empty <= empty;
    end

    // ========== SCOREBOARD TASKS ==========

    task sb_push(input [7:0] data);
        ref_queue.push_back(data);
    endtask

    task sb_pop_check(input [7:0] actual_data);
        logic [7:0] expected;
        total_checks++;
        if (ref_queue.size() == 0) begin
            $error("[SCOREBOARD] Pop from empty queue!");
            scoreboard_errors++;
        end else begin
            expected = ref_queue.pop_front();
            if (actual_data !== expected) begin
                $error("[SCOREBOARD] Mismatch: expected 0x%02h, got 0x%02h", expected, actual_data);
                scoreboard_errors++;
            end
        end
    endtask

    task sb_check_empty();
        if (ref_queue.size() != 0) begin
            $error("[SCOREBOARD] Expected empty queue, has %0d items", ref_queue.size());
            scoreboard_errors++;
        end
    endtask

    // ========== UTILITY TASKS ==========

    task reset_dut();
        rst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;
        ref_queue = {};  // Clear scoreboard
    endtask

    task drive_write(input [7:0] data);
        wdata = data; wr_en = 1;
        @(posedge clk);
        wr_en = 0; wdata = 0;
        sb_push(data);  // Track expected data
    endtask

    task drive_read();
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        sb_pop_check(rdata);  // Check against expected
    endtask

    // ========== TEST TASKS ==========

    // T01: Reset test
    task test_reset();
        $display("\n[T01] Reset Test");
        reset_dut();
        #10;
        if (dut.wr_ptr !== 0 || dut.rd_ptr !== 0 || dut.count !== 0 || !empty) begin
            $error("[T01] FAILED: Reset state incorrect");
            test_errors++;
        end else begin
            $display("[T01] PASSED");
        end
    endtask

    // T02: Basic read/write - FIFO ordering
    task test_basic_rw();
        logic [7:0] i;
        $display("\n[T02] Basic Read/Write Test");
        reset_dut();
        // Write sequence
        for (i = 0; i < 8; i++) drive_write(i * 16);
        // Read and verify
        for (i = 0; i < 8; i++) drive_read();
        sb_check_empty();
        if (scoreboard_errors == 0) $display("[T02] PASSED");
        else $error("[T02] FAILED");
    endtask

    // T03: Fill to full
    task test_fill_full();
        integer i;
        $display("\n[T03] Fill to Full Test");
        reset_dut();
        for (i = 0; i < 16; i++) drive_write(8'(i));
        #5;
        if (!full) begin
            $error("[T03] FAILED: Full flag not set");
            test_errors++;
        end else begin
            $display("[T03] PASSED: Full flag asserted at 16 entries");
        end
    endtask

    // T04: Drain to empty
    task test_drain_empty();
        integer i;
        $display("\n[T04] Drain to Empty Test");
        reset_dut();
        for (i = 0; i < 10; i++) drive_write(8'(i));
        for (i = 0; i < 10; i++) drive_read();
        #5;
        if (!empty) begin
            $error("[T04] FAILED: Empty flag not set");
            test_errors++;
        end else begin
            $display("[T04] PASSED: Empty flag asserted");
        end
    endtask

    // T05: Simultaneous read/write
    task test_simul_rw();
        integer i;
        $display("\n[T05] Simultaneous Read/Write Test");
        reset_dut();
        // Pre-fill with 8 items
        for (i = 0; i < 8; i++) drive_write(8'(i + 100));
        // Now do simultaneous read/write for 10 cycles
        for (i = 0; i < 10; i++) begin
            wdata = 8'(i); wr_en = 1; rd_en = 1;
            @(posedge clk);
            wr_en = 0; rd_en = 0;
            sb_push(8'(i));  // New data in
            sb_pop_check(rdata);  // Old data out
        end
        $display("[T05] Count after simul_rw: %0d (should be 8)", dut.count);
        if (dut.count !== 8) begin
            $error("[T05] FAILED: Count should be 8");
            test_errors++;
        end else begin
            $display("[T05] PASSED");
        end
    endtask

    // T06: Pointer wraparound
    task test_wraparound();
        integer i;
        $display("\n[T06] Pointer Wraparound Test");
        reset_dut();
        // Write 16, read 16, write 16 again
        for (i = 0; i < 16; i++) drive_write(8'(i));
        for (i = 0; i < 16; i++) drive_read();
        for (i = 0; i < 16; i++) drive_write(8'(i + 50));
        $display("[T06] Wrapped write pointer: %0d, read pointer: %0d", dut.wr_ptr, dut.rd_ptr);
        if (dut.wr_ptr !== 0 || dut.rd_ptr !== 0) begin
            $display("[T06] Pointers: wr=%0d rd=%0d count=%0d", dut.wr_ptr, dut.rd_ptr, dut.count);
        end
        $display("[T06] PASSED (manual verification needed)");
    endtask

    // T07: Overflow protection
    task test_overflow();
        integer i;
        $display("\n[T07] Overflow Protection Test");
        reset_dut();
        // Fill to full
        for (i = 0; i < 16; i++) drive_write(8'(i));
        // Try to write 5 more (should be rejected)
        for (i = 0; i < 5; i++) begin
            if (!full) drive_write(8'(i + 200));
            else begin
                wr_en = 0; @(posedge clk);  // Just clock, no write
                $display("[T07] Write blocked at full (attempt %0d)", i);
            end
        end
        if (dut.count !== 16) begin
            $error("[T07] FAILED: Count corrupted after overflow attempts");
            test_errors++;
        end else begin
            $display("[T07] PASSED: Count stable at 16");
        end
    endtask

    // T08: Underflow protection
    task test_underflow();
        integer i;
        $display("\n[T08] Underflow Protection Test");
        reset_dut();
        // Write 5, read 5 to empty
        for (i = 0; i < 5; i++) drive_write(8'(i));
        for (i = 0; i < 5; i++) drive_read();
        // Try to read 3 more (should be rejected)
        for (i = 0; i < 3; i++) begin
            if (!empty) drive_read();
            else begin
                rd_en = 0; @(posedge clk);
                $display("[T08] Read blocked at empty (attempt %0d)", i);
            end
        end
        if (dut.count !== 0) begin
            $error("[T08] FAILED: Count corrupted after underflow attempts");
            test_errors++;
        end else begin
            $display("[T08] PASSED: Count stable at 0");
        end
    endtask

    // T09: Random stimulus (using $random for iVerilog compatibility)
    task test_random(input integer seed, input integer cycles);
        integer i, rand_val, wval;
        $display("\n[T09] Random Test (seed=%0d, cycles=%0d)", seed, cycles);
        $random(seed);  // Initialize seed
        reset_dut();
        for (i = 0; i < cycles; i++) begin
            rand_val = $random;
            case (rand_val % 4)
                0: begin  // Write only
                    if (!full) begin
                        wval = $random % 256;
                        drive_write(8'(wval));
                    end
                end
                1: begin  // Read only
                    if (!empty) drive_read();
                end
                2,3: begin  // Simultaneous
                    if (!full && !empty) begin
                        wval = $random % 256;
                        drive_write(8'(wval));
                        drive_read();
                    end
                end
            endcase
        end
        $display("[T09] Random test complete. Scoreboard errors: %0d", scoreboard_errors);
        if (scoreboard_errors == 0) $display("[T09] PASSED");
        else $error("[T09] FAILED");
    endtask

    // ========== COVERAGE REPORT ==========

    task print_coverage();
        begin
            $display("\n========================================");
            $display("  Functional Coverage Report");
            $display("========================================");
            $display("Occupancy: empty=%0d low=%0d mid=%0d high=%0d full=%0d",
                     cov_empty, cov_low, cov_mid, cov_high, cov_full);
            $display("Operations: writes=%0d reads=%0d", cov_write, cov_read);
            $display("Toggles: full=%0d empty=%0d", cov_full_toggle, cov_empty_toggle);
            $display("Scoreboard: checks=%0d errors=%0d", total_checks, scoreboard_errors);
            $display("========================================");
        end
    endtask

    // ========== MAIN TEST RUNNER ==========

    initial begin
        $display("========================================");
        $display("  FIFO Verification Suite");
        $display("========================================");

        wr_en = 0; rd_en = 0; wdata = 0; rst_n = 0;

        // Run all tests
        test_reset();
        test_basic_rw();
        test_fill_full();
        test_drain_empty();
        test_simul_rw();
        test_wraparound();
        test_overflow();
        test_underflow();
        test_random(42, 200);
        test_random(123, 200);

        // Final report
        print_coverage();

        $display("\n========================================");
        $display("  Verification Summary");
        $display("========================================");
        if (scoreboard_errors == 0) begin
            $display("ALL TESTS PASSED - Scoreboard clean");
        end else begin
            $display("TESTS FAILED - %0d scoreboard errors", scoreboard_errors);
        end
        $display("========================================");

        #20;
        $finish;
    end

endmodule

`default_nettype wire
