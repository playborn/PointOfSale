@echo off


:main func self params
if "%2"=="" call :error_FATAL "MAIN: to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" call :error_FATAL "MAIN: "%2" was not init by this modul"
	endlocal
)
call :file.%*
goto :EOF




:file.init self "file" [maxRetrys]
if "%~2"=="" call :error_FATAL ".init: missing args"
if not "%~4"=="" call :error_FATAL ".init: to much args"
set "%1=%~dpnx0"
set "%1.file=%~2"
if not "%~3"=="" (set /a "%1.maxRetrys=%~3") else (set /a "%1.maxRetrys=0")
set "%1.retrys=0"
exit /b 0

:file.print self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "COMMAND=:_file.exist %1"
call :retry %1 COMMAND || exit /b 1
set "COMMAND=:_file.type %1"
call :retry %1 COMMAND || exit /b 1
exit /b 0

:file.append self || pipe
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "COMMAND=:_file.exist %1"
call :retry %1 COMMAND || exit /b 1
set "COMMAND=:_file.appendLine %1 APPENDLINE"
set /a "line=0"
rem findstr /N stellt sicher dass auch leere zeilen geschieben werden
For /f "usebackq tokens=1* delims=: eol=" %%a in (`findstr /N "^"`) do (
	set "APPENDLINE=%%~b"
	call :retry %1 COMMAND|| (
		call :error_INFO ".append: ### ERROR WHILE APPENDING ###"
		call :error_INFO ".append: Versuche:!%1.retrys! von !%1.maxRetrys!"
		call :error_INFO ".append: Geschriebene Zeilen bis zum Fehler:!line!"
		rem call :error_FATAL ".append: Vorgang wurde unerwartet unterbrochen"
		exit /b 1
	)
	set /a "line+=1"
)
exit /b 0

:file.write self || pipe
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "COMMAND=:_file.exist %1"
call :retry %1 COMMAND || (
	call :error_INFO ".write: Datei nicht gefunden:"!%1.file!""
	exit /b 1
)
set "COMMAND=:_file.clean %1"
call :retry %1 COMMAND || (
	call :error_INFO ".write: Zugriff verweigert:"!%1.file!""
	exit /b 1
)
set "COMMAND=:_file.appendLine %1 APPENDLINE"
set /a "line=0"
rem findstr /N stellt sicher dass auch leere zeilen geschieben werden
For /f "usebackq tokens=1* delims=: eol=" %%a in (`findstr /N "^"`) do (
	set "APPENDLINE=%%~b"
	call :retry %1 COMMAND|| (
		call :error_INFO ".write: ### ERROR WHILE WRITING ###"
		call :error_INFO ".write: Versuche:!%1.retrys! von !%1.maxRetrys!"
		call :error_INFO ".write: inhalt der Datei wurde überschrieben"
		call :error_INFO ".write: Geschriebene Zeilen bis zum Fehler:!line!"
		rem call :error_FATAL ".write: Vorgang wurde unerwartet unterbrochen"
		exit /b 1
	)
	set /a "line+=1"
)
exit /b 0

:_file.appendLine self übergabeVariable
2>NUL >>"!%1.file!" echo.!%2!|| exit /b 1
exit /b 0

:_file.clean self
2>NUL TYPE NUL>"!%1.file!"||exit /b 1
exit /b 0

:_file.type self
2>NUL type "!%1.file!"||exit /b 1
exit /b 0

:_file.exist self
if not exist "!%1.file!" exit /b 1
exit /b 0

:retry self übergabeVariable
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "COMMAND=!%2!"
set "retrys=!%1.retrys!"
set "maxRetrys=!%1.maxRetrys!"
if %retrys% GTR %maxRetrys% exit /b 1
endlocal & (
	call %COMMAND%||(
		if %retrys% GTR %maxRetrys% (set "%1.retrys=0" & exit /b 1)
		call :error_INFO " ## Vorgang wird wiederholt ## "
		set /a "%1.retrys+=1"
		goto retry
	)
set "%1.retrys=0"
)
exit /b 0



:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %* ###
>&2 echo No exit option implemented yet
2>&1 >NUL pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo( #INFO[%~n0] %*
GOTO :EOF
