@echo off

:main func self params
if "%2"=="" call :error_FATAL "MAIN: to less arguments"
rem wenn der aufruf nicht init ist, prüfe ob das Objekt %2 mit dieser datei %~dpnx0 inizialisiert wurde
if not "%1"=="init" (
	setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	if not "!%2!"=="%~dpnx0" call :error_FATAL "MAIN: "%2" was not init by this modul"
	endlocal
)
call :accounts.%*
goto :EOF




:accounts.init self "rootFolder" [maxRetry]
if "%~2"=="" call :error_FATAL "init: to less arguments"
if not "%~4"=="" call :error_FATAL "init: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "self=%~dpnx0"
set "root=%~2"
if "%~3"=="" (set /a "maxRetry=0") else (set /a "maxRetry=%~3")
endlocal & (
	set "%1=%self%"
	set "%1.root=%root%"
	set "%1.activeTransactionId="
	set "%1.COMMAND="
	call lib\retry init %1.retryHandler %1.COMMAND %maxRetry%
)
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
if not exist "!%1.root!" (
	mkdir "!%1.root!"|| call :error_FATAL ".init: !%1.root! konnte nicht erstellt werden "
)
if not exist "!%1.root!\acc" (
	mkdir "!%1.root!\acc"|| call :error_FATAL ".init: !%1.root!/acc konnte nicht erstellt werden"
)
call :_accounts.getTransactionIdFile %1 transactionIdFile
call lib\io exist transactionIdFile || (
	set "%1.COMMAND=echo.0|call lib\io write transactionIdFile"
	call lib\retry exec %1.retryHandler || call :error_FATAL ".init: transactionIdFile konnte nicht erstellt werden"
)
exit /b 0

