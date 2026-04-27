@echo off

setlocal

set MSOVER=11.0

reg delete HKCU\Software\Microsoft\Office\%MSOVER%\Common\Scan /v Device  /f > nul 
reg delete HKCU\Software\Microsoft\Office\%MSOVER%\Common\Scan /v Device0 /f > nul
reg delete HKCU\Software\Microsoft\Office\%MSOVER%\Common\Scan /v Device1 /f > nul
reg delete HKCU\Software\Microsoft\Office\%MSOVER%\Common\Scan /v Flags0  /f > nul
reg delete HKCU\Software\Microsoft\Office\%MSOVER%\Common\Scan /v Flags1  /f > nul

set MSOVER=

endlocal


