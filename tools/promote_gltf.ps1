# Copy glTF/GLB assets with sidecars from external_raw to game/art.
# Usage: .\tools\promote_gltf.ps1 [-ProjectRoot E:\Projects\goblin-colony]

param(
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)

function Copy-GltfFolder {
    param(
        [string]$SrcGltf,
        [string]$DestDir,
        [string]$DestBase
    )
    if (-not (Test-Path $SrcGltf)) {
        Write-Warning "Missing source: $SrcGltf"
        return $false
    }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    $srcDir = Split-Path $SrcGltf -Parent
    $srcName = [System.IO.Path]::GetFileNameWithoutExtension($SrcGltf)
    $destGltf = Join-Path $DestDir "$DestBase.gltf"
    Copy-Item $SrcGltf $destGltf -Force
    $srcBin = Join-Path $srcDir "$srcName.bin"
    if (Test-Path $srcBin) {
        Copy-Item $srcBin (Join-Path $DestDir "$DestBase.bin") -Force
        if ($DestBase -ne $srcName) {
            (Get-Content $destGltf -Raw) -replace "$srcName\.bin", "$DestBase.bin" | Set-Content $destGltf -NoNewline
        }
    }
    $json = Get-Content $destGltf -Raw
    foreach ($m in [regex]::Matches($json, '"uri"\s*:\s*"([^"]+\.(png|jpg|jpeg))"')) {
        $texName = $m.Groups[1].Value
        $srcTex = Join-Path $srcDir $texName
        if (Test-Path $srcTex) {
            Copy-Item $srcTex (Join-Path $DestDir $texName) -Force
        }
    }
    return $true
}

function Copy-GlbFile {
    param(
        [string]$SrcGlb,
        [string]$DestDir,
        [string]$DestBase
    )
    if (-not (Test-Path $SrcGlb)) {
        Write-Warning "Missing GLB: $SrcGlb"
        return $false
    }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    Copy-Item $SrcGlb (Join-Path $DestDir "$DestBase.glb") -Force
    $srcDir = Split-Path $SrcGlb -Parent
    Get-ChildItem $srcDir -Filter "*.png" -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $DestDir $_.Name) -Force
    }
    return $true
}

$raw = Join-Path $ProjectRoot "external_raw"
$art = Join-Path $ProjectRoot "game\art"