:accounts.iterAccounts self
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
for /D %%a in ("!%1.root!\acc\*") do (
	rem customerID=%%~nxa
	echo(%%~nxa
)
exit /b 0




:accounts.accountCreate self "accountID"
if "%~2"=="" call :error_FATAL "accountCreate: to less arguments"
if not "%~3"=="" call :error_FATAL "accountCreate: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "accountID=%~2"
call :_accounts.isAccountIDAllowed "%accountID%" || (
	call :error_INFO " Die AccountID ist nicht erlaubt"
	exit /b 1
)
call :_accounts.getAccountRootPath %1 "%accountID%" accountRootPath
mkdir "%accountRootPath%" || (
	call :error_INFO " Account kann nicht erstellt werden."
	exit /b 1
)

call :_accounts.getAccountJournalFile %1 "%accountID%" journalFile
set "%1.COMMAND=call lib\io open journalFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung journalFile"
set "%1.COMMAND=call lib\io wipe journalFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung journalFile"
set "%1.COMMAND=call lib\io close journalFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung journalFile"

call :_accounts.getAccountBalanceCacheFile %1 "%accountID%" balanceCacheFile
set "%1.COMMAND=call lib\io open balanceCacheFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung balanceCacheFile"
set "%1.COMMAND=echo.0|call lib\io write balanceCacheFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung balanceCacheFile"
set "%1.COMMAND=call lib\io close balanceCacheFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".accountCreate: Zeitüberschreitung balanceCacheFile"
exit /B 0

:accounts.accountGetCacheBalance self "accountID" returnVar
if "%~2"=="" call :error_FATAL "accountGetCacheBalance: to less arguments"
if not "%~4"=="" call :error_FATAL "accountGetCacheBalance: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :_accounts.getAccountBalanceCacheFile %1 %2 balanceCacheFile
set "%1.COMMAND=call lib\io open balanceCacheFile"
call lib\retry exec %1.retryHandler
set "%1.COMMAND=call lib\io print balanceCacheFile"
set "balance="
for /F "usebackq delims=" %%a in (`call lib\retry exec %1.retryHandler`) do (
	set /a "balance=%%~a"
)
set "%1.COMMAND=call lib\io close balanceCacheFile"
call lib\retry exec %1.retryHandler
if not DEFINED balance call :error_FATAL ".accountGetCacheBalance: Es konnte kein kontostand gelesen werden"
endlocal & (
	set /a "%3=%balance%"
)
exit /b 0


:accounts.accountExist self "accountID"
if "%~2"=="" call :error_FATAL "accountExist: to less arguments"
if not "%~3"=="" call :error_FATAL "accountExist: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :_accounts.isAccountIDAllowed %2 || call :error_FATAL ".accountExist: AccountID ist nicht erlaubt"
call :_accounts.getAccountRootPath %1 %2 accountRootPath
if exist "%accountRootPath%" exit /b 0
exit /b 1


:accounts.doTransaction self "accountID" || pipe !betrag!;"!verwendungszweck!";"!transactionCode!"
if "%~2"=="" call :error_FATAL "doTransaction: to less arguments"
if not "%~3"=="" call :error_FATAL "doTransaction: to much arguments"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
IF NOT DEFINED %1.activeTransactionId (
	call :error_FATAL ".doTransaction: YOU HAVE TO requestNewTransactionID"
	exit /b 1
)
set "transactionId=!%1.activeTransactionId!"
set "accountID=%~2"
set "timeStamp=%date% %time%"
set /a "summe=0"
call :_accounts.getAccountJournalFile %1 %2 journalFile
rem versuch ohne journal exclusiv imense beschleunigung, bisher keine kollision
rem wenn journal nicht exclusiv ist arbeiten wir gegen die regeln, wenn bearbeitung stattfindet muss exclusiv
set "%1.COMMAND=call lib\io open journalFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".doTransaction: Zeitüberschreitung journalFile"
for /F "usebackq tokens=1-3 delims=;" %%a in (`findstr "^"`) do (
	set /a "betrag=%%~a"
	set "verwendungszweck=%%~b"
	set "transactionCode=%%~c"
	set "transactionStr=!betrag!;"!verwendungszweck!";"!transactionCode!";"!timeStamp!";"!transactionId!""
	set "%1.COMMAND=echo.!transactionStr!|call lib\io append journalFile"
	call lib\retry exec %1.retryHandler || call :error_FATAL ".doTransaction: fehler beim schreiben der transaktion"
	set /a "summe+=!betrag!"
)
set "%1.COMMAND=call lib\io close journalFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".doTransaction: Zeitüberschreitung journalFile"
if %summe% NEQ 0 (
	rem balanceCache muss exklusiv, weil zwischen lesen und schreiben zeit vergeht
	call :_accounts.getAccountBalanceCacheFile %1 %2 balanceCacheFile
	set "%1.COMMAND=call lib\io open balanceCacheFile"
	call lib\retry exec %1.retryHandler || call :error_FATAL ".doTransaction: Zeitüberschreitung balanceCacheFile"
	call :_accounts.accountIncrementBalanceCache %1 balanceCacheFile "%summe%"
	set "%1.COMMAND=call lib\io close balanceCacheFile"
	call lib\retry exec %1.retryHandler || call :error_FATAL ".doTransaction: Zeitüberschreitung balanceCacheFile"
)
exit /b 0

:accounts.requestNewTransactionID self returnVar
if "%~2"=="" call :error_FATAL "requestNewTransactionID: to less arguments"
if not "%~3"=="" call :error_FATAL "requestNewTransactionID: to much arguments"
rem returns a transactionId
rem die id wird für alle transactionen benutzt, bis ein neuer aufruf stattfindet.
rem damit werden einzelne transactionen miteinander in verbindung gebracht.
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
call :_accounts.getTransactionIdFile %1 transactionIdFile
set "transactionId="
set "%1.COMMAND=call lib\io open transactionIdFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".requestNewTransactionID: Zeitüberschreitung"
set "%1.COMMAND=call lib\io print transactionIdFile"
for /F "usebackq delims=" %%a in (`call lib\retry exec %1.retryHandler`) do (
	set "transactionId=%%~a"
)
if not DEFINED transactionId call :error_FATAL ".requestNewTransactionID: fehler beim lesen der Datei"
set /a "nextID=%transactionId%+1"
set "%1.COMMAND=echo.%nextID%|call lib\io write transactionIdFile"
call lib\retry exec %1.retryHandler || call :error_FATAL ".requestNewTransactionID: fehler beim schreiben der Datei"
set "%1.COMMAND=call lib\io close transactionIdFile"
call lib\retry exec %1.retryHandler|| call :error_FATAL ".requestNewTransactionID: Zeitüberschreitung"
endlocal & (
	set "%1.activeTransactionId=%transactionId%"
	set "%2=%transactionId%"
)
exit /b 0

:accounts.getCurrentTransactionID self returnVar
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
endlocal & set "%2=!%1.activeTransactionId!"
exit /b 0

:accounts.forceUnlockAll self
rem entfernt alle *.lock ordner im kundenstamm, die durch lib\io open erstellt wurden
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	rem %%~dpna ist die datei für die das lock erstellt wurde
	rem %%~a ist der ordner der als schloss fungiert.
for /F "usebackq delims=" %%a in (`dir /S /B /ad "!%1.root!\*.LOCK"`) do (
	rmdir "%%~a" && echo. Schloss entfert von:"%%~dpna"
)
exit /b 0

:accounts.accountForceUnlock self "accountID"
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
	rem %%~dpna ist die datei für die das lock erstellt wurde
	rem %%~a ist der ordner der als schloss fungiert.
call :_accounts.getAccountRootPath %1 %2 accountRootPath
for /F "usebackq delims=" %%a in (`dir /B /ad "%accountRootPath%\*.LOCK"`) do (
	rmdir "%%~a" && echo. Schloss entfert von:"%%~dpna"
)
exit /b 0


:accounts.exportTransactionsToCsv self
rem :kunde.exportToCsv self
rem prints all customers transactions to consol
rem format Kundennummer;Betrag;Verwendungszweck;TransactionCode;Zeitstempel;transactionId
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "root=!%1.root!"
rem prefix customerID to every Transaction
echo Kundennummer;Betrag;Verwendungszweck;TransactionCode;Zeitstempel;transactionId
for /D %%i in ("%root%\acc\*") do (
	set "accountID=%%~nxi"
	call :_accounts.getAccountJournalFile %1 "!accountID!" journalFile
	rem set "%1.COMMAND=call lib\io open journalFile"
	rem call lib\retry exec %1.retryHandler
	set "%1.COMMAND=call lib\io print journalFile"
	for /F "usebackq delims=" %%a in (`call lib\retry exec %1.retryHandler`) do (
		echo "!accountID!";%%a
	)
	rem set "%1.COMMAND=call lib\io close journalFile"
	rem call lib\retry exec %1.retryHandler
)

exit /b 0

:accounts.exportTransactionsByTransactionID self "transactionID"
rem gibt alle transaktionen mit der gegebenen transID zurück
rem prefixed mit customerID
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "transactionId=%~2"
set "root=!%1.root!"
for /D %%i in ("%root%\acc\*") do (
	set "accountID=%%~nxi"
	call :_accounts.getAccountJournalFile %1 "!accountID!" journalFile
	rem set "%1.COMMAND=call lib\io open journalFile"
	rem call lib\retry exec %1.retryHandler
	set "%1.COMMAND=call lib\io print journalFile"
	rem nur dateinamen anzeigen in der transID vorkommt
	for /F "usebackq delims=" %%A in (`call lib\retry exec %1.retryHandler^|findstr /R /C:"\"%transactionId%\"$"`) do (
		echo "!accountID!";%%A
	)
	rem set "%1.COMMAND=call lib\io close journalFile"
	rem call lib\retry exec %1.retryHandler
)
exit /b 0





:_accounts.accountIncrementBalanceCache self balanceCacheFileObj betrag
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set /a "increment=%~3"
set "%1.COMMAND=call lib\io print %2"
set "cachedBalance="
for /F "usebackq delims=" %%a in (`call lib\retry exec %1.retryHandler`) do (
	set /a "cachedBalance=%%~a"
)
set /a "cachedBalance+=%increment%"
set "%1.COMMAND=echo.%cachedBalance%|call lib\io write %2"
call lib\retry exec %1.retryHandler
exit /b 0

:_accounts.getAccountRootPath self "accountID" returnVar
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "accountRootPath=!%1.root!\acc\%~2"
endlocal & set "%3=%accountRootPath%"
GOTO :EOF

:_accounts.getAccountBalanceCacheFile self "customerID" returnObj
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "accountID=%~2"
set "accountBalanceCacheFilePath=!%1.root!\acc\%accountID%\balanceCache.txt"
endlocal & (
	call lib\io init %3 "%accountBalanceCacheFilePath%" || exit /b 1
)
exit /b 0

:_accounts.getAccountJournalFile self "accountID" returnObj
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "accountID=%~2"
set "accountJournal=!%1.root!\acc\%accountID%\journal.txt"
endlocal & (
	call lib\io init %3 "%accountJournal%" || exit /b 1
)
GOTO :EOF

:_accounts.getTransactionIdFile self returnObj
setlocal ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS
set "transactionIdFilePath=!%1.root!\transactionID.txt"
endlocal & (
	call lib\io init %2 "%transactionIdFilePath%" || exit /b 1
)
GOTO :EOF



:_accounts.isAccountIDAllowed "accountID"
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



:error_FATAL "Message"
>&2 echo( FATAL ERROR:"%~dpnx0"
>&2 echo( ### %* ###
>&2 echo No exit option implemented yet
>&2 pause
goto :error_FATAL

:error_INFO "Message"
>&2 echo. #[%~n0]# %*
GOTO :EOF
:INFO "Message"
echo. #[%~n0]# %*
GOTO :EOF
