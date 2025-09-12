@echo off
:: ToDO
::
:: NEU#
:: + hart überarbeitet anti collision funktioniert anscheinend wunderbar.
:: + lock/unlockFile mechanismus verbessert. bisher konsistente daten trotz FLOODING
:: + customerForceUnlock
:: + (track customerBalance) so that the customerBalance has not to be calculatet every time. problem:
::   größeres problem ist das auffinden der Dateien auf netzlaufwerken, kann zu problemen führen.
::
:: errorlevels internal
:: 99 = transasction konnte nicht in datei geschrieben werden

:main func self params
if "%2"=="" call :error_FATAL "to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" call :error_FATAL "MAIN: "%2" was not init by this modul"
	endlocal
)
call :customers.%*
set "%2.lastExitCode=%errorlevel%"

setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem exitCode 0=good/true 1=bad/false
set "lastExitCode=!%2.lastExitCode!"
if %lastExitCode% EQU 99 (
	rem gedacht für endlose neuversuche.
	rem pauschal retry möglich, weil noch keine änderungen stattgefunden hatten.
	rem oder eine read option fehlgeschlagen hat.
	rem !%2.writeRetrys! wird durch init inizialisiert
	if !%2.writeRetrys! LSS !%2.maxWriteRetrysBevoreError! (
		endlocal
		rem if !%2.writeRetrys! EQU 0 call :error_INFO "## ... Der Vorgang dauert länger als erwartet, einen moment bitte ... ##"
		set /a "%2.writeRetrys+=1"
		rem >NUL timeout /t 1
		goto main
	) else (
		endlocal
		call :error_INFO "# ... [ +++ Der Vorgang benötigt sehr lang - PAUSE +++ ] ... #"
		call :error_INFO "# 1.Verbindung prüfen. 2.lock mechanik prüfen"
		call :error_INFO "# Wenn die Verbindung sichergestellt ist liegt ein problem im schreibschutz"
		call :error_INFO "# siehe .customerForceUnlock"
		call :error_INFO "# oder das Kassenkonto ist momentan überlastet."
		call :error_INFO "# Fenster geöffnet halten um Datenverlust zu vermeiden."
		call :error_INFO "# Problem beseitigen, neu versuchen."
		call :error_INFO "#"
		call :error_INFO "#"
		call :error_INFO "# Weiter mit beliebiger Taste...Fenster schließen zum abbrechen."
		rem call :error_FATAL "Retrying limit erreicht"
		set /a "%2.writeRetrys=0"
		2>&1 >NUL pause
		call :error_INFO "# ...es geht weiter..."
		goto main
	)
)
endlocal & (
	set "%2.writeRetrys=0"
	exit /b %lastExitCode%
)
goto :EOF





:customers.init self "rootFolder"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem :kunde.init self "root"
if "%~2"=="" call :error_FATAL ".init: missing ARGS"
if not "%~4"=="" call :error_FATAL ".init To much ARGS"
if not exist "%~2\" call :error_FATAL ".init: Folder "%~2" not exist."
set "transactionIdFile=%~2\transactionID.txt"
set "startID=0"
if not exist "%transactionIdFile%" (
	call :_customers.lockThisFile "%transactionIdFile%" || exit /b 99
	2>NUL >"%transactionIdFile%" echo.%startID%|| (call:_customers.unlockThisFile "%transactionIdFile%"& call :error_FATAL ".init: could not write to file."%transactionIdFile%"")
	call :_customers.unlockThisFile "%transactionIdFile%" || call :error_FATAL ".init: UNLOCK FAIL"
)
endlocal & (
set "%1=%~dpnx0"
set "%1.root=%~2"
set "%1.writeRetrys=0"
set "%1.maxWriteRetrysBevoreError=99"
set "%1.billName=bill.txt"
set "%1.balanceCacheFile=balance.txt"
set "%1.transactionIdFile=%transactionIdFile%"
set "%1.selectedCustomerID="
set "%1.selectedCustomerFolder="
set "%1.selectedCustomerBill="
set "%1.selectedCustomerBalanceFile="
set "%1.transactionId="
)
exit /b 0

