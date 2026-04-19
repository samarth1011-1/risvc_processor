# 5-Stage Pipelined RISC-V Processor

A hardware implementation of a pipelined RISC-V processor built in Verilog, supporting the RV32I base with M-extension multiply/divide support and shift operations.

## Features

- **5-stage pipeline** (IF → ID → EX → MEM → WB)
- **Data forwarding** to reduce stalls on dependent instructions
- **Hazard detection** for load-use conflicts and multi-cycle operations
- **Multiply/Divide unit** with busy/ready handshake
- **Branch handling** with pipeline flush
- **Register file bypassing** for same-cycle read/write cases
- **Separate instruction and data memory**
- **Module-level verification** with self-checking testbenches

## Quick Start

```bash
# Compile
iverilog -o cpu tb_top.v src/*.v

# Run simulation
vvp cpu

# View waveform
gtkwave cpu_dump.vcd
```

## Verification

The core was verified in pieces first and then tested at the top level with a small program in hex format.  
Module-level testbenches were used for:

- program counter
- decoder
- control unit
- register file
- multiply/divide unit
- instruction memory
- data memory
- forwarding unit
- hazard detection
- pipeline registers

Top-level simulation was then used to confirm that the full processor could fetch, decode, execute, access memory, and write back correctly.

## Project Structure

```text
├── top_module.v           # Top-level integration
├── pc.v                   # Program counter
├── instruction_memory.v   # Instruction storage
├── decoder.v              # Instruction decoder
├── control_unit.v         # Control signal generation
├── reg_file.v             # 32x32 register file
├── alu.v                  # Arithmetic/logic unit
├── alu_control.v         # ALU and M-extension control
├── mul_div.v              # Multiply/divide unit
├── data_memory.v          # Data RAM
├── forwarding_unit.v      # Data hazard resolution
├── hazard_detection.v     # Stall and flush control
├── if_id_pipeline.v       # IF/ID pipeline register
├── id_ex_pipeline.v       # ID/EX pipeline register
├── ex_mem_pipeline.v      # EX/MEM pipeline register
├── mem_wb_pipeline.v      # MEM/WB pipeline register
└── tb_top.v               # Top-level testbench
```

## What I Learned

- How a 5-stage pipeline moves instructions through each stage
- How forwarding and stalling are used to handle hazards
- How branch flushing affects pipeline flow
- How to handle multi-cycle operations in a pipeline
- How to debug RTL with waveform-based simulation
- How small control bugs can affect the whole processor

## Verified Instructions

- Arithmetic: `ADD`, `SUB`, `MUL`, `DIV`
- Logic: `AND`, `OR`, `XOR`
- Shifts: `SLL`, `SRL`, `SRA`
- Immediate ops: `ADDI`, `ANDI`, `ORI`
- Memory: `LW`, `SW`
- Branches: `BEQ`

Built as a learning project to understand processor architecture, pipelining, and RTL design in practice.
