# 5-Stage Pipelined RISC-V Processor

A hardware implementation of a pipelined RISC-V processor supporting the RV32IM instruction set.

## Features

- **5-stage pipeline** (IF → ID → EX → MEM → WB)
- **Data forwarding** to minimize pipeline stalls
- **Hazard detection** for load-use conflicts
- **Multiply/Divide unit** (M extension support)
- **Branch handling** with pipeline flush

## Architecture

The processor uses a classic datapath-controller separation:
- **Datapath**: ALU, registers, memory, pipeline registers
- **Controller**: FSM-based control unit with hazard detection and forwarding

Pipeline stages complete one instruction per cycle after initial fill, achieving ~5× speedup over single-cycle design.

## Quick Start
```bash
# Compile
iverilog -o cpu top_module.v tb_top.v *.v

# Run simulation
vvp cpu

# View waveform
gtkwave cpu_dump.vcd
```

## Test Program

Simple test (`final_test.hex`):
```
x1 = 5
x2 = 10
x3 = x1 + x2 = 15
x4 = x1 - x2 = -5
```

## Project Structure
```
├── top_module.v           # Top-level integration
├── program_counter.v      # PC logic
├── instruction_memory.v   # Program storage
├── decoder.v              # Instruction decoder
├── control_unit.v         # Control signal generation
├── register_file.v        # 32 registers
├── ALU.v                  # Arithmetic/logic unit
├── mul_div.v              # Multiply/divide unit
├── data_memory.v          # Data RAM
├── forwarding_unit.v      # Data hazard resolution
├── hazard_detection.v     # Stall logic
├── *_pipeline.v           # Pipeline registers
└── tb_top.v               # Testbench
```

## What I Learned

- Designing FSM-based controllers for sequential operations
- Implementing data forwarding to resolve pipeline hazards
- Working with 2's complement arithmetic in hardware
- Managing timing and synchronization in multi-stage pipelines

## Verified Instructions

✓ Arithmetic (ADD, SUB, MUL, DIV)  
✓ Logic (AND, OR, XOR)  
✓ Shifts (SLL, SRL, SRA)  
✓ Memory (LW, SW)  
✓ Branches (BEQ, BNE)

Built as a learning project to understand processor architecture and pipeline design.