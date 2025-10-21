@echo off

:main func self params
if "%2"=="" call :error_FATAL "MAIN: to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" (
		call :error_FATAL "MAIN: "%2" was not init by this modul"
		endlocal & exit /b 1
	)
	endlocal
)
call :retry.%*
GOTO :EOF




:retry.init self cmdVar maxRetrys
rem cmdVar der var name der den auszuführenden befehl enthält. wird dynamisch zum exec aufruf expandiert.
if "%~3"=="" call :error_FATAL ".init: to less arguments"
if not "%~4"=="" call :error_FATAL ".init: to much arguments"
set "%1=%~dpnx0"
set "%1.cmdVar=%2"
set /a "%1.maxRetrys=%~3"
set /a "%1.retrys=0"
exit /B 0


:retry.exec self [returnVar]
rem führt den befehl aus bis er erfolgreich ist oder die maximalen versuche überschritten sind.
rem gibt optional die benötigten neuversuche zurück
rem exit 1 wenn befehl nicht erfoglreich inerhalb der definierten neuversuche
rem returns number of needed retrys
rem if the command runs in the first attempt return is 0
if not "%~2"=="" set /a "%2="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "cmdVar=!%1.cmdVar!"
set "COMMAND=!%cmdVar%!"
if not defined COMMAND call :error_FATAL ".exec: NO COMMAND DEFINED"
set /a "retrys=!%1.retrys!"
set /a "maxRetrys=!%1.maxRetrys!"
endlocal & (
	if not "%~2"=="" set /a "%2=%retrys%"
	
	%COMMAND%||(
		if not %maxRetrys% EQU -1 (
			if %retrys% EQU %maxRetrys% (
				set "%1.retrys=0"
				rem wir fallen hier in ein fatal error, weil die fehler im hauptprogramm nicht behandelt werden
				call :error_INFO ".exec: Programm wird gestoppt" 
				call :error_FATAL ".exec: MAXIMUM RETRY LIMIT"
				exit /b 1
			)
		)
		call :error_INFO " .. Es wird neu versucht [%retrys%/%maxRetrys%] .. "
		set /a "%1.retrys+=1"
		call :retard 10000
		goto retry.exec
	)
set "%1.retrys=0"
)
exit /b 0


:retard maxRetardTicks
rem 100 benötigt ca. 500 ms
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "retard=!random! %% %~1"
call :error_INFO " .. Prozess wird ausgebremst um !retard! ticks.. "
for /L %%i in (0,1,!retard!) do (
	echo.>NUL
)
goto :EOF

:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %* ###
>&2 pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo( #INFO[%~n0] %*
GOTO :EOF
