@echo off

setlocal

set SCRACTIVE=1
set SCRSECURE=0
set SCRTIMEOUT=5
set SCR_EXE=logon.scr

reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive    /t REG_SZ /d %SCRACTIVE%  /f
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d %SCRSECURE%  /f
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut   /t REG_SZ /d %SCRTIMEOUT% /f
reg add "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE        /t REG_SZ /d %SCR_EXE%    /f

reg add "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveActive    /t REG_SZ /d %SCRACTIVE%  /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d %SCRSECURE%  /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveTimeOut   /t REG_SZ /d %SCRTIMEOUT% /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" /v SCRNSAVE.EXE        /t REG_SZ /d %SCR_EXE%    /f

endlocal


