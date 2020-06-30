:: BACKUP SCRIPT AUTODESK VAULT
:: Version 1.0.0 - Original version created by Wouter Breedveld, Cadac Group B.V., 22-06-2020
:: Version 1.0.1 - By Wouter Breedveld, Cadac Group B.V., 26-06-2020
::					- Fixes ADMS path for Vault 2020 and earlier.
::					- Added PushOver support

:: Version 1.1.0 - By Wouter Breedveld, Cadac Group B.V., 30-06-2020
::					- Added Telegram support
::					- Added settings and info file export
::					- Added external settings file (BackupSettings.bat)
:: Version 1.2.0 - By Wouter Breedveld, Cadac Group B.V., 30-06-2020
::					- Added Auto-update




:: Info: https://help.autodesk.com/view/VAULT/2021/ENU/?guid=GUID-7FD9DAD8-0104-46FA-BCE7-11259FAB4235
:: Switches: https://knowledge.autodesk.com/support/vault-products/learn-explore/caas/CloudHelp/cloudhelp/2018/ENU/Vault-Admin/files/GUID-56F358D7-C47B-4B6A-95CB-F402D6F2C7F9-htm.html
:: Notepad++ is the preferend editor: https://notepad-plus-plus.org/downloads/"





:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!

:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!

:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!

:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!

:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!

:: DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT! - DANGER ZONE - DO NOT EDIT!


@echo off
TITLE Cadac Group B.V. - Vault Backup Script
if not "%1" == "max" start /MAX cmd /c %0 max & exit/b
setlocal enabledelayedexpansion
set scriptversion=1.2.0
set BackupSettings=BackupSettings.bat

:: Check admin
call :BatchGotAdmin

:: Check for update
call :Updater

:: Import Settings
IF NOT EXIST "BackupSettings.bat" (
	echo Settings file not found! Creating...
	CALL :SettingsMissing
	echo Settings file created. Please run again.
	pause
	exit
) ELSE (
	for /f "delims=" %%x in (%BackupSettings%) do %%x> nul 2> nul
)

:: Get date and time
SET "TIME="
SET "Start=%TIME%"
FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
SET "YY=%dt:~2,2%" & SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
SET "datestampstart=%YYYY%%MM%%DD%" & SET "timestampstart=%HH%%Min%%Sec%" & SET "fullstampstart=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"

:: Console Log
SET "LogLocation=%BackUpDrive%\ADMSBackup\Logs"
SET ScriptLogFolder="%LogLocation%\Script"
IF NOT EXIST %ScriptLogFolder% (mkdir %ScriptLogFolder%)
SET ScriptLog="%LogLocation%\Script\ScriptLog !fullstampstart!.txt"
BREAK>%ScriptLog%

if "%InstallNotepadPlus%"=="Yes" (
	call :InstallNotepad
)

call :Initilization
call :DisableQuickedit
call :checkCURL
call :Authentication
call :BackupOptions
call :getVaultVersion VaultVersion VaultType
if %VaultVersion% LEQ 2020 (
	SET ADSKDM="%AutodeskInstallLocation%\ADMS %VaultType% %VaultVersion%\ADMS Console\Connectivity.ADMSConsole.exe"
) ELSE (
	SET ADSKDM="%AutodeskInstallLocation%\Vault Server %VaultVersion%\ADMS Console\Connectivity.ADMSConsole.exe"
)

::1:
::1:         cCddDDDDDdCc                                                                                                                                  
::1:      ADDDDDdCCCAdDDDDDc                                                                                                                               
::1:    CDDDDCdc ccc    cDDDDc                                                                                                                             
::1:   DDDDA  c CDDdDDdc AddDDd                                                                                                                            
::1:  dDDDc   CcCDddddddddddddDC           dDDDDD      CD      cDDDDdc       CD        dDDDDD          DDDDDDc    DDDDC      ADDDDDC     DA    DC   cDDDd  
::1:  DdDd    A CdddddddddddddDD          DD    c     cDDC     dD   CDD     cDDA     cDA    c        ADc    cC    DD  DD    DD    cDD    DD    DD   dD  dD 
::1: cDdDC    CcCDdddddddddddddD         DD          cD  Dc    CD     Dc   cD  Dc    Dd              Dc    c      DDccDc   DD       DD   Dd    Dd   CDcCDD 
::1:  DDDd    C CdddddddddddddDD         DD         cDDCCDDc   CD    dD    DDCADDc   DD              DD    cADD   DDdD     DD       DA   DD    DD   ADcc   
::1:  dDDDC   C CDdddddDdddddDDc          dDDCcAD  cDC    CDc  dDCCdDD   cDA    cDc   DDdCcAD         DDAccCDD    DD cDd    dDdCcCDDC    cDdccDD    dD     
::1:   dDDDd  c CDDdDddc AddDDA             cCACc  cc      cc   cccc     cc      cc     cCACc          cCACc      c    c      cCACc        cACc      c     
::1:    cDDDDddc   c    cDDDDc                                                                                                                             
::1:      CDDDDDDACCAdDDDDDc                                                                                                                               
::1:          cCCdddAAcc                                                                                                                                                                                                                                                                                                                                                           

@cls
FOR /f "delims=::1: tokens=*" %%A IN ('findstr /b ::1: "%~f0"') DO @ECHO %Purple% %%A

ECHO %Red%============================================================================================================================================================
ECHO %White%Created by Wouter Breedveld, Cadac Group B.V. & ECHO Created by Wouter Breedveld, Cadac Group B.V.>>%ScriptLog%
ECHO %White%Version %scriptversion% & ECHO Version %scriptversion%>>%ScriptLog%
ECHO %White%Date last edited %filedate% & ECHO Date last edited %filedate%>>%ScriptLog%
ECHO %White%Installed Vault version: %VaultType% %VaultVersion% & ECHO Installed Vault version: %VaultType% %VaultVersion%>>%ScriptLog%
ECHO %Red%============================================================================================================================================================
ECHO %White%Starting opperations !fullstampstart! & ECHO Starting opperations !fullstampstart!>>%ScriptLog%
ECHO %Red%============================================================================================================================================================
ECHO %White%

