<#
.SYNOPSIS
    Checks lightgun and dual-gun Hypseus Singe games for the specific setup mistakes
    that are easy to make when hand-building folder structure and launch scripts.

.DESCRIPTION
    This is a companion to hypseus_game_audit.ps1 (which only checks that a launcher
    exists at all). This script goes one level deeper on the two things that actually
    cause confusion when adding lightgun/2-player titles by hand:

        1. Every launch_<GameName>.bat MUST start with an explicit "cd /d" line
           pointing at the real Hypseus Singe install folder. If it doesn't, BigBox
           can launch the game from the wrong working directory and the relative
           paths (singe\...) silently fail to resolve — an intermittent, confusing
           failure documented in this repo's main README.

        2. Known lightgun titles (American Laser Games games, Mad Dog McCree/2,
           Crime Patrol, etc.) usually have a dip_Crosshair setting in their .cfg
           file. This script does NOT know which specific value is "the blank one"
           for a given game (that's trial-and-error per the README), but it flags:
             - lightgun games with NO dip_Crosshair line in the .cfg at all (worth
               adding one and testing values 1-4 if the crosshair doesn't show), and
             - lightgun games with no .cfg file found at all (nothing to tune yet).

    This does not fix anything or guess at folder layouts for you — it only tells you
    which games are worth a closer manual look before you assume something's broken.
    Read-only, same as the audit script.

.PARAMETER HypseusRoot
    Path to the Hypseus Singe installation (the folder containing hypseus.exe and
    the singe\ subfolder). Defaults to the current directory.

.PARAMETER LauncherRoot
    Path to the folder where your launch_<GameName>.bat files live, if different
    from HypseusRoot. Defaults to HypseusRoot.

.PARAMETER LightgunTitles
    Optional list of extra game-folder names to treat as lightgun titles, on top of
    the built-in list below. Use this for titles this script doesn't already know
    about (custom names, less common ALG ports, etc.).

.EXAMPLE
    .\hypseus_lightgun_launch_check.ps1 -HypseusRoot "C:\Games\Hypseus Singe"

.EXAMPLE
    .\hypseus_lightgun_launch_check.ps1 -HypseusRoot "C:\Games\Hypseus Singe" -LightgunTitles "mytitle","anothergame"
#>

param(
    [string]$HypseusRoot = ".",
    [string]$LauncherRoot = $HypseusRoot,
    [string[]]$LightgunTitles = @()
)

# Built-in list of commonly-known lightgun/ALG-style Singe titles (by common folder-name
# conventions). Not exhaustive — pass extra names via -LightgunTitles for anything missed.
$knownLightgunTitles = @(
    "maddog", "maddog2", "maddog2-hd", "maddogii",
    "crimepatrol", "crimepatrol2", "whogshot",
    "spacepirates", "fastdraw", "gallaghergallery",
    "lastbountyhunter", "policetrainer"
) + $LightgunTitles

$singeFolder = Join-Path $HypseusRoot "singe"

if (-not (Test-Path $singeFolder)) {
    Write-Error "Couldn't find a 'singe' folder under: $HypseusRoot"
    Write-Error "Pass the folder that contains hypseus.exe via -HypseusRoot."
    exit 1
}

$gameFolders = Get-ChildItem -Path $singeFolder -Directory

$batIssues = @()
$lightgunFlags = @()

foreach ($game in $gameFolders) {
    $gameName = $game.Name
    $expectedLauncher = Join-Path $LauncherRoot "launch_$gameName.bat"

    # --- Check 1: does the launcher cd /d into a real folder before calling hypseus.exe? ---
    if (Test-Path $expectedLauncher) {
        $batContent = Get-Content -Path $expectedLauncher -Raw
        $cdMatch = [regex]::Match($batContent, '(?im)^\s*cd\s*/d\s*"?([^"\r\n]+)"?\s*$')

        if (-not $cdMatch.Success) {
            $batIssues += [PSCustomObject]@{
                Game   = $gameName
                Issue  = "No 'cd /d' line found in launcher"
                Detail = $expectedLauncher
            }
        } else {
            $targetPath = $cdMatch.Groups[1].Value.Trim()
            if (-not (Test-Path $targetPath)) {
                $batIssues += [PSCustomObject]@{
                    Game   = $gameName
                    Issue  = "'cd /d' target folder doesn't exist"
                    Detail = $targetPath
                }
            }
        }
    }

    # --- Check 2: known lightgun titles - is there a .cfg, and does it set dip_Crosshair? ---
    $isLightgun = $knownLightgunTitles -contains $gameName.ToLower()

    if ($isLightgun) {
        $cfgFiles = Get-ChildItem -Path $game.FullName -Filter "*.cfg" -File -ErrorAction SilentlyContinue

        if (-not $cfgFiles -or $cfgFiles.Count -eq 0) {
            $lightgunFlags += [PSCustomObject]@{
                Game  = $gameName
                Flag  = "No .cfg file found - nothing to tune yet if crosshair is invisible"
            }
        } else {
            $hasCrosshairSetting = $false
            foreach ($cfg in $cfgFiles) {
                $cfgContent = Get-Content -Path $cfg.FullName -Raw -ErrorAction SilentlyContinue
                if ($cfgContent -match '(?im)dip_Crosshair') {
                    $hasCrosshairSetting = $true
                }
            }
            if (-not $hasCrosshairSetting) {
                $lightgunFlags += [PSCustomObject]@{
                    Game = $gameName
                    Flag = "Lightgun title with no dip_Crosshair setting in its .cfg - if the crosshair doesn't show, add one and try values 1-4 (see README)"
                }
            }
        }
    }
}

Write-Host ""
Write-Host "Hypseus Singe lightgun & launch-script check" -ForegroundColor Cyan
Write-Host "  Games folder:     $singeFolder"
Write-Host "  Launchers folder: $LauncherRoot"
Write-Host ""

if ($batIssues.Count -eq 0) {
    Write-Host "  All launcher .bat files have a valid 'cd /d' line." -ForegroundColor Green
} else {
    Write-Host ("  {0} launcher(s) with a working-directory problem:" -f $batIssues.Count) -ForegroundColor Yellow
    $batIssues | Format-Table -AutoSize
}

Write-Host ""

if ($lightgunFlags.Count -eq 0) {
    Write-Host "  No known lightgun titles found needing a closer look." -ForegroundColor Green
} else {
    Write-Host ("  {0} known lightgun title(s) worth double-checking:" -f $lightgunFlags.Count) -ForegroundColor Yellow
    $lightgunFlags | Format-Table -AutoSize
}

Write-Host ""
