@echo off

path | tr ";" "\n" | sed "/PATH=/s///"