call :getDiskspace freeMainDrive sizeMainDrive MainDrive
call :getDiskspace freeBackUpDrive sizeBackUpDrive BackUpDrive

set FMD=%freeMainDrive%
set FBD=%freeBackUpDrive%

if "%UseSSL%"=="Yes" (
	SET SSL=/SSL
) else (
	SET SSL=
)

SET NASbackup="%NASPath%\VaultBackup\ADMS\Scheduled Backup\%Vault%"
SET BackUpNew="%BackUpDrive%\ADMSBackup\Scheduled Backup\%Vault%"
SET BackUpOld="%BackUpDrive%\ADMSBackup\Scheduled Backup\%Vault% Old"

:: SET up some variables
call :getTime now & ECHO %White%[!now!] - Setting the required variables & ECHO [!now!] - Setting the required variables>>%ScriptLog%
IF "%CopyToNAS%"=="Yes" (
	IF not exist %NASbackup% (mkdir %NASbackup%)
)
IF not exist %BackUpNew% (mkdir %BackUpNew%)

SET LogFolder=%LogLocation%\Backups
SET Log="%LogFolder%\BackupLog !fullstampstart!.txt"

SET VaultSettingsFolder=%LogLocation%
SET VaultSettings="%VaultSettingsFolder%\Vault %VaultType% %VaultVersion% Settings %CompanyName%.txt"

SET DefragLogFolder="%LogLocation%\Defragmentations"
SET DefragLog="%DefragLogFolder%\DefragLog !fullstampstart!.txt"

SET B2BMigrateLogFolder="%LogLocation%\B2BMigrations"
SET B2BMigrateLog="%B2BMigrateLogFolder%\DefragLog !fullstampstart!.txt"

if exist %VaultSettings% ( del %VaultSettings% )
call :ExportSettings > nul 2> nul
call :SetSchedule
call :KillADMS
call :ResetServices

:: Set time free space
FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
SET "fullstampfreespace=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
SET SubjectFail="WARNING. Vault backup error. - %fullstampfreespace%"
SET BodyFail="Hi,<br /^><br /^>Unfortunatly the %Vault% Vault backup failed<br /^>There is not enough space on the %BackUpDrive% drive<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault Server<br /^><br /^>Remeber to eat healthy, get enough sleep and backup your computer"
call :getTime now & ECHO [!now!] - Done Setting variables & ECHO [!now!] - Done Setting variables>>%ScriptLog%

:: Check if enough free space is available
CALL :folderSize size "%VaultLocation%" "/S"

IF %sizeGb%+2 GEQ %freeBackUpDrive% (
	call :getTime now & ECHO [!now!] - %Red%Failed%White%. Not enough free space on %BackUpDrive% & ECHO [!now!] - Failed. Not enough free space on %BackUpDrive%>>%ScriptLog%
	if "%EnableMail%"=="Yes" (
		"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /b %BodyFail% /html
	)
	call :SendNotification "%CompanyName% Vault Backup Failed! Not enough free space."
	call :getTime now & ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	timeout 600
	GOTO :QUIT
) ELSE (
	call :getTime now & ECHO [!now!] - Enough free space for backup available on %BackUpDrive% & ECHO [!now!] - Enough free space for backup available on %BackUpDrive%>>%ScriptLog%
)

:: Check if there is a backup present
call :getTime now & ECHO [!now!] - Checking if a current back-up is present & ECHO [!now!] - Checking if a current back-up is present>>%ScriptLog%
for /f %%a in ('dir /b /s /ad %BackUpNew%^|find /c /v "" ') do SET count=%%a

IF "%count%"=="0" (
 	SET BackupType=Full
	call :getTime now & ECHO [!now!] - No backup is present. Creating Full back-up & ECHO [!now!] - No backup is present. Creating Full back-up>>%ScriptLog%
)

:: Do a full or incremental backup
IF "%BackupType%"=="Full" (
	call :getTime now & ECHO [!now!] - Creating a new Full back-up and deleting the old if successfull & ECHO [!now!] - Creating a new Full back-up and deleting the old if successfull>>%ScriptLog%
	MOVE /Y %BackUpNew% %BackUpOld% > nul 2> nul
	IF not exist %BackUpNew% (mkdir %BackUpNew%)
	call :getTime now & ECHO [!now!] - Now creating full back-up on local machine & ECHO [!now!] - Now creating full back-up on local machine>>%ScriptLog%
	%ADSKDM% -Obackup -B%BackUpNew% %VaultAuth%%VaultOpt% -S -L%Log% > nul 2> nul
) ELSE (
	call :getTime now & ECHO [!now!] - Now creating incremental back-up on local machine & ECHO [!now!] - Now creating incremental back-up on local machine>>%ScriptLog%
	%ADSKDM% -Obackup -B%BackUpNew% %VaultAuth%%VaultOpt% -INC -S -L%Log% > nul 2> nul
)

:: Set time backup finished
FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
SET "fullstampendbackup=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"

set "End=%TIME%"
call :timediff Elapsed Start End

:: FOR TESTING
REM ECHO The backup operation has been successfully finished>>%Log%

:: Check if backup is successfull
findstr /m /C:"%CheckString%" %Log%
IF %errorlevel% EQU 0 (
	GOTO :BackupSuccess
)
findstr /m /C:"%CheckString2%" %Log%
IF %errorlevel% EQU 0 (
	GOTO :BackupSuccess
) else (
	GOTO :BackupFailed
)

