`timescale 1ns / 1ps
`default_nettype none
module fifo_tb();
    logic clk, rst_n, wr_en, rd_en;
    logic [7:0] wdata, rdata;
    logic full, empty;
    fifo dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
              .wdata(wdata), .rdata(rdata), .full(full), .empty(empty));
    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin $dumpfile("waves/fifo.vcd"); $dumpvars(0, fifo_tb); end
    task reset_dut; rst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        @(posedge clk); @(posedge clk); rst_n = 1;
    endtask
    task write_byte(input [7:0] d); wdata = d; wr_en = 1; @(posedge clk); wr_en = 0; wdata = 0; endtask
    task read_byte; rd_en = 1; @(posedge clk); rd_en = 0; @(posedge clk); endtask
    initial begin
        rst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        repeat(2) @(posedge clk); reset_dut();
        write_byte(8'hAA); write_byte(8'hBB); write_byte(8'hCC);
        read_byte(); read_byte(); read_byte();
        $display("Test Complete"); #20; $finish;
    end
endmodule
`default_nettype wire
