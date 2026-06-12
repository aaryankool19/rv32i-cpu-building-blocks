# Program Counter Path

This project builds only the Program Counter (PC) path for a small RV32I-style CPU.
It does not build the whole CPU, a pipeline, or branch prediction.

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

## Files

- `src/pc_reg.sv`: 32-bit PC register with reset and write enable.
- `src/pc_plus4.sv`: Adds 4 to the current PC for normal instruction flow.
- `src/pc_next_mux.sv`: Chooses between `PC + 4` and a branch/jump target.
- `tb/tb_pc_path.sv`: Testbench that connects and verifies the PC path.
- `Makefile`: Builds and runs the simulation with Icarus Verilog.

## How to Run

Install Icarus Verilog if it is not already installed, then run:

```sh
make sim
```

The simulation creates:

- `build/tb_pc_path.vvp`: compiled simulation file
- `build/pc_path.vcd`: waveform file

To remove generated files:

```sh
make clean
```
