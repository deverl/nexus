@echo off

setlocal

reg delete "HKCU\Software\Marvell\mvhlewsi" /v DebugLevel /f

endlocal


