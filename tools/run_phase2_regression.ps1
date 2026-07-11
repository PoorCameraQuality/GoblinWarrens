# Phase 2 approval gate — full smoke suite from a clean headless process.
# Usage: tools/run_phase2_regression.ps1

$ErrorActionPreference = "Stop"
$Project = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$Project\project.godot")) {
	$Project = "E:\Projects\goblin-colony"
}
$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$scripts = @(
	"tools/import_semantic_map.gd",
	"tests/smoke/test_semantic_map_import.gd",
	"tests/smoke/test_grid_compiler.gd",
	"tests/smoke/test_semantic_map_regression.gd"
)

Write-Host "== Phase 2 approval gate =="
$total = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($rel in $scripts) {
	Write-Host "-- $rel"
	& $Godot --headless --path $Project --script $rel
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$total.Stop()
Write-Host "== Phase 2 passed in $($total.ElapsedMilliseconds) ms =="
Write-Host "== Artifact =="
Get-Content "$Project\data\maps\three_lane_swamp_valley\phase2_regression_artifact.json"
exit 0
