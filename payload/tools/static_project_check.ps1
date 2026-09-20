param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Errors = @()
$Checks = 0

function Add-Failure([string]$Message) {
    $script:Errors += $Message
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Add-Pass([string]$Message) {
    $script:Checks++
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

Write-Host ''
Write-Host '============================================================'
Write-Host '  RAGNAROK CORE - STATIC PROJECT CHECK'
Write-Host '============================================================'
Write-Host ''

$required = @(
    'project.godot',
    'core\main.tscn',
    'actors\player\player.gd',
    'actors\monsters\monster.gd',
    'systems\inventory\inventory.gd',
    'systems\equipment\equipment.gd',
    'systems\combat\pre_renewal_formulas.gd',
    'systems\skills\skill_system.gd',
    'systems\save\save_system.gd',
    'systems\mobile\mobile_mode.gd',
    'systems\mobile\mobile_ui.gd',
    'systems\mobile\mobile_ui.tscn',
    'data\rathena\mobs\poring.json',
    'data\rathena\loot\poring.json',
    'data\rathena\items\items.json',
    'data\rathena\progression\novice_progression.json',
    'data\rathena\progression\novice_stats.json',
    'data\maps\dev_town.json',
    'data\maps\south_field.json'
)
foreach ($relative in $required) {
    $full = Join-Path $Root $relative
    if (-not (Test-Path -LiteralPath $full)) { Add-Failure "Pflichtdatei fehlt: $relative" }
}
if ($Errors.Count -eq 0) { Add-Pass 'Pflichtdateien vorhanden' }

$jsonFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.json'
foreach ($jsonFile in $jsonFiles) {
    try {
        $null = Get-Content -LiteralPath $jsonFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Add-Failure ("JSON ungueltig: {0} -> {1}" -f $jsonFile.FullName.Substring($Root.Length + 1), $_.Exception.Message)
    }
}
if ($Errors.Count -eq 0) { Add-Pass ("JSON parsebar: {0} Dateien" -f $jsonFiles.Count) }

$implicitTyping = @()
$gdFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.gd'
foreach ($gdFile in $gdFiles) {
    $lineNo = 0
    foreach ($line in Get-Content -LiteralPath $gdFile.FullName -Encoding UTF8) {
        $lineNo++
        if ($line -match ':=') {
            $implicitTyping += ("{0}:{1}" -f $gdFile.FullName.Substring($Root.Length + 1), $lineNo)
        }
    }
}
if ($implicitTyping.Count -gt 0) {
    Add-Failure ("Problematische Variant-Typinferenz gefunden: " + ($implicitTyping -join ', '))
} else {
    Add-Pass ("Explizite GDScript-Typisierung: {0} Skripte ohne ':='" -f $gdFiles.Count)
}

$resourceExtensions = 'gd|tscn|tres|json|png|jpg|jpeg|webp|svg|shader|wav|ogg|mp3'
$resourcePattern = [regex]("res://[A-Za-z0-9_./%\-]+\.(?:" + $resourceExtensions + ")")
$sourceFiles = Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object {
    $_.Extension -in @('.gd','.tscn','.tres','.json','.md','.txt','.ps1','.bat')
}
$missingResources = @()
foreach ($sourceFile in $sourceFiles) {
    $text = Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8
    foreach ($match in $resourcePattern.Matches($text)) {
        $uri = [string]$match.Value
        if ($uri.Contains('%')) { continue }
        $relative = $uri.Substring(6).Replace('/', '\')
        if (-not (Test-Path -LiteralPath (Join-Path $Root $relative))) {
            $missingResources += ("{0} -> {1}" -f $sourceFile.FullName.Substring($Root.Length + 1), $uri)
        }
    }
}
if ($missingResources.Count -gt 0) {
    Add-Failure ("Fehlende res://-Dateien: " + ($missingResources -join '; '))
} else {
    Add-Pass 'Statische res://-Dateireferenzen vorhanden'
}

try {
    $poring = Get-Content -LiteralPath (Join-Path $Root 'data\rathena\mobs\poring.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$poring.id -ne 1002 -or [int]$poring.hp -ne 50 -or [int]$poring.base_exp -ne 2 -or [int]$poring.job_exp -ne 1 -or [int]$poring.attack -ne 7 -or [int]$poring.attack2 -ne 10 -or [string]$poring.ai -ne '02') {
        Add-Failure 'Poring-Profil entspricht nicht dem gebuendelten Pre-Renewal-Vertrag.'
    } else {
        Add-Pass 'Poring Pre-Renewal Kernwerte'
    }

    $loot = Get-Content -LiteralPath (Join-Path $Root 'data\rathena\loot\poring.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$loot.rate_denominator -ne 10000 -or $loot.drops.Count -lt 8) {
        Add-Failure 'Poring-Drop-Tabelle ist unvollstaendig.'
    } else {
        Add-Pass 'Poring-Drop-Tabelle'
    }

    $progression = Get-Content -LiteralPath (Join-Path $Root 'data\rathena\progression\novice_progression.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$progression.max_base_level -ne 99 -or $progression.base_exp_to_next.Count -ne 98 -or [int]$progression.novice_max_job_level -ne 10 -or $progression.novice_job_exp_to_next.Count -ne 9) {
        Add-Failure 'Pre-Renewal EXP-Daten sind unvollstaendig.'
    } else {
        Add-Pass 'Pre-Renewal Base-/Novice-Job-EXP'
    }

    $stats = Get-Content -LiteralPath (Join-Path $Root 'data\rathena\progression\novice_stats.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($stats.total_stat_points_by_level.Count -ne 99 -or [int]$stats.total_stat_points_by_level[0] -ne 48 -or [int]$stats.total_stat_points_by_level[98] -ne 1273) {
        Add-Failure 'Pre-Renewal Statpoint-Tabelle ist unvollstaendig.'
    } elseif ($stats.novice_base_hp_by_level.Count -ne 99 -or [int]$stats.novice_base_hp_by_level[0] -ne 40 -or [int]$stats.novice_base_hp_by_level[98] -ne 530) {
        Add-Failure 'Novice Base-HP-Tabelle ist unvollstaendig.'
    } elseif ($stats.novice_base_sp_by_level.Count -ne 99 -or [int]$stats.novice_base_sp_by_level[0] -ne 11 -or [int]$stats.novice_base_sp_by_level[98] -ne 109) {
        Add-Failure 'Novice Base-SP-Tabelle ist unvollstaendig.'
    } elseif ([int]$stats.novice_base_amotion_ms.Fist -ne 500 -or [int]$stats.novice_base_amotion_ms.Dagger -ne 650) {
        Add-Failure 'Novice Pre-Renewal ASPD-Basisdaten fehlen.'
    } elseif ([int]$stats.initial_stats.str -ne 9 -or [int]$stats.initial_stats.agi -ne 9 -or [int]$stats.initial_stats.vit -ne 1 -or [int]$stats.initial_stats.int -ne 1 -or [int]$stats.initial_stats.dex -ne 9 -or [int]$stats.initial_stats.luk -ne 1) {
        Add-Failure 'Projekt-Startstats entsprechen nicht dem 48-Punkte-Vertrag.'
    } else {
        Add-Pass 'Pre-Renewal Stats/Statpoints/HP/SP/ASPD'
    }

    $items = Get-Content -LiteralPath (Join-Path $Root 'data\rathena\items\items.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$items.knife.attack_bonus -ne 17 -or [string]$items.knife.weapon_type -ne 'Dagger' -or [int]$items.cotton_shirt.defense_bonus -ne 1 -or [int]$items.apple.heal_hp_min -ne 16 -or [int]$items.red_herb.heal_hp_min -ne 18) {
        Add-Failure 'Starter-/Heilitemdaten entsprechen nicht dem Pre-Renewal-Vertrag.'
    } else {
        Add-Pass 'Pre-Renewal Starter-/Heilitems'
    }

    $south = Get-Content -LiteralPath (Join-Path $Root 'data\maps\south_field.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($south.monsters.Count -lt 6 -or $south.blockers.Count -lt 4) {
        Add-Failure 'South Field erwartet mindestens 6 Porings und 4 Kollisionsblocker.'
    } elseif ([int]$south.size[0] -ne 1440 -or [int]$south.size[1] -ne 1920 -or [string]$south.ambience -ne 'ill_field') {
        Add-Failure 'South Field entspricht nicht dem Step-3 Portrait/Horror-ill-Vertrag.'
    } else {
        Add-Pass 'South Field Step-3 Spawns/Kollisionen/Horror-ill'
    }
} catch {
    Add-Failure ("Datenvertrag konnte nicht geprueft werden: " + $_.Exception.Message)
}

$formulaText = Get-Content -LiteralPath (Join-Path $Root 'systems\combat\pre_renewal_formulas.gd') -Raw -Encoding UTF8
$playerText = Get-Content -LiteralPath (Join-Path $Root 'actors\player\player.gd') -Raw -Encoding UTF8
$monsterText = Get-Content -LiteralPath (Join-Path $Root 'actors\monsters\monster.gd') -Raw -Encoding UTF8
$windowsText = Get-Content -LiteralPath (Join-Path $Root 'systems\ui\ro_windows.gd') -Raw -Encoding UTF8
if ($formulaText -notmatch '80 \+ attacker_hit - defender_flee' -or $formulaText -notmatch 'player_vit_defense_roll' -or $formulaText -notmatch 'critical_tenths' -or $formulaText -notmatch 'value \+ 9') {
    Add-Failure 'Zentrale Pre-Renewal-Kampfformeln sind unvollstaendig.'
} elseif ($playerText -notmatch 'receive_basic_attack' -or $monsterText -notmatch 'receive_basic_attack') {
    Add-Failure 'Player/Monster nutzen die zentrale Basic-Attack-Aufloesung nicht.'
} elseif ($playerText -notmatch '"stats":' -or $playerText -notmatch 'status_points') {
    Add-Failure 'Save-kompatibler Stats-State fehlt im Player.'
} elseif ($windowsText -notmatch '_make_stat_row' -or $windowsText -notmatch 'status_hit_flee' -or $windowsText -notmatch 'status_crit_aspd') {
    Add-Failure 'Statusfenster zeigt das neue Stat-/Combat-System nicht vollstaendig.'
} else {
    Add-Pass 'Pre-Renewal Combat/Stats Integration'
}

$mainText = Get-Content -LiteralPath (Join-Path $Root 'core\main.gd') -Raw -Encoding UTF8
$hotbarText = Get-Content -LiteralPath (Join-Path $Root 'systems\skills\skill_hotbar.gd') -Raw -Encoding UTF8
if ($mainText -match '"save_game", \[KEY_F9\]' -or $mainText -match '"load_game", \[KEY_F10\]') {
    Add-Failure 'F9/F10 kollidieren mit der F1-F9-Hotbar.'
} elseif ($mainText -notmatch '"save_game", \[KEY_F11\]' -or $mainText -notmatch '"load_game", \[KEY_F12\]' -or $hotbarText -notmatch 'KEY_F9') {
    Add-Failure 'Hotbar-/Save-/Load-Tastenvertrag ist unvollstaendig.'
} else {
    Add-Pass 'F1-F9 Hotbar ohne Save-Konflikt; F11/F12 Save/Load'
}


$projectText = Get-Content -LiteralPath (Join-Path $Root 'project.godot') -Raw -Encoding UTF8
$mainSceneText = Get-Content -LiteralPath (Join-Path $Root 'core\main.tscn') -Raw -Encoding UTF8
$mainRuntimeText = Get-Content -LiteralPath (Join-Path $Root 'core\main.gd') -Raw -Encoding UTF8
$mobileText = Get-Content -LiteralPath (Join-Path $Root 'systems\mobile\mobile_ui.gd') -Raw -Encoding UTF8
$mobileModeText = Get-Content -LiteralPath (Join-Path $Root 'systems\mobile\mobile_mode.gd') -Raw -Encoding UTF8
$minimapText = Get-Content -LiteralPath (Join-Path $Root 'systems\mobile\mobile_minimap.gd') -Raw -Encoding UTF8
$inventoryUiText = Get-Content -LiteralPath (Join-Path $Root 'systems\inventory\inventory_ui.gd') -Raw -Encoding UTF8
if ($projectText -notmatch 'window/stretch/aspect="expand"' -or $projectText -notmatch 'window/handheld/orientation=5' -or $projectText -notmatch 'pointing/emulate_mouse_from_touch=false') {
    Add-Failure 'Step-3 Mobile-Projekteinstellungen fuer Sensor-Portrait/Expand/explizites Touch fehlen.'
} elseif ($mainRuntimeText -notmatch 'MOBILE_VIRTUAL_SIZE:\s*Vector2i\s*=\s*Vector2i\(720, 1280\)' -or $mainSceneText -notmatch 'systems/mobile/mobile_camera.gd') {
    Add-Failure '720x1280 Mobile-Viewport oder MobileCamera fehlt.'
} elseif ($mobileModeText -notmatch 'get_display_safe_area' -or $mobileModeText -notmatch 'get_safe_margins' -or $minimapText -notmatch '_map_world_point') {
    Add-Failure 'Safe-Area- oder Mobile-Minimap-Vertrag fehlt.'
} elseif ($mobileText -notmatch 'var _event_log:\s*Label\s*=\s*null' -or $mobileText -notmatch 'attack_selected_target_with_approach' -or $inventoryUiText -notmatch 'not _mobile_mode and not mouse_event.double_click') {
    Add-Failure 'Mobile-Touch/UI-Integration ist unvollstaendig.'
} else {
    Add-Pass 'Mobile Portrait/Safe-Area/Minimap/explicit Touch Integration'
}

$saveText = Get-Content -LiteralPath (Join-Path $Root 'systems\save\save_system.gd') -Raw -Encoding UTF8
if ($saveText -notmatch 'SAVE_FORMAT_VERSION:\s*int\s*=\s*4') {
    Add-Failure 'Save-Format wurde unerwartet veraendert.'
} else {
    Add-Pass 'Save-Format 4 unveraendert'
}

Write-Host ''
if ($Errors.Count -gt 0) {
    Write-Host ("STATIC CHECK: FAIL ({0} Fehler)" -f $Errors.Count) -ForegroundColor Red
    exit 1
}

Write-Host ("STATIC CHECK: PASS ({0} Pruefgruppen)" -f $Checks) -ForegroundColor Green
exit 0