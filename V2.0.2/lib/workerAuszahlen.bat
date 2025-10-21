@echo off
>NUL chcp 65001
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
title ..processing..
:warenkorb.einzahlen warenkorbObj kundenObj "customerID" "KassenID"
if "%~4"=="" call :error_FATAL " to less arguments"
if not "%~5"=="" call :error_FATAL " to much arguments"
set "customerID=%~3"
set "kassenID=%~4"
call lib\accounts getCurrentTransactionID %2 transactionID
title ..processing..
echo. # Dieses Fenster nicht schließen
echo. # Transaction [ %transactionID% ] wird übermittelt...
echo. # Für Kunde [ %customerID% ]


for /F "usebackq tokens=2,3 delims=;" %%a in (`call lib\warenkorb printCSVsingle %1 ";"`) do (
	set "betrag=%%~a*-1"
	set "name=%%~b"
	echo.!betrag!;"!name!";"AUSZAHLUNG"|call lib\accounts doTransaction %2 "!customerID!"
	if /I not "!customerID!"=="!kassenID!" echo.!betrag!;"!name!";"AUSZAHLUNG"|call lib\accounts doTransaction %2 "!kassenID!"
)

exit /b 0




:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
rem >&2 pause
EXIT



