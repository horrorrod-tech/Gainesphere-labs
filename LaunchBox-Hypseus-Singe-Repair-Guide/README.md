# Hypseus Singe + LaunchBox (Windows) — Repair & Setup Guide

**This is a written guide and a couple of small reference scripts — not an app, not a program you run, and nothing here installs or configures anything automatically.** You'll still need LaunchBox and Hypseus Singe installed yourself; this just documents the specific steps and fixes for getting them to work together, and gives you a template file to copy and edit by hand.

Get laserdisc and Singe-engine arcade games (Dragon's Lair-style FMV games, American Laser Games lightgun titles, etc.) running natively inside [LaunchBox](https://www.launchbox-app.com/) on Windows via [Hypseus Singe](https://github.com/DirtBagXon/hypseus-singe), the actively-maintained successor to Daphne.

## Why bother with this instead of Batocera

[Batocera](https://batocera.org/) is the path a lot of people take to play these games, and it uses the same Hypseus Singe emulator under the hood — but it's a dedicated Linux distro you boot *into*, like a second operating system living alongside Windows. Switching between your regular desktop/Steam library and these laserdisc games means a full reboot every time.

This setup runs Hypseus Singe as just another platform inside LaunchBox on your existing Windows install — no reboot, no second OS, sits right next to your other emulators and games in the same frontend.

## The method that actually works

Don't bother creating a LaunchBox **Emulator** record for Hypseus Singe at all. It causes more problems than it solves, because Hypseus needs a `-homedir` starting point to resolve its own relative paths (`singe/`, `sound/`, `roms/`, etc.), and a frontend calling `hypseus.exe` directly doesn't give it one unless you pass `-homedir`/`-datadir` explicitly. Confirmed straight from the project's own maintainer ([DirtBagXon/hypseus-singe discussion #83](https://github.com/DirtBagXon/hypseus-singe/discussions/83)) and independently re-confirmed on the LaunchBox forums as recently as [February 2026](https://forums.launchbox-app.com/topic/93223-how-do-add-hypseus-singe-emulator-to-launchbox/): the reliable approach is a **per-game `.bat` file**, launched directly, with **no Emulator association at all**.

1. For each game, write a small batch file that `cd`s into the Hypseus Singe install folder first (so all the relative paths resolve correctly), then calls `hypseus.exe` with that game's arguments. Example (`launch_template.bat` in this folder):

   ```bat
   @echo off
   cd /d "C:\Games\Hypseus Singe"
   hypseus.exe singe vldp -framefile "singe\GAMENAME\GAMENAME.txt" -script "singe\GAMENAME\GAMENAME.singe" -sound_buffer 2048 -volume_nonvldp 5 -volume_vldp 20 -fullscreen -nolinear_scale
   ```

2. In LaunchBox, add the game and point its **Application Path** straight at that `.bat` file.
3. When asked which emulator to use, choose **None of the Above** (you're not importing a ROM the emulator loads — you're launching a self-contained script).
4. If a game entry already has an Emulator record attached from an earlier attempt, remove/disable it. Leaving one attached is the #1 reported cause of a "the emulator file specified does not exist" error at launch, even though the game would run fine double-clicked from Explorer.

## Grouping games under their own platform (not lumped into generic "Arcade")

Create a platform named whatever you like (e.g. "Hypseus Singe") instead of using LaunchBox's built-in "Arcade - Laserdisc" default — you can type a custom name directly in the platform field. To make it show up nested under an existing sidebar category (Arcade, Consoles, Handhelds) the way MAME/FinalBurn do:

- **In the LaunchBox GUI:** edit the platform, go to the **Parents** tab, and check the category you want it under.
- **Editing `Platforms.xml` directly:** set that platform's `<Category>` field to the category name (e.g. `Arcade`) — an empty `<Category />` is why a custom platform sometimes fails to show up anywhere in the sidebar at all.

## Known issues worth checking before you assume something's broken

- **"Emulator file does not exist" at launch, even though the `.bat` runs fine from Explorer.** Almost always a leftover Emulator record still attached to the game (see above) — remove it.
- **Shots register but no crosshair is visible.** Some games (e.g. `maddog2-hd`) pick their crosshair image based on a `dip_Crosshair` value in that game's `.cfg` file, and one of the five built-in crosshair graphics ships as a blank placeholder. If yours lands on the blank one, changing `dip_Crosshair` to a different value (1–4) switches to an actual visible crosshair — no code or engine issue involved.
- **BIOS/core says a dependency file is missing even though it's "right there" in a `.zip` next to the main BIOS file.** Some emulator cores need that zip's contents actually extracted into the system folder alongside the loose files, not left zipped — worth double-checking before assuming a bad download.
- **Game launches fine from LaunchBox but hangs with a stuck `cmd.exe` window under BigBox specifically, sometimes working on a second attempt.** Not independently confirmed by us yet, but the likely cause: BigBox can launch a game from a different working directory than LaunchBox does, and if the `.bat` doesn't explicitly `cd /d` into the Hypseus Singe folder first (see `launch_template.bat`), the relative paths (`singe\...`) resolve against whatever folder BigBox happened to start from instead — an intermittent, timing-flavored failure rather than a consistently broken one. Make sure every launch `.bat` starts with an explicit `cd /d "path\to\Hypseus Singe"` line before calling `hypseus.exe`, and this class of issue should go away regardless of whether LaunchBox or BigBox launches it.

## Want a bigger, ready-made library instead of building your own?

If you'd rather not curate individual games, the LaunchBox/Hypseus Singe community has pre-built LaunchBox + BigBox packs — the [Uncle Rick lightgun builds](https://www.arcadepunks.com/launchbox-hypseus-singe-build-including-light-guns-uncle-rick-special/) are the best-known example, bundling 100+ Daphne/Singe/American Laser Games/ActionMax titles with Sinden lightgun support and bezels already configured. This repo's approach is for people adding their own existing collection rather than downloading someone else's bundle.

## `hypseus_game_audit.ps1`

A small PowerShell script for anyone whose Hypseus Singe library grows over time: scans your `singe\` games folder and flags any game folder that doesn't have a matching launch script, so you catch a missing/renamed launcher before you're standing in front of the cabinet wondering why a game won't start. Usage and parameters are documented at the top of the script.

## Sources

- [DirtBagXon/hypseus-singe](https://github.com/DirtBagXon/hypseus-singe) — the project itself
- [Discussion #83: Ability to add Hypseus into Launchbox](https://github.com/DirtBagXon/hypseus-singe/discussions/83)
- [LaunchBox forums: How do add Hypseus-Singe emulator to Launchbox (Feb 2026)](https://forums.launchbox-app.com/topic/93223-how-do-add-hypseus-singe-emulator-to-launchbox/)
- [ArcadePunks: Hypseus Singe LaunchBox Lightgun Build (Uncle Rick)](https://www.arcadepunks.com/launchbox-hypseus-singe-build-including-light-guns-uncle-rick-special/)
