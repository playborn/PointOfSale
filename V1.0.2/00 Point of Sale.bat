@echo off
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
chcp 65001
cls
rem pushd "%~dp0"
rem BUGS: wenn von Netzlaufwerk ausgeführt wird, je nach verbindung werden call´s auf lib\... nicht gefunden
rem       und brechen das programm
rem groß und kleinschreibung der customerID macht auf Netzlaufwerken unterschiede also pfade werden anders behandelt.

:setup
call lib\readINI "config.ini"
if not defined kundenStamm call :error_FATAL " ERROR IN config.ini: kundenStamm nicht definiert"
if not defined preisListe call :error_FATAL " ERROR IN config.ini: preisListe nicht definiert"
if not defined minGuthaben call :error_FATAL " ERROR IN config.ini: minGuthaben nicht definiert"
if not defined maxGuthaben call :error_FATAL " ERROR IN config.ini: maxGuthaben nicht definiert"
if not defined kassenID call :error_FATAL " ERROR IN config.ini: kassenID nicht definiert"

rem maxRetry für lib\artikel dort intern angewendet auf lib\file
set "maxRetrys=99"

call lib\kunden init kunden "%kundenStamm%" || call :error_FATAL "lib\kunden nicht gefunden"
call lib\artikel init artikel "%preisListe%" "%maxRetrys%" || call :error_FATAL "lib\artikel nicht gefunden"
call lib\kunden customerExist kunden "%kassenID%" || call lib\kunden customerCreate kunden "%kassenID%"

:main
title Point of Sale
call :verkauf
goto main

