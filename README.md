# RV32I CPU Building Blocks

This project builds a small RV32I-style CPU one beginner-friendly component at a time.
It does not build the whole CPU yet, a pipeline, or branch prediction.

The current building blocks are:

- Program Counter path
- Register file
- Immediate generator
- Instruction memory

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

## Immediate Generator

An immediate is a constant value stored directly inside a RISC-V instruction.
Some instructions need small constants, offsets, or upper address bits without
reading those values from another register.

The immediate generator takes the 32-bit instruction and extracts the immediate
bits into a normal 32-bit value called `imm_out`.

RISC-V needs this module because different instruction formats store immediate
bits in different places. Store, branch, and jump immediates are split across
the instruction instead of sitting in one simple field.

Sign extension matters because many immediates can be negative. If the immediate
sign bit is 1, the immediate generator fills the upper bits with 1s so the small
immediate becomes the correct 32-bit signed value.

This project supports these immediate formats:

| Format | Example instructions | What it is used for |
|---|---|---|
| I-type | `addi`, `lw`, `jalr` | ALU constants, load offsets, jump-register offsets |
| S-type | `sw` | store offsets |
| B-type | `beq`, `bne`, `blt`, `bge` | branch target offsets |
| U-type | `lui`, `auipc` | upper immediate values |
| J-type | `jal` | jump target offsets |

The immediate generator does not decide which immediate type to use.
Later, the control unit will decode the instruction opcode and choose the
correct `imm_sel` value.

Later in the CPU, `imm_out` will connect to the ALU input mux, branch target
calculation, and jump target calculation.

```text
instruction[31:0]
        |
        v
   imm_gen
        |
        v
   imm_out[31:0]
        |
        +--> ALU input mux
        +--> branch/jump target logic
```

| File | Purpose |
|---|---|
| `src/imm_gen.sv` | Extracts and sign-extends RISC-V immediates |
| `tb/tb_imm_gen.sv` | Tests I, S, B, U, and J immediate formats |

## Instruction Memory

Instruction memory stores the program instructions for the CPU.
The Program Counter gives instruction memory an address, and instruction memory
outputs the 32-bit instruction stored at that address as `instr[31:0]`.

RV32I instructions are 32 bits wide, which is 4 bytes.
That is why normal execution uses `PC + 4`: the next instruction usually starts
4 bytes after the current instruction.

The PC gives a byte address, but the instruction memory array is organized as
32-bit instruction words. The expression `addr[31:2]` drops the bottom two
address bits and converts the byte address into a word index:

```text
addr = 0   -> addr[31:2] = 0
addr = 4   -> addr[31:2] = 1
addr = 8   -> addr[31:2] = 2
addr = 12  -> addr[31:2] = 3
```

This module does not decode or execute instructions.
It only returns instruction bits. Later, decode and control logic will look at
those bits and decide what the CPU should do.

Instruction memory is different from data memory:

- instruction memory stores the program
- data memory stores program data, such as variables, stack values, and loaded or stored words

```text
pc_current[31:0]
        |
        v
   instr_mem
        |
        v
   instr[31:0]
        |
        v
 future decode/control
```

```text
             +---------+
             | pc_reg  |
             +---------+
                  |
                  v
             instr_mem
                  |
                  v
             instr[31:0]
```

| File | Purpose |
|---|---|
| `src/instr_mem.sv` | Stores and outputs 32-bit RV32I instructions |
| `tb/tb_instr_mem.sv` | Tests hardcoded instruction memory contents |
| `tb/tb_instr_mem_hex.sv` | Tests loading instructions from a .hex file |
| `programs/simple_program.hex` | Small example machine-code program |

Some simulators do not allow comments inside `.hex` files, so
`programs/simple_program.hex` is kept as plain hex only: one 32-bit instruction
per line.

## Files

- `src/pc_reg.sv`: 32-bit PC register with reset and write enable.
- `src/pc_plus4.sv`: Adds 4 to the current PC for normal instruction flow.
- `src/pc_next_mux.sv`: Chooses between `PC + 4` and a branch/jump target.
- `src/reg_file.sv`: 32-register RV32I-style integer register file.
- `src/imm_gen.sv`: Extracts and sign-extends RISC-V immediates.
- `src/instr_mem.sv`: ROM-style instruction memory for 32-bit RV32I instructions.
- `tb/tb_pc_path.sv`: Testbench that connects and verifies the PC path.
- `tb/tb_reg_file.sv`: Testbench that verifies register file reads, writes, x0, and write enable.
- `tb/tb_imm_gen.sv`: Testbench that verifies I, S, B, U, and J immediate formats.
- `tb/tb_instr_mem.sv`: Testbench for hardcoded instruction memory contents.
- `tb/tb_instr_mem_hex.sv`: Testbench for loading instruction memory from a hex file.
- `programs/simple_program.hex`: Plain hex example program for `$readmemh`.
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

To run the immediate generator test:

```sh
make sim_imm
```

To run the instruction memory tests:

```sh
make sim_instr
make sim_instr_hex
```

To run all available simulations:

```sh
make sim_all
```

The PC simulation creates:

- `build/tb_pc_path.vvp`: compiled simulation file
- `build/pc_path.vcd`: waveform file

The register file simulation creates:

- `build/tb_reg_file.vvp`: compiled simulation file
- `build/reg_file.vcd`: waveform file

The immediate generator simulation creates:

- `build/tb_imm_gen.vvp`: compiled simulation file
- `build/imm_gen.vcd`: waveform file

The instruction memory simulations create:

- `build/tb_instr_mem.vvp`: compiled simulation file
- `build/tb_instr_mem_hex.vvp`: compiled simulation file
- `build/instr_mem.vcd`: waveform file
- `build/instr_mem_hex.vcd`: waveform file

Generated build files such as `build/tb_imm_gen.vvp` and `build/imm_gen.vcd`
should not be committed to GitHub.
Generated files such as `build/tb_instr_mem.vvp`, `build/tb_instr_mem_hex.vvp`,
`build/instr_mem.vcd`, and `build/instr_mem_hex.vcd` should not be committed
to GitHub.

To remove generated files:

```sh
make clean
```