:BackupSuccess
	call :getTime now & ECHO [!now!] - Successfully finished back-up opperations & ECHO [!now!] - Successfully finished back-up opperations>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8! & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8!>>%ScriptLog%

	IF %defragbool% EQU 1 (
		call :getTime now & ECHO [!now!] - Defragmenting the Vault & ECHO [!now!] - Defragmenting the Vault>>%ScriptLog%
		%ADSKDM% -Odefragmentvault -N%Vault% %VaultAuth% -S
		call :getTime now & ECHO [!now!] - Done defragmenting & ECHO [!now!] - Done defragmenting>>%ScriptLog%
		:: Set time Defrag finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampenddefrag=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	) else (
		call :getTime now & ECHO [!now!] - Not defragmenting the Vault at this time & ECHO [!now!] - Not defragmenting the Vault at this time>>%ScriptLog%
		SET fullstampenddefrag=Didn't defragment the database
	)

	IF %b2bbool% EQU 1 (
		call :getTime now & ECHO [!now!] - Running B2BMigration to improve performance & ECHO [!now!] - Running B2BMigration to improve performance>>%ScriptLog%
		%ADSKDM% -Ob2bmigrate %VaultAuth% -S
		call :getTime now & ECHO [!now!] - Done running B2BMigration & ECHO [!now!] - Done running B2BMigration>>%ScriptLog%
		:: Set time B2BMigration finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampendB2B=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	) else (
		call :getTime now & ECHO [!now!] - Not running B2BMigration at this time & ECHO [!now!] - Not running B2BMigration at this time>>%ScriptLog%
		SET fullstampendB2B=Didn't run B2BMigration
	)
	
	IF "%CopyToNAS%"=="Yes" (
		call :getTime now & ECHO [!now!] - Deleting old backup on NAS & ECHO [!now!] - Deleting old backup on NAS>>%ScriptLog%
		RMDIR /S /Q %NASbackup%>>%ScriptLog%
		call :getTime now & ECHO [!now!] - Done deleting old backup on NAS & ECHO [!now!] - Done deleting old backup on NAS>>%ScriptLog%
		:: Set time Deletion NAS finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampenddelnas=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		call :getTime now & ECHO [!now!] - Moving backup to NAS & ECHO [!now!] - Moving backup to NAS>>%ScriptLog%
		ROBOCOPY /E %BackUpNew% %NASbackup%>>NUL
		call :getTime now & ECHO [!now!] - Done moving backup to NAS & ECHO [!now!] - Done moving backup to NAS>>%ScriptLog%
		:: Set time moving finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampendmove=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		IF %errorlevel% EQU 0 (
			call :getTime now & ECHO [!now!] - Deleting backup on local disk & ECHO [!now!] - Deleting backup on local disk>>%ScriptLog%
			RMDIR /S /Q %BackUpNew%>>%ScriptLog%
			call :getTime now & ECHO [!now!] - Done deleting backup on local disk & ECHO [!now!] - Done deleting backup on local disk>>%ScriptLog%
			:: Set time Deletion local finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampenddellocal=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		) ELSE (
			call :getTime now & ECHO [!now!] - Moving backup to NAS failed & ECHO [!now!] - Moving backup to NAS failed>>%ScriptLog%
			:: Set time Move failed
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET fullstampenddellocal=Failed moving the backup
		)
	)
	
	:: Try to delete old local backup
	IF exist %BackUpOld% (
		RMDIR /S /Q %BackUpOld%>>%ScriptLog%
	)
	SET successbool=1
	GOTO :Close
	
:BackupFailed
	SET successbool=0
	GOTO :Close

:Close
SET SubjectSuccess="Vault backup successfull - %fullstampendbackup%"
SET BodySuccess="Hi,<br /^><br /^>Attached is the log file of the %Vault% Vault backup.<br /^>Opperations started: %fullstampstart%<br /^>Backup finished: !fullstampendbackup!<br /^>Defragmentation finished: !fullstampenddefrag!<br /^>B2BMigration finished: !fullstampendB2B!<br /^>Deleting old backup from NAS finished: !fullstampenddelnas!<br /^>Moving new backup to NAS finished: !fullstampendmove!<br /^>Deleting local backup finished: !fullstampenddellocal!<br /^>Duration: !Elapsed:~0,8!<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault Server<br /^><br /^>Remeber to eat healthy, get enough sleep and backup your computer"
SET SubjectFail="WARNING Vault backup error - %fullstampendbackup%"
SET BodyFail="Hi,<br /^><br /^>Unfortunatly the %Vault% Vault backup failed.<br /^>Attached is the log file of the Vault backup.<br /^>Backup started !fullstampstart!<br /^>Backup finished !fullstampendbackup!<br /^>Duration: !Elapsed:~0,8!<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault Server<br /^><br /^>Remeber to eat healthy, get enough sleep and backup your computer"

IF %successbool% EQU 1 (
	call :getTime now & ECHO [!now!] - %Green%Success%White%. & ECHO [!now!] - Success.>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8! & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8!>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Sending logfile to emailaddress & ECHO [!now!] - Sending logfile to emailaddress>>%ScriptLog%
	if "%EnableMail%"=="Yes" (
		"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectSuccess% /a %Log%^|%ScriptLog% /b %BodySuccess% /html
	)
	call :SendNotification "%CompanyName% Vault Backup Successfull!"
	call :getTime now & ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	timeout 600
	GOTO :QUIT
) ELSE (
	call :getTime now & ECHO [!now!] - %Red%Failed%White%. & ECHO [!now!] - Failed. >>%ScriptLog%
	call :getTime now & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8! & ECHO [!now!] - Elapsed Time: !Elapsed:~0,8!>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Sending logfile to emailaddress & ECHO [!now!] - Sending logfile to emailaddress>>%ScriptLog%
	if "%EnableMail%"=="Yes" (
		"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /a %Log%^|%ScriptLog% /b %BodyFail% /html
	)
	call :SendEmail %SubjectFail% %BodyFail%
	call :SendNotification "%CompanyName% Vault Backup Failed!"
	call :getTime now &	ECHO [!now!] -  Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	timeout 600
	GOTO :QUIT
)


