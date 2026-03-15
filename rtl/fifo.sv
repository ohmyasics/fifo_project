`timescale 1ns / 1ps
`default_nettype none

// Synchronous FIFO - 8 bit width, 16 entries deep
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
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH:0]   count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rdata  <= 0;
        end else if (rd_en && !empty) begin
            rdata <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // count tracking
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    // =====================================================
    // ASSERTIONS (procedural for iverilog compat)
    // SVA equivalents for commercial simulators shown in comments
    // =====================================================

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) full |-> !wr_en);
    always @(posedge clk) begin
        if (rst_n && full && wr_en)
            $error("ASSERT: Write when full");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) empty |-> !rd_en);
    always @(posedge clk) begin
        if (rst_n && empty && rd_en)
            $error("ASSERT: Read when empty");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) !(full && empty));
    always @(posedge clk) begin
        if (rst_n && full && empty)
            $error("ASSERT: Both full and empty");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) (count == 0) |-> empty);
    always @(posedge clk) begin
        if (rst_n && (count == 0) && !empty)
            $error("ASSERT: Count zero but not empty");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) (count == DEPTH) |-> full);
    always @(posedge clk) begin
        if (rst_n && (count == DEPTH) && !full)
            $error("ASSERT: Count max but not full");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) count <= DEPTH);
    always @(posedge clk) begin
        if (rst_n && count > DEPTH)
            $error("ASSERT: Count overflow");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) wr_ptr < DEPTH);
    always @(posedge clk) begin
        if (rst_n && wr_ptr >= DEPTH)
            $error("ASSERT: Write ptr overflow");
    end

    // SVA: assert property (@(posedge clk) disable iff (!rst_n) rd_ptr < DEPTH);
    always @(posedge clk) begin
        if (rst_n && rd_ptr >= DEPTH)
            $error("ASSERT: Read ptr overflow");
    end

endmodule

`default_nettype wire
