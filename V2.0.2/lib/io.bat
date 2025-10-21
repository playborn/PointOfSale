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




:file.init self "file"
if "%~2"=="" call :error_FATAL ".init: missing args"
if not "%~3"=="" call :error_FATAL ".init: to much args"
set "%1=%~dpnx0"
set "%1.file=%~2"
exit /b 0

:file.print self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
type "!%1.file!"||(
	call :error_INFO " .. Datei kann nicht angezeigt werden .. "
	exit /b 1
)
exit /b 0

:file.open self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
>NUL 2>&1 mkdir "!%1.file!.LOCK" || (
	call :error_INFO " .. Datei kann nicht geöffnet werden .. "
	exit /b 1
)
exit /b 0

:file.close self
>NUL 2>&1 rmdir "!%1.file!.LOCK" || (
	call :error_INFO " .. Datei kann nicht geschlossen werden .. "
	exit /b 1
)
exit /b 0

:file.append self || pipe
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
findstr "^">>"!%1.file!"||(
	call :error_INFO " .. Es kann nicht an die Datei angehängt werden.. "
	exit /b 1
)
exit /b 0

:file.write self || pipe
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
findstr "^">"!%1.file!"||(
	call :error_INFO " .. Es kann nicht in die Datei geschrieben werden .. "
	exit /b 1
)
exit /b 0

:file.wipe self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
type NUL>"!%1.file!"||(
	call :error_INFO " .. Datei konnte nicht bereinigt werden .. "
	exit /b 1
)
exit /b 0

:file.getPath self returnVar
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "%2=!%1.file!"
exit /b 0

:file.exist self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if exist "!%1.file!" exit /b 0
exit /b 1

:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %* ###
>&2 echo No exit option implemented yet
2>&1 >NUL pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo( #INFO[%~n0] %*
GOTO :EOF
