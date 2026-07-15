@echo off
REM Template launch script for a single Hypseus Singe game.
REM Copy this file, rename it to launch_GAMENAME.bat, and fill in GAMENAME below.
REM Point LaunchBox's "Application Path" for this game straight at the renamed
REM copy, with no Emulator record attached (see README.md for why).

cd /d "C:\Games\Hypseus Singe"

hypseus.exe singe vldp ^
  -framefile "singe\GAMENAME\GAMENAME.txt" ^
  -script "singe\GAMENAME\GAMENAME.singe" ^
  -sound_buffer 2048 ^
  -volume_nonvldp 5 ^
  -volume_vldp 20 ^
  -fullscreen ^
  -nolinear_scale