:timediff <outDiff> <inStartTime> <inEndTime>
(
    setlocal EnableDelayedExpansion
    set "Input=!%~2! !%~3!"
    for /F "tokens=1,3 delims=0123456789 " %%A in ("!Input!") do set "time.delims=%%A%%B "
)
for /F "tokens=1-8 delims=%time.delims%" %%a in ("%Input%") do (
    for %%A in ("@h1=%%a" "@m1=%%b" "@s1=%%c" "@c1=%%d" "@h2=%%e" "@m2=%%f" "@s2=%%g" "@c2=%%h") do (
        for /F "tokens=1,2 delims==" %%A in ("%%~A") do (
            for /F "tokens=* delims=0" %%B in ("%%B") do set "%%A=%%B"
        )
    )
    set /a "@d=(@h2-@h1)*360000+(@m2-@m1)*6000+(@s2-@s1)*100+(@c2-@c1), @sign=(@d>>31)&1, @d+=(@sign*24*360000), @h=(@d/360000), @d%%=360000, @m=@d/6000, @d%%=6000, @s=@d/100, @c=@d%%100"
)
(
    if %@h% LEQ 9 set "@h=0%@h%"
    if %@m% LEQ 9 set "@m=0%@m%"
    if %@s% LEQ 9 set "@s=0%@s%"
    if %@c% LEQ 9 set "@c=0%@c%"
)
(
    endlocal
    set "%~1=%@h%%time.delims:~0,1%%@m%%time.delims:~0,1%%@s%%time.delims:~1,1%%@c%"
    exit /b
)

:: getTime
::    This routine returns the current (or passed as argument) time
::    in the form hh:mm:ss,cc in 24h format, with two digits in each
::    of the segments, 0 prefixed where needed.
:getTime returnVar [time]
    setlocal enableextensions disabledelayedexpansion

    :: Retrieve parameters if present. Else take current time
    if "%~2"=="" ( set "t=%time%" ) else ( set "t=%~2" )

    :: Test if time contains "correct" (usual) data. Else try something else
    echo(%t%|findstr /i /r /x /c:"[0-9:,.apm -]*" >nul || ( 
        set "t="
        for /f "tokens=2" %%a in ('2^>nul robocopy "|" . /njh') do (
            if not defined t set "t=%%a,00"
        )
        rem If we do not have a valid time string, leave
        if not defined t exit /b
    )

    :: Check if 24h time adjust is needed
    if not "%t:pm=%"=="%t%" (set "p=12" ) else (set "p=0")

    :: Separate the elements of the time string
    for /f "tokens=1-5 delims=:.,-PpAaMm " %%a in ("%t%") do (
        set "h=%%a" & set "m=00%%b" & set "s=00%%c" & set "c=00%%d" 
    )

    :: Adjust the hour part of the time string
    set /a "h=100%h%+%p%"

    :: Clean up and return the new time string
    endlocal & if not "%~1"=="" set "%~1=%h:~-2%:%m:~-2%:%s:~-2%,%c:~-2%" & exit /b
	
	
:getVaultVersion <VaultVersion> <VaultType>
	setlocal enableextensions disabledelayedexpansion
	:: Get vault version
	reg export HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall temp1.txt
	find "DisplayName" temp1.txt| find /V "ParentDisplayName" > temp2.txt
	FOR /f "tokens=2,3 delims==" %%a IN (temp2.txt) DO (ECHO %%a >> software_list.txt)
	DEL temp1.txt
	DEL temp2.txt
	SET findfile="software_list.txt"
	
	findstr /R /C:\""Autodesk Vault Professional .... (Server)"\" %findfile%
	IF %errorlevel% EQU 0 (
		SET VT=Professional
		GOTO :Continue
	)
	findstr /R /C:\""Autodesk Vault Workgroup .... (Server)"\" %findfile%
	IF %errorlevel% EQU 0 (
		SET VT=Workgroup
		GOTO :Continue
	)
	findstr /R /C:\""Autodesk Vault Basic .... (Server)"\" %findfile%
	IF %errorlevel% EQU 0 (
		SET VT=Basic
		GOTO :Continue
	)
	
	@cls
	DEL software_list.txt
	FOR /f "delims=::1: tokens=*" %%A IN ('findstr /b ::1: "%~f0"') DO @ECHO %Purple% %%A
	ECHO %Red%============================================================================================================================================================
	ECHO %White%No Vault installed! Exiting... & ECHO No Vault installed! Exiting...>>%ScriptLog%
	timeout 30
	GOTO :QUIT
	
	:Continue
	SET findtext="Autodesk Vault %VT% .... (Server)"
	findstr /R /C:\"%findtext%\" %findfile% > temp3.txt
	DEL software_list.txt
	FOR /f "tokens=4 delims== " %%a IN ('findstr /R /C:"[0-9][0-9][0-9][0-9]" temp3.txt') DO (ECHO %%a >> temp4.txt)
	DEL temp3.txt
	set /A MAX=0
	for /F %%i in (temp4.txt) do ( if %%i GTR !MAX! ( set /A MAX=%%i))
	DEL temp4.txt
	SET GetVaultVersion=%MAX%
	
    :: Clean up and return the new time string
	(
		endlocal
		if not "%~1"=="" set "%~1=%GetVaultVersion%"
		if not "%~2"=="" set "%~2=%VT%"
		exit /b
	)

:KillADMS
	:: Kill ADMS Console, if open
	setlocal enabledelayedexpansion
	call :getTime now
	ECHO [!now!] - Closing ADMS Console if open & ECHO [!now!] - Closing ADMS Console if open>>%ScriptLog%
	taskkill /F /IM Connectivity.ADMSConsole.exe > nul 2> nul
	IF %errorlevel% NEQ 0 (
		call :getTime now
		ECHO [!now!] - Successfully closed running ADMS Console & ECHO [!now!] - Successfully closed running ADMS Console>>%ScriptLog%
	) ELSE (
		call :getTime now
		ECHO [!now!] - ADMS Console wasn't running & ECHO [!now!] - ADMS Console wasn't running>>%ScriptLog%
	)
	exit /b
	
:BatchGotAdmin
	:: Check for permissions
	IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
	>NUL 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
	) ELSE (
	>NUL 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
	)

	:: If error flag SET, we do not have admin.
	IF '%errorlevel%' NEQ '0' (
		ECHO %White%Requesting administrative privileges...
		GOTO UACPrompt
	) ELSE ( GOTO gotAdmin )

	:UACPrompt
		ECHO SET UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
		SET params = %*:"=""
		ECHO UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

		"%temp%\getadmin.vbs"
		DEL "%temp%\getadmin.vbs"
		exit /b

	:gotAdmin
		PUSHD "%CD%"
		CD /D "%~dp0"
		exit /b

