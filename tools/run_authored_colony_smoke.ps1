# Full authored colony scene smoke (nested Godot process with env vars).
$ErrorActionPreference = "Stop"
$G = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
$Root = Split-Path -Parent $PSScriptRoot

$env:GC_MAP_MODE = "authored"
$env:GC_AUTHORED_AUTO_WARREN = "1"
$env:GC_AUTHORED_COLONY_SMOKE = "1"

& $G --headless --path $Root --script tests/smoke/test_authored_colony_bootstrap.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $G --headless --path $Root --scene tests/smoke/colony_authored_smoke_runner.tscn
exit $LASTEXITCODE
