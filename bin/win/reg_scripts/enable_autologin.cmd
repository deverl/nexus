@echo off

setlocal

parent_key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon

reg add "%parent_key%" /v DefaultUsername /t REG_SZ "DeVerl Stokes" /f
reg add "%parent_key%" /v DefaultPassword /t REG_SZ ""              /f 
reg add "%parent_key%" /v AutoAdminLogon  /t REG_SZ "1"             /f 

endlocal


