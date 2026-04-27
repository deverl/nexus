@echo off

reg add "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d "user"  /f

reg add "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d ""  /f

reg add "HKLM\SOFTWARE\Microsoft\WindowsNT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d "1"  /f
