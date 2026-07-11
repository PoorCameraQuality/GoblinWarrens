# Full smoke battery — procgen colony + authored map pipeline + integration.
# Usage: tools/run_all_smokes.ps1
# Expected runtime: ~3–6 minutes (warren placement + colony smokes are slow).

$ErrorActionPreference = "Stop"
$Project = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path "$Project\project.godot")) {
	$Project = "E:\Projects\goblin-colony"
}
$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
if (-not (Test-Path $Godot)) {
	Write-Error "Godot console binary not found: $Godot"
}

Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$scripts = @(
	"tests/smoke/test_smoke.gd",
	"tests/smoke/test_mapgen.gd",
	"tests/smoke/test_grid_compiler.gd",
	"tests/smoke/test_semantic_map_import.gd",
	"tests/smoke/test_semantic_map_regression.gd",
	"tests/smoke/test_map_definition_smoke.gd",
	"tests/smoke/test_foliage_scatter_smoke.gd",
	"tests/smoke/test_resource_scatter_smoke.gd",
	"tests/smoke/test_warren_placement_smoke.gd",
	"tests/smoke/test_strategic_map_smoke.gd",
	"tests/smoke/test_colony_observability_smoke.gd",
	"tests/smoke/test_terrain3d_movement_spike.gd",
	"tests/smoke/test_authored_demo_smoke.gd",
	"tests/smoke/test_authored_colony_bootstrap.gd",
	"tests/smoke/test_colony.gd"
)

Write-Host "== Goblin Warrens full smoke battery =="
Write-Host "Project: $Project"
$total = [System.Diagnostics.Stopwatch]::StartNew()
$passed = 0

foreach ($rel in $scripts) {
	$sw = [System.Diagnostics.Stopwatch]::StartNew()
	Write-Host ""
	Write-Host "-- $rel"
	& $Godot --headless --path $Project --script $rel
	if ($LASTEXITCODE -ne 0) {
		Write-Host "FAILED: $rel (exit $LASTEXITCODE) after $($sw.ElapsedMilliseconds) ms"
		exit $LASTEXITCODE
	}
	$sw.Stop()
	$passed++
	Write-Host "OK ($($sw.ElapsedMilliseconds) ms)"
}

Write-Host ""
Write-Host "-- tools/run_authored_colony_smoke.ps1 (nested scene + env)"
& "$Project\tools\run_authored_colony_smoke.ps1"
if ($LASTEXITCODE -ne 0) {
	Write-Host "FAILED: run_authored_colony_smoke.ps1 (exit $LASTEXITCODE)"
	exit $LASTEXITCODE
}
$passed++

$total.Stop()
Write-Host ""
Write-Host "== All $passed checks passed in $($total.Elapsed.TotalSeconds.ToString('0.0')) s =="
exit 0
