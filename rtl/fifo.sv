`timescale 1ns / 1ps
`default_nettype none

// Simple synchronous FIFO - 8 bit width, 16 entries deep
// Active-low reset
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

    // Memory array for FIFO storage
    logic [7:0] mem [0:DEPTH-1];

    // Pointers and count
    logic [ADDR_WIDTH-1:0] wr_ptr;
    logic [ADDR_WIDTH-1:0] rd_ptr;
    logic [ADDR_WIDTH:0]   count;  // need extra bit to detect full

    // Status flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Write data on clock edge if not full
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read data - goes out one cycle after rd_en
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rdata  <= 0;
        end else if (rd_en && !empty) begin
            rdata <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Track how many items in FIFO
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1;  // write only
                2'b01: count <= count - 1;  // read only
                default: count <= count;    // idle or both
            endcase
        end
    end

    // ============ ASSERTIONS (using $error for iVerilog compat) ============
    
    // Check: no write when full
    always @(posedge clk) begin
        if (rst_n && full && wr_en) begin
            $error("ASSERT FAIL: Write attempted when FIFO full");
        end
    end

    // Check: no read when empty
    always @(posedge clk) begin
        if (rst_n && empty && rd_en) begin
            $error("ASSERT FAIL: Read attempted when FIFO empty");
        end
    end

    // Check: full and empty cannot both be true
    always @(posedge clk) begin
        if (rst_n && full && empty) begin
            $error("ASSERT FAIL: FIFO cannot be both full and empty");
        end
    end

    // Check: count==0 implies empty
    always @(posedge clk) begin
        if (rst_n && (count == 0) && !empty) begin
            $error("ASSERT FAIL: Count is 0 but empty not set");
        end
    end

    // Check: count==DEPTH implies full
    always @(posedge clk) begin
        if (rst_n && (count == DEPTH) && !full) begin
            $error("ASSERT FAIL: Count is max but full not set");
        end
    end

endmodule

`default_nettype wire
