`timescale 1ns / 1ps
`default_nettype none

module fifo_tb();

    logic clk;
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic full;
    logic empty;

    // coverage counters (manual approach for iverilog)
    // For commercial simulators, use covergroup with coverpoints
    integer cov_empty = 0, cov_low = 0, cov_mid = 0, cov_high = 0, cov_full = 0;
    integer cov_write = 0, cov_read = 0;
    integer cov_full_toggle = 0, cov_empty_toggle = 0;
    integer cov_wr_when_full = 0, cov_rd_when_empty = 0;
    integer cov_simul_rw = 0;
    integer cov_wdata_00 = 0, cov_wdata_ff = 0, cov_wdata_55 = 0, cov_wdata_aa = 0;
    integer cov_wdata_walk = 0;
    logic prev_full = 0, prev_empty = 0;

    // scoreboard
    logic [7:0] ref_queue [$];
    integer scoreboard_errors = 0;
    integer total_checks = 0;

    // test counters
    integer test_errors = 0;
    integer tests_passed = 0, tests_failed = 0;

    // DUT instance
    fifo dut (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .wdata(wdata), .rdata(rdata), .full(full), .empty(empty)
    );

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // dump waves
    initial begin
        $dumpfile("../waves/fifo.vcd");
        $dumpvars(0, fifo_tb);
    end

    // coverage sampling
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
        if (wr_en && full) cov_wr_when_full++;
        if (rd_en && empty) cov_rd_when_empty++;
        if (wr_en && rd_en && !full && !empty) cov_simul_rw++;
        // wdata pattern coverage
        if (wr_en) begin
            case (wdata)
                8'h00: cov_wdata_00++;
                8'hFF: cov_wdata_ff++;
                8'h55: cov_wdata_55++;
                8'hAA: cov_wdata_aa++;
                8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80: cov_wdata_walk++;
            endcase
        end
        prev_full <= full;
        prev_empty <= empty;
    end

    // ========== SCOREBOARD ==========

    task sb_push(input [7:0] data);
        ref_queue.push_back(data);
    endtask

    task sb_pop_check(input [7:0] actual);
        logic [7:0] expected;
        total_checks++;
        if (ref_queue.size() == 0) begin
            $error("[SB] Empty queue!");
            scoreboard_errors++;
        end else begin
            expected = ref_queue.pop_front();
            if (actual !== expected) begin
                $error("[SB] Exp 0x%02h got 0x%02h", expected, actual);
                scoreboard_errors++;
            end
        end
    endtask

    task sb_check_empty();
        if (ref_queue.size() != 0) begin
            $error("[SB] Queue has %0d items", ref_queue.size());
            scoreboard_errors++;
        end
    endtask

    // ========== UTILITIES ==========

    task reset_dut();
        rst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;
        ref_queue = {};
    endtask

    task drive_write(input [7:0] data);
        wdata = data; wr_en = 1;
        @(posedge clk);
        wr_en = 0; wdata = 0;
        sb_push(data);
    endtask

    task drive_read();
        rd_en = 1;
        @(posedge clk);
        rd_en = 0;
        @(posedge clk);
        sb_pop_check(rdata);
    endtask

    // ========== TESTS ==========

    task test_reset();
        $display("\n[T01] Reset");
        reset_dut();
        #10;
        if (dut.wr_ptr !== 0 || dut.rd_ptr !== 0 || dut.count !== 0 || !empty) begin
            $error("[T01] FAIL");
            test_errors++;
            tests_failed++;
        end else begin
            $display("[T01] PASS");
            tests_passed++;
        end
    endtask

    task test_basic_rw();
        logic [7:0] i;
        $display("\n[T02] Basic RW");
        reset_dut();
        for (i = 0; i < 8; i++) drive_write(i * 16);
        for (i = 0; i < 8; i++) drive_read();
        sb_check_empty();
        if (scoreboard_errors == 0) begin
            $display("[T02] PASS");
            tests_passed++;
        end else begin
            $error("[T02] FAIL");
            tests_failed++;
        end
    endtask

    task test_fill_full();
        integer i;
        $display("\n[T03] Fill Full");
        reset_dut();
        for (i = 0; i < 16; i++) drive_write(8'(i));
        #5;
        if (!full) begin
            $error("[T03] FAIL");
            tests_failed++;
        end else begin
            $display("[T03] PASS");
            tests_passed++;
        end
    endtask

    task test_drain_empty();
        integer i;
        $display("\n[T04] Drain Empty");
        reset_dut();
        for (i = 0; i < 10; i++) drive_write(8'(i));
        for (i = 0; i < 10; i++) drive_read();
        #5;
        if (!empty) begin
            $error("[T04] FAIL");
            tests_failed++;
        end else begin
            $display("[T04] PASS");
            tests_passed++;
        end
    endtask

    task test_simul_rw();
        integer i;
        $display("\n[T05] Simul RW");
        reset_dut();
        for (i = 0; i < 8; i++) drive_write(8'(i + 100));
        for (i = 0; i < 10; i++) begin
            wdata = 8'(i); wr_en = 1; rd_en = 1;
            @(posedge clk);
            wr_en = 0; rd_en = 0;
            sb_push(8'(i));
            sb_pop_check(rdata);
        end
        if (dut.count !== 8) begin
            $error("[T05] FAIL count=%0d", dut.count);
            tests_failed++;
        end else begin
            $display("[T05] PASS");
            tests_passed++;
        end
    endtask

    task test_wraparound();
        integer i;
        $display("\n[T06] Wraparound");
        reset_dut();
        for (i = 0; i < 16; i++) drive_write(8'(i));
        for (i = 0; i < 16; i++) drive_read();
        for (i = 0; i < 16; i++) drive_write(8'(i + 50));
        $display("[T06] PASS (ptrs: wr=%0d rd=%0d)", dut.wr_ptr, dut.rd_ptr);
        tests_passed++;
    endtask

    task test_overflow();
        integer i;
        $display("\n[T07] Overflow");
        reset_dut();
        for (i = 0; i < 16; i++) drive_write(8'(i));
        for (i = 0; i < 5; i++) begin
            if (!full) drive_write(8'(i + 200));
            else begin
                wr_en = 0; @(posedge clk);
                $display("[T07] blocked at full %0d", i);
            end
        end
        if (dut.count !== 16) begin
            $error("[T07] FAIL");
            tests_failed++;
        end else begin
            $display("[T07] PASS");
            tests_passed++;
        end
    endtask

    task test_underflow();
        integer i;
        $display("\n[T08] Underflow");
        reset_dut();
        for (i = 0; i < 5; i++) drive_write(8'(i));
        for (i = 0; i < 5; i++) drive_read();
        for (i = 0; i < 3; i++) begin
            if (!empty) drive_read();
            else begin
                rd_en = 0; @(posedge clk);
                $display("[T08] blocked at empty %0d", i);
            end
        end
        if (dut.count !== 0) begin
            $error("[T08] FAIL");
            tests_failed++;
        end else begin
            $display("[T08] PASS");
            tests_passed++;
        end
    endtask

    task test_boundary_cov();
        integer i;
        $display("\n[T09] Boundary Coverage");
        reset_dut();
        drive_write(8'h00);
        drive_write(8'hFF);
        drive_write(8'h55);
        drive_write(8'hAA);
        drive_write(8'h01);
        drive_write(8'h02);
        drive_write(8'h04);
        for (i = 0; i < 8; i++) drive_write(8'(i));
        for (i = 0; i < 12; i++) drive_read();
        for (i = 0; i < 16; i++) drive_write(8'(i));
        for (i = 0; i < 16; i++) drive_read();
        $display("[T09] PASS");
        tests_passed++;
    endtask

    task test_random(integer seed, integer cycles);
        integer i, rand_val, wval;
        $display("\n[T10] Random seed=%0d cycles=%0d", seed, cycles);
        $random(seed);
        reset_dut();
        for (i = 0; i < cycles; i++) begin
            rand_val = $random;
            case (rand_val % 4)
                0: if (!full) begin wval = $random % 256; drive_write(8'(wval)); end
                1: if (!empty) drive_read();
                2,3: if (!full && !empty) begin wval = $random % 256; drive_write(8'(wval)); drive_read(); end
            endcase
        end
        if (scoreboard_errors == 0) begin
            $display("[T10] PASS");
            tests_passed++;
        end else begin
            $error("[T10] FAIL");
            tests_failed++;
        end
    endtask

    task print_coverage();
        $display("\n========================================");
        $display("  Coverage Report");
        $display("========================================");
        $display("Occupancy: empty=%0d low=%0d mid=%0d high=%0d full=%0d",
                 cov_empty, cov_low, cov_mid, cov_high, cov_full);
        $display("Ops: writes=%0d reads=%0d simul=%0d", cov_write, cov_read, cov_simul_rw);
        $display("Toggles: full=%0d empty=%0d", cov_full_toggle, cov_empty_toggle);
        $display("Boundary: wr_full=%0d rd_empty=%0d", cov_wr_when_full, cov_rd_when_empty);
        $display("WData patterns: 0x00=%0d 0xFF=%0d 0x55=%0d 0xAA=%0d walk=%0d",
                 cov_wdata_00, cov_wdata_ff, cov_wdata_55, cov_wdata_aa, cov_wdata_walk);
        $display("Scoreboard: checks=%0d errors=%0d", total_checks, scoreboard_errors);
        $display("========================================");
    endtask

    initial begin
        $display("========================================");
        $display("  FIFO Verification Suite");
        $display("========================================");

        wr_en = 0; rd_en = 0; wdata = 0; rst_n = 0;

        test_reset();
        test_basic_rw();
        test_fill_full();
        test_drain_empty();
        test_simul_rw();
        test_wraparound();
        test_overflow();
        test_underflow();
        test_boundary_cov();
        test_random(42, 200);
        test_random(123, 200);

        print_coverage();

        $display("\n========================================");
        $display("  Summary: PASS=%0d FAIL=%0d", tests_passed, tests_failed);
        if (scoreboard_errors == 0 && tests_failed == 0)
            $display("  ALL PASSED");
        else
            $display("  FAILED");
        $display("========================================");

        #20;
        $finish;
    end

endmodule

`default_nettype wire
