@echo off

setlocal

reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Setup" /v LogLevel /t REG_DWORD /d 0 /f

endlocal

