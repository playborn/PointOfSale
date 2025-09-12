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
call lib\kunden init kunden "%kundenStamm%"
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
call lib\kunden customerExist %1 "%customerID%" && (
	call :colorNotFound
	echo. # Kunde existiert bereits #
	echo.
	rem call :showCustomer kunden "%customerID%"
	exit /b 1
	
)
call lib\kunden customerCreate %1 "%customerID%" && (
	call :colorSuccess
	echo. # Kunde wurde erstellt. #
	call :showCustomer kunden "%customerID%"
	echo.
)
exit /b 0

:showCustomer self "id"
setlocal
call lib\kunden customerSelect %1 %2
call lib\kunden customerGetBalanceFromCache %1 guthaben
echo. # Kundennummer:[%~2] Guthaben:[%guthaben%]
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