:customers.iterCustomers self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not exist "!%1.root!" call :error_FATAL ".iterCustomers: root folder not found"
for /D %%a in ("!%1.root!\*") do (
	rem customerID=%%~nxa
	echo(%%~nxa
)
exit /b 0

:customers.customerCreate self "CustomerID"
rem :kunde.create self "customerID"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL ".CustomerCreate: missing ARGS"
if not "%~3"=="" call :error_FATAL ".CustomerCreate: To much ARGS"
call :_isValidFolderName "%~2" || call :error_FATAL ".customerCreate: CUSTOMER ID NOT ALLOWED"
set "customerID=%~2"
set "customerFolder=!%1.root!\%customerID%"
set "customerBill=%customerFolder%\!%1.billName!"
set "customerBalanceFile=%customerFolder%\!%1.balanceCacheFile!"
if exist "%customerFolder%" call :error_FATAL ".customerCreate: customerFolder already exist: %customerFolder%"
if exist "%customerBill%" call :error_FATAL ".customerCreate: Cant create Customer, customerBill already exist: %customerBill%"
mkdir "%customerFolder%" || call :error_FATAL ".customerCreate: Could not create path: %customerFolder%"
type NUL>"%customerBill%" || call :error_FATAL ".customerCreate: Could not create file: %customerBill%"
type NUL>"%customerBalanceFile%" || call :error_FATAL ".customerCreate: Could not create file: %customerBalanceFile%"
>"%customerBalanceFile%" echo 0|| call :error_FATAL ".customerCreate: Could not write to file: %customerBalanceFile%"
endlocal
exit /b 0


:_isValidFolderName "path"
rem fängt nicht alles ab, der rest kommt über fatal error bei erstellen der ordner
rem bzw. andere zeichen brechen das programm.
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "name=%~1"
:: empty
if "%name%"=="" exit /b 1
:: ; is reserved vor delimiter
for /F "delims=;\/:?" %%a in ("%name%") do set "stripName=%%a"
if not "%name%"=="%stripName%" exit /b 1
:: leading space
if "%name:~0,1%"==" " exit /b 1
:: trailing space
if "%name:~-1%"==" " exit /b 1
:: Reservierte Namen prüfen
for %%R in (CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9) do (
    if /I "%name%"=="%%R" exit /b 1
)
exit /b 0

:customers.customerSelect self "customerID"
rem erlvl 1 if customerID not exist or id is not allowed
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL ".customerSelect: missing ARGS"
if not "%~3"=="" call :error_FATAL ".customerSelect: To much ARGS"
call :_isValidFolderName "%~2" || exit /b 1
if not exist "!%1.root!\%~2\!%1.billName!" exit /b 1
set "customerID=%~2"
set "customerFolder=!%1.root!\%customerID%"
set "customerBill=%customerFolder%\!%1.billName!"
set "customerBalanceFile=%customerFolder%\!%1.balanceCacheFile!"
endlocal & (
	set "%1.selectedCustomerID=%customerID%"
	set "%1.selectedCustomerFolder=%customerFolder%"
	set "%1.selectedCustomerBill=%customerBill%"
	set "%1.selectedCustomerBalanceFile=%customerBalanceFile%"
)
exit /b 0

:customers.requestNewTransactionID self returnVar
rem returns a transactionID
rem die id wird für alle transactionen benutzt, bis ein neuer aufruf stattfindet.
rem damit werden einzelne transactionen miteinander in verbindung gebracht.
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL ".requestNewTransactionID: missing ARGS"
if not "%~3"=="" call :error_FATAL ".requestNewTransactionID: To much ARGS"
set "transactionID="
set "transactionIdFile=!%1.transactionIdFile!"
call :_customers.lockThisFile "%transactionIdFile%" || exit /b 99
set /p "nextID="<"%transactionIdFile%" || (call :_customers.unlockThisFile "%transactionIdFile%" & exit /b 99)
set "transactionID=%nextID%"
set /a "nextID+=1"
2>NUL >"%transactionIdFile%" echo.%nextID%|| (call :_customers.unlockThisFile "%transactionIdFile%" & exit /b 99)
call :_customers.unlockThisFile "%transactionIdFile%" || call :error_FATAL ".requestNewTransactionID: UNLOCK FAIL"
endlocal & (
	rem intern speichern, die ID wird intern gezogen, return ist nur für benutzer
	set "%1.transactionId=%transactionID%"
	set "%2=%transactionID%"
)
exit /b 0

:customers.customerDoTransaction self betrag "verwendungszweck" "transactionCode"
:: betrag ist negative wenn kunde belastet wird, positiv wenn kunde gutschreibung erfährt.
rem :kunde.transaktion self betrag "verwendungszweck"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~4"=="" call :error_FATAL ".customerDoTransaction: missing ARGS"
if not "%~5"=="" call :error_FATAL ".customerDoTransaction: To much ARGS"
if not defined %1.selectedCustomerBill call :error_FATAL ".customerDoTransaction: No customer selected"
set "customerBill=!%1.selectedCustomerBill!"
set "customerBalanceFile=!%1.selectedCustomerBalanceFile!"
set /a "betrag=%~2"
set "verwendungszweck=%~3"
set "transactionCode=%~4"
set "timeStamp=%date% %time%"
rem eine transactionId muss vorher vom Benutzer angefragt worden sein.
if not defined %1.transactionId call :error_FATAL ".customerDoTransaction: No transasctionId was requested"
set "transactionId=!%1.transactionId!"
rem lock bill first and unlock it last
call :_customers.lockThisFile "%customerBill%" || exit /b 99
call :_customers.lockThisFile "%customerBalanceFile%" || (
	call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".customerDoTransaction: UNLOCK FAIL"
	exit /b 99
)

rem weil der balance cache zur gleichen zeit von außen ohne lock abgefragt werden kann, lassen wir hier einen retry zu
rem deswegen auch vor transaction schreiben
call :_customers.customerIncrementBalanceCache %1 "%betrag%"|| (
	call :_customers.unlockThisFile "%customerBalanceFile%" || call :error_FATAL ".customerDoTransaction: UNLOCK FAIL"
	call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".customerDoTransaction: UNLOCK FAIL"
	exit /b 99
)
rem collision durch modul ausgeschlossen, aber verbindungsabbrüche können zur inkonsistenz führen.
rem customerBill ist gesperrt wenn trozdem schreiben fehlschlägt, wurde der cache schon verändert
>>"%customerBill%" echo %betrag%;"%verwendungszweck%";"%transactionCode%";"%timeStamp%";"%transactionId%"|| call :error_FATAL ".customerDoTransaction: Access violation"
call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".customerDoTransaction: UNLOCK FAIL"
call :_customers.unlockThisFile "%customerBalanceFile%" || call :error_FATAL ".customerDoTransaction: UNLOCK FAIL"
endlocal
exit /b 0




:_customers.customerIncrementBalanceCache self "valueToAdd"
rem lock file bevore use, then unlock it
rem cares about the customer balance cacheFile
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL "_.customerIncrementBalanceCache: missing ARGS"
if not "%~3"=="" call :error_FATAL "_.customerIncrementBalanceCache: To much ARGS"
if not defined %1.selectedCustomerBalanceFile call :error_FATAL "_.customerIncrementBalanceCache: No customer selected"
set "customerBalanceFile=!%1.selectedCustomerBalanceFile!"
set /a "addValue=%~2"
set "balance="
rem Nicht mehr ZEITKRITISCH VON HIER durch lock mechanismus
set /p "balance="<"%customerBalanceFile%"|| exit /b 1
set /a "balance+=addValue"
>"%customerBalanceFile%" echo !balance!|| exit /b 1
rem BIS HIER
exit /b 0

:customers.customerForceUnlock self
rem errlvl 0 wenn ein lock gefunden und gelöscht wurde
rem forciert löschen von .lock files des lock mechanismusses
if not defined %1.selectedCustomerID call :error_FATAL ".customerForceUnlock: No customer selected"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "billFile=!%1.selectedCustomerBill!"
set "balanceFile=!%1.selectedCustomerBalanceFile!"
set "somethingUnlocked=1"
call :_customers.unlockThisFile "%billFile%" && set "somethingUnlocked=0"
call :_customers.unlockThisFile "%balanceFile%" && set "somethingUnlocked=0"
exit /b %error%



:customers.CustomerGetBalanceFromCache self returnVar
:: das kundenguthaben wird vom cacheFile gezogen, der Cachewert kann unter umständen anders sein als der Berechnete Wert.
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL ".CustomerGetBalanceFromCache: missing ARGS"
if not "%~3"=="" call :error_FATAL ".CustomerGetBalanceFromCache: To much ARGS"
if not defined %1.selectedCustomerBalanceFile call :error_FATAL ".CustomerGetBalanceFromCache: No customer selected"
set "balanceFile=!%1.selectedCustomerBalanceFile!"
set "balance="
rem no lock to speedUp the process, could cause problems in updating balanceFile in .CustomerRecalculateBalanceCache
set /p "balance="<"%balanceFile%"|| exit /b 99
endlocal & set "%2=%balance%"
exit /b 0

:customers.CustomerRecalculateBalanceCache self var
:: sollte nicht nötig sein, wenn der lock mechanismus funktioniert
:: sonst könnten die transactionen in der bill auch inkonsistent sein.
:: könnte auf ein programm abburch inmitten einer transaktion hinweisen
:: also könnte man daraus eine konsistens abfrage machen, erst cache abrufen dann neu rechnen, dann vergleichen
:: calculating customerBalance from customerBill and refresh the customerBalanceFile
:: berechnet das guthaben anhand der bill und aktualisiert/reinizalisiert balanceFile, mehr transaktionen mehr Zeit, aber sicher 
:: the summ of all transactions from selected customer
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if "%~2"=="" call :error_FATAL ".CustomerRecalculateBalanceCache: missing ARGS"
if not "%~3"=="" call :error_FATAL ".CustomerRecalculateBalanceCache: To much ARGS"
if not defined %1.selectedCustomerID call :error_FATAL ".CustomerRecalculateBalanceCache: No customer selected"
set "customerBill=!%1.selectedCustomerBill!"
set "customerBalanceFile=!%1.selectedCustomerBalanceFile!"
if not exist "%customerBill%" call :error_FATAL ".CustomerRecalculateBalanceCache: customerBill not found:%customerBill%"
if not exist "%customerBalanceFile%" call :error_FATAL ".CustomerRecalculateBalanceCache: customerBalanceFile not found:%customerBalanceFile%"
rem lock customerBill and customerBalanceFile so no changes can occur while calculating.
call :_customers.lockThisFile "%customerBill%" || exit /b 99
call :_customers.lockThisFile "%customerBalanceFile%" || (
	call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".CustomerRecalculateBalanceCache: UNLOCK FAIL"
	exit /b 99
)
rem es kann mit abfragen von außen collidieren 1 zu unendlich, abfragen werden wegen performance nicht mit locks versehen.
call :customers.CustomerGetBalanceFromCache %1 balanceCache || (
	rem wenn wir hier landen war die datei nicht erreichbar wegen verbindung oder ein abfrage von ausen hat gleichzeitig stattgefunden
	call :_customers.unlockThisFile "%customerBalanceFile%" || call :error_FATAL ".CustomerRecalculateBalanceCache: UNLOCK ERROR"
	call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".CustomerRecalculateBalanceCache: UNLOCK ERROR"
	exit /b 99
)
rem berechne guthaben anhand der bill, bill kann leer sein!
rem Um zu prüfen ob die Datei auch wirklich eingelesen wurde der umweg über type
set /a "guthaben=0"
for /F "usebackq tokens=1 delims=;" %%a in (`2^>NUL type "%customerBill%" ^|^| echo.`) do (
	set /a "guthaben+=%%a" || set "guthaben="
)
rem eine collision, instablie verbindung
if not defined guthaben (
	call :_customers.unlockFile "%customerBalanceFile%" || call :error_FATAL ".CustomerRecalculateBalanceCache: UNLOCK ERROR"
	call :_customers.unlockFile "%customerBill%" || call :error_FATAL ".CustomerRecalculateBalanceCache: UNLOCK ERROR"
	exit /b 99
)
rem berechne unterschied zum cache
set /a "increment=guthaben-balanceCache"
rem refresh customerBalanceFile
rem if it failes it should be a connection error or somethin like this
rem ja wir aktualisieren hier auch gleich den cache, weil dieser aus der bill hervorgeht, also egal was voher war bill ist MASTER.
call :_customers.customerIncrementBalanceCache %1 "%increment%" || (
	rem wenn wir hier landen war die datei nicht erreichbar wegen verbindung oder ein abfrage hat gleichzeitig stattgefunden
	call :_customers.unlockThisFile "%customerBalanceFile%" || call :error_FATAL ".customerGetBalance: UNLOCK ERROR"
	call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".customerGetBalance: UNLOCK ERROR"
	exit /b 99
)
call :_customers.unlockThisFile "%customerBalanceFile%" || call :error_FATAL ".customerGetBalance: UNLOCK ERROR"
call :_customers.unlockThisFile "%customerBill%" || call :error_FATAL ".customerGetBalance: UNLOCK ERROR"
endlocal & (
	set /a "%2=%guthaben%"
)
exit /b 0

:customers.customerGetID self var
if "%~2"=="" call :error_FATAL ".customerGetID: missing ARGS"
if not "%~3"=="" call :error_FATAL ".customerGetID: To much ARGS"
if not defined %1.selectedCustomerID call :error_FATAL ".customerGetID: NO CUSTOMER SELECTED"
set "%2=!%1.selectedCustomerID!"
exit /b 0

:customers.customerExist self "customerID"
rem :kunde.exist self "customerID"
if "%~2"=="" call :error_FATAL ".exist: missing ARGS"
if not "%~3"=="" call :error_FATAL ".exist: To much ARGS"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
:: muss validieren weil sonst ungleiche rückgaben gegenüber customer create gibt.
call :_isValidFolderName "%~2" || call :error_FATAL "customerExist: CustomerID not ALLOWED"
if exist "!%1.root!\%~2\!%1.billName!" exit /b 0
exit /b 1

:customers.customerIsBlocked self
rem exit 0 if is blocked
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "exitCode=1"
call :_customers.isThisFileLocked "!%1.selectedCustomerBill!" && set "exitCode=0"
call :_customers.isThisFileLocked "!%1.selectedCustomerBalanceFile!" && set "exitCode=0"
exit /b %exitCode%

:customers.exportTransactionsToCsv self
rem :kunde.exportToCsv self
rem prints all customers transactions to consol
rem format Kundennummer;Betrag;Verwendungszweck;TransactionCode;Zeitstempel;transactionId
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not "%~2"=="" call :error_FATAL ".exportToCsv: To much ARGS"
set "root=!%1.root!"
echo Kundennummer;Betrag;Verwendungszweck;TransactionCode;Zeitstempel;transactionId
if not exist "%root%" call :error_FATAL ".exportToCsv: folder not found"
rem prefix customerID to every Transaction
for /D %%i in ("%root%\*") do (
	for /F "usebackq delims=" %%a in (`type "%root%\%%~nxi\!%1.billName!"`) do (
		echo "%%~nxi";%%a
	)
)
exit /b 0

:customers.exportTransactionsByTransactionID self "transactionID"
rem gibt alle transaktionen mit der gegebenen transID zurück
rem prefixed mit customerID
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "root=!%1.root!"
set "transactionId=%~2"
rem nur dateinamen anzeigen in der transID vorkommt
for /F "usebackq delims=" %%p in (`findstr /S /M /R /C:"\"%transactionId%\"$" "!root!\!%1.billName!"`) do (
	rem %%p pfad zur bill datei mit vorkommen
	call :_customers.billPathToCustomerID %1 "%%~p" customerID
	for /F "usebackq delims=" %%A in (`findstr /R /C:"\"%transactionId%\"$" "!root!\!customerID!\!%1.billName!"`) do (
		echo "!customerID!";%%A
	)
)
exit /b 0

:_customers.billPathToCustomerID self "billFilepath" returnVar
rem gibt die customerID zurück anhand eines pfades zur bill datei
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
rem file abziehen
set "pfad=%~dp2"
rem backslash entfernen
set "pfad=%pfad:~0,-1%"
rem customerID extrahieren
for /F "delims=" %%i in ("%pfad%") do (
	set "customerID=%%~nxi"
)
rem prüfen ob customer existiert
call :customers.customerExist %1 "!customerID!" || call :error_FATAL "_.billPathToCustomerID: EXTRAKTIONSFEHLER ToDo"
endlocal & (
	set "%3=%CustomerID%"
)
exit /b 0






:_customers.lockThisFile "filePath"
rem exit 1 = could not make a lock file
>NUL 2>&1 mkdir "%~1.lock\" || exit /b 1
exit /b 0

:_customers.unlockThisFile "filePath"
rem exit 1 = could not unlock or no lock was there
rem exit 0 = unlock good or no lock was there
>NUL 2>&1 rmdir "%~1.lock\" || exit /b 1
exit /b 0

:_customers.isThisFileLocked "filePath"
>NUL 2>&1 dir /B "%~1.lock\"||exit /b 1
exit /b 0

:customers.forceUnlockAll self
rem entfernt alle *.lock ordner im kundenstamm
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not defined %1.root call :error_FATAL ".customerForceUnlock: NO PATH DEFINED"
	rem %%~dpna ist die datei für die das lock erstellt wurde
	rem %%~a ist der ordner der als schloss fungiert.
for /F "usebackq delims=" %%a in (`dir /S /B /ad "!%1.root!\*.lock"`) do (
	rmdir "%%~a" && echo.Schloss entfert von:"%%~dpna"
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
