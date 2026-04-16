# FIFO Verification Makefile

IV = iverilog
VVP = vvp
TB = ../tb/fifo_tb.sv
RTL = ../rtl/fifo.sv
WAVES = ../waves
SIM = $(WAVES)/sim.out

.PHONY: all clean test_smoke test_full regress ci

all: compile

compile:
	@mkdir -p $(WAVES)
	$(IV) -g2012 -o $(SIM) $(TB) $(RTL)
	@echo "Compilation complete."

# Quick smoke test
test_smoke: compile
	@echo "Running smoke test..."
	$(VVP) $(SIM) 2>&1 | tee $(WAVES)/smoke.log

# Full regression
regress: compile
	@echo "Running full regression..."
	@echo ""
	$(VVP) $(SIM) 2>&1 | tee $(WAVES)/regress.log
	@echo ""
	@echo "Checking for failures..."
	@if grep -q "ALL PASSED" $(WAVES)/regress.log && ! grep -q "FAILED\|ERROR" $(WAVES)/regress.log; then \
		echo "REGRESSION PASSED"; \
	else \
		echo "REGRESSION FAILED - see $(WAVES)/regress.log"; \
		exit 1; \
	fi

ci: regress

# Individual test targets (for future expansion)
test_reset: compile
	@echo "Test: reset"
	$(VVP) $(SIM) 2>&1 | grep -A2 "\[T01\]"

test_basic: compile
	@echo "Test: basic_rw"
	$(VVP) $(SIM) 2>&1 | grep -A2 "\[T02\]"

test_overflow: compile
	@echo "Test: overflow"
	$(VVP) $(SIM) 2>&1 | grep -A2 "\[T07\]"

test_underflow: compile
	@echo "Test: underflow"
	$(VVP) $(SIM) 2>&1 | grep -A2 "\[T08\]"

# Random test with specific seed
test_rand: compile
	@echo "Running random test with SEED=$(SEED)..."
	$(VVP) $(SIM) 2>&1 | grep -A5 "\[T10\]"

# View waveforms
waves:
	gtkwave $(WAVES)/fifo.vcd

clean:
	rm -f $(SIM) $(WAVES)/*.vcd $(WAVES)/*.log
	@echo "Cleaned."
