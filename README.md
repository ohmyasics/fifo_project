# FIFO Project

Synchronous FIFO implementation in SystemVerilog with complete verification suite.

## Specs

- Data width: 8 bits
- Depth: 16 entries
- Active-low asynchronous reset
- Overflow/underflow protection

## Files

```
fifo_project/
├── rtl/
│   └── fifo.sv        # FIFO module with SVA assertions
├── tb/
│   ├── fifo_if.sv     # SystemVerilog interface (clocking blocks)
│   └── fifo_tb.sv     # Testbench with scoreboard & coverage
├── docs/
│   └── testplan.md    # Verification test plan
├── scripts/
│   └── Makefile       # Regression runner
└── waves/             # VCD output for GTKWave
```

## Running Simulation

```bash
cd tb
iverilog -g2012 -o fifo_sim ../rtl/fifo.sv fifo_tb.sv
vvp fifo_sim
```

Or use the Makefile:

```bash
cd scripts
make regress
```

## Test Suite

| ID | Test | Description |
|----|------|-------------|
| T01 | test_reset | Verifies reset state |
| T02 | test_basic_rw | FIFO ordering with scoreboard |
| T03 | test_fill_full | Full flag at 16 entries |
| T04 | test_drain_empty | Empty flag behavior |
| T05 | test_simul_rw | Simultaneous read+write |
| T06 | test_wraparound | Pointer wraparound |
| T07 | test_overflow | Write-when-full protection |
| T08 | test_underflow | Read-when-empty protection |
| T09 | test_boundary_cov | Boundary condition coverage |
| T10 | test_random | Constrained-random traffic |

## Verification Features

### SystemVerilog Interface
- `fifo_if.sv` with clocking blocks for timing abstraction
- Driver and monitor modports
- Decouples TB from DUT (modern TB architecture)

### SVA Assertions (RTL)
| Assertion | Description |
|-----------|-------------|
| full_no_write | No write when full |
| empty_no_read | No read when empty |
| not_both_flags | Full and empty never both true |
| count_empty | count==0 implies empty |
| count_full | count==16 implies full |
| count_bounds | Count never exceeds DEPTH |
| ptr_bounds | Pointers stay within range |

### Functional Coverage
| Coverpoint | Bins |
|------------|------|
| Occupancy | empty, low[4], mid[6], high[5], full |
| Operations | idle, write_only, read_only, simul_rw |
| WData patterns | 0x00, 0xFF, 0x55, 0xAA, walking ones |
| Flag toggles | full transitions, empty transitions |
| Boundary attempts | wr_when_full, rd_when_empty |

## Coverage Report Example

```
========================================
  Coverage Report
========================================
Occupancy: empty=43 low=279 mid=250 high=160 full=27
Ops: writes=45 reads=45 simul=10
Toggles: full=19 empty=15
Boundary: wr_full=0 rd_empty=0
WData patterns: 0x00=2 0xFF=2 0x55=1 0xAA=1 walk=5
Scoreboard: checks=222 errors=0
========================================
```

## Changelog

### v1.4 - Mar 15, 2026
- Added SystemVerilog interface with clocking blocks
- Expanded functional coverage (wdata patterns, boundary)
- Added SVA-style assertion documentation in RTL
- Added boundary coverage test

### v1.3 - Jan 25, 2026
- Added verification test plan
- Added scoreboard (self-checking reference model)
- Added 9 directed tests
- Added constrained-random stimulus

### v1.1 - Jan 22, 2026
- Added assertions to RTL
- Added functional coverage counters

### v1.0 - Jan 19, 2026
- Initial implementation
