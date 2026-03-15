`timescale 1ns / 1ps
`default_nettype none

// FIFO interface - decouples TB from DUT
interface fifo_if #(parameter DEPTH=16, parameter WIDTH=8);
    logic clk;
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [WIDTH-1:0] wdata;
    logic [WIDTH-1:0] rdata;
    logic full;
    logic empty;

    // driver modport - TB drives these
    modport driver (
        output wr_en, rd_en, wdata,
        input full, empty, rdata,
        input clk, rst_n
    );

    // monitor modport - TB observes these
    modport monitor (
        input wr_en, rd_en, wdata, rdata,
        input full, empty, clk, rst_n
    );

    // DUT modport
    modport dut (
        input clk, rst_n, wr_en, rd_en, wdata,
        output rdata, full, empty
    );

    // clocking block for driver sync
    clocking drv_cb @(posedge clk);
        default input #1 output #0;
        output wr_en, rd_en, wdata;
        input full, empty, rdata;
    endclocking

    // clocking block for monitor sync
    clocking mon_cb @(posedge clk);
        default input #1 output #0;
        input wr_en, rd_en, wdata, rdata, full, empty;
    endclocking

endinterface

`default_nettype wire