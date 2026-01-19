`timescale 1ns / 1ps
`default_nettype none

module fifo (
    input wire        clk,
    input wire        rst_n,
    input wire        wr_en,
    input wire        rd_en,
    input wire [7:0]  wdata,
    output logic [7:0] rdata,
    output logic      full,
    output logic      empty
);
    localparam DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(DEPTH);
    logic [7:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0] count;
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_ptr <= 0;
        else if (wr_en && !full) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin rd_ptr <= 0; rdata <= 0; end
        else if (rd_en && !empty) begin
            rdata <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) count <= 0;
        else case ({wr_en && !full, rd_en && !empty})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: count <= count;
        endcase
    end
endmodule
`default_nettype wire
