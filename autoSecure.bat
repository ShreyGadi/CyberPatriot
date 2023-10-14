@echo off
setlocal enabledelayedexpansion
net session

:: Show hidden files
reg ADD HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Hidden /t REG_DWORD /d 1 /f
reg ADD HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ShowSuperHidden /t REG_DWORD /d 1 /f

:: Check if admin permissions for script to run
if %errorlevel%==0 (
	echo Admin rights granted!
) else (
    echo Failure, no rights
	pause
    exit
)

cls

:: Make sure you answer all forensic questions
set /p answer=Have you answered all the forensics questions?[y/n]: 
	if /I {%answer%}=={y} (
		goto :menu
	) else (
		echo please go and answer them.
		pause
		exit
	)
	
:menu
	cls
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	echo "1)Change all passwords	2)Add User"
	echo "3)Disable User			4)Disable Default Guest and Admin"
	echo "5)Enable Firewall			6)Disable services"
	echo "7)Local Group Policy		8)Media Files to Delete"
	echo "9)			10)"
	echo "11)			12)"
	echo "13)			14)"
	echo "15)			16)"
	echo "69)Exit"
	echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	set /p answer=Please choose an option: 
		if "%answer%"=="1" goto :passwd
		if "%answer%"=="2" goto :createUser
		if "%answer%"=="3" goto :disableUser
		if "%answer%"=="4" goto :disGueAdm
		if "%answer%"=="5" goto :firewall
		if "%answer%"=="6" goto :services
		if "%answer%"=="7" goto :localgroup
		if "%answer%"=="8" goto :media
		if "%answer%"=="9" goto :menu
		if "%answer%"=="10" goto :menu
		if "%answer%"=="11" goto :menu
		if "%answer%"=="12" goto :menu
		if "%answer%"=="13" goto :menu
		if "%answer%"=="14" goto :menu
		if "%answer%"=="15" goto :menu
		if "%answer%"=="16" goto :menu
	pause

:passwd
    echo Changing all user passwords
	for /F "tokens=2* delims==" %%G in ('
		wmic UserAccount where "status='ok'" get name >null
	') do for %%g in (%%~G) do (
		net user %%~g p1SSw0rd!24$13
	)
	pause
	goto :menu

:createUser
    set /p answer=Would you like to create a user?[y/n]: 
	if /I "%answer%"=="y" (
        set /p NAME=What is the user you would like to create?:
        set /p GROUP=What group do you want to put the user in?:
        net user !NAME! /add
        net localgroup !GROUP! !NAME! /add
        echo !NAME! is now in !GROUP!
        pause
		goto :createUser
    )
    if /I "%answer%"=="n" (
        goto :menu
	)

:disableUser
 	set /p answer=Would you like to disable a user?[y/n]:
    if /I "%answer%"=="y" (
        set /p NAME=What is the user you would like to disable?:
        net user !NAME! /active:no
        echo !NAME! is now disabled
        pause
        goto :disableUser
    )
    if /I "%answer%"=="n" (
        goto :menu
    )

:disGueAdm
    :: Disables the guest account
	net user Guest | findstr Active | findstr Yes
	if %errorlevel%==0 (
		echo Guest account is already disabled.
	)
	if %errorlevel%==1 (
		net user guest p1SSw0rd!24$13 /active:no
	)
	
	:: Disables the Admin account
	net user Administrator | findstr Active | findstr Yes
	if %errorlevel%==0 (
		echo Admin account is already disabled.
		pause
		goto :menu
	)
	if %errorlevel%==1 (
		net user administrator p1SSw0rd!24$13 /active:no
		pause
		goto :menu
	)

:firewall
    netsh advfirewall set allprofiles state on
    netsh advfirewall set allprofiles logging filename %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log
    echo Firewall has been turn on
    goto :menu

:services
    ::might be too many services turned off
     set services=Telephony TapiSrv Tlntsvr tlntsvr p2pimsvc simptcp fax  iprip RasMan RasAuto seclogon W3SVC SMTPSVC Dfs TrkWks MSDTC ERSVC NtFrs MSFtpsvc helpsvc HTTPFilter IsmServ WmdmPmSN Spooler RDSessMgr RPCLocator RsoPProv ShellHWDetection ScardSvr Sacsvr Uploadmgr VDS VSS WINS WinHttpAutoProxySvc SZCSVC CscService hidserv IPBusEnum PolicyAgent SCPolicySvc SharedAccess SSDPSRV Themes upnphost
     set gmuServices=AxInstSV SensrSvc ALG WBENGINE bthserv CertPropSvc DPS WdiServiceHost defragsvc Fax HomeGroupListener UI0Detect SharedAccess KtmRm MSiSCSI swprv MMCSS Netlogon WpcMonSvc PNRPsvc p2psvc p2pimsvc PlugPlay IPBusEnum PNRPAutoReg WPDBusEnum Spooler QWAVE RasAuto RasMan TermService RemoteRegistry seclogon SstpSvc ShellHWDetection SCardSvr SCPolicySvc SNMPTRAP SSDPSRV TabletInputService Schedule lmhosts tapisrv Telnet SNMPTRAP mdnsresponder 
     for %%a in (!services!) do (   
        echo Disabling %%a
        sc stop "%%a"
        sc config "%%a" start=disabled
    )
    for %%a in (!gmuServices!) do (   
        echo Disabling %%a
        sc stop "%%a"
        sc config "%%a" start=disabled
    )
    sc stop "WinDefend"
    sc config "WinDefend" start=auto
    sc start "WinDefend"
    sc stop "wuauserv"
    sc config "wuauserv" start=auto
    sc start "wuauserv"
    goto :menu

:localgroup
	:: cd to current directory for LGPO to work
	cd C:\Users
	for /f "delims=" %%a in ('dir /s /b LGPO.exe') do (
    	cd %%a\..
	)

    echo Importing policies from policies folder	
    LGPO.exe /g MyP /v
	auditpol /set /category:* /success:enable
	auditpol /set /category:* /failure:enable
    goto:menu

:UAC
	echo Turning on UAC has to be done manually.
	echo Type UAC in to search menu.
	echo Drag the slider all the way up.
	pause
	goto :menu

:media 
	set filetypes=mp3 mov mp4 avi mpg mpeg flac m4a flv ogg gif png jpg jpeg exe
	cd C:\Users
    for %%i in (!filetypes!) do (
        echo Finding .%%i files...
        for /f "delims=" %%a in ('dir /s /b *.%%i') do (
            echo %%a
        )
	)
	pause
	goto :menu