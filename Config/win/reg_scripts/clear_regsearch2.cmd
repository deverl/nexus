@echo off

reg add "HKCR\Interface\{AD6F3ECA-A851-11cf-BB0E-444553540000}\NumMethods" /v Value /t REG_DWORD /d 0  /f

