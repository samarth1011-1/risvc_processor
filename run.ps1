# PowerShell script for Verilog simulation in VSCode terminal
# Compiles all .v files in src/ directory + testbench file

# === CONFIGURATION ===
$TESTBENCH = "tb/tb_top.v"        # Change to your testbench filename
$OUTPUT = "simulation.vvp"         # Compiled output

Write-Host "`n=== Verilog Compilation & Simulation ===`n" -ForegroundColor Cyan

# Check if src directory exists
if (-Not (Test-Path "src" -PathType Container)) {
    Write-Host "[ERROR] src/ directory not found in current location!" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Check if testbench file exists
if (-Not (Test-Path $TESTBENCH -PathType Leaf)) {
    Write-Host "[ERROR] Testbench file '$TESTBENCH' not found!" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Get all .v files from src directory
$srcFiles = Get-ChildItem -Path "src\*.v" -File

if ($srcFiles.Count -eq 0) {
    Write-Host "[ERROR] No .v files found in src/ directory!" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Found $($srcFiles.Count) files in src/ directory" -ForegroundColor Green
Write-Host "[INFO] Testbench: $TESTBENCH" -ForegroundColor Green
Write-Host "`n--- Compiling ---`n" -ForegroundColor Yellow

# Compile: iverilog -o output src/*.v testbench.v
iverilog -o $OUTPUT src/*.v $TESTBENCH

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FAILED] Compilation failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n[SUCCESS] Compilation completed!`n" -ForegroundColor Green

# Run simulation
Write-Host "--- Running Simulation ---`n" -ForegroundColor Yellow
vvp $OUTPUT

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[FAILED] Simulation failed!`n" -ForegroundColor Red
    exit 1
}

Write-Host "`n[SUCCESS] Simulation completed!`n" -ForegroundColor Green
Write-Host "=== All Done! ===`n" -ForegroundColor Cyan