:verkauf
timeout /T 0 >NUL
echo.&echo.&echo.&echo.&echo.
call lib\warenkorb init warenkorb
rem call :warenkorb.init warenkorb
call lib\prompt "Scanne eine Kundenkarte um in den Warenkorb zu gelangen"
call :colorNormal
if "%customerIDinput%"=="UNLOCK" cls & call :hidden_forceUnlock kunden
call :kundeScannen kunden customerIDinput || (call :colorNotFound & echo. # Kundennummer ist nicht registriert #& goto verkauf)
:verkauf_changeCustomer
call :colorSuccess
call :getCustomerInfos kunden customerID customerBalance customerStr
set "customerIDstr=%customerID%                         "
set "customerIDstr=%customerIDstr:~0,13%"
call :cntToEuroStr "%customerBalance%" customerBalanceStr
set "customerBalanceStr=                         %customerBalanceStr%"
set "customerBalanceStr=%customerBalanceStr:~-10%"
:verkauf_continue
call lib\warenkorb getSumm warenkorb warenkorbSumme
call :cntToEuroStr %warenkorbSumme% warenkorbSummeStr
set /a "guthabenNachKauf=customerBalance-warenkorbSumme"
call :cntToEuroStr %guthabenNachKauf% guthabenNachKaufStr
set /a "guthabenNachGutschrift=customerBalance+warenkorbSumme"
call :cntToEuroStr %guthabenNachGutschrift% guthabenNachGutschriftStr
set "guthabenNachKaufStr=                         %guthabenNachKaufStr%"
set "guthabenNachGutschriftStr=                         %guthabenNachGutschriftStr%"
set "warenkorbSummeStr=_________________________%warenkorbSummeStr%"
set "guthabenNachKaufStr=%guthabenNachKaufStr:~-10%"
set "guthabenNachGutschriftStr=%guthabenNachGutschriftStr:~-10%"
set "warenkorbSummeStr=%warenkorbSummeStr:~-10%"
cls
echo.
call lib\warenkorb show warenkorb warenkorbIndex
echo. #
echo. # Kunde[ %customerIDstr% ]
echo. # Guthaben[ %customerBalanceStr% ]        +/-[ %guthabenNachGutschriftStr% / %guthabenNachKaufStr% ]
call lib\prompt "Artikel hinzufügen oder [ENTER]Optionen ein-/ausblenden"

:verkauf_scanLoop
set "artikelID="
call :ArtikelScannen warenkorb artikel artikelIDinput && (
	set "artikelID=!artikelIDinput!"
	call :colorSuccess
	goto :verkauf_continue
)
rem kein artikel gefunden und eingabe war nicht leer
rem also springe zum menü und übergebe den input
if defined artikelIDinput set "input=%artikelIDinput%" & goto verkauf_menuSkipInput
:verkauf_menu
call :colorAttention
echo.  _________________[ Warenkorb - Optionen ]_________________
echo. /                                                          \
echo. /      [V](verkaufen)        [A](von guthaben auszahlen)   \
echo. /      [S](stornieren)       [E](in guthaben einzahlen)    \
echo. /                                                          \
echo. /      [H](handeingabe)      [K](Kunde ändern)             \
echo. /      [-](Pos. löschen)                                   \
echo. /      [X](Vorgang abbrechen)[T]TransID. rückgängig machen \
echo. /__________________________________________________________\
call lib\readKey getKey input
:verkauf_menuSkipInput
if "%input%"=="" call :colorSuccess & goto verkauf_continue
if /I "%input%"=="V" (
	call lib\warenkorb isEmpty warenkorb && goto verkauf_continue
	if %guthabenNachKauf% LSS %minGuthaben% (
		call :colorOverLimit
		echo. # Verkauf kann nicht durchgeführt werden !
		echo. #  -Guthaben reicht nicht aus.
		pause
		goto verkauf_continue
	)
	cls
	call lib\warenkorb show warenkorb warenkorbIndex
	echo.
	call :colorAttention
	echo. ######   [ VERKAUFEN ]   ######
	echo. #   Die Artikel im Warenkorb werden mit der Kundenkarte bezahlt.
	echo. #   Kundennummer:   [!customerID!]
	echo. #   Neues Guthaben: [ %guthabenNachKaufStr% ]
	call :areYouSure || (call :colorNotFound & goto verkauf_continue)
	call :warenkorb.abziehen warenkorb kunden "%customerID%"
	exit /b 0
)
if /I "%input%"=="S" (
	call lib\warenkorb isEmpty warenkorb && goto verkauf_continue
	if %guthabenNachGutschrift% GTR %maxGuthaben% (
		call :colorOverLimit
		echo. # Gutschrift kann nicht durchgeführt werden !
		echo. #  -Guthaben überschreitet maximales Guthaben.
		pause
		goto verkauf_continue
	)
	cls
	call lib\warenkorb show warenkorb warenkorbIndex
	echo.
	call :colorAttention
	echo. ###### [ STORNIEREN ]  ######
	echo. #  Die Artikel im Warenkorb werden der Kundenkarte gutgeschrieben.
	echo. #  Kundennummer:  [!customerID!]
	echo. #  Neues Guthaben:[ %guthabenNachGutschriftStr% ]
	call :areYouSure || (call :colorNotFound & goto verkauf_continue)
	call :Warenkorb.gutschreiben warenkorb kunden "%customerID%"
	exit /b 0
)
if /I "%input%"=="E" (
	call lib\warenkorb isEmpty warenkorb && goto verkauf_continue
	call :colorAttention
	if %guthabenNachGutschrift% GTR %maxGuthaben% (
		call :colorOverLimit
		echo # Einzahlung kann nicht durchgeführt werden !
		echo #  -Guthaben überschreitet maximales limit.
		pause
		goto verkauf_continue
	)
	cls
	call lib\warenkorb show warenkorb warenkorbIndex
	echo.
	echo. ###### [ EINZAHLUNG ]  ######
	echo. #  Der Warenkorb wird auf der Kundenkarte gutgeschrieben.
	echo. #  Kundennummer: [!customerID!]
	echo. #  Neues Guthaben:[ %guthabenNachGutschriftStr% ]
	echo. #
	echo. #  # In Kasse legen #
	echo. #  ^>^>^> %warenkorbSummeStr% ^<^<^<
	call :areYouSure || (call :colorNotFound & goto verkauf_continue)
	call :warenkorb.einzahlen warenkorb kunden "%customerID%" "%kassenID%"
	exit /b 0
)
if /I "%input%"=="A" (
	call lib\warenkorb isEmpty warenkorb && goto verkauf_continue
	call :colorAttention
	if %guthabenNachKauf% LSS %minGuthaben% (
		call :colorOverLimit
		echo # Auszahlung kann nicht durchgeführt werden !
		echo #  -Guthaben reicht nicht aus.
		pause
		goto verkauf_continue
	)
	cls
	call lib\warenkorb show warenkorb warenkorbIndex
	echo.
	echo. ###### [ AUSZAHLUNG ] ######
	echo. #  Der Warenkorb wird der Kundenkarte abgezogen.
	echo. #  Kundennummer:  [!customerID!]
	echo. #  Neues Guthaben:[ %guthabenNachKaufStr% ]
	echo. #
	echo. #  # Aus Kasse nehmen #
	echo. #  ^>^>^> %warenkorbSummeStr% ^<^<^<
	call :areYouSure || (call :colorNotFound & goto verkauf_continue)
	call :warenkorb.auszahlen warenkorb kunden "%customerID%" "%kassenID%"
	exit /b 0
)
if /I "%input%"=="K" (
	rem kunde wechseln
	call :colorAttention
	echo.
	echo.
	echo. ### [ Andere Kundenkarte Scannen ] ###
	call :kundeScannen kunden customerIDinput && (set "customerID=!customerIDinput!" & call :colorSuccess & goto verkauf_changeCustomer)
	call :colorNotFound
	call lib\prompt "Kundennummer wurde nicht gefunden"
	pause
	goto verkauf_continue
)
if /I "%input%"=="H" (
	call :colorAttention
	call :bargeldEingabe warenkorb handeingabe && (call :colorSuccess & goto verkauf_continue)
	call :colorNotFound
	goto verkauf_continue
)
if /I "%input%"=="X" echo. # Vorgang abgebrochen # & exit /b 1
if /I "%input%"=="-" (
	call lib\warenkorb pop warenkorb "%warenkorbIndex%" && (call :colorSuccess & goto verkauf_continue)
	call :colorNotFound
	goto verkauf_continue
)
if /I "%input%"=="T" (
	cls
	call :colorAttention
	echo.
	echo. Hiermit wird eine schon ausgeführte transaktions ID wieder zurück gebucht.
	echo. *zum reparieren von nicht fertiggestellten transaktionen gedacht.
	echo. * achtung, kein schutz vor mehrfach durchführung.
	set "inputTransID="
	set /P "inputTransID=Transaktions ID eingeben:
	if "!inputTransID!"=="" (call :colorSuccess & goto verkauf_continue)
	call :transactionIdUndo kunden "!inputTransID!" || (call :colorNotFound & goto verkauf_continue)
	call :colorSuccess
	pause
	goto verkauf_continue
)
IF "%input%"=="UNLOCK" (
	echo ### ADMIN FUNKTION ###
	echo ### Schreibschutz für diesen Kunden entfernen?
	echo ### Programm schließen zum abbrechen
	pause
	call lib\kunden customerForceUnlock kunden
	call :colorSuccess
	goto verkauf_continue
	
)
call :colorNotFound
goto verkauf_continue

:hidden_forceUnlock kundenObj
rem Achtung nur verwenden wenn du weißt warum und wiso.
rem Falls ein programm unsachgemäß geschlossen wurde, existieren ggf. noch Schlösser auf kunden
rem hiermit werden alle schlösser in der kundendatenbank entfernt.
setlocal
echo.
echo ... Schreibschutz wird entfernt, dieser Prozess kann jederzeit abgebrochen werden ...
pause
echo. # ...Suche gestartet:%date% %time%... #
call lib\kunden forceUnlockAll %1
echo. # Vorgang abgeschlossen: %date% %time% #
pause
exit /b 0


:areYouSure
setlocal
echo. #
echo. ### Bestätigen mit [ Leertaste ] ###
call lib\readKey getKey input
if "%input%"==" " exit /b 0
exit /b 1

rem nur diese funktion darf den customer selectieren
:kundeScannen kundenObj varInput
setlocal
set "customerID="
set /p "customerID=Kundennummer:"
endlocal & (
	set "%2=%customerID%"
	if "%customerID%"=="" exit /b 1
	call lib\kunden customerSelect %1 "%customerID%" || exit /b 1

)
exit /b 0

:ArtikelScannen warenkorbObj artikelObj varInput
rem fügt einen artikel zum warenkorb hinzu, wenn die ArtikelID gefunden wird
rem beendet mit exit /b 1 wenn KEIN artikel zum warenkorb hinzugefügt wurde
rem gibt die eingabe des benutzers immer zurück
set "%3="
setlocal
set "artikelID="
set /p "artikelID=Artikelnummer:"
set "exist=false"
if defined artikelID (
	call lib\artikel select %2 "%artikelID%" name price && set "exist=true"
)
endlocal & (
	set "%3=%artikelID%"
	if %exist%==true call lib\warenkorb append %1 "%artikelID%" "%price%" "%name%"
	if %exist%==false exit /b 1
)
exit /b 0

:bargeldEingabe warenkorbObj varInput
rem fügt eine Bargeldeingabe zum warenkorb hinzu, wenn die eingabe gültig ist
rem die eingabe des benutzers wird nur für den warenkorb gestript
rem beendet mit exit /b 1 wenn gestripte eingabe für warenkorb ungültig ist.
rem gibt die eingabe des benutzers immer roh zurück
setlocal
set "betrag="
set "valid=false"
set /p "betrag=Betrag Eingeben:"
if defined betrag (
	set "valid=true"
	set "stripBetrag=!betrag:,=!"
	set "stripBetrag=!stripBetrag:.=!"
	rem ist was andere enthalten als zahlen und rechenoperationen
	for /F "delims=-+*0123456789" %%a in ("!stripBetrag!") do (
		set "valid=false"
	)
	if "!stripBetrag:~0,1!"=="0" set "valid=false"
	if "!stripBetrag:~0,1!"=="-" if "!stripBetrag:~1,1!"=="0" set "valid=false"
	rem scheint valide also berechne eingabe
	if !valid!==true set /a "stripBetrag=!stripBetrag!"
	rem prevent 32-bit overflow
	if not "!stripBetrag:~9,1!"=="" set "valid=false"
)
endlocal & (
	rem roh eingabe wird zruückgegeben, gestripter betrag wird wenn valide an warenkorb gehängt
	set "%2=%betrag%"
	if %valid%==true call lib\warenkorb append %1 "NOID" "%stripBetrag%" "Handeingabe"
	if %valid%==false exit /b 1
)
exit /b 0


:getCustomerInfos kundenObj varID varBalance varString
setlocal
echo.
echo. ... Kundeninformationen werden abgerufen ...
echo.
rem wann sonst den cache ravalidieren ??
call lib\kunden customerRecalculateBalanceCache %1 customerBalance
rem call lib\kunden customerGetBalanceFromCache %1 customerBalance
call :cntToEuroStr customerBalance customerBalanceStr
call lib\kunden customerGetID %1 customerID
endlocal & (
	set "%2=%customerID%"
	set "%3=%customerBalance%"
	set "%4=# Guthaben:[ %customerBalanceStr% ] Kundennummer:[ %customerID% ] "
)
exit /b 0


:colorNotFound
color 4F
GOTO :EOF

:colorAttention
color 60
GOTO :EOF

:colorSuccess
color 20
goto :EOF

:colorNormal
color 0F
goto :EOF

:colorOverLimit
color CF
goto :EOF



:warenkorb.einzahlen warenkorbObj kundenObj "customerID" "KassenID"
if "%~4"=="" call :error_FATAL "warenkorb.einzahlen: to less arguments"
if not "%~5"=="" call :error_FATAL "warenkorb.einzahlen: to much arguments"
setlocal
set "customerID=%~3"
set "kassenID=%~4"
echo.
echo. ### Vorgang wird verarbeitet, einen moment bitte
call lib\kunden requestNewTransactionID %2 transactionID
echo. ### TransaktionsID[ %transactionID% ]
for /F "usebackq tokens=2,3 delims=;" %%a in (`call lib\warenkorb printCSVsingle %1 ";"`) do (
	set "betrag=%%~a"
	set "name=%%~b"
	
	call :transaction %2 "!customerID!" "!betrag!" "!name!" "EINZAHLUNG"
	if /I not "!customerID!"=="!kassenID!" call :transaction %2 "!kassenID!" "!betrag!" "!name!" "EINZAHLUNG"
)
echo. ### erfolgreich
exit /b 0

:warenkorb.auszahlen warenkorbObj kundenObj "customerID" "KassenID"
if "%~4"=="" call :error_FATAL "warenkorb.auszahlen: to less arguments"
if not "%~5"=="" call :error_FATAL "warenkorb.auszahlen: to much arguments"
setlocal
set "customerID=%~3"
set "kassenID=%~4"
echo.
echo. ### Vorgang wird verarbeitet, einen moment bitte
call lib\kunden requestNewTransactionID %2 transactionID
echo. ### TransaktionsID[ %transactionID% ]
for /F "usebackq tokens=2,3 delims=;" %%a in (`call lib\warenkorb printCSVsingle %1 ";"`) do (
	set /a "betrag=%%~a*-1"
	set "name=%%~b"
	
	call :transaction %2 "!customerID!" "!betrag!" "!name!" "AUSZAHLUNG"
	if /I not "!customerID!"=="!kassenID!" call :transaction %2 "!kassenID!" "!betrag!" "!name!" "AUSZAHLUNG"
	
	rem call :cntToEuroStr !betrag! betragStr
	rem echo. # Transaktion durchgeführt: [ !betragStr! ] [ !name! ]
)
echo. ### erfolgreich
exit /b 0

:warenkorb.gutschreiben warenkorbObj kundenObj "customerID"
if "%~3"=="" call :error_FATAL "warenkorb.gutschreiben: to less arguments"
if not "%~4"=="" call :error_FATAL "warenkorb.gutschreiben: to much arguments"
setlocal
set "customerID=%~3"
echo.
echo. ### Vorgang wird verarbeitet, einen moment bitte
call lib\kunden requestNewTransactionID %2 transactionID
echo. ### TransaktionsID[ %transactionID% ]
for /F "usebackq tokens=2,3 delims=;" %%a in (`call lib\warenkorb printCSVsingle %1 ";"`) do (
	set /a "betrag=%%~a"
	set "name=%%~b"
	
	call :transaction %2 "!customerID!" "!betrag!" "!name!" "STORNO"
	
	rem call :cntToEuroStr !betrag! betragStr
	rem echo. # Transaktion durchgeführt: [ !betragStr! ] [ !name! ]
)
echo. ### erfolgreich
exit /b 0

:warenkorb.abziehen warenkorbObj kundenObj "customerID"
if "%~3"=="" call :error_FATAL "warenkorb.abziehen: to less arguments"
if not "%~4"=="" call :error_FATAL "warenkorb.abziehen: to much arguments"
setlocal
set "customerID=%~3"
echo.
echo. ### Vorgang wird verarbeitet, einen moment bitte
call lib\kunden requestNewTransactionID %2 transactionID
echo. ### TransaktionsID[ %transactionID% ]
for /F "usebackq tokens=2,3 delims=;" %%a in (`call lib\warenkorb printCSVsingle %1 ";"`) do (
	set /a "betrag=%%~a*-1"
	set "name=%%~b"
	
	call :transaction %2 "!customerID!" "!betrag!" "!name!" "VERKAUF"
	
	rem call :cntToEuroStr !betrag! betragStr
	rem echo. # Transaktion durchgeführt: [ !betragStr! ] [ !name! ]
)
echo. ### erfolgreich
exit /b 0

:transaction kundenObj "customerID" "betrag" "name" "transactionCode"
if "%~5"=="" call :error_FATAL "transaction: to less arguments"
if not "%~6"=="" call :error_FATAL "transaction: to much arguments"
setlocal
set "customerID=%~2"
set /a "betrag=%~3"
set "name=%~4"
set "transactionCode=%~5"
call lib\kunden customerSelect %1 "%customerID%"
call lib\kunden customerDoTransaction %1 "%betrag%" "%name%" "%transactionCode%"
echo. # Transaktion ausgeführt: Kunde[%customerID%] Betrag[%betrag%] Verwendung[%name%] Code[%transactionCode%]
exit /b 0


:transactionIdToWarenkorb kundenObj warenkorbObj transID
rem betrag einlesen wie gebucht
rem kundennummer wird im artikelID slot benutzt und im name slot geprefixt
echo. # Transaktion wird gesucht ID[ %~3 ] #
for /F "usebackq tokens=1-6 delims=;" %%a in (`call lib\kunden exportTransactionsByTransactionID %1 "%~3"`) do (
	rem Kundennummer;Betrag;Verwendungszweck;TransactionCode;Zeitstempel;transactionId
	rem verwendungszweck ist hier name und artikelID
	rem betrag noch nicht negieren
	call lib\warenkorb append %2 "%%~a" "%%~b" "Kunde[%%~a] %%~d %%~c"
)
exit /b 0

:transactionIdUndo kundenObj transID
rem zum rückgängig machen von nicht ganz ausgeführten transactionen
rem findet alle transID einträge negiert den betrag und führt transaction aus
rem 
setlocal
call lib\warenkorb init warenkorb
call :transactionIdToWarenkorb %1 warenkorb %2
call lib\warenkorb show warenkorb summe
echo.
echo. # Diese Positionen wurden gefunden.
echo. # Sollen diese positionen rückgängig gemacht werden ?
call :areYouSure || exit /b 1
echo.
call lib\kunden requestNewTransactionID %1 transactionID
echo. ### TransaktionsID[ %transactionID% ] ###
echo. 
echo. #  ... Wird ausgeführt, einen moment bitte ... 
set "transactionCode=UNDO"
set "name=%~2"
for /F "usebackq tokens=1-6 delims=;" %%a in (`call lib\warenkorb printCSVsingle warenkorb`) do (
	rem id;preis;name
	set "customerID=%%~a"
	rem preise negieren
	set /a "betrag=%%~b*-1"
	call :transaction %1 "!customerID!" "!betrag!" "!name!" "!transactionCode!"
)
echo. # ... ENDE ...
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

	










:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %1 ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL