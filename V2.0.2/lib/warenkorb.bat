@echo off

:main function self params
	rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
	if not "%1"=="init" (
		setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
		if not "!%2!"=="%~dpnx0" (
			call :error_FATAL "MAIN: "%2" was not init by this modul"
			endlocal
			goto :EOF
		)
		endlocal
	)
	call :warenkorb.%*
goto :EOF

:warenkorb.init self
	rem minimun, !%1! entpricht dem pfad zu dieser Batchdatei
	set "%1=%~dpnx0"
	call lib\array init %1.idArray
	call lib\array init %1.preisArray
	call lib\array init %1.nameArray
	call lib\array init %1.anzahlArray
	call lib\array init %1.printArray
	set "%1.summe=0"
	set "%1.gesamtAnzahl=0"
exit /b 0

:warenkorb.getSumm self returnVar
rem gibt den gesamt betrag des warenkorb zurück
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "summe=!%1.summe!"
endlocal & set "%2=%summe%"
exit /b 0

:warenkorb.getSummItems self returnVar
rem gibt die anzahl der einzelen elemente im warenkob zurück
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "gesamtAnzahl=!%1.gesamtAnzahl!"
endlocal & set "%2=%gesamtAnzahl%"
exit /b 0

:warenkorb.isEmpty self
rem exit 1 if empty
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call lib\array len %1.idArray len
if %len% EQU 0 exit /b 0
exit /b 1

:warenkorb.append self "id" "preis" "name"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "id=%~2"
set /a "preis=%~3" || call :error_FATAL ".append: 32-bit OVERVLOW"
set "name=%~4"
set /a "anzahl=0"
rem alle indexe wo id ist input
set "index="
rem die schleife der gruppierung kostet ein paar ms....
for /F "usebackq delims=" %%a in (`call lib\array filter %1.idArray "%id%"`) do (
	call lib\array get %1.preisArray "%%~a" tmpPreis
	if !tmpPreis! EQU %preis% (
		set "index=%%a"
		call lib\array get %1.anzahlArray !index! anzahl
	)
)
set /a "anzahl+=1"
call :_warenkorb.makePrintLn printLn  "%preis%" "%name%" "%anzahl%"
endlocal & (
	set /a "%1.gesamtAnzahl+=1"
	set /a "%1.summe+=%preis%" || call :error_FATAL ".append: 32-bit OVERVLOW"
	if not "%index%"=="" (
		call lib\array set %1.anzahlArray %index% "%anzahl%"
		call lib\array set %1.printArray %index% "%printLn%"
	) else (
		call lib\array append %1.idArray "%id%"
		call lib\array append %1.preisArray "%preis%"
		call lib\array append %1.nameArray "%name%"
		call lib\array append %1.anzahlArray "%anzahl%"
		call lib\array append %1.printArray "%printLn%"
	)
)

exit /b 0

:warenkorb.pop self index
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "index=%~2"
call lib\array index %1.anzahlArray maxIndex
if %index% GTR %maxIndex% exit /b 1
if %index% LSS 0 exit /b 1
call lib\array get %1.anzahlArray %index% anzahl
call lib\array get %1.preisArray %index% preis
set /a "anzahl-=1"
if %anzahl% GTR 0 (
	call lib\array get %1.nameArray %index% name
	call :_warenkorb.makePrintLn printLn "!preis!" "!name!" "!anzahl!"
)
endlocal & (
	set /a "%1.gesamtAnzahl-=1"
	set /a "%1.summe-=%preis%" || call :error_FATAL ".pop: 32-bit OVERVLOW"
	if %anzahl% GTR 0 (
		call lib\array set %1.anzahlArray %index% "%anzahl%"
		call lib\array set %1.printArray %index% "%printLn%"
	) else (
		call lib\array pop %1.idArray %index%
		call lib\array pop %1.preisArray %index%
		call lib\array pop %1.nameArray %index%
		call lib\array pop %1.anzahlArray %index%
		call lib\array pop %1.printArray %index%
	)
)
exit /b 0

:warenkorb.popByID self "id"
rem sucht nach der artikelid im warenkorb, der letzte gefundene eintrag wird um 1 veringert
rem exit 0 wenn eine veringerung stattgefunden hat
rem exit 1 wenn kein passender eintrag gefunden wurde
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "id=%~2"
set "index="
for /F "usebackq delims=" %%a in (`call lib\array filter %1.idArray "%id%"`) do (
	set "index=%%a"
)
endlocal & (
	if not "%index%"=="" call :warenkorb.pop %1 "%index%" && exit /b 0
)
exit /b 1

:_warenkorb.makePrintLn returnVar "preis" "name" "anzahl"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "summe=%~2*%~4"
call :_warenkorb.cntToEuroStr "%~2" preisStr
call :_warenkorb.cntToEuroStr "%summe%" summeStr
set "preisStr=__________________%preisStr%"
set "summeStr=__________________%summeStr%"
set "nameStr=%~3____________________________________"
set "anzahlStr=__________________x%~4"
endlocal & set "%1=%nameStr:~0,25% %preisStr:~-10% %anzahlStr:~-4%  %summeStr:~-10%"
exit /b 0

:_warenkorb.cntToEuroStr ct var
if "%~2"=="" call :error_FATAL "cntToEuroStr: to less arguments"
if not "%~3"=="" call :error_FATAL "cntToEuroStr: to much arguments"
setlocal
:: Beispiel-Eingabe in Cent
set "negativPrefix="
set /a "inputCent=%~1"
if %inputCent% LSS 0 (
	set /a "inputCent*=-1" || call :error_FATAL "_.cntToEuroStr: 32-bit OVERVLOW"
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

:warenkorb.show self returnVar
rem print warenkorb return index
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "pos=-1"
call :_warenkorb.cntToEuroStr "!%1.summe!" summeStr
set "summeStr=__________________%summeStr%"
echo. #_Pos.________Name__________________Preis___Anzahl___gesamt__
echo.
for /F "usebackq delims=" %%a in (`call lib\array print %1.printArray`) do (
	set /a "pos+=1"
	set "posStr=!pos!____"
	echo. # !posStr:~0,2!   %%a
)
echo. #                                                 ----------
echo. #                                           Summe %summeStr:~-10%
endlocal & set "%2=%pos%"
exit /b 0

:warenkorb.printCSV self [delims]
rem prints format: preis,name,anzahl
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "delim=%~2"
if not defined delim set "delim=;"
call lib\array index %1.preisArray index
for /L %%i in (0,1,%index%) do (
	call lib\array get %1.idArray %%i id
	call lib\array get %1.preisArray %%i preis
	call lib\array get %1.nameArray %%i name
	call lib\array get %1.anzahlArray %%i anzahl
	echo."!id!"%delim%"!preis!"%delim%"!name!"%delim%"!anzahl!"
)
endlocal
exit /b 0

:warenkorb.printCSVsingle self [delims]
rem prints xTimes the item format: preis,name
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "delim=%~2"
if not defined delim set "delim=;"
call lib\array index %1.preisArray index
for /L %%i in (0,1,%index%) do (
	call lib\array get %1.anzahlArray %%i anzahl
	call lib\array get %1.idArray %%i id
	call lib\array get %1.preisArray %%i preis
	call lib\array get %1.nameArray %%i name
	for /L %%j in (1,1,!anzahl!) do (
		echo."!id!"%delim%"!preis!"%delim%"!name!"
	)
)
endlocal
exit /b 0




:error_FATAL "Message"
>&2 echo( FATAL ERROR: "%~dpnx0"
>&2 echo( ### %* ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo( #INFO: %*
GOTO :EOF
