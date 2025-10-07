# checklist
```
/riscv_cpu
 ├── /src
 │    ├── pc.v                      (done)
 │    ├── instruction_memory.v      (done)
 │    ├── decoder.v
 │    ├── reg_file.v                (done)
 │    ├── control_unit.v
 │    ├── alu.v
 │    ├── mul_div_unit.v
 │    ├── forwarding_unit.v
 │    ├── hazard_detection.v
 │    ├── branch_predictor.v
 │    ├── data_memory.v
 │    ├── pipeline_registers.v
 │    ├── top_module.v
 ├── /tb
 │    ├── tb_pc.v
 │    ├── tb_reg_file.v
 │    ├── tb_alu.v
 │    ├── tb_mul_div_unit.v
 │    ├── tb_top.v
 ├── /programs
 │    ├── test_add.hex
 │    ├── test_mul.hex
 ├── README.md
 └── Makefile  (optional for build automation)
```