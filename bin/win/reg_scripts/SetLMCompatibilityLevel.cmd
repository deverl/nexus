@echo off

setlocal

set NEWLMCOMPATLEVEL=1

if "%1" equ "" goto :skip_set_var
set NEWLMCOMPATLEVEL=%1

:skip_set_var

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LMCompatibilityLevel /t REG_DWORD /d %NEWLMCOMPATLEVEL%  /f

endlocal

