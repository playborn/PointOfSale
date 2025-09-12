@echo off


:main func self params
if "%2"=="" call :error_FATAL "to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" call :error_FATAL "MAIN: "%2" was not init by this modul"
	endlocal
)
call :list.%*
goto :EOF




:list.init self
rem Objekt wurde inizialisiert mit dieser Datei
set "%1=%~dpnx0"
set "%1.len=0"
exit /b 0

:list.len self var
if "%2"=="" call :error_FATAL ".len: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
endlocal & set /a "%2=!%1.len!"
exit /b 0

:list.index self var
if "%2"=="" call :error_FATAL ".index: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
endlocal & set /a "%2=!%1.len!-1"
exit /b 0

:list.append self "string"
if not "%~3"=="" call :error_FATAL ".append: to much arguments, maybe special chars?"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "string=%~2"
set /a "len=!%1.len!"
endlocal & (
	set "%1[%len%]=%string%"
	set /a "%1.len+=1"
)
exit /b 0

:list.pop self index [var]
rem Entfernt Element an Index und gibt es in %3 zurück
if "%~2"=="" call :error_FATAL ".pop: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :list.indexNormalizer %1 %2 index || call :error_FATAL ".pop: INDEX[!index!] OUT OF BOUND"
set /a "lastIndex=!%1.len!-1"
if %lastIndex% LSS 0 call :error_FATAL ".pop: array is empty"
call :list.get %1 %index% value
endlocal & (
	if not "%~3"=="" set "%3=%value%"
	rem Schiebe alle nachfolgenden Elemente eins nach vorn
	for /L %%i in (%index%,1,%lastIndex%) do (
		rem set /a "nextID=%%i+1"
		if %%i LSS %lastIndex% (
			call :list.get %1 "%%i+1" next
			call :list.set %1 %%i "!next!"
		)
	)
rem Letztes Element löschen
set "%1[%lastIndex%]="
set /a "%1.len-=1"
)
exit /b 0

:list.get self index var
if "%3"=="" call :error_FATAL ".get: to less arguments"
set "%3="
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :list.indexNormalizer %1 %2 index || call :error_FATAL ".get: INDEX[!index!] OUT OF BOUND"
set "string=!%1[%index%]!"
endlocal & set "%3=%string%"
exit /b 0

:list.set self index "string"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :list.indexNormalizer %1 %2 index || call :error_FATAL ".set: INDEX[!index!] OUT OF BOUND"
endlocal & set "%1[%index%]=%~3"
exit /b 0

:list.insert self index "string"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "insertValue=%~3"
call :list.indexNormalizer %1 %2 insertIndex || call :error_FATAL ".insert: INDEX[!insertIndex!]OUT OF BOUND"
set /a "lastIndex=!%1.len!-1"
endlocal & (
	set /a "%1.len+=1"
	for /L %%i in (%lastIndex%,-1,%insertIndex%) do (
		rem set /a "nextID=%%i+1"
		rem call :list.get %1 %%i moveValue
		call :list.set %1 "%%i+1" "!%1[%%i]!"
	)
	call :list.set %1 %insertIndex% "%insertValue%"
)
exit /b 0

:list.copy self self2
if "%2"=="" call :error_FATAL ".copy: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "index=!%1.len!-1"
endlocal & (
	for /L %%i in (0,1,%index%) do (
		set "%2[%%i]=!%1[%%i]!"
	)
	set "%2.len=!%1.len!"
)
exit /b 0

:list.swap self indexA IndexB
if "%~3"=="" call :error_FATAL ".swap: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "indexA=%~2"
call :list.indexNormalizer %1 %indexA% indexA || call :error_FATAL ".swap: INDEX OUT OF BOUND"
set /a "indexB=%~3"
call :list.indexNormalizer %1 %indexB% indexB || call :error_FATAL ".swap: INDEX OUT OF BOUND"
set "valA=!%1[%indexA%]!"
set "valB=!%1[%indexB%]!"
endlocal & (
	set "%1[%indexA%]=%valB%"
	set "%1[%indexB%]=%valA%"
)
exit /b 0

:list.shuffle self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem Fisher-Yates Shuffle
set /a "index=!%1.len!-1"
endlocal & (
	for /L %%i in (%index%,-1,1) do (
		rem set /a "j=!random! %% (%%i+1)"
		rem 4x %%%% wird durch call oder so, weggekürzt
		call :list.swap %1 %%i "!random! %%%% (%%i+1)"
	)
)
exit /b 0

:list.print self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "index=!%1.len!-1"
for /L %%i in (0,1,%index%) do (
	echo(!%1[%%i]!
)
exit /b 0

rem Wandelt negativen Index in positiven um Und prüft auf index in range
:list.indexNormalizer self index var
if "%3"=="" call:error_FATAL ".indexNormalizer: to less arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem %2 könnte auch eine rechnung sein
set /a "index=%~2" || call :error_FATAL ".indexNormalizer: Index is not a number"
rem negativen Index in positiven umrechnen
if %index% lss 0 (
    set /a "index+=!%1.len!"
)
if %index% LSS 0 call :error_FATAL ".indexNormalizer: index out of bound"
if %index% GEQ !%1.len! call :error_FATAL ".indexNormalizer: index out of bound"
endlocal & set "%3=%index%"
exit /b 0

:_list.del self
rem reseting all vars starting with %1
for /F "usebackq tokens=1 delims==" %%a in (`2^>NUL set %1`) do (
	set "%%a="
)
exit /b 0

:list.filter self "value"
rem prints indexes wehre values are same
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "index=!%1.len!-1"
set "searchValue=%~2"
for /L %%i in (0,1,%index%) do (
	if "!%1[%%i]!"=="%searchValue%" echo(%%i
)
exit /b 0

:list.count self "value" var
rem returns how often a value occurs in array
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "index=!%1.len!-1"
set "searchValue=%~2"
set /a "counter=0"
for /L %%i in (0,1,%index%) do (
	if "!%1[%%i]!"=="%searchValue%" set /a "counter+=1"
)
endlocal & set "%3=%counter%"
exit /b 0






:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL