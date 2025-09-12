@echo off


:main func self params
if "%2"=="" call :error_FATAL "MAIN: to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" call :error_FATAL "MAIN: "%2" was not init by this modul"
	endlocal
)
call :artikel.%*
goto :EOF






:artikel.init self "priceTable" [maxRetrys]
if "%~2"=="" call :error_FATAL ".init: to less arguments"
if not "%~4"=="" call :error_FATAL ".init: to much arguments"
set "%1=%~dpnx0"
set "%1.priceTable=%~2"
if not exist "!%1.priceTable!" call :error_FATAL ".init: File not found "!%1.priceTable!""
set "%1.selectedID="
set "%1.selectedPrice="
set "%1.selectedName="
if "%~3"=="" (set "%1.maxRetrys=0") else (set /a "%1.maxRetrys=%~3")
exit /b 0

:artikel.create self "articleID" "price" "name"
if "%~4"=="" call :error_FATAL ".create: to less arguments"
if not "%~5"=="" call :error_FATAL ".create: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "articleID=%~2"
set "price=%~3"
set "name=%~4"
if not exist "!%1.priceTable!" call :error_FATAL ".create: File not found:!%1.priceTable!"
call lib\file init priceTable "!%1.priceTable!" "!%1.maxRetrys!"|| call :error_FATAL ".create: File init Failed"
call :artikel.exist %1 %articleID% && call :error_FATAL ".create: articleID already exist: %articleID%"
echo %articleID%;%price%;"%name%"| call lib\file append priceTable || call :error_FATAL ".create: Could not write to file"
exit /b 0


:artikel.select self "articleID" [returnName] [returnPrice]
rem returns erlvl 1 if customer not found
if "%~2"=="" call :error_FATAL ".select: to less arguments"
if not "%~5"=="" call :error_FATAL ".select: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "priceTable=!%1.priceTable!"
set "articleID=%~2"
set "id="
set "price="
set "name="
rem detect multiple ids
set /a "matches=0"
call lib\file init tableFile "%priceTable%" "!%1.maxRetrys!"

for /F "usebackq tokens=1,2,3,4 delims=;" %%a in (`call lib\file print tableFile^|findstr "^%articleID%;"`) do (
	if "%articleID%"=="%%~a" (
		set /a "matches+=1"
		set "id=%%~a"
		set "price=%%~b"
		set "name=%%~c"
		rem detect wrong file format
		if not "%%~d"=="" call :error_FATAL ".select: To much tokens detected for id:"!articleID!" "
	)
)
if %matches% GTR 1 call :error_FATAL ".select: ArticleID:"%articleID%" exist multiple times: %matches%"
if %matches% GTR 0 (
	if "%id%"=="" call :error_FATAL ".select: wrong format in file:%priceTable%"
	if "%price%"=="" call :error_FATAL ".select: wrong format in file:%priceTable%"
)
endlocal & (
	set "%1.selectedID=%id%"
	set "%1.selectedPrice=%price%"
	set "%1.selectedName=%name%"
	if not "%3"=="" set "%3=%name%"
	if not "%4"=="" set "%4=%price%"
	if %matches% EQU 0 exit /b 1
)
exit /b 0

:artikel.getPrice self var
if "%~2"=="" call :error_FATAL ".getPrice: to less arguments"
if not "%~3"=="" call :error_FATAL ".getPrice: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not defined %1.selectedID call :error_FATAL ".getPrice: no artikel selected"
endlocal & set "%2=!%1.selectedPrice!"
exit /b 0

:artikel.getName self var
if "%~2"=="" call :error_FATAL ".getName: to less arguments"
if not "%~3"=="" call :error_FATAL ".getName: to much arguments"
if not defined %1.selectedID call :error_FATAL ".getName: no artikel selected"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
endlocal & set "%2=!%1.selectedName!"
exit /b 0

:artikel.iterIDs self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call lib\file init tableFile "!%1.priceTable!" "!%1.maxRetrys!"
for /F "usebackq tokens=1 delims=;" %%a in (`call lib\file print tableFile`) do (
	echo %%~a
)
exit /b 0

:artikel.count self returnVar
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not defined %1.priceTable call :error_FATAL ".count: No File selected"
for /f "usebackq delims=" %%a in (`findstr /R /N "^^" "!%1.priceTable!" ^| find /C ":"`) do (
	set "number=%%a"
)
endlocal & (
	set "%2=%number%"
)
exit /b 0


:artikel.print self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not defined %1.selectedID call :error_FATAL ".print: no selected ID"
echo( !%1.selectedID!;!%1.selectedPrice!;"!%1.selectedName!"
exit /b 0

:artikel.exist self "articleID"
if "%~2"=="" call :error_FATAL ".exist: to less arguments"
if not "%~3"=="" call :error_FATAL ".exist: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "articleID=%~2"
set "priceTable=!%1.priceTable!"
rem die Preistabelle kann noch nicht existieren, dennoch kann eine exist abfrage stattfinden
if not exist "%priceTable%" exit /b 1
set "matches=0"
call lib\file init tableFile "%priceTable%" "!%1.maxRetrys!"
for /F "usebackq tokens=1 delims=;" %%a in (`call lib\file print tableFile^|findstr "^%articleID%;"`) do (
	if "%%~a"=="%articleID%" set /a "matches+=1"
)
if %matches% GTR 1 call :error_FATAL ".exist: MULTIPLE DETECTIONS %matches%"
if %matches% EQU 0 exit /b 1
exit /b 0


:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL