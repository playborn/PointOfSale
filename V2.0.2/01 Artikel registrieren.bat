@echo off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
chcp 65001
cls
:setup
title %~n0
set "preisListe="
call lib\readINI "config.ini"
if not defined preisListe (
	echo.
	echo. Eine neue Preisliste erstellen oder eine existierende angeben.
	set /p "preisListe=Pfad zur Preistabellen Datei:"
	call :cleanString preisListe %preisListe%
)
if not defined maxRetrys call :error_FATAL " ERROR IN config.ini: maxRetrys nicht definiert"
call lib\artikel init articels "%preisListe%" "%maxRetrys%"

:main
call :menu articels
goto main






:menu articelsObj
call lib\artikel count %1 articelsInFile
set "id="
set "price=0"
set "name="
:menuLOOP
call :cntToEuroStr %price% priceStr
set "priceStr=%priceStr%_________________________"
set "priceStr=%priceStr:~0,25%"
set "idStr=%id%_________________________"
set "idStr=%idStr:~0,25%"
set "nameStr=%name%_________________________"
set "nameStr=%nameStr:~0,25%"
cls
echo. 
echo. Artikel werden in folgender Datei gespeichert.
echo. preiliste: [ %preisListe% ]
echo. Registrierte Artikel: [ %articelsInFile% ]
echo. 
echo. ###### [ Neuer Artikel ] ######
echo.
echo.  [1] Artikelnummer:[ %idStr% ]
echo.  [2]   Bezeichnung:[ %nameStr% ]
echo.  [3]         Preis:[ %priceStr% ]
echo.
echo. ###############################
echo. # [+]Speichern  [-]leeren
echo. %statusStr%
call lib\readKey getKey menu
set "statusStr="
if "%menu%"=="1" (
	set /p "ID=13 stellige EAN:"
)
if "%menu%"=="3" (
	call :bargeldEingabe input && (set "price=!input!" & goto menuLOOP)
)
if "%menu%"=="2" (
	set /p "name=Name:"
	goto menuLOOP
)
if "%menu%"=="-" (
	set "id="
	set "name="
	set "price=0"
	goto menuLOOP
)
if "%menu%"=="+" (
	call :artikelErstellen %1 "%ID%" "%price%" "%name%" && (
		set "statusStr=# erfolgreich gespeichert"
		set "id="
		call lib\artikel count %1 articelsInFile
		goto menuLOOP
	)
	echo.
	echo # Speichern nicht möglich #
	echo # Eingaben auf vollständigkeit prüfen, oder Artikelnummer schon vergeben #
	pause
)
goto menuLOOP




:artikelErstellen self "articelID" "price" "name"
setlocal
set "ID=%~2"
set "price=%~3"
set "name=%~4"
if not defined ID exit /b 1
if not defined price exit /b 1
call lib\artikel exist %1 "%ID%" && exit /b 1
call lib\artikel create %1 "%ID%" "%price%" "%name%"
exit /b 0



:bargeldEingabe varInput
rem beendet mit exit /b 1 wenn eingabe ungültig ist.
rem gibt die eingabe des benutzers immer zurück
setlocal
set "betrag="
set "valid=false"
set /p "betrag=Betrag Eingeben:"
if defined betrag (
	set "valid=true"
	set "betrag=!betrag:,=!"
	set "betrag=!betrag:.=!"
	for /F "delims=-0123456789" %%a in ("!betrag!") do (
		set "valid=false"
	)
	if "!betrag:~0,1!"=="0" set "valid=false"
	if "!betrag:~0,1!"=="-" if "!betrag:~1,1!"=="0" set "valid=false"
	
	rem prevent 32-bit overflow
	if not "!betrag:~9,1!"=="" set "valid=false"
)
endlocal & (
	set "%1=%betrag%"
	if %valid%==false exit /b 1
)
exit /b 0

:cntToEuroStr ct var
if "%~2"=="" call :error_FATAL "cntToEuroStr: to less arguments"
if not "%~3"=="" call :error_FATAL "cntToEuroStr: to much arguments"
setlocal
:: Beispiel-Eingabe in Cent
set "negativPrefix="
set /a "inputCent=%~1"
if %inputCent% LSS 0 (
	set /a "inputCent*=-1"
	set "negativPrefix=-"
)
:: Euro- und Cent-Anteil ermitteln
set /a "euroPart=inputCent/100"
set /a "centPart=inputCent %% 100"
:: Cent auf zwei Stellen bringen
if %centPart% LSS 10 set "centPart=0%centPart%"
:: Ergebnis
endlocal & set "%2=%negativPrefix%%euroPart%,%centPart% €"
exit /b 0




:cleanString var "input"
set "%1=%~2"
exit /B 0


:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL