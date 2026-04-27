@echo off

setlocal

reg add "HKCU\Software\Marvell\mvhlewsi" /v DebugLevel /t REG_DWORD /d 7 /f

endlocal


