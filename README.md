# FIFO Project
Simple synchronous FIFO in SystemVerilog.

## Specs
- 8-bit data width, 16 entries depth
- Active-low async reset

## Usage
```bash
iverilog -g2012 -o waves/sim.out tb/fifo_tb.sv rtl/fifo.sv
vvp waves/sim.out
gtkwave waves/fifo.vcd
```
