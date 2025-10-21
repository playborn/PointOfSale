@echo off
call :%*
goto :EOF

::getMaskedInput  [/P "Prompt"]  StrVar  [ValidVar [/I]]
::
:: Get a user input string, echoing * for each key pressed. [Backspace] erases
:: the previous character. [Enter] completes the string. Additionally, any
:: method that generates Null (0x00), LineFeed (0x0A) or Carriage Return (0x0D)
:: will also terminate the string. On Windows 10 a [Ctrl-Z] (0x1A) will also
:: terminate the string. The final string may contain any characters between
:: 0x01 and 0xFF except Backspace, LineFeed, and Carriage Return. On Windows 10
:: Ctrl-Z is also excluded.
::
:: The optional /P parameter is used to specify a "Prompt" that is written to
:: stdout, without a newline.
::
:: The optional ValidVar parameter defines the characters that will be accepted.
:: If the variable is not given or not defined, then all characters are accepted.
:: If given and defined, then only characters within ValidVar are accepted.
::
:: If ValidVar is followed by the optional /I switch, then case of standard
:: English letters is ignored. The case of the pressed key is preserved in
:: the result, but English letters A-Z and a-z are not rejected due to case
:: differences when the /I switch is added.
::
:: Any value (except null) may be entered by holding the [Alt] key and pressing
:: the appropriate decimal code on the numeric keypad. For example, holding
:: [Alt] and pressing numeric keypad [1] and [0], and then releasing [Alt] will
:: result in a LineFeed.
::
:: The only way to enter a Null is by holding [Ctrl] and pressing the normal [2]
::
:: An alternate way to enter control characters 0x01 through 0x1A is by holding
:: the [Ctrl] key and pressing any one of the letter keys [A] through [Z].
:: However, [Ctrl-A], [Ctrl-F], [Ctrl-M], and [Ctrl-V] will be blocked on Win 10
:: if the console has Ctrl key shortcuts enabled.
::
:: This function works properly regardless whether delayed expansion
:: is enabled or disabled.
::
:: :getMaskedInput version 2.0 was written by Dave Benham, and originally
:: posted at http://www.dostips.com/forum/viewtopic.php?f=3&t=7396
::
:: This work was inspired by posts from carlos and others at
:: http://www.dostips.com/forum/viewtopic.php?f=3&t=6382
::
:getMaskedInput
setlocal
set "notDelayed=!"
if /i "%~1" equ "/P" (
  <nul set /p ^"=%2"
  shift /1
  shift /1
)
setlocal enableDelayedExpansion
set "mask=!%2!"
for /f %%A in ('"Prompt;$H&for %%A in (1) do rem"') do set "BS=%%A"
if defined mask set "mask=1!BS!!mask!"
set "str="
:getMaskedInputLoop
(
  call :getKey key mask %3
  if defined key (
    if not defined notDelayed (
      if "!key!" equ "^!" set "key=^^^!"
      if "!key!" equ "^" set "key=^^"
    )
    if "!key!" equ "!BS!" (
      if defined str (
        set "str=!str:~0,-1!"
        <nul set /p "=%BS% %BS%"
      )
    ) else (
      set "str=!str!!key!"
      <nul set /p "=*"
    )
    goto :getMaskedInputLoop
  )
  for /f "delims=" %%A in (""!str!"") do (
    endlocal
    endlocal
    set "%1=%%~A" !
    echo(
    exit /b
  )
)

::getKey  [/P "Prompt"]  KeyVar  [ValidVar [/I]]
::
:: Read a keypress representing a character between 0x00 and 0xFF and store the
:: value in variable KeyVar. Null (0x00), LineFeed (0x0A), and Carriage Return
:: (0x0D) will result in an undefined KeyVar. On Windows 10, Ctrl-Z (0x1A) will
:: also result in an undefined KeyVar. The simplest way to get an undefined
:: KeyVar is to press the [Enter] key.
::
:: The optional /P parameter is used to specify a "Prompt" that is written to
:: stdout, without a newline. Also, the accepted character is ECHOed after the
:: prompt if the /P option was used.
::
:: The optional ValidVar parameter defines the values that will be accepted.
:: If the variable is not given or not defined, then all characters are accepted.
:: If given and defined, then only characters within ValidVar are accepted. The
:: first character within ValidVar should either be 0, meaning ignore undefined
:: KeyVar, or 1, meaning accept undefined KeyVar. The remaining characters
:: represent themselves. For example, a ValidVar value of 0YN will only accept
:: uppercase Y or N. A value of 1YN will additionally accept [Enter] etc.
::
:: If ValidVar is followed by the optional /I switch, then case of standard
:: English letters is ignored. The case of the pressed key is preserved in
:: the result, but English letters A-Z and a-z are not rejected due to case
:: differences when the /I switch is added.
::
:: Any value (except null) may be entered by holding the [Alt] key and pressing
:: the appropriate decimal code on the numeric keypad. For example, holding
:: [Alt] and pressing numeric keypad [1] and [0], and then releasing [Alt] will
:: result in a LineFeed.
::
:: The only way to enter a Null is by holding [Ctrl] and pressing the normal [2]
::
:: An alternate way to enter control characters 0x01 through 0x1A is by holding
:: the [Ctrl] key and pressing any one of the letter keys [A] through [Z].
:: However, [Ctrl-A], [Ctrl-F], [Ctrl-M], and [Ctrl-V] will be blocked on Win 10
:: if the console has Ctrl key shortcuts enabled.
::
:: This function works properly regardless whether delayed expansion is enabled
:: or disabled.
::
:: :getKey version 2.0 was written by Dave Benham, and originally posted at
:: http://www.dostips.com/forum/viewtopic.php?f=3&t=7396
::
:: This work was inspired by posts from carlos and others at
:: http://www.dostips.com/forum/viewtopic.php?f=3&t=6382
::
:getKey
setlocal disableDelayedExpansion
if /i "%~1" equ "/P" (
  <nul set /p ^"=%2"
  shift /1
  shift /1
  set "getKey./P=1"
) else (
  set "getKey./P="
)
:getKeyRetry
(
  endlocal&setlocal disableDelayedExpansion
  (for /f skip^=1^ delims^=^ eol^= %%A in ('replace.exe ? . /u /w') do for /f delims^=^ eol^= %%B in ("%%A") do (
    endlocal
    if "%%B" equ "" (set "%1=^!") else set "%1=%%B"
    setlocal enableDelayedExpansion
  )) || (
    endlocal
    set "%1="
    setlocal enableDelayedExpansion
  )
  set "getKey./P=%getKey./P%"
  if defined %1 (set "getKey.key=!%1!") else set "getKey.key=x"
)
(
  if "!%2!" neq "" (
    if defined %1 (
      set "getKey.mask=!%2:~1!"
      if not defined getKey.mask goto :getKeyRetry
      if /i "%~3" equ "/I" (
        if "!%1!" equ "=" (
          set "getKey.mask=a!getKey.mask!"
          for /f "delims=" %%A in ("!getKey.mask!") do if /i "!getKey.mask:%%A=%%A!" equ "!getKey.mask!" goto :getKeyRetry
        ) else for /f delims^=^ eol^= %%A in ("!%1!") do if "!getKey.mask:*%%A=!" equ "!getKey.mask!" goto :getKeyRetry
      ) else (
        for /f tokens^=1*^ eol^=^%getKey.key%^ delims^=^%getKey.key% %%A in ("!getKey.mask!!getKey.mask!") do if "%%B" equ "" goto :getKeyRetry
      )
    ) else if "!%2:~0,1!" equ "0" goto :getKeyRetry
  )
  if defined getKey./P echo(!%1!
  exit /b
)

::getAnyKey  [/P "Prompt"]  KeyVar  [ValidVar [/I]]
::
:: Read a keypress representing any character between 0x00 and 0xFF and store
:: the character in variable KeyVar. A Null value of 0x00 is represented as an
:: undefined KeyVar.
::
:: Calling :getAnyKey will also define the following three variables:
::   getAnyKey.LF    = Linefeed        0x0A, decimal 10
::   getAnyKey.CR    = Carriage Return 0x0D, decimal 13
::   getAnyKey.CtrlZ = Control-Z       0x1A, decimal 26
:: The three variables can be defined in advance by calling :getAnyKeyInit.
::
:: The optional /P parameter is used to specify a "Prompt" that is written to
:: stdout, without a newline. Also, the accepted character is ECHOed after the
:: prompt if the /P option was used.
::
:: The optional ValidVar parameter defines the characters that will be accepted.
:: If the variable is not given or not defined, then all values are accepted.
:: If given and defined, then only characters within ValidVar are accepted. The
:: first character indicates whether Null (0x00) is accepted. A value of 1 means
:: acceptance, and 0 means rejection. The remaining characters represent
:: themselves. For example, a ValidVar value of 0YN will only accept upper case
:: Y or N. A value of 1YN will additionally accept Null.
::
:: Linefeed, Carriage Return, and/or Control-Z may be added to ValidVar by
:: enabling delayedExpansion, calling :getAnyKeyInit, and then appending
:: !getAnyKey.LF!, !getAnyKey.CR!, and/or !getAnyKey.CtrlZ! respectively.
::
:: If ValidVar is followed by the optional /I switch, then case of standard
:: English letters is ignored. The case of the pressed key is preserved in
:: the result, but English letters A-Z and a-z are not rejected due to case
:: differences when the /I switch is added.
::
:: Note that [Enter] is interpreted as a Carriage Return.
::
:: Any value (except null) may be entered by holding the [Alt] key and pressing
:: the appropriate decimal code on the numeric keypad. For example, holding
:: [Alt] and pressing numeric keypad [1] and [0], and then releasing [Alt] will
:: result in a Linefeed.
::
:: The only way to enter a Null is by holding [Ctrl] and pressing the normal [2]
::
:: An alternate way to enter control characters 0x01 through 0x1A is by holding
:: the [Ctrl] key and pressing any one of the letter keys [A] through [Z].
:: However, [Ctrl-A], [Ctrl-F], [Ctrl-M], and [Ctrl-V] will be blocked on Win 10
:: if the console has Ctrl key shortcuts enabled.
::
:: This function works properly regardless whether delayed expansion is enabled
:: or disabled.
::
:: :getAnyKey version 2.0 was written by Dave Benham, and originally posted at
:: http://www.dostips.com/forum/viewtopic.php?f=3&t=7396
::
:: This work was inspired by posts from carlos and others at
:: http://www.dostips.com/forum/viewtopic.php?f=3&t=6382
::
:getAnyKey
if not defined getAnyKey.CtrlZ call :getAnyKeyInit
setlocal
if "!!" equ "" set "getAnyKey.delayed=1"
(
  endlocal&setlocal disableDelayedExpansion
  set "getAnyKey.delayed=%getAnyKey.delayed%"
  if /i "%~1" equ "/P" (
    set "getAnyKey./P=1"
    <nul set /p ^"=%2"
    shift /1
    shift /1
  ) else (
    set "getAnyKey./P="
  )
)
:getAnyKeyRetry
(
  endlocal&setlocal disableDelayedExpansion
  for /f "skip=1 delims=" %%A in (
    'replace.exe ? . /u /w ^| findstr /n "^" ^| find /n /v ""'
  ) do set "str=%%A"
  setlocal enableDelayedExpansion
  if "!str!" equ "[3]3:" (  %= LineFeed =%
    endlocal&endlocal
    set ^"%1=^%getAnyKey.LF%%getAnyKey.LF%"
  ) else (                  %= Not LineFeed =%
    if "!str!" equ "[2]2:" (         %= Ctrl-Z on Win 10 =%
      set "key=!getAnyKey.CtrlZ!
    ) else if "!str!" equ "[3]" (    %= Null = %
      set "key="
    ) else (                         %= All others =%
      set "key=!str:~-1!"
      if "%getAnyKey.delayed%"=="1" if "!key!" equ "^!" set "key=^^^!"
    )
    for /f "delims=" %%A in (""!key!"") do endlocal&endlocal&set "%1=%%~A"
  )
  setlocal enableDelayedExpansion
  set "getAnyKey.delayed=%getAnyKey.delayed%"
  set "getAnyKey./P=%getAnyKey./P%"
  set "getAnyKey.key=x"
  if defined %1 if !%1! neq !getAnyKey.LF! if !%1! neq !getAnyKey.CR! set "getAnyKey.key=!%1!"
)
(
  if "!%2!" neq "" (
    if defined %1 (
      set "getAnyKey.mask=!%2:~1!"
      if not defined getAnyKey.mask goto :getAnyKeyRetry
      if "!%1!" equ "!getAnyKey.LF!" (
        for %%A in ("!%1!") do if "!getAnyKey.mask:%%~A=!" equ "!getAnyKey.mask!" goto :getAnyKeyRetry
      ) else if "!%1!" equ "!getAnyKey.CR!" (
        for /f %%A in (""!%1!"") do if "!getAnyKey.mask:%%~A=!" equ "!getAnyKey.mask!" goto :getAnyKeyRetry
      ) else if /i "%~3" equ "/I" (
        if "!%1!" neq "=" (
          for /f "delims=" %%A in (""!%1!"") do if "!getAnyKey.mask:*%%~A=!" equ "!getAnyKey.mask!" goto :getAnyKeyRetry
        ) else (
          for %%A in ("!getAnyKey.LF!") do set "getAnyKey.mask=a!getAnyKey.mask:%%~A=!"
          for /f "delims=" %%A in (""!getAnyKey.mask!"") do if /i "!getAnyKey.mask:%%~A=%%~A!" equ "!getAnyKey.mask!" goto :getKeyRetry
        )
      ) else (
        for %%A in ("!getAnyKey.LF!") do set "getAnyKey.mask=!getAnyKey.mask:%%~A=!"
        for /f tokens^=1*^ eol^=^%getAnyKey.key%^ delims^=^%getAnyKey.key% %%A in (
          "!getAnyKey.mask!!getAnyKey.mask!!getAnyKey.CR!"
        ) do if "%%B" equ "" goto :getAnyKeyRetry
      )
    ) else if "!%2:~0,1!" equ "0" goto :getAnyKeyRetry
  )
  if defined getAnyKey./P echo(!%1!
  exit /b
)

:getAnyKeyInit
:: Ctrl-Z  0x1A  decimal 26
copy nul "%temp%\ctrlZ.tmp" /a <nul >nul
(for /f "usebackq" %%A in ("%temp%\ctrlZ.tmp") do set "getAnyKey.CtrlZ=%%A")2>nul||goto :getAnyKeyInit
del "%temp%\ctrlZ.tmp" 2>nul
:: Linefeed  0x0A  decimal 10
(set getAnyKey.LF=^
%= Do not remove or alter this line =%
)
:: Carriage Return  0x0D  decimal 13
for /f %%A in ('copy /z "%~dpf0" nul') do set "getAnyKey.CR=%%A"
exit /b