# FIFO Verification Test Plan

## Overview

This document describes the verification plan for the 8-bit wide, 16-deep synchronous FIFO.

## Test Scenarios

| ID | Test Name | Goal | Coverage Target |
|----|-----------|------|-----------------|
| T01 | `test_reset` | Verify pointers/count/flags after reset | Empty bin |
| T02 | `test_basic_rw` | Confirm FIFO ordering (LIFO would fail) | Low occupancy |
| T03 | `test_fill_full` | Verify full flag and reject writes at capacity | Full bin |
| T04 | `test_drain_empty` | Verify empty flag and reject reads when empty | Empty toggle |
| T05 | `test_simul_rw` | Verify count/data under same-cycle read+write | Mid/High occupancy |
| T06 | `test_wraparound` | Verify pointer wraparound works correctly | All occupancy bins |
| T07 | `test_overflow` | Verify write-when-full does not corrupt state | Full + recovery |
| T08 | `test_underflow` | Verify read-when-empty does not corrupt state | Empty + recovery |
| T09 | `test_random` | Constrained-random traffic for coverage closure | All bins |

## Corner Cases

### 1. Overflow Protection
- Fill FIFO to full (16 entries)
- Attempt extra writes
- Verify: count stays at 16, old data preserved, no corruption

### 2. Underflow Protection
- Drain FIFO to empty
- Attempt extra reads
- Verify: count stays at 0, rdata stable, no corruption

### 3. Simultaneous Read/Write
- Apply `wr_en=1` and `rd_en=1` in same cycle
- Test at: empty, partially full, and full conditions
- Verify: count unchanged when both active, data flows correctly

### 4. Pointer Wraparound
- Write 16, read 16, write 16 again
- Verify: pointers wrap from 15→0 correctly
- Verify: no off-by-one errors

### 5. Back-to-Back Operations
- Continuous writes until full
- Continuous reads until empty
- Verify: no glitches on flags

## Pass Criteria

1. All assertions pass (no $error messages)
2. Scoreboard matches: all read data matches expected
3. Coverage > 90% across all bins
4. Regression passes all seeds

## Coverage Goals

| Bin Type | Target |
|----------|--------|
| Occupancy (all 5 bins) | Hit at least once |
| Write operations | 50+ |
| Read operations | 50+ |
| Full toggle | Both transitions |
| Empty toggle | Both transitions |
