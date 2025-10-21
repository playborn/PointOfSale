@echo off

:main
call :string.%*
goto :EOF





:string.len "string" var
if "%~2"=="" call :error_FATAL ".len missing Args"
if not "%~3"=="" call :error_FATAL ".len to much Args"
set "%2="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "str=%~1"
set "len=0"
if defined str (
	set /a "len=1"
	for %%i in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
		if "!str:~%%i,1!" NEQ "" ( 
			set /a "len+=%%i"
			set "str=!str:~%%i!"
		)
	)
)
endlocal & (
	set /a "%2=%len%"
)
exit /b 0

:string.padRight "string" "wantedSize" "spaceCHAR" var
if "%~4"=="" call :error_FATAL ".padRight missing Args"
if not "%~5"=="" call :error_FATAL ".padRight to much Args"
set "%4="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "str=%~1"
set /a "wantedSize=%~2" || call :error_FATAL ".padRight wantedSize is not a integer"
set "spaceCHAR=%~3"
call :string.len "!str!" strLen
set /a "spaceLeftLen=wantedSize-strLen"
set "space="
if !spaceLeftLen! GTR 0 (
	call :string.makeSpace "!spaceCHAR!" "!spaceLeftLen!" space
	set "str=!space!!str!"
)
set /a "spaceLeftLenInverted=spaceLeftLen*-1"
if !spaceLeftLen! LSS 0 (
	rem RECHTS ABSCHNEIDEN
	rem set "str=!str:~0,%wantedSize%!"
	rem LINKS ABSCHNEIDEN
	set "str=!str:~%spaceLeftLenInverted%!"
)

endlocal & (
	set "%4=%str%"
)
exit /b 0

:string.padLeft "string" "wantedSize" "spaceCHAR" var
if "%~4"=="" call :error_FATAL ".padLeft missing Args"
if not "%~5"=="" call :error_FATAL ".padLeft to much Args"
set "%4="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "str=%~1"
set "wantedSize=%~2" || call :error_FATAL ".padLeft wantedSize is not a integer"
set "spaceCHAR=%~3"
call :string.len "!str!" strLen
set /a "spaceRightLen=wantedSize-strLen"
set "space="
if !spaceRightLen! GTR 0 (
	call :string.makeSpace "!spaceCHAR!" "!spaceRightLen!" space
	set "str=!str!!space!"
)
if !spaceRightLen! LSS 0 (
	set "str=!str:~0,%wantedSize%!"
)

endlocal & (
	set "%4=%str%"
)
exit /b 0

:string.padCenter "str" "wantedSize" "spaceCHAR" var
if "%~4"=="" call :error_FATAL ".padCenter missing Args"
if not "%~5"=="" call :error_FATAL ".padCenter to much Args"
set "%4="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "str=%~1"
set /a "wantedSize=%~2" || call :error_FATAL ".padCenter wantedSize is not a integer"
set "spaceCHAR=%~3"

set "spaceLeft="
set "spaceRight="
call :string.len "!str!" strLen
set /a "diffSize=wantedSize-strLen"
set /a "spaceLeftLen=diffSize/2+(diffSize %% 2)"
set /a "spaceRightLen=diffSize-spaceLeftLen"
if !spaceRightLen! GTR 0 (
	call :string.makeSpace "!spaceCHAR!" "!spaceRightLen!" spaceRight
)
if !spaceLeftLen! GTR 0 (
	call :string.makeSpace "!spaceCHAR!" "!spaceLeftLen!" spaceLeft
)
if !spaceRightLen! LSS 0 (
	rem schneide ab von rechts
	set "str=!str:~0,%spaceRightLen%!"
)
rem inverted helper var because delayed expansion
set /a "spaceLeftLenInverted=spaceLeftLen*-1"
if !spaceLeftLen! LSS 0 (
	rem schneide ab von links
	set "str=!str:~%spaceLeftLenInverted%!"
)
set "str=!spaceLeft!!str!!spaceRight!"
endlocal & (
	set "%4=%str%"
)
exit /b 0



:string.makeSpace "Char" "len" var
if "%~3"=="" call :error_FATAL ".makeSpace missing Args"
if not "%~4"=="" call :error_FATAL ".makeSpace to much Args"
set "%3="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "char=%~1"
set /a "len=%~2"
set "space=!char!"
for %%i in (2 4 8 16 32 64 128 256 512 1024 2048 4096) do (
	set "space=!space!!space!"
)
set "space=!space:~0,%len%!"
endlocal & (
	set "%3=%space%"
)

exit /b 0



:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %* ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo( #INFO: %*
GOTO :EOF
