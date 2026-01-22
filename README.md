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

## Assertions
- No write when full
- No read when empty  
- Not both full/empty

## Coverage
Occupancy bins: empty, low (1-4), mid (5-10), high (11-15), full (16)

## Changelog
### v1.1 - Jan 22, 2026
- Added assertions and functional coverage

### v1.0 - Jan 19, 2026
- Initial implementation
