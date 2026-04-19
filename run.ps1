$ErrorActionPreference = "Stop"

$SRC_DIR = "src"
$TB_FILE = "tb/tb_top.v"
$OUT_FILE = "sim.out"

Write-Host "Compiling RISC-V Core..."

iverilog `
-o $OUT_FILE `
-s tb_riscv_core `
$TB_FILE `
"$SRC_DIR/alu_control.v" `
"$SRC_DIR/alu.v" `
"$SRC_DIR/branch_predictor.v" `
"$SRC_DIR/control_unit.v" `
"$SRC_DIR/data_memory.v" `
"$SRC_DIR/decoder.v" `
"$SRC_DIR/ex_mem_pipeline.v" `
"$SRC_DIR/forwarding_unit.v" `
"$SRC_DIR/hazard_detection.v" `
"$SRC_DIR/id_ex_pipeline.v" `
"$SRC_DIR/if_id_pipeline.v" `
"$SRC_DIR/instruction_memory.v" `
"$SRC_DIR/mem_wb_pipeline.v" `
"$SRC_DIR/mul_div_unit.v" `
"$SRC_DIR/pc.v" `
"$SRC_DIR/reg_file.v" `
"$SRC_DIR/top_module.v"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation FAILED"
    exit
}

Write-Host "Compilation SUCCESS"

Write-Host "Running Simulation..."

vvp $OUT_FILE

Write-Host "Simulation Finished"