param(
    [string]$BaselineZip = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Payload = Join-Path $Here "payload"
$OutputName = "Ragnarok_Godot_Core_ILL_Mobile_Step3_Gold"
$Work = Join-Path $Here $OutputName
$FinalZip = Join-Path $Here ($OutputName + ".zip")

function Find-Baseline {
    param([string]$Explicit)
    if ($Explicit -and (Test-Path -LiteralPath $Explicit)) { return (Resolve-Path $Explicit).Path }
    $names = @(
        "Ragnarok_Godot_Core_Mobile_Demo_PreRenewal.zip",
        "Ragnarok_Godot_Core_Stats_PreRenewal_Combat.zip"
    )
    foreach ($name in $names) {
        $local = Join-Path $Here $name
        if (Test-Path -LiteralPath $local) { return (Resolve-Path $local).Path }
        $download = Join-Path $env:USERPROFILE ("Downloads\" + $name)
        if (Test-Path -LiteralPath $download) { return (Resolve-Path $download).Path }
    }
    return ""
}

$BaselineZip = Find-Baseline $BaselineZip
if (-not $BaselineZip) {
    Write-Host "[FEHLER] Basis-ZIP nicht gefunden." -ForegroundColor Red
    Write-Host "Lege Ragnarok_Godot_Core_Mobile_Demo_PreRenewal.zip neben diese Datei"
    Write-Host "oder in deinen Downloads-Ordner und starte APPLY_STEP3.bat erneut."
    exit 10
}
if (-not (Test-Path -LiteralPath $Payload)) {
    Write-Host "[FEHLER] payload-Ordner fehlt." -ForegroundColor Red
    exit 11
}

if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force }
New-Item -ItemType Directory -Path $Work | Out-Null

Write-Host "[1/5] Basis entpacken ..."
Expand-Archive -LiteralPath $BaselineZip -DestinationPath $Work -Force

$ProjectFile = Get-ChildItem -LiteralPath $Work -Recurse -File -Filter "project.godot" | Select-Object -First 1
if (-not $ProjectFile) {
    Write-Host "[FEHLER] project.godot in Basis-ZIP nicht gefunden." -ForegroundColor Red
    exit 12
}
$ProjectRoot = $ProjectFile.Directory.FullName

Write-Host "[2/5] Step-3-Dateien anwenden ..."
Copy-Item -Path (Join-Path $Payload "*") -Destination $ProjectRoot -Recurse -Force

Write-Host "[3/5] Statische QA ..."
$Static = Join-Path $ProjectRoot "tools\static_project_check.ps1"
if (-not (Test-Path -LiteralPath $Static)) {
    Write-Host "[FEHLER] static_project_check.ps1 fehlt." -ForegroundColor Red
    exit 13
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Static
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FEHLER] Statische QA fehlgeschlagen." -ForegroundColor Red
    exit 14
}

Write-Host "[4/5] Optionaler Godot-Check ..."
$Godot = $null
$localGodot = Get-ChildItem -LiteralPath $ProjectRoot -File -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($localGodot) { $Godot = $localGodot.FullName }
if (-not $Godot) {
    $cmd = Get-Command godot4.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command godot.exe -ErrorAction SilentlyContinue }
    if ($cmd) { $Godot = $cmd.Source }
}
if ($Godot) {
    & $Godot --headless --path $ProjectRoot --editor --quit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FEHLER] Godot Editor/Import-Check fehlgeschlagen." -ForegroundColor Red
        exit 15
    }
    & $Godot --headless --path $ProjectRoot --quit-after 20 -- --mobile-demo
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FEHLER] Godot Mobile-Smoke-Test fehlgeschlagen." -ForegroundColor Red
        exit 16
    }
    Write-Host "[PASS] Godot-Runtime-Checks ausgefuehrt." -ForegroundColor Green
} else {
    Write-Host "[HINWEIS] Godot wurde auf diesem PC nicht automatisch gefunden; Runtime-Test uebersprungen." -ForegroundColor Yellow
}

Write-Host "[5/5] Finale ZIP erzeugen ..."
if (Test-Path -LiteralPath $FinalZip) { Remove-Item -LiteralPath $FinalZip -Force }
Compress-Archive -Path (Join-Path $ProjectRoot "*") -DestinationPath $FinalZip -CompressionLevel Optimal
Write-Host "[PASS] $FinalZip" -ForegroundColor Green
exit 0
