@echo off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
chcp 65001
cls
:setup
title %~n0
set "kundenStamm="
call lib\readINI "config.ini"
if not defined kundenStamm (
	echo.
	echo In welchen Ordner sollen Kunden registriet werden?
	echo Einen neuen Kundenstamm erstellen oder einen existierenden auswählen.
	set /p "kundenStamm=Pfad zum Kundenstamm angeben (Ordner):"
	call :cleanString kundenStamm !kundenStamm! 
	if "!kundenStamm!"=="" goto setup
)
if not exist "%kundenStamm%" (
	echo.
	echo Der Ordner "%kundenStamm%"
	echo existiert nicht, soll er erstellt werden? j/n:
	call lib\readKey getKey input
	if /I "!input!"=="j" (
		mkdir "%kundenStamm%"
	) else (
		echo Abbruch
		goto setup
	)
)
if not defined maxRetrys call :error_FATAL " ERROR IN config.ini: maxRetrys nicht definiert"
call lib\accounts init kunden "%kundenStamm%" "%maxRetrys%"
rem call lib\kunden init kunden "%kundenStamm%"
echo.
echo. #### [ Achtung ] ####
echo. # Kundennummern werden nach eingabe direkt im Kundenstamm registriert.
echo. #
echo. # Kundenstamm: "%kundenStamm%"
echo. #
:main
call :menu kunden
goto main


:menu self
echo.
echo. #### [ Kundennummer Registrieren ] ####
echo. # 
echo. # Bestätigen mit [ENTER]
echo.
set "customerID="
set /p "customerID= Neue Kundennummer:"
if "%customerID%"=="" exit /b 1

call lib\accounts accountExist %1 "%customerID%"||(
	call lib\accounts accountCreate %1 "%customerID%" && (
	call :colorSuccess
	echo. # Kunde wurde erstellt. #
	echo.
	call :showCustomer kunden "%customerID%"
	echo.
	exit /B 0
	)
)
call :colorNotFound
echo.
echo.  .. KundenID existiert schon ..
exit /b 1

:showCustomer self "id"
setlocal
call :getCustomerInfosFast %1 %2
echo %customerStr%
exit /b 0

:getCustomerInfosFast kundenObj "customerID"
rem returns customerID customerBalance customerIDstr customerBalanceStr customerStr
setlocal
echo.
echo. ... Kundeninformationen werden abgerufen ...
echo.
call lib\accounts accountGetCacheBalance %1 %2 customerBalance
rem call lib\kunden customerGetBalanceFromCache %1 customerBalance
rem call lib\kunden customerGetID %1 customerID
endlocal & (
	rem returns customerIDstr customerBalanceStr customerStr
	call :_formatInfos "%customerID%" "%customerBalance%"
	set "customerID=%customerID%"
	set "customerBalance=%customerBalance%"
)
exit /b 0

:_formatInfos customerID customerBalance
rem returns customerIDstr customerBalanceStr customerStr
set "customerIDstr=%~1                         "
set "customerIDstr=%customerIDstr:~0,13%"
call :cntToEuroStr %2 customerBalanceStr
set "customerBalanceStr=                         %customerBalanceStr%"
set "customerBalanceStr=%customerBalanceStr:~-10%"
set "customerStr=# Guthaben:[ %customerBalanceStr% ] Kundennummer:[ %~1 ] "
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



:colorNotFound
color 4F
GOTO :EOF

:colorAttention
color 60
GOTO :EOF

:colorSuccess
color 20
goto :EOF

:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL