# FIFO Project

Simple synchronous FIFO implementation in SystemVerilog with verification suite.

## Specs

- Data width: 8 bits
- Depth: 16 entries
- Active-low asynchronous reset

## Files

```
fifo_project/
├── rtl/
│   └── fifo.sv        # FIFO module with assertions
├── tb/
│   └── fifo_tb.sv     # Testbench with scoreboard & coverage
├── docs/
│   └── testplan.md    # Verification test plan
├── scripts/
│   └── Makefile       # Regression runner
└── waves/             # Simulation output
```

## Running Simulation

```bash
cd scripts
make compile
make regress
make waves
```

## Test Suite

| ID | Test | Description |
|----|------|-------------|
| T01 | test_reset | Verifies pointers/count/flags after reset |
| T02 | test_basic_rw | Confirms FIFO ordering with scoreboard |
| T03 | test_fill_full | Verifies full flag at 16 entries |
| T04 | test_drain_empty | Verifies empty flag behavior |
| T05 | test_simul_rw | Tests simultaneous read+write cycles |
| T06 | test_wraparound | Verifies pointer wraparound |
| T07 | test_overflow | Confirms write-when-full protection |
| T08 | test_underflow | Confirms read-when-empty protection |
| T09 | test_random | Constrained-random traffic (2 seeds) |

## Verification Features

### Scoreboard
Self-checking reference model using SystemVerilog queues.

### Functional Coverage
| Coverage Type | Bins |
|---------------|------|
| Occupancy | empty, low, mid, high, full |
| Toggle | full/empty transitions |

## Changelog

### v1.3 - Jan 25, 2026
- Added verification test plan
- Added scoreboard (self-checking reference model)
- Added 9 directed tests
- Added constrained-random stimulus
- Added Makefile regression flow

### v1.1 - Jan 22, 2026
- Added assertions to RTL
- Added functional coverage

### v1.0 - Jan 19, 2026
- Initial implementation