:DisableQuickedit
	:: Disable QuickEdit
	SET REGKEY=HKEY_CURRENT_USER\Console
	SET REGVAL=QuickEdit
	FOR /F "tokens=2* skip=2" %%a IN ('reg query %REGKEY% /v %REGVAL%') DO SET /A VALUE=%%b
	IF "%VALUE%"=="1" (
		ECHO %White%QuickEdit is enabled. Disabling...
		REG ADD %REGKEY% /v %REGVAL% /t REG_DWORD /d "0" /f
		IF "%ERRORLEVEL%"=="0" (
			ECHO QuickEdit disabled successfully!
		) ELSE (
			ECHO Failed to disable QuickEdit...
		)
	) ELSE (
		ECHO QuickEdit is disabled. Continuing...
	)
	exit /b
	
:Initilization
	SET CheckString=The backup operation has been successfully finished
	SET CheckString2=No changes have occurred since the last Full or Incremental Backup
	SET ESC=
	SET Red=%ESC%[31m
	SET Green=%ESC%[32m
	SET Blue=%ESC%[34m
	SET Purple=%ESC%[35m
	SET White=%ESC%[37m
	SET ThisFile="%CD%\%~n0%~x0"
	FOR %%? IN (%ThisFile%) DO SET filedate=%%~t?
	exit /b
	
:getDiskspace <outFree> <outSize> <inDrive>
	:: Get Freespace
	(
		setlocal EnableDelayedExpansion
	)
	FOR /F "tokens=2 delims==" %%S IN ('wmic /NODE:"%COMPUTERNAME%" LogicalDisk Where ^(DriveType^="3" and DeviceID^="!%~3!"^) Get FreeSpace /VALUE') DO @SET output1=%%S
	FOR /F "tokens=2 delims==" %%S IN ('wmic /NODE:"%COMPUTERNAME%" LogicalDisk Where ^(DriveType^="3" and DeviceID^="!%~3!"^) Get Size /VALUE') DO @SET output2=%%S
	SET /a temp1=%output1:~0,-4%/1048576
	SET /a temp2=%output2:~0,-4%/1048576
	(
		endlocal
		SET %~1=%temp1%
		SET %~2=%temp2%
		exit /b
	)

:ResetServices
	:: Reset services
	call :getTime now
	ECHO [!now!] - Cycling Autodesk Data Management Job Dispatch & ECHO [!now!] - Cycling Autodesk Data Management Job Dispatch>>%ScriptLog%
	NET STOP "Autodesk Data Management Job Dispatch" > nul 2> nul
	NET START "Autodesk Data Management Job Dispatch" > nul 2> nul
	
	call :getTime now
	ECHO [!now!] - Cycling SQL Services & ECHO [!now!] - Cycling SQL Services>>%ScriptLog%
	NET STOP "SQLBrowser" > nul 2> nul
	NET STOP "SQLAgent$AUTODESKVAULT" > nul 2> nul
	NET STOP "MSSQL$AUTODESKVAULT" > nul 2> nul
	NET START "MSSQL$AUTODESKVAULT" > nul 2> nul
	NET START "SQLAgent$AUTODESKVAULT" > nul 2> nul
	NET START "SQLBrowser" > nul 2> nul
	
	call :getTime now
	ECHO [!now!] - Cycling IIS & ECHO [!now!] - Cycling IIS>>%ScriptLog%
	iisreset /restart > nul 2> nul
	(
		exit /b
	)

:SetSchedule
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get DayOfWeek') do if not defined dayNumber set dayNumber=%%a
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get WeekInMonth') do if not defined weekNumber set weekNumber=%%a
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get Month') do if not defined monthNumber set monthNumber=%%a
	
	for %%i in (%FullBackUpOnMonth%) do (if %%i==%monthNumber% (
		for %%i in (%FullBackUpOnWeek%) do (if %%i==%weekNumber% (
			for %%i in (%FullBackUpOnDay%) do (if %%i==%dayNumber% (
				SET BackupType=Full
			))
		))
	))
	
	for %%i in (%IncrementalBackUpOnMonth%) do (if %%i==%monthNumber% (
		for %%i in (%IncrementalBackUpOnWeek%) do (if %%i==%weekNumber% (
			for %%i in (%IncrementalBackUpOnDay%) do (if %%i==%dayNumber% (
				SET BackupType=Incremental
			))
		))
	))		
	
	SET defragbool=0
	if "%RunDefragmentation%"=="Yes" (
		for %%i in (%DefragmentOnMonth%) do (if %%i==%monthNumber% (
			for %%i in (%DefragmentOnWeek%) do (if %%i==%weekNumber% (
				for %%i in (%DefragmentOnDay%) do (if %%i==%dayNumber% (
					SET defragbool=1
				))
			))
		))
	)
	
	SET b2bbool=0
	if "%RunB2BMigration%"=="Yes" (
		for %%i in (%B2BMigrationOnMonth%) do (if %%i==%monthNumber% (
			for %%i in (%B2BMigrationOnWeek%) do (if %%i==%weekNumber% (
				for %%i in (%B2BMigrationOnDay%) do (if %%i==%dayNumber% (
					SET b2bbool=1
				))
			))
		))
	)
	(
		exit /b
	)


:: Function to calculate the size of a directory and its subdirectories
::----------------------------------------------------------------------
:folderSize <returnVariableName> <folder> [DIR parameters]
	CALL :strNumDivide sizeKb %size% 1024
	CALL :strNumDivide sizeMb %sizeKb% 1024
	CALL :strNumDivide sizeGb %sizeMb% 1024
	CALL :formatNumber size %size%
	CALL :formatNumber sizeKb %sizeKb%
	CALL :formatNumber sizeMb %sizeMb%
	CALL :formatNumber sizeGb %sizeGb%

    SetLocal EnableExtensions EnableDelayedExpansion

    SET folder=%2
    SET params=%~3

    IF NOT DEFINED folder SET folder="%CD%"

    DIR %params% /W "%folder:"=%" > %TEMP%\folderSize.tmp

    FOR /F "tokens=1 delims=:" %%x IN ('findstr /n /e ":" %TEMP%\folderSize.tmp') DO (SET line=%%x)

    IF DEFINED line (

        SET /A line = !line! + 1

        FOR /F "tokens=4 delims= " %%i IN ('findstr /n "bytes" %TEMP%\folderSize.tmp^|findstr "!line!:"') DO (SET size=%%i)
        SET size=!size:,=.!
		SET size=!size:.=!

    ) ELSE (

        FOR /F "tokens=3 delims= " %%i IN ('findstr /e "bytes" %TEMP%\folderSize.tmp') DO (SET size=%%i)
        SET size=!size:,=.!
		SET size=!size:.=!

    )

    DEL %TEMP%\folderSize.tmp > nul

    EndLocal & SET "%~1=%size%"

GOTO:EOF



:: Extras functions to convert between different units and to give numerical format
:: --------------------------------------------------------------------------------
:strNumDivide <returnVariableName> <stringNum> <divisor>
    SetLocal EnableExtensions EnableDelayedExpansion 

    SET strNum=%~2
    SET divisor=%~3

    SET result=
    SET number=

    IF !divisor! EQU 0 GOTO:EOF

    FOR /L %%n IN (0,1,18) DO (
        IF NOT "!strNum:~%%n!" == "" (
            SET number=!number!!strNum:~%%n,1!

            IF !number! GEQ !divisor! (
                SET /A quotient=!number! / !divisor!
                SET /A number=!number! - !quotient! * !divisor!
                IF !number! EQU 0 SET number=
                SET result=!result!!quotient!
            ) ELSE (
                IF DEFINED result SET result=!result!0
            )
        )
    )

    IF NOT DEFINED result SET "result=0"
    EndLocal & SET "%~1=%result%"

GOTO:EOF


:formatNumber <returnVariableName> <number> [separator [group size]] 
    SetLocal EnableExtensions EnableDelayedExpansion 
    SET "raw=%~2"
    SET "separator=%~3" 
    SET "group=%~4" 
    SET "answer=" 
    IF NOT DEFINED raw GOTO :EOF
    IF NOT DEFINED separator SET "separator=."
    IF NOT DEFINED group SET "group=3"

    FOR %%g IN (-%group%) DO (
        FOR /F "tokens=1,2 delims=,." %%a IN ("%raw%") DO ( 
            SET int=%%a
            SET frac=%%b

            FOR /F "delims=:" %%c IN ('^(ECHO;!int!^& Echo.NEXT LINE^)^|FindStr /O "NEXT LINE"') DO (
                SET /A length=%%c-3
            ) 

            FOR %%c IN (!length!) DO ( 
                SET radix=!raw:~%%c,1!
            )

            FOR /L %%i IN (!length!, %%g, 1) DO ( 
                SET answer=!int:~%%g!!separator!!answer! 
                SET int=!int:~0,%%g!
            ) 
        ) 
    )
    SET answer=%answer: =%
    SET answer=%answer:~0,-1%

    EndLocal & SET "%~1=%answer%%radix%%frac%" 
	Goto :EOF

:: Checks if curl is installed. If not, download chocolatey package manager to install latest version of curl.
:checkCURL
	if "%EnablePushOver%"=="Yes" (
		if not exist %SYSTEMROOT%\System32\curl.exe (
			if not exist %PROGRAMDATA%\chocolatey\choco.exe (
				@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
				start "" "%~f0"
				exit
			)
			if not exist %PROGRAMDATA%\chocolatey\lib\curl (
				choco install curl -y
			)
		)
	)
	(
		exit /b
	)

:: Installs Notepad++
:InstallNotepad
	if not exist %PROGRAMDATA%\chocolatey\choco.exe (
		@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
		start "" "%~f0"
		exit
	)
	if not exist "%ProgramFiles%\Notepad++\notepad++.exe" (
		choco install notepadplusplus.install -y
	)
	(
		exit /b
	)

:: Create Vault authentication string
:Authentication
	if "%WindowsAuthentication%"=="Yes" (
		SET VaultAuth=-WA
	)
	if "%WindowsAuthentication%"=="No" (
		SET VaultAuth=-VU"%BackupUser%" -VP"%BackupPassword%"
	)
	(
		exit /b
	)
:: Create Vault backup options string
:BackupOptions
	if "%ValidateBackup%"=="Yes" (
		SET VAL= -VAL
	) ELSE (
		SET VAL=
	)	
	if "%BackupStandardContentCenter%"=="No" (
		SET DBSC= -DBSC
	) ELSE (
		SET DBSC=
	)
	SET VaultOpt=%VAL%%DBSC%
	(
		exit /b
	)

:SendNotification <Message>
	if "%EnableTelegram%"=="Yes" (
		endlocal
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendMessage -d chat_id=%TelegramChatID% -d text="%~1" > nul 2> nul
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendDocument -F chat_id=%TelegramChatID% -F caption="Script Log" -F document=@%ScriptLog% > nul 2> nul
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendDocument -F chat_id=%TelegramChatID% -F caption="Backup Log" -F document=@%Log% > nul 2> nul
		setlocal enabledelayedexpansion
	)
	if "%EnablePushOver%"=="Yes" (
		endlocal
		curl --form-string "token="%PushOverToken%"" --form-string "user="%PushOverUser%"" --form-string "html=1" --form-string "message=%~1" --form-string "title=%CompanyName% - Vault Server" --form-string "priority=-1" https://api.pushover.net/1/messages.json > nul 2> nul
		setlocal enabledelayedexpansion
	)
	(
		exit /b
	)

:ExportSettings
	for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "IPv4"') do set ip==%%b
	set ipAddress=%ip:~2%

	for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Physical"') do set mac==%%b
	set macAddress=%mac:~2%
	
	for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Host Name"') do set host==%%b
	set HostName=%host:~2%
	
	for /f "skip=1 delims=" %%a in ('WMIC cpu Get name') do if not defined cpu set cpu=%%a
	for /f "skip=1 delims=" %%a in ('WMIC cpu Get numberofcores') do if not defined cores set cores=%%a
	
	:: Main settings
	ECHO ============================== Main Settings ==============================   >>%VaultSettings%
	ECHO Main drive:		%MainDrive%>>%VaultSettings%
	ECHO Back-up Drive:		%BackUpDrive%>>%VaultSettings%
	ECHO Vault Location:		%VaultLocation%>>%VaultSettings%
	ECHO Copy back-up to NAS?:	%CopyToNAS%>>%VaultSettings% 
	ECHO NAS Path:		%NASPath%>>%VaultSettings%
	ECHO Autodesk Install:	%AutodeskInstallLocation%>>%VaultSettings%
	ECHO Vault Name:		%Vault%>>%VaultSettings%
	ECHO Company Name:		%CompanyName%>>%VaultSettings%
	ECHO Install Notepad++?:	%InstallNotepadPlus%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Vault Authentication and Backup settings ==============================   >>%VaultSettings% 
	ECHO Windows Authentication Enabled?:	%WindowsAuthentication%>>%VaultSettings%
	ECHO Vault User for Back-up:			%BackupUser%>>%VaultSettings%
	ECHO Vault Password for Back-up:		%BackupPassword%>>%VaultSettings%
	ECHO Validate Backup?:			%ValidateBackup%>>%VaultSettings%
	ECHO Backup Standard Content Center?:	%BackupStandardContentCenter%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Extra fucntions ==============================   >>%VaultSettings%
	ECHO Run Defragmentation?:			%RunDefragmentation%>>%VaultSettings%
	ECHO Run B2BMigration?:			%RunB2BMigration%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Backup Scheduled ==============================   >>%VaultSettings%
	ECHO Full Back-ups runs on months:		%FullBackUpOnMonth% >>%VaultSettings%
	ECHO Incremental Back-ups runs on months:	%IncrementalBackUpOnMonth% >>%VaultSettings%
	ECHO Full Back-ups runs on weeks:		%FullBackUpOnWeek% >>%VaultSettings%
	ECHO Incremental Back-ups runs on weeks:	%IncrementalBackUpOnWeek% >>%VaultSettings%
	ECHO Full Back-ups runs on days:		%FullBackUpOnDay% >>%VaultSettings%
	ECHO Incremental Back-ups runs on days:	%IncrementalBackUpOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO Defragment runs on months:		%DefragmentOnMonth% >>%VaultSettings%
	ECHO Defragment runs on weeks:		%DefragmentOnWeek% >>%VaultSettings%
	ECHO Defragment runs on days:		%DefragmentOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO B2BMigration runs on months:		%B2BMigrationOnMonth% >>%VaultSettings%
	ECHO B2BMigration runs on weeks:		%B2BMigrationOnWeek% >>%VaultSettings%
	ECHO B2BMigration runs on days:		%B2BMigrationOnDay% >>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== PushOver Notifications ==============================   >>%VaultSettings% 
	ECHO Enable PushOver?:			%EnablePushOver%>>%VaultSettings%
	ECHO PushOver Token:				%PushOverToken%>>%VaultSettings%
	ECHO PushOver User:				%PushOverUser%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Telegram Notifications ==============================   >>%VaultSettings% 
	ECHO Enable Telegram?:			%EnableTelegram%>>%VaultSettings%
	ECHO Telegram Token:				%TelegramToken%>>%VaultSettings%
	ECHO Telegram ChatID:			%TelegramChatID%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Email Notifications ==============================   >>%VaultSettings% 
	ECHO Enable Mail?:				%EnableMail%>>%VaultSettings%
	ECHO SwithMail.exe location:			%SwithMail%>>%VaultSettings%
	ECHO Outgoing mail server:			%ExchSvr%>>%VaultSettings%
	ECHO Server Port:				%SrvPort%>>%VaultSettings%
	ECHO Use SSL?:				%UseSSL%>>%VaultSettings%
	ECHO Outgoing mail user:			%SvrUser%>>%VaultSettings%
	ECHO Outgoing mail password:			%SvrPass%>>%VaultSettings%
	ECHO EMail From:				%EMailFrom%>>%VaultSettings%
	ECHO Email to when back-up successfull:	%EmailToSuccess%>>%VaultSettings%
	ECHO Email to when back-up failed:		%EmailToFail%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== System info ==============================   >>%VaultSettings%
	for /f "tokens=1-3" %%a in ('WMIC LOGICALDISK GET FreeSpace^,Name^,Size ^|FINDSTR /I /V "Name"') do @echo wsh.echo "Drive info %%b		" ^& "free=" ^& FormatNumber^(cdbl^(%%a^)/1024/1024/1024, 2^)^& " GiB"^& " size=" ^& FormatNumber^(cdbl^(%%c^)/1024/1024/1024, 2^)^& " GiB" > %temp%\tmp.vbs & @if not "%%c"=="" @echo & @cscript //nologo %temp%\tmp.vbs>>%VaultSettings% & del %temp%\tmp.vbs
	ECHO IP Address:		%ipAddress%>>%VaultSettings%
	ECHO MAC Address:		%macAddress%>>%VaultSettings%
	ECHO Host Name:		%HostName%>>%VaultSettings%
	ECHO CPU Type:		%cpu%(%cores:~0,2% Cores)>>%VaultSettings%
	ECHO.>>%VaultSettings%
	systeminfo>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== SQL info ==============================   >>%VaultSettings%
	sqlcmd -S %HostName%\AUTODESKVAULT -E -Q "SELECT @@VERSION">>%VaultSettings%
	sqlcmd -S 2021_ADMS_SVR\AUTODESKVAULT -U sa -P AutodeskVault@26200 -Q "SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [CPU Threads],cpu_count/hyperthread_ratio AS [Physical CPU Count],physical_memory_kb/1024 AS [Physical Memory in MB] from sys.dm_os_sys_info">>%VaultSettings%

	(
		exit /b
	)

:SettingsMissing
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:.
::2:	:: Info: https://help.autodesk.com/view/VAULT/2021/ENU/?guid=GUID-7FD9DAD8-0104-46FA-BCE7-11259FAB4235
::2:	:: Switches: https://knowledge.autodesk.com/support/vault-products/learn-explore/caas/CloudHelp/cloudhelp/2018/ENU/Vault-Admin/files/GUID-56F358D7-C47B-4B6A-95CB-F402D6F2C7F9-htm.html
::2:	:: Notepad++ is the preferend editor: https://notepad-plus-plus.org/downloads/"
::2:.
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:.
::2:	:: For Yes/No options use "Yes" or "No" (without quotes, case sensitive!)
::2:	:: Note that trailing spaces will break the script!!! So use "C:" NOT "C: "!!!
::2:.
::2:	:: Main settings
::2:	SET MainDrive=C:
::2:	SET BackUpDrive=C:
::2:	SET VaultLocation=C:\ADMS
::2:	SET CopyToNAS=No
::2:	SET NASPath=\\NAS\somewhere
::2:	SET AutodeskInstallLocation=C:\Program Files\Autodesk
::2:	SET Vault=Vault
::2:	SET CompanyName=Your Company Name
::2:	SET InstallNotepadPlus=No
::2:.
::2:	:: Vault Authentication and Backup settings
::2:	SET WindowsAuthentication=No
::2:	SET BackupUser=backup
::2:	SET BackupPassword=backup
::2:	SET ValidateBackup=No
::2:	SET BackupStandardContentCenter=No
::2:.
::2:	:: Extra fucntions
::2:	SET RunDefragmentation=No
::2:	SET RunB2BMigration=No
::2:.
::2:	::===== SCHEDULE =====
::2:	:: Day of week. 1 = monday, 7 = sunday
::2:	:: Week of Month. 1 to 5
::2:	:: Month. 1 = Januari, 12 = December
::2:.
::2:	:: Settings bellow wil create a full backup every saturday. All other days an incremental backup will be made.
::2:	SET FullBackUpOnMonth=1,2,4,5,6,7,8,9,10,11,12
::2:	SET IncrementalBackUpOnMonth=1,2,4,5,6,7,8,9,10,11,12
::2:	SET FullBackUpOnWeek=1,2,3,4,5,6
::2:	SET IncrementalBackUpOnWeek=1,2,3,4,5,6
::2:	SET FullBackUpOnDay=6
::2:	SET IncrementalBackUpOnDay=1,2,3,4,5,7
::2:.
::2:	SET DefragmentOnMonth=1,2,4,5,6,7,8,9,10,11,12
::2:	SET DefragmentOnWeek=1,2,3,4,5,6
::2:	SET DefragmentOnDay=6
::2:.
::2:	SET B2BMigrationOnMonth=1,2,4,5,6,7,8,9,10,11,12
::2:	SET B2BMigrationOnWeek=1,2,3,4,5,6
::2:	SET B2BMigrationOnDay=6
::2:.
::2:	::===== NOTIFICATIONS =====
::2:.
::2:	:: PushOver Notification settings
::2:	:: Setup PushOver: https://pushover.net/
::2:	SET EnablePushOver=No
::2:	SET PushOverToken=123456
::2:	SET PushOverUser=123456
::2:.
::2:	:: Telegram Notification settings
::2:	:: Create TelegramBot: https://core.telegram.org/bots#6-botfather 
::2:	:: Got to to get chatID: https://api.telegram.org/bot<TelegramToken>/getupdates
::2:	SET EnableTelegram=No
::2:	SET TelegramToken=123456
::2:	SET TelegramChatID=123456
::2:.
::2:	:: Email settings
::2:	SET EnableMail=No
::2:	SET SwithMail=%CD%\SwithMail.exe
::2:	SET ExchSvr=smtp.domain.com
::2:	SET SrvPort=587
::2:	SET UseSSL=Yes
::2:	SET SvrUser=USER
::2:	SET SvrPass=PASSWORD
::2:	SET EMailFrom=from@domain.com
::2:	SET EmailToSuccess=succes@domain.com
::2:	SET EmailToFail=fail@domain.com
::2:.
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
	
	FOR /f "delims=::2: tokens=*" %%A IN ('findstr /b ::2: "%~f0"') DO @ECHO%%A>>%BackupSettings%
	
	(
		exit /b
	)	
	
:Updater
	@echo off
	:: INPUT THE LOCAL VERSION HERE (replace local's "1.0") also replace link with your own.
	set local=%scriptversion%
	set localtwo=%local%
	set updatelink=https://raw.githubusercontent.com/Womabre/vault-backup-script/master/version.bat
	set downloadlink=https://raw.githubusercontent.com/Womabre/vault-backup-script/master/VaultBackup.bat
	goto :updater-check
	:: Text like these are batch file comments, and will not affect the code.
	:: If you're new to batch please follow these carefully.

	:: the CHECK parameter checks for existing version.bat files and deletes it.
	:updater-check
		IF EXIST %CD%\version.bat DEL /Q %CD%\version.bat
		goto :updater-download
	:: this is the main download process.
	:: be sure download.exe is present in the directory where update.bat runs.
	:: be sure to add " set local=2.0 " in your remote link.
	:updater-download
		bitsadmin.exe /transfer "Download" %updatelink% %CD%\version.bat
		CALL version.bat
		goto updater-check-2

	:: updater-check-2 is where it checks if your remote matches with your local.
	:updater-check-2
		IF "%local%"=="%localtwo%" goto :updater-no
		IF NOT "%local%"=="%localtwo%" goto :updater-yes

	:updater-no
		DEL /Q %CD%\version.bat
		exit /b
		
	:updater-yes
		DEL /Q %CD%\version.bat
		bitsadmin.exe /transfer "Download" %downloadlink% %CD%\VaultBackup.bat
		exit /b



:QUIT
EXIT
