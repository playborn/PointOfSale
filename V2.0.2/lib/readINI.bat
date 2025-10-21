@echo off

:main "file"
if "%~1"=="" call :error_FATAL "MAIN: to less arguments"
if not "%~2"=="" call :error_FATAL "MAIN: to much arguments"
if not exist "%~1" call :error_FATAL "MAIN: file not found:"%~1""


for /F "usebackq tokens=1-3 delims==" %%a in ("%~1") do (
	echo( INFO# setting %%a=%%~b
	set "%%a=%%~b"
	if not "%%c"=="" call :error_FATAL "MAIN: CORRUPT FILE FORMAT:"%~1""
)

GOTO :EOF


:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL