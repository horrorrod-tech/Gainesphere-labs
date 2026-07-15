<#
.SYNOPSIS
    Audits a Hypseus Singe game library for missing/orphaned launch scripts.

.DESCRIPTION
    Hypseus Singe games are typically organized as:

        <HypseusRoot>\singe\<GameName>\<GameName>.txt
        <HypseusRoot>\singe\<GameName>\<GameName>.singe
        <HypseusRoot>\launch_<GameName>.bat   (or wherever you keep your per-game launchers)

    Over time it's easy for a game folder to end up without a matching launcher
    (a copy/rename that didn't carry the .bat with it, a game added but never
    wired up in LaunchBox, etc.). This script flags exactly that: any game
    folder under \singe\ that doesn't have a corresponding launch_<GameName>.bat
    somewhere under the launcher folder you point it at.

    Read-only. Doesn't touch, move, or delete anything — just reports.

.PARAMETER HypseusRoot
    Path to the Hypseus Singe installation (the folder containing hypseus.exe
    and the singe\ subfolder). Defaults to the current directory.

.PARAMETER LauncherRoot
    Path to the folder where your launch_<GameName>.bat files live, if different
    from HypseusRoot. Defaults to HypseusRoot.

.EXAMPLE
    .\hypseus_game_audit.ps1 -HypseusRoot "C:\Games\Hypseus Singe"

.EXAMPLE
    .\hypseus_game_audit.ps1 -HypseusRoot "C:\Games\Hypseus Singe" -LauncherRoot "C:\Games\Hypseus Singe\Launchers"
#>

param(
    [string]$HypseusRoot = ".",
    [string]$LauncherRoot = $HypseusRoot
)

$singeFolder = Join-Path $HypseusRoot "singe"

if (-not (Test-Path $singeFolder)) {
    Write-Error "Couldn't find a 'singe' folder under: $HypseusRoot"
    Write-Error "Pass the folder that contains hypseus.exe via -HypseusRoot."
    exit 1
}

$gameFolders = Get-ChildItem -Path $singeFolder -Directory
$missing = @()
$ok = @()

foreach ($game in $gameFolders) {
    $gameName = $game.Name
    $expectedLauncher = Join-Path $LauncherRoot "launch_$gameName.bat"

    if (Test-Path $expectedLauncher) {
        $ok += $gameName
    } else {
        $missing += [PSCustomObject]@{
            Game            = $gameName
            ExpectedLauncher = $expectedLauncher
        }
    }
}

Write-Host ""
Write-Host "Hypseus Singe library audit" -ForegroundColor Cyan
Write-Host "  Games folder:    $singeFolder"
Write-Host "  Launchers folder: $LauncherRoot"
Write-Host ""
Write-Host ("  {0} game(s) with a matching launcher" -f $ok.Count) -ForegroundColor Green

if ($missing.Count -eq 0) {
    Write-Host "  No orphaned game folders found." -ForegroundColor Green
} else {
    Write-Host ("  {0} game(s) missing a launcher:" -f $missing.Count) -ForegroundColor Yellow
    $missing | Format-Table -AutoSize
}

Write-Host ""
