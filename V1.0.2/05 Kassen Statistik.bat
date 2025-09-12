@echo off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
chcp 65001
cls

:setup
title %~n0
call lib\readINI "config.ini"
if not defined kundenStamm call :error_FATAL "Configuration Error: kundenStamm not set"
if not defined kassenID call :error_FATAL "Configuration Error: kassenID not set"

set "expandCustomers=false"
call lib\kunden init kunden "%kundenStamm%"

:main
echo.
echo.
echo. ##### [ Wichtig ] #####
echo. # 
echo. #
echo. #
echo. # [ 1 ] = Alle Transaktionen Exportieren "wird gespeichert in export.csv"
echo. # [ 2 ] = Statistik hier Anzeigen
call lib\readKey getKey mainMenu
if "%mainMenu%"=="1" (
	call :export kunden
)
if "%mainMenu%"=="2" (
	call :kasseAnzeigen kunden
)
goto main


:kasseAnzeigen kundenObj
cls
echo.
echo. ##   ...[ Vorgang läuft ]...   ##
echo. # Es werden berechnungen durchgeführt
echo. # ...Die Statistik wird gleich angezeigt...
set "kassenStand=0"
set "offeneGuthaben=0"
set "offeneSchulden=0"
set "kassenStandStr=#Kein Kassen Konto inizialisiert#"
set "customersCnt=0"
set "dateTimeStr=%date% %time%"
call lib\array init positivCustomers
call lib\array init negativCustomers
call lib\array init zeroCustomers
for /F "usebackq delims=" %%i in (`call lib\kunden iterCustomers %1`) do (
	call lib\kunden customerSelect %1 "%%i"
	rem es erzeugt verletzungen durch die Zeitspanne dazwischen wenn transaktionen stattfinden vergleiche cache mit berechnung um integrität festzustellen.... vielleicht
	call lib\kunden customerGetBalanceFromCache %1 guthaben
	if "%%i"=="%kassenID%" (
		set "kassenStand=!guthaben!"
		call :cntToEuroStr !kassenStand! kassenStandStr
	) else (
		set /a "customersCnt+=1"
		call :cntToEuroStr !guthaben! guthabenStr
		if !guthaben! GTR 0 set /a "offeneGuthaben+=!guthaben!"
		if !guthaben! LSS 0 set /a "offeneSchulden+=!guthaben!"
		rem if "%expandCustomers%"=="true" ( 
			if !guthaben! LSS 0 call lib\array append negativCustomers "KundenID:[ %%~i ]  Guthaben:[ !guthabenStr! ]"
			if !guthaben! GTR 0 call lib\array append positivCustomers "KundenID:[ %%~i ]  Guthaben:[ !guthabenStr! ]"
			if !guthaben! EQU 0 call lib\array append zeroCustomers "KundenID:[ %%~i ]  Guthaben:[ !guthabenStr! ]"
		rem )
	)
)
set /a "kassenStandNachAbschluss=kassenStand-offeneGuthaben+offeneSchulden*-1"
call :cntToEuroStr %offeneGuthaben% offeneGuthabenStr
call :cntToEuroStr %offeneSchulden% offeneSchuldenStr
call :cntToEuroStr %kassenStandNachAbschluss% kassenStandNachAbschlussStr
call lib\array len zeroCustomers zeroCustomersLen
call lib\array len positivCustomers positivCustomersLen
call lib\array len negativCustomers negativCustomersLen
:kasseAnzeigen_rePrint
cls
echo.
echo.
if "%expandCustomers%"=="true" (
	echo. #### Kunden ohne Guthaben [ !zeroCustomersLen! ] ####
	call lib\array print zeroCustomers
	echo.
	echo. #### Kunden mit Guthaben [ !positivCustomersLen! ] ####
	call lib\array print positivCustomers
	echo. -- Summe:[ %offeneGuthabenStr% ]
	echo.
	echo. #### Kunden mit Schulden [ !negativCustomersLen! ] ####
	call lib\array print negativCustomers
	echo. -- Summe:[ %offeneSchuldenStr% ]
)
echo.
echo. ####[ %dateTimeStr% ]###################################
echo. ### Registrierte Kunden   :[ %customersCnt%
echo. ###  -Kunden mit Guthaben :[ !positivCustomersLen!
echo. ###  -Kunden mit Schulden :[ !negativCustomersLen!
echo. ### KassenkontoID         :[ %kassenID%
echo. ###  -Bargeld ist in Kasse:[ %kassenStandStr%
echo. ###  -offene guthaben     :[ %offeneGuthabenStr%
echo. ###  -offene schulden     :[ %offeneSchuldenStr%
echo. ###  -Bargeld nach abzug  :[ %kassenStandNachAbschlussStr%
echo.
echo. [Enter]:Aktualisieren [+/-]:Kunden ein-/ausblenden
echo.                       [E] Transactionen Exportieren
timeout /t 0 >NUL
call lib\readKey getKey menu
if "%menu%"=="+" if %expandCustomers%==false (set "expandCustomers=true"& goto kasseAnzeigen_rePrint)
if "%menu%"=="-" if %expandCustomers%==true (set "expandCustomers=false"& goto kasseAnzeigen_rePrint)
if /I "%menu%"=="E" (
	call :export %1
	goto kasseAnzeigen_rePrint
)
if "%menu%"=="" goto kasseAnzeigen
goto kasseAnzeigen_rePrint
	

:export kundenObj
setlocal
echo. Kundenstamm als .CSV exportieren.
set "file=export.csv"
if exist "%file%" (
	echo. Die Datei "%file%" existiert bereits, überschreiben?
	pause
)
echo. Exportiere Transactionen in:"%file%"
>"%file%" call lib\kunden exportTransactionsToCSV %1
exit /b 0




:cntToEuroStr ct var
setlocal
:: Eingabe in Cent
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
endlocal & set "%2=%negativPrefix%%euroPart%,%centPart% €"
exit /b 0



:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL