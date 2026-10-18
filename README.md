# Synchronized FIFO

A parameter-light, single-clock synchronous FIFO written in SystemVerilog, together with a self-checking, constrained-random testbench and SystemVerilog Assertions (SVA) that verify its flag and protection behavior.

## Features

- **4 entries × 8 bits**, single clock domain
- **Active-low synchronous reset** (`rst_n`)
- **Simultaneous read and write** in the same cycle
- **Registered read data** (`data_out` updates one clock after a read is accepted)
- **Combinational `full` / `empty` flags**, derived from extended (3-bit) pointers
- **Overflow / underflow protection**: writes while full and reads while empty are ignored
- **Verification environment** with a scoreboard (golden queue), constrained-random stimulus, and concurrent assertions

## Repository Structure

| File | Description |
|------|-------------|
| `fifo.sv` | The FIFO design (DUT) |
| `fifo_interface.sv` | `fifo_int` interface: signals, clocking block, modports, and assertions |
| `transaction_class.sv` | `fifo_transaction` class with randomized `wr_en`, `rd_en`, `data_in` |
| `tb.sv` | Testbench `program`: reset, random stimulus, and golden-model checking |
| `top.sv` | Top-level module: generates the clock and wires the DUT and testbench together |

## Design Overview

### Interface

| Signal | Direction | Width | Description |
|--------|-----------|-------|-------------|
| `clk` | input | 1 | Clock (rising edge) |
| `rst_n` | input | 1 | Active-low synchronous reset |
| `wr_en` | input | 1 | Write enable |
| `rd_en` | input | 1 | Read enable |
| `data_in` | input | 8 | Write data |
| `data_out` | output | 8 | Read data (registered) |
| `full` | output | 1 | Asserted when all 4 slots are occupied |
| `empty` | output | 1 | Asserted when no data is stored |

### How it works

The storage is a 4-deep memory (`mem[0:3]`). Each of the read and write pointers is **3 bits wide**: the lower 2 bits index the memory and the extra MSB tracks wrap-around, which lets the FIFO distinguish between full and empty without a separate counter.

- **Empty:** `rd_ptr == wr_ptr`
- **Full:** lower 2 bits equal, but the MSBs differ

On each rising clock edge (when not in reset):

- If `wr_en && !full`, `data_in` is stored and `wr_ptr` increments.
- If `rd_en && !empty`, `mem[rd_ptr]` is latched into `data_out` and `rd_ptr` increments.

Both can happen in the same cycle. On reset, both pointers and `data_out` are cleared.

## Verification

### Stimulus (`transaction_class.sv`)

Each transaction randomizes `wr_en`, `rd_en`, and `data_in`:

- `wr_en` is biased toward 1 (60% high / 40% low)
- `rd_en` is biased toward 0 (40% high / 60% low)
- `data_in` is `randc`, so values cycle through the 8-bit range without repeating until exhausted

The write bias makes the FIFO tend to fill up, exercising the `full` condition.

### Testbench (`tb.sv`)

1. Holds the DUT in reset for 2 clock cycles, then releases it.
2. Runs a loop of random transactions (currently **5 iterations**), driving signals through the clocking block.
3. Maintains a **golden queue** model: accepted writes are pushed, accepted reads are popped.
4. One cycle after each accepted read, compares `data_out` against the expected value from the golden queue and reports `MISMATCH` via `$error` on failure.

To run longer or more thorough tests, increase the `repeat(5)` count in `tb.sv`.

### Assertions (`fifo_interface.sv`)

| Assertion | Checks |
|-----------|--------|
| `check_flags` | After reset, the FIFO is empty and not full |
| `check_full` | After 4 consecutive writes (no reads) starting from empty, `full` is asserted |
| `check_fall` | Writing into an empty FIFO deasserts `empty` on the next cycle |
| `overflow` | Writing while full (without a read) leaves the FIFO full |
| `underflow` | Reading while empty (without a write) leaves the FIFO empty |

All except `check_flags` are disabled during reset.

### Clocking block

The `cb` clocking block samples inputs 1 step before the clock edge and drives outputs 2 ns after it, avoiding race conditions between the testbench and the DUT. The clock period is 10 ns (`#5` toggle in `top.sv`).

## Getting Started

### Requirements

A SystemVerilog simulator with support for interfaces, clocking blocks, `program` blocks, constrained randomization (`rand`/`randc`/`dist`), and concurrent assertions, such as Siemens Questa/ModelSim, Synopsys VCS, or Cadence Xcelium. (Support in open-source simulators varies; check that yours handles randomization and SVA.)

### Running the simulation

`top.sv` includes all the other files, so compile and elaborate `top` as the top-level module. Example with Questa/ModelSim:

```sh
vlog -sv top.sv
vsim -c top -do "run -all; quit"
```

Example with VCS:

```sh
vcs -sverilog top.sv -R
```

Adjust commands for your tool and flow. Assertion failures and scoreboard mismatches are reported in the simulator log.

## Possible Improvements

- Parameterize depth and data width
- Add `almost_full` / `almost_empty` flags
- Increase test length and add directed tests (fill-then-drain, simultaneous read/write at full and empty)
- Add functional coverage (e.g., covergroups for flag transitions and pointer wrap-around)
- Add a waveform dump and a Makefile or script for one-command simulation
