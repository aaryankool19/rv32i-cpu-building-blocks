# RV32I CPU Building Blocks

This project builds a small RV32I-style CPU one beginner-friendly component at a time.
It does not build the whole CPU yet, a pipeline, or branch prediction.

The current building blocks are:

- Program Counter path
- Register file

## What Is the PC?

The Program Counter is a 32-bit register that stores the address of the current instruction.
The CPU uses this address to ask instruction memory for the instruction to run.

In this project, `pc_reg` stores the current PC value.

## Why PC + 4?

Most RV32I instructions are 4 bytes wide.
When the CPU is running instructions in normal order, the next instruction is usually located
4 bytes after the current one.

That is why the normal next PC is:

```text
pc_next = pc_current + 4
```

The `pc_plus4` module performs this simple addition.

## Why Branches and Jumps Need a Mux

Sometimes the CPU should not go to `PC + 4`.
For a branch or jump, the next PC should become a target address instead.

The `pc_next_mux` chooses between:

- `pc_plus_4` for normal execution
- `pc_target` for a branch or jump target

Later, another part of the CPU can decide when `pc_src` should be 1 and what `pc_target`
should be.

## Why pc_reg Does Not Contain Branch Logic

The PC register should stay simple.
Its job is only to remember the current PC value.

Branch and jump decisions belong outside the register because they are control logic.
Keeping them separate makes the design easier to read, test, and expand later.

## How This Connects Later to Instruction Memory

Later, `pc_current` will connect to instruction memory.
Instruction memory will use the PC as an address and return the instruction stored there.

```text
pc_reg -> instruction memory
     |
     v
  pc_plus4 -> pc_next_mux -> pc_reg
              ^
              |
           pc_target
```

## Register File

The register file is the CPU's small bank of general-purpose integer registers.
Instructions read values from registers, do work, and often write a result back
to a register.

RISC-V has 32 integer registers named `x0` through `x31`.
In RV32I, each register is 32 bits wide.

Register addresses are 5 bits wide because:

```text
2^5 = 32
```

That means a 5-bit address can select one of the 32 registers.

The register file uses these common RISC-V register fields:

- `rs1`: first source register address
- `rs2`: second source register address
- `rd`: destination register address

This project's `reg_file` has:

- two combinational read ports, so `rs1` and `rs2` can be read at the same time
- one synchronous write port, so `rd` is written on a clock edge
- a reset input that clears the stored registers
- a write enable input so control logic can decide when a write should happen

### Why x0 Always Reads as Zero

In RISC-V, register `x0` is hardwired to zero.
Reading `x0` always returns `32'h00000000`.
Writing to `x0` is ignored.

This is useful because many instructions need a constant zero value.

### Reads vs Writes

Reads are combinational.
If `rs1_addr` or `rs2_addr` changes, the matching read data changes without
waiting for a clock edge.

Writes are synchronous.
When `reg_write_en` is high, the register selected by `rd_addr` receives
`rd_data` on the rising edge of `clk`.

## Files

- `src/pc_reg.sv`: 32-bit PC register with reset and write enable.
- `src/pc_plus4.sv`: Adds 4 to the current PC for normal instruction flow.
- `src/pc_next_mux.sv`: Chooses between `PC + 4` and a branch/jump target.
- `src/reg_file.sv`: 32-register RV32I-style integer register file.
- `tb/tb_pc_path.sv`: Testbench that connects and verifies the PC path.
- `tb/tb_reg_file.sv`: Testbench that verifies register file reads, writes, x0, and write enable.
- `Makefile`: Builds and runs the simulation with Icarus Verilog.

## How to Run

Install Icarus Verilog if it is not already installed, then run:

```sh
make sim
```

To run the register file test:

```sh
make sim_reg
```

The PC simulation creates:

- `build/tb_pc_path.vvp`: compiled simulation file
- `build/pc_path.vcd`: waveform file

The register file simulation creates:

- `build/tb_reg_file.vvp`: compiled simulation file
- `build/reg_file.vcd`: waveform file

To remove generated files:

```sh
make clean
```
