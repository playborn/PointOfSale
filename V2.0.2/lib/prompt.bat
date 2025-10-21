@echo off

:prompt "Text"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "border=+"
set "text=%border% %~1 %border%"
call lib\string len "%text%" textLen
call lib\string makeSpace "%border%" %textLen% border
echo. %border%
echo. %text%
echo. %border%
exit /b 0