$gltfJobs = @(
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\CommonTree_1.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\tree_oak"; Base = "tree_oak_quaternius" },
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\CommonTree_3.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\tree_pine"; Base = "tree_pine_quaternius" },
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\Rock_Medium_1.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\rock_large"; Base = "rock_large_quaternius" },
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\Mushroom_Common.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\mushroom"; Base = "mushroom_common_quaternius" },
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\Bush_Common.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\bush"; Base = "bush_common_quaternius" },
    @{ Src = "$raw\quaternius\nature\stylized_nature_megakit\Grass_Common_Short.gltf"; Dest = "$art\props\nature\quaternius\stylized_nature\grass_short"; Base = "grass_short_quaternius" },
    @{ Src = "$raw\quaternius\props\fantasy_props_megakit\Barrel.gltf"; Dest = "$art\props\resources\quaternius_fantasy_props\barrel"; Base = "barrel_quaternius" },
    @{ Src = "$raw\quaternius\props\fantasy_props_megakit\Crate_Wooden.gltf"; Dest = "$art\props\resources\quaternius_fantasy_props\wood_crate"; Base = "wood_crate_quaternius" },
    @{ Src = "$raw\quaternius\buildings\medieval_village_megakit\Wall_UnevenBrick_Straight.gltf"; Dest = "$art\buildings\quaternius_parts\medieval_village\wall_straight"; Base = "wall_straight_quaternius" },
    @{ Src = "$raw\quaternius\buildings\medieval_village_megakit\Wall_UnevenBrick_Door_Flat.gltf"; Dest = "$art\buildings\quaternius_parts\medieval_village\wall_door"; Base = "wall_door_quaternius" },
    @{ Src = "$raw\quaternius\buildings\medieval_village_megakit\Roof_Wooden_2x1.gltf"; Dest = "$art\buildings\quaternius_parts\medieval_village\roof_wood"; Base = "roof_wood_quaternius" },
    @{ Src = "$raw\quaternius\buildings\medieval_village_megakit\Roof_Tower_RoundTiles.gltf"; Dest = "$art\buildings\quaternius_parts\medieval_village\roof_tower"; Base = "roof_tower_quaternius" },
    @{ Src = "$raw\quaternius\buildings\medieval_village_megakit\Stairs_Exterior_Straight_R.gltf"; Dest = "$art\buildings\quaternius_parts\medieval_village\stairs"; Base = "stairs_quaternius" },
    @{ Src = "$raw\itch_io\resources\kaykit_resource_bits\Assets\gltf\Wood_Log_Stack.gltf"; Dest = "$art\props\resources\kaykit\wood_stack"; Base = "wood_stack_kaykit" },
    @{ Src = "$raw\itch_io\resources\kaykit_resource_bits\Assets\gltf\Stone_Chunks_Large.gltf"; Dest = "$art\props\resources\kaykit\stone_large"; Base = "stone_large_kaykit" },
    @{ Src = "$raw\itch_io\resources\kaykit_resource_bits\Assets\gltf\Stone_Chunks_Small.gltf"; Dest = "$art\props\resources\kaykit\stone_small"; Base = "stone_small_kaykit" },
    @{ Src = "$raw\itch_io\resources\kaykit_resource_bits\Assets\gltf\Gold_Nuggets.gltf"; Dest = "$art\props\resources\kaykit\gold_nuggets"; Base = "gold_nuggets_kaykit" },
    @{ Src = "$raw\itch_io\graveyard\kaykit_halloween_bits\gravestone.gltf"; Dest = "$art\props\graveyard\kaykit_halloween\gravestone"; Base = "grave_marker_kaykit" },
    @{ Src = "$raw\itch_io\graveyard\kaykit_halloween_bits\skull.gltf"; Dest = "$art\props\graveyard\kaykit_halloween\skull"; Base = "skull_kaykit" },
    @{ Src = "$raw\itch_io\graveyard\kaykit_halloween_bits\ribcage.gltf"; Dest = "$art\props\graveyard\kaykit_halloween\ribcage"; Base = "ribcage_kaykit" },
    @{ Src = "$raw\itch_io\graveyard\kaykit_halloween_bits\lantern_standing.gltf"; Dest = "$art\props\graveyard\kaykit_halloween\lantern"; Base = "lantern_kaykit" }
)

$glbJobs = @(
    @{ Src = "$raw\itch_io\goblins\standout7_lowpo_goblin_assets\GLB\Characters\Basic_Goblin.glb"; Dest = "$art\units\goblins\standout7_lowpo"; Base = "basic_goblin_lowpo" },
    @{ Src = "$raw\itch_io\goblins\standout7_lowpo_goblin_assets\GLB\Characters\Goblin_Warrior.glb"; Dest = "$art\units\goblins\standout7_lowpo"; Base = "goblin_warrior_lowpo" },
    @{ Src = "$raw\itch_io\goblins\standout7_lowpo_goblin_assets\GLB\Characters\Goblin_Archer.glb"; Dest = "$art\units\goblins\standout7_lowpo"; Base = "goblin_archer_lowpo" },
    @{ Src = "$raw\itch_io\characters\kaykit_adventurers\Characters\gltf\Knight.glb"; Dest = "$art\units\enemies\kaykit_adventurers"; Base = "knight_kaykit" },
    @{ Src = "$raw\itch_io\characters\kaykit_adventurers\Characters\gltf\Ranger.glb"; Dest = "$art\units\enemies\kaykit_adventurers"; Base = "ranger_kaykit" }
)

$ok = 0
foreach ($job in $gltfJobs) {
    if (Copy-GltfFolder -SrcGltf $job.Src -DestDir $job.Dest -DestBase $job.Base) { $ok++ }
}
foreach ($job in $glbJobs) {
    if (Copy-GlbFile -SrcGlb $job.Src -DestDir $job.Dest -DestBase $job.Base) { $ok++ }
}
Write-Host "Promoted $ok assets to game/art/"
