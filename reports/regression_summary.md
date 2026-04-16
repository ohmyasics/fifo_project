# FIFO Regression Summary

Environment used for the checked run:

- Simulator: Icarus Verilog 11.0
- Command: `make -C scripts ci`
- Wave dump: `waves/fifo.vcd`

## What Was Checked

The testbench drives reset, ordered writes/reads, full and empty transitions, pointer wraparound, blocked overflow/underflow attempts, boundary data values, and two random traffic seeds. The scoreboard keeps an expected FIFO queue and checks read data when the DUT returns it.

## Current Result

```text
Summary: PASS=11 FAIL=0
Scoreboard: checks=222 errors=0
```

Coverage is intentionally simple and tool-portable. The counters are enough to show that the regression visits empty, low, mid, high, and full occupancy ranges, exercises simultaneous read/write, and writes the main data patterns used in debug.

## Notes

The testbench uses procedural assertion-style checks because the target open-source simulator is Icarus Verilog. The RTL comments call out the SVA intent so the same checks can be moved into properties if the repo is run under a commercial simulator later.
