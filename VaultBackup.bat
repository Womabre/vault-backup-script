:: BACKUP SCRIPT AUTODESK VAULT
:: Contact: wouterbreedveld@cadac.com

:: Version 1.0.0 - Original version created by Wouter Breedveld, Cadac Group B.V., 22-06-2020

:: Version 1.0.1 - By Wouter Breedveld, Cadac Group B.V., 26-06-2020
::					- Fixes ADMS path for Vault 2020 and earlier.
::					- Added PushOver support
::					- Added email support Source: https://www.tbare.com/software/swithmail/

:: Version 1.0.2 - By Wouter Breedveld, Cadac Group B.V., 30-06-2020
::					- Added Telegram support
::					- Added settings and info file export
::					- Added external settings file (BackupSettings.bat)

:: Version 1.0.3 - By Wouter Breedveld, Cadac Group B.V., 30-06-2020
::					- Added Auto-update
::					- Added Windows Notifications

:: Version 1.0.4 - By Wouter Breedveld, Cadac Group B.V., 01-07-2020
::					- Fixed log patch quotes
::					- Changed location from ADMSBackup to ADMS\Backup
::					- Added error notification if Defrag/B2BMigrate/SQLMaintenance failes
::					- Added notification test script creation.

:: Version 1.0.5 - By Wouter Breedveld, Cadac Group B.V., 02-07-2020
::					- Added MaintenanceSolution.sql Source: https://ola.hallengren.com/
::					- Added System Info export to NFO file.
::					- Added Validation Schedule
::					- Added detection to create a full backup when new Vault or library was added.

:: Version 1.0.6 - By Wouter Breedveld, Cadac Group B.V., 03-07-2020
::					- Defragmentation now runs on all Vaults selected under SET Vault=
::					- Automatic download of SwitchMail when it doesn't exist. https://www.tbare.com/software/swithmail/

:: Version 1.0.7 - By Wouter Breedveld, Cadac Group B.V., 07-07-2020
::					- Small bug fixes in logging.
::					- Added Recovery mode check for KnowledgeVaultMaster. Set to SIMPLE.

:: Version 1.0.8 - By Wouter Breedveld, Cadac Group B.V., 08-07-2020
::					- Updated switches link in BackupSettings.bat

:: Version 1.0.9 - By Wouter Breedveld, Cadac Group B.V., 22-07-2020
::					- Fix. No incremental backup when Vault Workgroup or Basic is installed.
::					- Added option to disable Automatic Updates.
::					- Added option to change the ADMS Path.

:: Version 1.0.10 - By Wouter Breedveld, Cadac Group B.V., 24-07-2020
::					- Added comments in BackupSettings.bat

:: Version 1.0.11 - By Wouter Breedveld, Cadac Group B.V., 11-08-2020
::					- Added SQL Credential type choise
::                  - Added notification to event log.

:: Version 1.0.12 - By Wouter Breedveld, Cadac Group B.V., 14-08-2020
::					- SQL System databases only get backedup when a Vault backup is scheduled.
::					- SQL validation only runs when a Vault backup is scheduled.
::					- Fixed email not being sent when no backup was created.
::					- Corrected some typos.
::					- Added option to send logs in the email body or as attachment.

:: Version 1.0.13 - By Wouter Breedveld, Cadac Group B.V., 17-08-2020
::					- Fixed CopyToNAS errorlevel.
::					- Added mount share as drive for CopyToNAS
::					- Fixed DayOfWeek (Sunday is 0, not 1)

:: Version 1.0.14 - By Wouter Breedveld, Cadac Group B.V., 18-08-2020
::					- Added backup to VHD Drive. (This is the new default)

:: Version 1.0.15 - By Wouter Breedveld, Cadac Group B.V., 05-09-2020
::					- Fixed incorrect calc of foldersize.

:: Version 1.0.16 - By Wouter Breedveld, Cadac Group B.V., 07-09-2020
::					- Added date to timestamp in log.

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
ECHO Please wait...
for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Host Name"') do set host==%%b
set HostName=%host:~2%
SET scriptversion=1.0.16
SET "SwithMail=%CD%\SwithMail.exe"
SET BackupSettings=BackupSettings.bat

:: Check admin
call :BatchGotAdmin

:: Check curl
call :checkCURL

:: Check for update
IF "%AutomaticUpdate%"=="Yes" (
	call :Updater
)

:: Import Settings
IF NOT EXIST "BackupSettings.bat" (
	echo Settings file not found! Creating...
	CALL :SettingsMissing
	echo Settings file created. Edit settings to your preference and then run this script again.
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
FOR /F "tokens=* delims=0" %%A IN ("%DD%") DO SET DayStart=%%A
IF "%DayStart%"=="" SET DayStart=0

:: Console Log
SET "LogLocation=%BackupRootPath%\Backup\Logs"
SET ScriptLogFolder="%LogLocation%\Script"
IF NOT EXIST %ScriptLogFolder% (mkdir %ScriptLogFolder%)
SET ScriptLog="%LogLocation%\Script\ScriptLog !fullstampstart!.txt"
BREAK>%ScriptLog%
SET VerboseLogFolder="%LogLocation%\VerboseLog"
IF NOT EXIST %VerboseLogFolder% (mkdir %VerboseLogFolder%)
SET VerboseLog="%LogLocation%\VerboseLog\VerboseLog !fullstampstart!.txt"
BREAK>%VerboseLog%
:: Mount NAS as drive
if "%CopyToNAS%"=="Yes" (
	net use %NASPath% %NASLocation% /user:%NASUser% %NASPassword%
)

if "%InstallNotepadPlus%"=="Yes" (
	call :InstallNotepad
)

call :Initilization
call :DisableQuickedit
call :Authentication
call :BackupOptions
call :getVaultVersion VaultVersion VaultType
if %VaultVersion% LEQ 2020 (
	SET ADSKDM="%AutodeskInstallLocation%\ADMS %VaultType% %VaultVersion%\ADMS Console\Connectivity.ADMSConsole.exe"
	SET WebConfig="%AutodeskInstallLocation%\ADMS %VaultType% %VaultVersion%\Server\Web\Services\web.config"
) ELSE (
	SET ADSKDM="%AutodeskInstallLocation%\Vault Server %VaultVersion%\ADMS Console\Connectivity.ADMSConsole.exe"
	SET WebConfig="%AutodeskInstallLocation%\Vault Server %VaultVersion%\Server\Web\Services\web.config"
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
ECHO %White%Starting operations !fullstampstart! & ECHO Starting operations !fullstampstart!>>%ScriptLog%
ECHO %Red%============================================================================================================================================================
ECHO %White%

call :getDiskspace freeMainDrive sizeMainDrive MainDrive
call :getDiskspace freeBackUpDrive sizeBackUpDrive BackUpDrive

if "%UseSSL%"=="Yes" (
	SET SSL=/SSL
) else (
	SET SSL=
)

:: Create Notifications Test Script
IF NOT EXIST "NotificationsTest.bat" (
	call :getTime now & ECHO [!now!] - Notifications Test Script does not exist. Creating... & ECHO [!now!] - Notifications Test Script does not exist. Creating...>>%ScriptLog%
	CALL :CreateNotificationTestScript
)

SET NASbackup="%NASPath%\Backup\Scheduled Backup\Vault"
SET BackUpNew="%BackupRootPath%\Backup\Scheduled Backup\Vault"
SET BackUpSQL='%BackupRootPath%\Backup\Scheduled Backup\Vault\SQL System Databases'
SET BackUpSQL2="%BackupRootPath%\Backup\Scheduled Backup\Vault\SQL System Databases"
SET BackUpOld="%BackupRootPath%\Backup\Scheduled Backup\Vault Old"

:: SET up some variables
call :getTime now & ECHO %White%[!now!] - Setting the required variables & ECHO [!now!] - Setting the required variables>>%ScriptLog%

SET LogFolder=%LogLocation%\Backups
SET Log="%LogFolder%\BackupLog !fullstampstart!.txt"

SET VaultSettingsFolder=%LogLocation%
SET VaultSettings="%VaultSettingsFolder%\Vault %VaultType% %VaultVersion% Settings %CompanyName%.txt"

SET SysInfoFolder=%LogLocation%
SET SysInfo="%SysInfoFolder%\%CompanyName% - %HostName% - System Information.NFO"

SET DefragLogFolder=%LogLocation%\Defragmentations
SET DefragLog="%DefragLogFolder%\DefragLog !fullstampstart!.txt"

SET ValidateLogFolder=%LogLocation%\Validations
SET ValidateLog="%ValidateLogFolder%\ValidateLog !fullstampstart!.txt"

SET B2BMigrateLogFolder=%LogLocation%\B2BMigrations
SET B2BMigrateLog="%B2BMigrateLogFolder%\B2BMigrationLog !fullstampstart!.txt"

SET SQLMaintenanceLogFolder=%LogLocation%\SQLMaintenance
SET SQLMaintenanceLog="%SQLMaintenanceLogFolder%\SQLMaintenanceLog !fullstampstart!.txt"

SET SQLIntegrityCheckLogFolder=%LogLocation%\SQLIntegrityCheck
SET SQLIntegrityCheckLog="%SQLIntegrityCheckLogFolder%\SQLIntegrityCheckLog !fullstampstart!.txt"

SET SQLBackupLogFolder=%LogLocation%\SQLBackup
SET SQLBackupLog="%SQLBackupLogFolder%\SQLBackupLog !fullstampstart!.txt"

SET CopyToNASLogFolder=%LogLocation%\CopyToNAS
SET CopyToNASLog="%CopyToNASLogFolder%\CopyToNASLog !fullstampstart!.txt"

IF "%CopyToNAS%"=="Yes" (
	IF not exist %NASbackup% (mkdir %NASbackup%)
)
IF not exist %BackUpNew% (mkdir %BackUpNew%)

:: Download SQL Maintenance Solution
IF not exist "%CD%\MaintenanceSolution.sql" (
	call :getTime now & ECHO [!now!] - MaintenanceSolution.sql does not exist. Downloading... & ECHO [!now!] - MaintenanceSolution.sql does not exist. Downloading...>>%ScriptLog%
	curl https://raw.githubusercontent.com/olahallengren/sql-server-maintenance-solution/master/MaintenanceSolution.sql --output "%CD%\MaintenanceSolution.sql" >>%VerboseLog% 2>nul
	sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -i MaintenanceSolution.sql >>%VerboseLog% 2>nul
)

:: Download SwithMail
IF not exist %SwithMail% (
	call :getTime now & ECHO [!now!] - SwithMail.exe does not exist. Downloading version 2.2.4.0... & ECHO [!now!] - SwithMail.exe does not exist. Downloading version 2.2.4.0...>>%ScriptLog%
	curl "https://raw.githubusercontent.com/Womabre/vault-backup-script/master/SwithMail.exe" --output "%CD%\SwithMail.exe" >>%VerboseLog% 2>nul
	curl "https://raw.githubusercontent.com/Womabre/vault-backup-script/master/SwithMailreadme.txt" --output "%CD%\SwithMail Readme.txt" >>%VerboseLog% 2>nul
)

:: Export sys info
if not exist %SysInfo% (
	call :getTime now & ECHO [!now!] - System info file does not exist. Exporting... & ECHO [!now!] - System info file does not exist. Exporting...>>%ScriptLog%
	msinfo32 /nfo %SysInfo% >>%VerboseLog% 2>nul
)

:: Check recovery mode KnowledgeVaultMaster
sqlcmd -S %HostName%\AUTODESKVAULT %SQLAuth% -Q "SELECT DATABASEPROPERTYEX('KnowledgeVaultMaster', 'Recovery');" > RecoveryMode.txt
findstr /m /C:"SIMPLE" RecoveryMode.txt >>%VerboseLog% 2>nul
IF %errorlevel% EQU 1 (
	call :getTime now & ECHO [!now!] - Recovery mode of KnowledgeVaultMaster not set to SIMPLE. Changing... & ECHO [!now!] - Recovery mode of KnowledgeVaultMaster not set to SIMPLE. Changing...>>%ScriptLog%
	sqlcmd -S %HostName%\AUTODESKVAULT %SQLAuth% -Q "ALTER DATABASE KnowledgeVaultMaster SET RECOVERY SIMPLE"
)
del RecoveryMode.txt

if exist %VaultSettings% ( del %VaultSettings% )
call :ExportSettings >>%VerboseLog% 2>nul
call :SetSchedule
call :KillADMS

:: Set time free space
FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
SET "fullstampfreespace=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
SET SubjectFail="WARNING. Vault backup error. - %fullstampfreespace%"
SET BodyFail="Hi,<br /^><br /^>Unfortunatly the Vault backup failed<br /^>There is not enough space on the %BackUpDrive% drive<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault %VaultType% %VaultVersion% Server<br /^><br /^>Remember to eat healthy, get enough sleep and backup your computer"

IF NOT "%BackupType%"=="None" (
	:: Check if enough free space is available
	call :getTime now & ECHO [!now!] - Checking if there is enough free space on %BackUpDrive% & ECHO [!now!] - Checking if there is enough free space on %BackUpDrive%>>%ScriptLog%
	CALL :folderSize size "%VaultLocation%" "/S"
)

SET /A SizeGB5=%sizeGb%+5

IF NOT "%BackupType%"=="None" (
	SET /A VHDDriveSize=%sizeMb%+%sizeMb%+10000

	IF %sizeGb5% GEQ %freeBackUpDrive% (
		call :getTime now & ECHO [!now!] - %Red%Failed. Not enough free space on %BackUpDrive%%White% & ECHO [!now!] - Failed. Not enough free space on %BackUpDrive%>>%ScriptLog%
		if "%EnableMail%"=="Yes" (
			"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /b %BodyFail% /html
		)
		call :SendNotification "%CompanyName% Vault Backup Failed! Not enough free space." "Autodesk Vault %VaultType% %VaultVersion%" "Error"
		call :getTime now & ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
		timeout 600
		GOTO :QUIT
	) ELSE (
		call :getTime now & ECHO [!now!] - %Green%Enough free space for backup available on %BackUpDrive%%White% & ECHO [!now!] - Enough free space for backup available on %BackUpDrive%>>%ScriptLog%
	)
)

IF NOT "%BackupType%"=="None" (
	:: Check if there is a backup present
	call :getTime now & ECHO [!now!] - Checking if a current backup is present & ECHO [!now!] - Checking if a current backup is present>>%ScriptLog%
	setlocal enabledelayedexpansion
	for /f %%a in ('dir /b /s %BackUpNew%^|find /c /v "" ') do SET count=%%a
	IF "!count!"=="0" (
		SET BackupType=Full
		call :getTime now & ECHO [!now!] - No backup is present. Creating Full backup & ECHO [!now!] - No backup is present. Creating Full backup>>%ScriptLog%
	) else (
		call :getTime now & ECHO [!now!] - A current backup is present. & ECHO [!now!] - A current backup is present.>>%ScriptLog%
	)
)

IF NOT "%BackupType%"=="None" (
	:: Check if Vault Pro. If not Vault Pro no Incremental Backup.
	setlocal enabledelayedexpansion
	IF NOT "%VaultType%"=="Professional" (
		SET BackupType=Full
		call :getTime now & ECHO [!now!] - Vault %VaultType% is installed. Incremental backup is not supported. Creating full backup. & ECHO [!now!] - Vault %VaultType% is installed. Incremental backup is not supported. Creating full backup.>>%ScriptLog%
	)
)

:SQLIntegrityCheck
	IF "%BackupType%"=="None" (
		call :getTime now & ECHO [!now!] - Not running SQL Integrity Check at this moment & ECHO [!now!] - Not running SQL Integrity Check at this moment>>%ScriptLog%
		SET "fullstampendSQLIntergity=Didn't run SQL Integrity Check
		goto :Backup
	)
	IF NOT "%ServerConfig%"=="VaultOnly" (
		call :getTime now & ECHO [!now!] - Running SQL Integrity Check & ECHO [!now!] - Running SQL Integrity Check>>%ScriptLog%
		IF NOT EXIST %SQLIntegrityCheckLogFolder% (mkdir %SQLIntegrityCheckLogFolder%)
		BREAK>%SQLIntegrityCheckLog%
		for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Host Name"') do set host==%%b
		set HostName=%host:~2%
		sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "EXECUTE dbo.DatabaseIntegrityCheck @Databases = 'USER_DATABASES'" -b -o %SQLIntegrityCheckLog% >>%VerboseLog% 2>nul
		sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "EXECUTE dbo.DatabaseIntegrityCheck @Databases = 'SYSTEM_DATABASES'" -b -o %SQLIntegrityCheckLog% >>%VerboseLog% 2>nul
		:: Set time SQL Maintenance finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampendSQLIntergity=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	)
	call :reset_error
	findstr /m /C:"%CheckStringSQL%" %SQLIntegrityCheckLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="VaultOnly" (
		IF %errorlevel% EQU 1 (
			call :getTime now & ECHO [!now!] - %Green%SQL Integrity finished successfully%White% & ECHO [!now!] - SQL Integrity finished successfully>>%ScriptLog%
			GOTO :Backup
		) else (
			SET successbool=0
			SET fullstampendSQLIntergity=SQL Integrity has errors. Please check logfile. NOT CREATING A BACKUP
			call :getTime now & ECHO [!now!] - %Red%SQL Integrity has errors. Please check logfile. NOT CREATING A BACKUP%White% & ECHO [!now!] - SQL Integrity has errors. Please check logfile. NOT CREATING A BACKUP>>%ScriptLog%
			set "End=%TIME%"
			GOTO :Close
		)
	)

:Backup
:: Do a full or incremental backup
IF "%BackupType%"=="Full" (
	call :ResetServices
	call :getTime now & ECHO [!now!] - Creating a new Full backup and deleting the old if successful & ECHO [!now!] - Creating a new Full backup and deleting the old if successful>>%ScriptLog%
	IF exist %BackUpNew% ( MOVE /Y %BackUpNew% %BackUpOld% >>%VerboseLog% 2>nul )
	IF not exist %BackUpNew% (mkdir %BackUpNew%)
	call :getTime now & ECHO [!now!] - Now creating full backup on local machine & ECHO [!now!] - Now creating full backup on local machine>>%ScriptLog%
	IF "%UseVHDforBackup%"=="Yes" (	
		ECHO create vdisk file="%BackupRootPath%\Backup\Scheduled Backup\Vault\VaultBackup.vhdx" type=expandable maximum=%VHDDriveSize%>>%AttachScript%
		ECHO select vdisk file="%BackupRootPath%\Backup\Scheduled Backup\Vault\VaultBackup.vhdx">>%AttachScript%
		ECHO attach vdisk>>%AttachScript%
		ECHO convert gpt>>%AttachScript%
		ECHO create partition primary>>%AttachScript%
		ECHO format fs=ntfs label="VaultBackup" quick>>%AttachScript%
		ECHO assign letter=%VHDDrive%>>%AttachScript%
		ECHO exit>>%AttachScript%
		diskpart /s "%AttachScript%" >>%VerboseLog% 2>nul
		del %AttachScript%
		%ADSKDM% -Obackup -B"%VHDDrive%\" %VaultAuth%%VaultOpt% -S -L%Log% >>%VerboseLog% 2>nul
	) ELSE (
		%ADSKDM% -Obackup -B%BackUpNew% %VaultAuth%%VaultOpt% -S -L%Log% >>%VerboseLog% 2>nul
	)
	:: Set time backup finished
	FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
	SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
	SET "fullstampendbackup=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	:: Copy WebConfig
	call :getTime now & ECHO [!now!] - Backing up Web.Config & ECHO [!now!] - Backing up Web.Config>>%ScriptLog%
	IF "%UseVHDforBackup%"=="Yes" (
		COPY /Y %WebConfig% "%VHDDrive%\Web.Config" >>%VerboseLog% 2>nul
	) ELSE (
		COPY /Y %WebConfig% %BackUpNew%\Web.Config >>%VerboseLog% 2>nul
	)
	call :getTime now & ECHO [!now!] - Done backing up Web.Config & ECHO [!now!] - Done backing up Web.Config>>%ScriptLog%
	GOTO :Check1
)
IF "%BackupType%"=="Incremental" (
	call :getTime now & ECHO [!now!] - Now creating incremental backup on local machine & ECHO [!now!] - Now creating incremental backup on local machine>>%ScriptLog%
	IF "%UseVHDforBackup%"=="Yes" (
		SET AttachScript="%CD%\AttachScript.txt"
		ECHO select vdisk file="%BackupRootPath%\Backup\Scheduled Backup\Vault\VaultBackup.vhdx">>%AttachScript%
		ECHO attach vdisk>>%AttachScript%
		ECHO assign letter=%VHDDrive%>>%AttachScript%
		ECHO exit>>%AttachScript%
		diskpart /s "%AttachScript%" >>%VerboseLog% 2>nul
		del %AttachScript%
		%ADSKDM% -Obackup -B"%VHDDrive%\" %VaultAuth%%VaultOpt% -INC -S -L%Log% >>%VerboseLog% 2>nul
	) ELSE (
		%ADSKDM% -Obackup -B%BackUpNew% %VaultAuth%%VaultOpt% -INC -S -L%Log% >>%VerboseLog% 2>nul
	)
	:: Set time backup finished
	FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
	SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
	SET "fullstampendbackup=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	GOTO :Check1
)
IF "%BackupType%"=="None" (
	call :getTime now & ECHO [!now!] - Not creating a backup at this moment & ECHO [!now!] - Not creating a backup at this moment>>%ScriptLog%
	SET fullstampendbackup=Didn't backup the database
	SET successbool=1
	goto :SQLBackup
)

:: Check if backup is successful
:Check1
call :reset_error
findstr /m /C:"%CheckString%" %Log% >>%VerboseLog% 2>nul
IF %errorlevel% EQU 0 (
	SET successbool=1
	call :getTime now & ECHO [!now!] - %Green%Successfully finished backup operations%White% & ECHO [!now!] - Successfully finished backup operations>>%ScriptLog%
	GOTO :SQLBackup
) else (
	GOTO :Check2
)

:Check2
call :reset_error
findstr /m /C:"%CheckString2%" %Log% >>%VerboseLog% 2>nul
IF %errorlevel% EQU 0 (
	SET successbool=1
	call :getTime now & ECHO [!now!] - %Green%Successfully finished backup operations%White% & ECHO [!now!] - Successfully finished backup operations>>%ScriptLog%
	GOTO :SQLBackup
) else (
	GOTO :Check3
)

:Check3
call :reset_error
findstr /m /C:"%CheckString3%" %Log% >>%VerboseLog% 2>nul
IF %errorlevel% EQU 0 (
	call :getTime now & ECHO [!now!] - %Red%Failed creating incremental backup. A Vault or Library has been added or removed. Creating full backup.%White% & ECHO [!now!] - Failed creating incremental backup. A Vault or Library has been added or removed. Creating full backup.>>%ScriptLog%
	SET BackupType=Full
	GOTO :Backup
) else (
	SET successbool=0
	GOTO :Close
)

:SQLBackup
	IF "%BackupType%"=="None" (
		call :getTime now & ECHO [!now!] - Not creating a SQL backup at this moment & ECHO [!now!] - Not creating a SQL backup at this moment>>%ScriptLog%
		SET "fullstampendSQLbackup=Didn't backup SQL
		goto :Validation
	)
	IF NOT "%ServerConfig%"=="VaultOnly" (
		call :getTime now & ECHO [!now!] - Running SQL Backup. Backup system databases. & ECHO [!now!] - Running SQL Backup. Backup system databases.>>%ScriptLog%
		IF NOT EXIST %SQLBackupLogFolder% (mkdir %SQLBackupLogFolder%)
		BREAK>%SQLBackupLog%	
		for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Host Name"') do set host==%%b
		set HostName=%host:~2%
		IF "%UseVHDforBackup%"=="Yes" (
			IF not exist "%VHDDrive%\SQL System Databases" (mkdir "%VHDDrive%\SQL System Databases")
			sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "EXECUTE dbo.DatabaseBackup @Databases = 'SYSTEM_DATABASES', @BackupType = 'FULL', @Directory = '%VHDDrive%\SQL System Databases'" -b -o %SQLBackupLog% >>%VerboseLog% 2>nul
		) ELSE (
			IF not exist %BackUpSQL2% (mkdir %BackUpSQL2%)
			sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "EXECUTE dbo.DatabaseBackup @Databases = 'SYSTEM_DATABASES', @BackupType = 'FULL', @Directory = %BackUpSQL%" -b -o %SQLBackupLog% >>%VerboseLog% 2>nul
		)
		:: Set time SQL Maintenance finished
		FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
		SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
		SET "fullstampendSQLbackup=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
	)
	call :reset_error
	findstr /m /C:"%CheckStringSQL%" %SQLBackupLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="VaultOnly" (
		IF %errorlevel% EQU 1 (
			SET successbool=1
			call :getTime now & ECHO [!now!] - %Green%SQL backup finished successfully.%White% & ECHO [!now!] - SQL backup finished successfully.>>%ScriptLog%
			GOTO :Validation
		) else (
			SET successbool=2
			SET fullstampendSQLbackup=SQL backup has errors. Please check logfile.
			call :getTime now & ECHO [!now!] - %Red%SQL backup has errors. Please check logfile.%White% & ECHO [!now!] - SQL backup has errors. Please check logfile.>>%ScriptLog%
			GOTO :Validation
		)
	)

:Validation
	IF NOT "%ServerConfig%"=="SQLOnly" (
		IF %validationbool% EQU 1 (
			call :getTime now & ECHO [!now!] - Validating the Vault & ECHO [!now!] - Validating the Vault>>%ScriptLog%
			IF NOT EXIST %ValidateLogFolder% (mkdir %ValidateLogFolder%)
			BREAK>%ValidateLog%
			%ADSKDM% -Ovalidatefilestore %VaultAuth% -S -L%ValidateLog% >>%VerboseLog% 2>nul
			:: Set time Validation finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampendvalidate=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		) else (
			call :getTime now & ECHO [!now!] - Not validating the Vault at this time & ECHO [!now!] - Not validating the Vault at this time>>%ScriptLog%
			SET fullstampendvalidate=Didn't validate the database
			GOTO :Defragment
		)
	)
	call :reset_error
	findstr /m /C:"%CheckStringValidate%" %ValidateLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="SQLOnly" (
		IF %errorlevel% EQU 1 (
			SET successbool=1
			call :getTime now & ECHO [!now!] - %Green%Validation finished successfully.%White% & ECHO [!now!] - Validation finished successfully.>>%ScriptLog%
			GOTO :Defragment
		) else (
			SET successbool=2
			SET fullstampendvalidate=Validation has errors. Please check logfile.
			call :getTime now & ECHO [!now!] - %Red%Validation has errors. Please check logfile.%White% & ECHO [!now!] - Validation has errors. Please check logfile.>>%ScriptLog%
			GOTO :Defragment
		)
	)

:Defragment
	IF NOT "%ServerConfig%"=="SQLOnly" (
		IF %defragbool% EQU 1 (
			call :getTime now & ECHO [!now!] - Defragmenting the Vault & ECHO [!now!] - Defragmenting the Vault>>%ScriptLog%
			IF NOT EXIST %DefragLogFolder% (mkdir %DefragLogFolder%)
			BREAK>%DefragLog%
			for %%i in (%Vault%) do (
				%ADSKDM% -Odefragmentvault -N%%i %VaultAuth% -S -L%DefragLog% >>%VerboseLog% 2>nul
			)
			:: Set time Defrag finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampenddefrag=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		) else (
			call :getTime now & ECHO [!now!] - Not defragmenting the Vault at this time & ECHO [!now!] - Not defragmenting the Vault at this time>>%ScriptLog%
			SET fullstampenddefrag=Didn't defragment the database
			GOTO :B2BMigrate
		)
	)
	call :reset_error
	findstr /m /C:"%CheckStringDefrag%" %DefragLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="SQLOnly" (	
		IF %errorlevel% EQU 0 (
			SET successbool=1
			call :getTime now & ECHO [!now!] - %Green%Defragmentation finished successfully.%White% & ECHO [!now!] - Defragmentation finished successfully.>>%ScriptLog%
			GOTO :B2BMigrate
		) else (
			SET successbool=2
			SET fullstampenddefrag=Defragmentation has errors. Please check logfile.
			call :getTime now & ECHO [!now!] - %Red%Defragmentation has errors. Please check logfile.%White% & ECHO [!now!] - Defragmentation has errors. Please check logfile.>>%ScriptLog%
			GOTO :B2BMigrate
		)
	)

:B2BMigrate
	IF NOT "%ServerConfig%"=="SQLOnly" (
		IF %b2bbool% EQU 1 (
			call :getTime now & ECHO [!now!] - Running B2BMigration to improve performance & ECHO [!now!] - Running B2BMigration to improve performance>>%ScriptLog%
			IF NOT EXIST %B2BMigrateLogFolder% (mkdir %B2BMigrateLogFolder%)
			BREAK>%B2BMigrateLog%
			%ADSKDM% -Ob2bmigrate %VaultAuth% -S -L%B2BMigrateLog% >>%VerboseLog% 2>nul
			:: Set time B2BMigration finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampendB2B=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		) else (
			call :getTime now & ECHO [!now!] - Not running B2BMigration at this time & ECHO [!now!] - Not running B2BMigration at this time>>%ScriptLog%
			SET fullstampendB2B=Didn't run B2BMigration
			GOTO :SQLMaintenance
		)
	)
	call :reset_error
	findstr /m /C:"%CheckStringMigrate%" %B2BMigrateLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="SQLOnly" (
		IF %errorlevel% EQU 0 (
			SET successbool=1
			call :getTime now & ECHO [!now!] - %Green%B2B Maintenance finished successfully.%White% & ECHO [!now!] - B2B Maintenance finished successfully.>>%ScriptLog%
			GOTO :SQLMaintenance
		) else (
			SET successbool=2
			SET fullstampendB2B=B2B Maintenance has errors. Please check logfile.
			call :getTime now & ECHO [!now!] - %Red%B2B Maintenance has errors. Please check logfile.%White% & ECHO [!now!] - B2B Maintenance has errors. Please check logfile.>>%ScriptLog%
			GOTO :SQLMaintenance		
		)
	)

:SQLMaintenance
	IF NOT "%ServerConfig%"=="VaultOnly" (
		IF %sqlmaintbool% EQU 1 (
			call :getTime now & ECHO [!now!] - Running SQL Maintenance to improve performance & ECHO [!now!] - Running SQL Maintenance to improve performance>>%ScriptLog%
			IF NOT EXIST %SQLMaintenanceLogFolder% (mkdir %SQLMaintenanceLogFolder%)
			BREAK>%SQLMaintenanceLog%
			for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Host Name"') do set host==%%b
			set HostName=%host:~2%
			sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "EXECUTE dbo.IndexOptimize @Databases = 'USER_DATABASES'" -b -o %SQLMaintenanceLog% >>%VerboseLog% 2>nul
			:: Set time SQL Maintenance finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampendSQL=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
		) else (
			call :getTime now & ECHO [!now!] - Not running SQL Maintenance at this time & ECHO [!now!] - Not running SQL Maintenance at this time>>%ScriptLog%
			SET fullstampendSQL=Didn't run SQL Maintenance
			GOTO :CopyToNAS
		)
	)
	call :reset_error
	findstr /m /C:"%CheckStringSQL%" %SQLMaintenanceLog% >>%VerboseLog% 2>nul
	IF NOT "%ServerConfig%"=="VaultOnly" (
		IF %errorlevel% EQU 1 (
			SET successbool=1
			call :getTime now & ECHO [!now!] - %Green%SQL Maintenance finished successfully.%White% & ECHO [!now!] - SQL Maintenance finished successfully.>>%ScriptLog%
			GOTO :CopyToNAS
		) else (
			SET successbool=2
			SET fullstampendSQL=SQL Maintenance has errors. Please check logfile.
			call :getTime now & ECHO [!now!] - %Red%SQL Maintenance has errors. Please check logfile.%White% & ECHO [!now!] - SQL Maintenance has errors. Please check logfile.>>%ScriptLog%
			GOTO :CopyToNAS
		)
	)
	
:CopyToNAS
	IF "%UseVHDforBackup%"=="Yes" (
		ECHO select vdisk file="%BackupRootPath%\Backup\Scheduled Backup\Vault\VaultBackup.vhdx">>%DetachScript%
		ECHO detach vdisk>>%DetachScript%
		ECHO compact vdisk>>%DetachScript%
		ECHO exit>>%DetachScript%
		diskpart /s "%DetachScript%" >>%VerboseLog% 2>nul
		del %DetachScript%
	)
	IF "%BackupType%"=="Full" (
		IF "%CopyToNAS%"=="Yes" (
			IF NOT EXIST %CopyToNASLogFolder% (mkdir %CopyToNASLogFolder%)
			BREAK>%CopyToNASLog%
			call :getTime now & ECHO [!now!] - Deleting old backup on NAS & ECHO [!now!] - Deleting old backup on NAS>>%ScriptLog%
			RMDIR /S /Q %NASbackup%>>%CopyToNASLog%
			call :getTime now & ECHO [!now!] - Done deleting old backup on NAS & ECHO [!now!] - Done deleting old backup on NAS>>%ScriptLog%
			:: Set time Deletion NAS finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampenddelnas=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
			call :getTime now & ECHO [!now!] - Moving backup to NAS & ECHO [!now!] - Moving backup to NAS>>%ScriptLog%
			ROBOCOPY /E %BackUpNew% %NASbackup%>>%CopyToNASLog%
			call :getTime now & ECHO [!now!] - Done moving backup to NAS & ECHO [!now!] - Done moving backup to NAS>>%ScriptLog%
			:: Set time moving finished
			FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
			SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
			SET "fullstampendmove=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
			IF %errorlevel% LSS 8 (
				SET successbool=1
				call :getTime now & ECHO [!now!] - Deleting backup on local disk & ECHO [!now!] - Deleting backup on local disk>>%ScriptLog%
				RMDIR /S /Q %BackUpNew%>>%CopyToNASLog%
				call :getTime now & ECHO [!now!] - Done deleting backup on local disk & ECHO [!now!] - Done deleting backup on local disk>>%ScriptLog%
				:: Set time Deletion local finished
				FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
				SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
				SET "fullstampenddellocal=!YYYY!-!MM!-!DD! !HH!.!Min!.!Sec!"
			) ELSE (
				SET successbool=2
				call :getTime now & ECHO [!now!] - %Red%Moving backup to NAS failed%White% & ECHO [!now!] - Moving backup to NAS failed>>%ScriptLog%
				:: Set time Move failed
				FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
				SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"
				SET fullstampenddellocal=Failed moving the backup. Please check logfile.
			)
		) else (
			call :getTime now & ECHO [!now!] - Not copying to NAS at this time & ECHO [!now!] - Not copying to NAS at this time>>%ScriptLog%
			SET fullstampendmove=Didn't copy to NAS
			SET fullstampenddellocal=Didn't copy to NAS
			SET fullstampenddelnas=Didn't copy to NAS
			GOTO :DeleteLocal
		)
	) else (
		call :getTime now & ECHO [!now!] - Not copying to NAS at this time & ECHO [!now!] - Not copying to NAS at this time>>%ScriptLog%
		SET fullstampendmove=Didn't copy to NAS
		SET fullstampenddellocal=Didn't copy to NAS
		SET fullstampenddelnas=Didn't copy to NAS
		GOTO :DeleteLocal
	)
	
:DeleteLocal
	:: Try to delete old local backup
	IF exist %BackUpOld% (
		RMDIR /S /Q %BackUpOld%>>%ScriptLog%
	)

:Close
SET "End=%TIME%"
FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
SET "YY=%dt:~2,2%" & SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"

FOR /F "tokens=* delims=0" %%A IN ("%DD%") DO SET DayEnd=%%A
IF "%DayEnd%"=="" SET DayEnd=0

SET /A DayDiff=%DayEnd%-%DayStart%
call :timediff Elapsed Start End
SET "ElapsedTime=%DayDiff%:%Elapsed:~0,8%"

IF "%BackupType%"=="None" (
	SET SubjectSuccess="Vault operations successful"
) ELSE (
	SET SubjectSuccess="Vault backup successful - %fullstampendbackup%"
)
SET BodySuccess="Hi,<br /^><br /^>Attached is the log file of the Vault backup.<br /^>Operations started: %fullstampstart%<br /^>SQL Integrity Check finished: !fullstampendSQLIntergity!<br /^>Backup finished: !fullstampendbackup!<br /^>SQL backup finished: !fullstampendSQLbackup!<br /^>Validation finished: !fullstampendvalidate!<br /^>Defragmentation finished: !fullstampenddefrag!<br /^>B2BMigration finished: !fullstampendB2B!<br /^>SQLMaintenance finished: !fullstampendSQL!<br /^>Deleting old backup from NAS finished: !fullstampenddelnas!<br /^>Moving new backup to NAS finished: !fullstampendmove!<br /^>Deleting local backup finished: !fullstampenddellocal!<br /^>Duration: %ElapsedTime%<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault %VaultType% %VaultVersion% Server<br /^><br /^>Remember to eat healthy, get enough sleep and backup your computer"

SET SubjectFail="WARNING Vault backup has failed - %fullstampendbackup%"
SET BodyFail="Hi,<br /^><br /^>Unfortunatly the Vault backup has failed.<br /^>Attached is the log file of the Vault backup.<br /^>Backup started !fullstampstart!<br /^>SQL Integrity Check finished: !fullstampendSQLIntergity!<br /^>Backup finished !fullstampendbackup!<br /^>SQL backup finished: !fullstampendSQLbackup!<br /^>Duration: %ElapsedTime%<br /^><br /^>Kind Regards,<br /^><br /^>%CompanyName% Vault %VaultType% %VaultVersion% Server<br /^><br /^>Remember to eat healthy, get enough sleep and backup your computer"

SET SubjectError="WARNING Vault backup has errors - %fullstampendbackup%"

ECHO %BodySuccess%>>tempbodysuccess.txt
ECHO ^<br /^>^<br /^>>>tempbodysuccess.txt
ECHO %BodyFail%>>tempbodyfail.txt
ECHO ^<br /^>^<br /^>>>tempbodyfail.txt

set "line="
for /F "tokens=1* delims=:" %%a in ('findstr /N "^" %ScriptLog%') do (
	if not "%%~a" == "%n%" (
		echo(%%b^<br /^>
	) else (
		set line=%%b
		setlocal enableDelayedExpansion
		<nul set /P "=!line!"
		endlocal
	)
) >> "tempbodysuccess.txt"

set "line="
for /F "tokens=1* delims=:" %%a in ('findstr /N "^" %ScriptLog%') do (
	if not "%%~a" == "%n%" (
		echo(%%b^<br /^>
	) else (
		set line=%%b
		setlocal enableDelayedExpansion
		<nul set /P "=!line!"
		endlocal
	)
) >> "tempbodyfail.txt"

IF NOT "%BackupType%"=="None" (
	ECHO ^<br /^>^<br /^>>>tempbodysuccess.txt
	ECHO ^<br /^>^<br /^>>>tempbodyfail.txt
	set "line="
	for /F "tokens=1* delims=:" %%a in ('findstr /N "^" %Log%') do (
		if not "%%~a" == "%n%" (
			echo(%%b^<br /^>
		) else (
			set line=%%b
			setlocal enableDelayedExpansion
			<nul set /P "=!line!"
			endlocal
		)
	) >> "tempbodysuccess.txt"

	set "line="
	for /F "tokens=1* delims=:" %%a in ('findstr /N "^" %Log%') do (
		if not "%%~a" == "%n%" (
			echo(%%b^<br /^>
		) else (
			set line=%%b
			setlocal enableDelayedExpansion
			<nul set /P "=!line!"
			endlocal
		)
	) >> "tempbodyfail.txt"
)

IF %successbool% EQU 1 (
	set "End=%TIME%"
	call :timediff Elapsed Start End
	call :getTime now & ECHO [!now!] - %Green%Success%White% & ECHO [!now!] - Success>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Total Elapsed Time: !ElapsedTime! & ECHO [!now!] - Total Elapsed Time: !ElapsedTime!>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Sending logfile to emailaddress & ECHO [!now!] - Sending logfile to emailaddress>>%ScriptLog%
	IF "%BackupType%"=="None" (
		if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToSuccess%" /sub %SubjectSuccess% /a %ScriptLog% /b %BodySuccess% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToSuccess%" /sub %SubjectSuccess% /btxt "%CD%/tempbodysuccess.txt" /html
			)
		)
	) ELSE (
		if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToSuccess%" /sub %SubjectSuccess% /a %Log%^|%ScriptLog%% /b %BodySuccess% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToSuccess%" /sub %SubjectSuccess% /btxt "%CD%/tempbodysuccess.txt" /html
			)
		)
	)
	call :SendNotification "%CompanyName% Vault Backup Successful!" "Autodesk Vault %VaultType% %VaultVersion%" "Information"
	call :getTime now & ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	del tempbodysuccess.txt
	del tempbodyfail.txt
	timeout 600
	GOTO :QUIT
)

IF %successbool% EQU 0 (
	set "End=%TIME%"
	call :timediff Elapsed Start End
	call :getTime now & ECHO [!now!] - %Red%Failed%White% & ECHO [!now!] - Failed >>%ScriptLog%
	call :getTime now & ECHO [!now!] - Total Elapsed Time: !ElapsedTime! & ECHO [!now!] - Total Elapsed Time: !ElapsedTime!>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Sending logfile to emailaddress & ECHO [!now!] - Sending logfile to emailaddress>>%ScriptLog%
	IF "%BackupType%"=="None" (
		if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /a %ScriptLog% /b %BodyFail% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /btxt "%CD%/tempbodyfail.txt" /html
			)
		)
	) ELSE (
		if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /a %Log%^|%ScriptLog% /b %BodyFail% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectFail% /btxt "%CD%/tempbodyfail.txt" /html
			)
		)
	)
	call :SendNotification "%CompanyName% Vault Backup Failed!" "Autodesk Vault %VaultType% %VaultVersion%" "Error"
	call :getTime now &	ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	del tempbodysuccess.txt
	del tempbodyfail.txt
	timeout 600
	GOTO :QUIT
)

IF %successbool% EQU 2 (
	set "End=%TIME%"
	call :timediff Elapsed Start End
	call :getTime now & ECHO [!now!] - %Red%There are errors. Check logs.%White% & ECHO [!now!] - There are errors. Check logs. >>%ScriptLog%
	call :getTime now & ECHO [!now!] - Total Elapsed Time: !ElapsedTime! & ECHO [!now!] - Total Elapsed Time: !ElapsedTime!>>%ScriptLog%
	call :getTime now & ECHO [!now!] - Sending logfile to emailaddress & ECHO [!now!] - Sending logfile to emailaddress>>%ScriptLog%
	IF "%BackupType%"=="None" (
		if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectError% /a %ScriptLog% /b %BodyFail% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectError% /btxt "%CD%/tempbodyfail.txt" /html
			)
		)
	) ELSE (
	if "%EnableMail%"=="Yes" (
			if "%Attachment%"=="Yes" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectError% /a %Log%^|%ScriptLog% /b %BodyFail% /html
			)
			if "%Attachment%"=="No" (
				"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault %VaultType% %VaultVersion% Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub %SubjectError% /btxt "%CD%/tempbodyfail.txt" /html
			)
		)
	)
	call :SendNotification "%CompanyName% Vault Backup has errors!" "Autodesk Vault %VaultType% %VaultVersion%" "Warning"
	call :getTime now &	ECHO [!now!] - Closing window in 10 minutes & ECHO [!now!] - Closing window in 10 minutes>>%ScriptLog%
	del tempbodysuccess.txt
	del tempbodyfail.txt
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
	
	FOR /f "tokens=2 delims==" %%a IN ('wmic OS Get localdatetime /value') DO SET "dt=%%a"
	SET "YY=%dt:~2,2%" & SET "YYYY=!dt:~0,4!" & SET "MM=!dt:~4,2!" & SET "DD=!dt:~6,2!" & SET "HH=!dt:~8,2!" & SET "Min=!dt:~10,2!" & SET "Sec=!dt:~12,2!"

    :: Clean up and return the new time string
    endlocal & if not "%~1"=="" set "%~1=%YYYY%-%MM%-%DD% - %h:~-2%:%m:~-2%:%s:~-2%,%c:~-2%" & exit /b
	
	
:getVaultVersion <VaultVersion> <VaultType>
	setlocal enableextensions disabledelayedexpansion
	:: Get vault version
	IF "%ServerConfig%"=="SQLOnly" (
		SET VT=SQL Server Only,
		SET GetVaultVersion= No Vault installed.
		GOTO :Continue2
	)

	reg export HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall temp1.txt
	find "DisplayName" temp1.txt| find /V "ParentDisplayName" > temp2.txt
	FOR /f "tokens=2,3 delims==" %%a IN (temp2.txt) DO (ECHO %%a >> software_list.txt)
	DEL temp1.txt
	DEL temp2.txt
	SET findfile="software_list.txt"
	
	call :reset_error	
	findstr /R /C:\""Autodesk Vault Professional .... (Server)"\" %findfile% >>%VerboseLog% 2>nul
	IF %errorlevel% EQU 0 (
		SET VT=Professional
		GOTO :Continue
	)
	call :reset_error
	findstr /R /C:\""Autodesk Vault Workgroup .... (Server)"\" %findfile% >>%VerboseLog% 2>nul
	IF %errorlevel% EQU 0 (
		SET VT=Workgroup
		GOTO :Continue
	)
	call :reset_error
	findstr /R /C:\""Autodesk Vault Basic .... (Server)"\" %findfile% >>%VerboseLog% 2>nul
	IF %errorlevel% EQU 0 (
		SET VT=Basic
		GOTO :Continue
	)

	
	@cls
	DEL software_list.txt
	FOR /f "delims=::1: tokens=*" %%A IN ('findstr /b ::1: "%~f0"') DO @ECHO %Purple% %%A
	ECHO %Red%============================================================================================================================================================
	ECHO %White%No Vault installed! Exiting... & ECHO No Vault installed! Exiting...>>%ScriptLog%
	call :SendNotification "%CompanyName% - No Vault installed" "Autodesk Vault" "Warning"
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
	
	:Continue2
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
	taskkill /F /IM Connectivity.ADMSConsole.exe >>%VerboseLog% 2>nul
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
	SET CheckString3=A Vault or Library has been added or removed
	SET CheckStringMigrate=The migrate operation has been successfully finished
	SET CheckStringDefrag=Defragmentation operation completed successfully
	SET CheckStringSQL=Failed
	SET CheckStringValidate=ERROR
	SET ESC=
	SET Red=%ESC%[31m
	SET Green=%ESC%[32m
	SET Blue=%ESC%[34m
	SET Purple=%ESC%[35m
	SET White=%ESC%[37m
	SET ThisFile="%CD%\%~n0%~x0"
	FOR %%? IN (%ThisFile%) DO SET filedate=%%~t?
	SET AttachScript="%CD%\AttachScript.txt"
	SET DetachScript="%CD%\DetachScript.txt"
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
	NET STOP "Autodesk Data Management Job Dispatch" >>%VerboseLog% 2>nul
	NET START "Autodesk Data Management Job Dispatch" >>%VerboseLog% 2>nul
	
	call :getTime now
	ECHO [!now!] - Cycling SQL Services & ECHO [!now!] - Cycling SQL Services>>%ScriptLog%
	NET STOP "SQLBrowser" >>%VerboseLog% 2>nul
	NET STOP "SQLAgent$%VaultDatabaseInstance%" >>%VerboseLog% 2>nul
	NET STOP "MSSQL$%VaultDatabaseInstance%" >>%VerboseLog% 2>nul
	NET START "MSSQL$%VaultDatabaseInstance%" >>%VerboseLog% 2>nul
	NET START "SQLAgent$%VaultDatabaseInstance%" >>%VerboseLog% 2>nul
	NET START "SQLBrowser" >>%VerboseLog% 2>nul
	
	call :getTime now
	ECHO [!now!] - Cycling IIS & ECHO [!now!] - Cycling IIS>>%ScriptLog%
	iisreset /restart >>%VerboseLog% 2>nul
	(
		exit /b
	)

:SetSchedule
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get DayOfWeek') do if not defined dayNumber set dayNumber=%%a
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get WeekInMonth') do if not defined weekNumber set weekNumber=%%a
	for /f "skip=1" %%a in ('WMIC Path win32_LocalTime Get Month') do if not defined monthNumber set monthNumber=%%a
	
	set BackupType=None
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
	
	SET sqlmaintbool=0
	if "%RunSQLMaintenance%"=="Yes" (
		for %%i in (%SQLMaintenanceOnMonth%) do (if %%i==%monthNumber% (
			for %%i in (%SQLMaintenanceOnWeek%) do (if %%i==%weekNumber% (
				for %%i in (%SQLMaintenanceOnDay%) do (if %%i==%dayNumber% (
					SET sqlmaintbool=1
				))
			))
		))
	)
	
	SET validationbool=0
	if "%RunValidation%"=="Yes" (
		for %%i in (%ValidationOnMonth%) do (if %%i==%monthNumber% (
			for %%i in (%ValidationOnWeek%) do (if %%i==%weekNumber% (
				for %%i in (%ValidationOnDay%) do (if %%i==%dayNumber% (
					SET validationbool=1
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

    endlocal & SET "%~1=%size%"
	CALL :strNumDivide sizeKb %size% 1024
	CALL :strNumDivide sizeMb %sizeKb% 1024
	CALL :strNumDivide sizeGb %sizeMb% 1024

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
	SET result=!result:,=.!
	SET result=!result:.=!

    IF NOT DEFINED result SET "result=0"
    EndLocal & SET "%~1=%result%"
	GOTO:EOF

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
	::SQL Authentication
	if "%SQLAuthentication%"=="Default" (
		SET SQLAuth=-E
	)
	if "%SQLAuthentication%"=="Specified" (
		SET SQLAuth=-U "%SAuser%" -P "%SApassword%"
	)
	
	if "%WindowsAuthentication%"=="Yes" (
		SET VaultAuth=-WA
	)
	if "%WindowsAuthentication%"=="No" (
		if "%SQLAuthentication%"=="Default" (
			SET VaultAuth=-VU"%BackupUser%" -VP"%BackupPassword%"
		)
		if "%SQLAuthentication%"=="Specified" (
			SET VaultAuth=-VU"%BackupUser%" -VP"%BackupPassword%" -DBU"%SAuser%" -DBP"%SApassword%"
		)
	)
	(
		exit /b
	)
	
:: Create Vault backup options string
:BackupOptions
	if "%BackupStandardContentCenter%"=="No" (
		SET DBSC= -DBSC
	) ELSE (
		SET DBSC=
	)
	SET VaultOpt=%DBSC%
	(
		exit /b
	)

:SendNotification <Message> <Title> <Icon>
	if "%EnableTelegram%"=="Yes" (
		endlocal
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendMessage -d chat_id=%TelegramChatID% -d text="%~1" >>%VerboseLog% 2>nul
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendDocument -F chat_id=%TelegramChatID% -F caption="Script Log" -F document=@%ScriptLog% >>%VerboseLog% 2>nul
		curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendDocument -F chat_id=%TelegramChatID% -F caption="Backup Log" -F document=@%Log% >>%VerboseLog% 2>nul
		setlocal enabledelayedexpansion
	)
	if "%EnablePushOver%"=="Yes" (
		endlocal
		curl --form-string "token="%PushOverToken%"" --form-string "user="%PushOverUser%"" --form-string "html=1" --form-string "message=%~1" --form-string "title=%CompanyName% Vault %VaultType% %VaultVersion% Server" --form-string "priority=-1" https://api.pushover.net/1/messages.json > nul 2> nul
		setlocal enabledelayedexpansion
	)
	if "%EnableWindowsNotification%"=="Yes" (
		endlocal
		set WinTitle=%~2
		Set WinMessage=%~1
		::You can replace the WinIcon value by Information, error, warning and none
		Set WinIcon=%~3
		EVENTCREATE /T %~3 /L APPLICATION /so "%~2" /ID 100 /D "%~1" >>%VerboseLog% 2>nul
		call :WinNot
		setlocal enabledelayedexpansion
	)
	(
		exit /b
	)
	
:WinNot
	for /f "delims=" %%a in ('powershell -c "[reflection.assembly]::loadwithpartialname('System.Windows.Forms');[reflection.assembly]::loadwithpartialname('System.Drawing');$notify = new-object system.windows.forms.notifyicon;$notify.icon = [System.Drawing.SystemIcons]::%WinIcon%;$notify.visible = $true;$notify.showballoontip(10,'%WinTitle%','%WinMessage%',[system.windows.forms.tooltipicon]::None)"') do set $=
	exit /b
	
:reset_error
exit /b 0




:ExportSettings
	call :getTime now & ECHO [!now!] - Exporting settings & ECHO [!now!] - Exporting settings>>%ScriptLog%
	for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "IPv4"') do set ip==%%b
	set ipAddress=%ip:~2%

	for /f "tokens=1-2 delims=:" %%a in ('ipconfig /all^|find "Physical"') do set mac==%%b
	set macAddress=%mac:~2%
		
	for /f "skip=1 delims=" %%a in ('WMIC cpu Get name') do if not defined cpu set cpu=%%a
	for /f "skip=1 delims=" %%a in ('WMIC cpu Get numberofcores') do if not defined cores set cores=%%a
	
	:: Main settings
	ECHO ============================== Main Settings ==============================   >>%VaultSettings%
	ECHO Main drive:				%MainDrive%>>%VaultSettings%
	ECHO backup Drive:				%BackUpDrive%>>%VaultSettings%
	ECHO Vault Location:				%VaultLocation%>>%VaultSettings%
	ECHO Copy backup to NAS?:			%CopyToNAS%>>%VaultSettings% 
	ECHO NAS Path:				%NASPath%>>%VaultSettings%
	ECHO Autodesk Install:			%AutodeskInstallLocation%>>%VaultSettings%
	ECHO Vault Name:				%Vault%>>%VaultSettings%
	ECHO Company Name:				%CompanyName%>>%VaultSettings%
	ECHO Install Notepad++?:			%InstallNotepadPlus%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Vault Authentication and Backup settings ==============================   >>%VaultSettings% 
	ECHO Windows Authentication Enabled?:	%WindowsAuthentication%>>%VaultSettings%
	ECHO Vault User for backup:			%BackupUser%>>%VaultSettings%
	ECHO Vault Password for backup:		%BackupPassword%>>%VaultSettings%
	ECHO Backup Standard Content Center?:	%BackupStandardContentCenter%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Extra fucntions ==============================   >>%VaultSettings%
	ECHO Run Validation?:			%RunValidation%>>%VaultSettings%
	ECHO Run Defragmentation?:			%RunDefragmentation%>>%VaultSettings%
	ECHO Run B2BMigration?:			%RunB2BMigration%>>%VaultSettings%
	ECHO Run SQL Maintenance?:			%RunSQLMaintenance%>>%VaultSettings%

	
	ECHO.>>%VaultSettings%
	ECHO ============================== Backup Scheduled ==============================   >>%VaultSettings%
	ECHO Full backups runs on months:		%FullBackUpOnMonth% >>%VaultSettings%
	ECHO Incremental backups runs on months:	%IncrementalBackUpOnMonth% >>%VaultSettings%
	ECHO Full backups runs on weeks:		%FullBackUpOnWeek% >>%VaultSettings%
	ECHO Incremental backups runs on weeks:	%IncrementalBackUpOnWeek% >>%VaultSettings%
	ECHO Full backups runs on days:		%FullBackUpOnDay% >>%VaultSettings%
	ECHO Incremental backups runs on days:	%IncrementalBackUpOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO Validation runs on months:		%ValidationOnMonth% >>%VaultSettings%
	ECHO Validation runs on weeks:		%ValidationOnWeek% >>%VaultSettings%
	ECHO Validation runs on days:		%ValidationOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO Defragment runs on months:		%DefragmentOnMonth% >>%VaultSettings%
	ECHO Defragment runs on weeks:		%DefragmentOnWeek% >>%VaultSettings%
	ECHO Defragment runs on days:		%DefragmentOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO B2BMigration runs on months:		%B2BMigrationOnMonth% >>%VaultSettings%
	ECHO B2BMigration runs on weeks:		%B2BMigrationOnWeek% >>%VaultSettings%
	ECHO B2BMigration runs on days:		%B2BMigrationOnDay% >>%VaultSettings%
	ECHO.>>%VaultSettings%
	ECHO SQL Maintenance runs on months:		%SQLMaintenanceOnMonth% >>%VaultSettings%
	ECHO SQL Maintenancen runs on weeks:		%SQLMaintenanceOnWeek% >>%VaultSettings%
	ECHO SQL Maintenance runs on days:		%SQLMaintenanceOnDay% >>%VaultSettings%

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
	ECHO ============================== Windows Notifications ==============================   >>%VaultSettings% 
	ECHO Enable Windows Notifications?:			%EnableWindowsNotification%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Email Notifications ==============================   >>%VaultSettings% 
	ECHO Enable Mail?:				%EnableMail%>>%VaultSettings%
	ECHO Outgoing mail server:			%ExchSvr%>>%VaultSettings%
	ECHO Server Port:				%SrvPort%>>%VaultSettings%
	ECHO Use SSL?:				%UseSSL%>>%VaultSettings%
	ECHO Outgoing mail user:			%SvrUser%>>%VaultSettings%
	ECHO Outgoing mail password:			%SvrPass%>>%VaultSettings%
	ECHO EMail From:				%EMailFrom%>>%VaultSettings%
	ECHO Email to when backup successful:	%EmailToSuccess%>>%VaultSettings%
	ECHO Email to when backup failed:		%EmailToFail%>>%VaultSettings%
	
	ECHO.>>%VaultSettings%
	ECHO ============================== Other settings ==============================   >>%VaultSettings%
	ECHO SA username:					%SAuser%>>%VaultSettings%
	ECHO SA password:					%SApassword%>>%VaultSettings%
	ECHO Vault Database Instance:		%VaultDatabaseInstance%>>%VaultSettings%
	ECHO This Server runs:			%ServerConfig%>>%VaultSettings%
	
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
	sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "SELECT @@VERSION">>%VaultSettings%
	sqlcmd -S %HostName%\%VaultDatabaseInstance% %SQLAuth% -Q "SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [CPU Threads],cpu_count/hyperthread_ratio AS [Physical CPU Count],physical_memory_kb/1024 AS [Physical Memory in MB] from sys.dm_os_sys_info">>%VaultSettings%

	(
		exit /b
	)

:SettingsMissing
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:.
::2:	:: Info: https://help.autodesk.com/view/VAULT/2021/ENU/?guid=GUID-7FD9DAD8-0104-46FA-BCE7-11259FAB4235
::2:	:: Switches: http://help.autodesk.com/view/VAULT/2021/ENU/?guid=GUID-56F358D7-C47B-4B6A-95CB-F402D6F2C7F9
::2:	:: Notepad++ is the preferend editor: https://notepad-plus-plus.org/downloads/"
::2:.
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:.
::2:	:: For Yes/No options use "Yes" or "No" (without quotes, case sensitive!)
::2:	:: Note that trailing spaces will break the script!!! So use "C:" NOT "C: "!!!
::2:	:: Also use for example "C:\ADMS" NOT "C:\ADMS\". So no extra trailing \
::2:.
::2:	:: Main settings
::2:	SET MainDrive=C:
::2:	SET BackUpDrive=C:
::2:	SET BackupRootPath=C:\ADMS
::2:	SET VaultLocation=C:\ADMS\FileStore
::2:.
::2:	:: Use of VHD dramatically improves copying and moving performance.
::2:	SET UseVHDforBackup=Yes
::2:	SET VHDDrive=V:
::2:.
::2:	:: When CopyToNAS is active only full backups are supported.
::2:	SET CopyToNAS=No
::2:	SET NASLocation=\\NAS\somewhere
::2:	SET NASPath=Y:
::2:	SET "NASUser=USERNAME"
::2:	SET "NASPassword=PASSWORD"
::2:.
::2:	SET AutodeskInstallLocation=C:\Program Files\Autodesk
::2:	SET Vault=Vault,Settings
::2:	:: All vaults comma separated
::2:	SET CompanyName=Your Company Name
::2:	SET InstallNotepadPlus=No
::2:	SET AutomaticUpdate=No
::2:.
::2:	:: Vault Authentication and Backup settings
::2:	SET WindowsAuthentication=No
::2:	SET BackupUser=backup
::2:	SET BackupPassword=backup
::2:	SET BackupStandardContentCenter=No
::2:.
::2:	:: Extra fucntions
::2:	SET RunValidation=Yes
::2:	SET RunDefragmentation=Yes
::2:	SET RunB2BMigration=No
::2:	SET RunSQLMaintenance=Yes
::2:.
::2:	::===== SCHEDULE =====
::2:	:: Day of week. 0 = sunday, 1 = monday ..... 6 = saturday
::2:	:: Week of Month. 1 to 5
::2:	:: Month. 1 = Januari, 12 = December
::2:.
::2:	:: Settings bellow will create a full backup every saturday. All other days an incremental backup will be made.
::2:	SET FullBackUpOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET IncrementalBackUpOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET FullBackUpOnWeek=1,2,3,4,5,6
::2:	SET IncrementalBackUpOnWeek=1,2,3,4,5,6
::2:	SET FullBackUpOnDay=5
::2:	SET IncrementalBackUpOnDay=1,2,3,4
::2:.
::2:	SET ValidationOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET ValidationOnWeek=1,2,3,4,5,6
::2:	SET ValidationOnDay=6
::2:.
::2:	SET DefragmentOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET DefragmentOnWeek=1,2,3,4,5,6
::2:	SET DefragmentOnDay=0
::2:.
::2:	SET B2BMigrationOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET B2BMigrationOnWeek=1,2,3,4,5,6
::2:	SET B2BMigrationOnDay=0
::2:.
::2:	SET SQLMaintenanceOnMonth=1,2,3,4,5,6,7,8,9,10,11,12
::2:	SET SQLMaintenanceOnWeek=1,2,3,4,5,6
::2:	SET SQLMaintenanceOnDay=0
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
::2:	:: Go here to get chatID: https://api.telegram.org/bot<TelegramToken>/getupdates
::2:	SET EnableTelegram=No
::2:	SET TelegramToken=123456
::2:	SET TelegramChatID=123456
::2:.
::2:	:: Windows Notification settings
::2:	SET EnableWindowsNotification=Yes
::2:.
::2:	:: Email settings
::2:	SET EnableMail=No
::2:	SET ExchSvr=smtp.domain.com
::2:	SET SrvPort=587
::2:	SET UseSSL=Yes
::2:	SET SvrUser=USER
::2:	SET "SvrPass=PASSWORD"
::2:	SET EMailFrom=from@domain.com
::2:	SET EmailToSuccess=succes@domain.com
::2:	SET EmailToFail=fail@domain.com
::2:	:: Multiple email adresses are possible. Comma separated, no space.
::2:	SET Attachment=Yes
::2:	:: "Yes" sends logs in the mail as attachment. "No" sends the logs in the email body.
::2:.
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:.
::2:	:: Other settings - only edit when instructed to!
::2:    :: "Default" for -E Switch. "Specified" for user and pass.
::2:    SET SQLAuthentication=Default
::2:	SET SAuser=sa
::2:	SET "SApassword=AutodeskVault@26200"
::2:	SET VaultDatabaseInstance=AUTODESKVAULT
::2:	:: Server configuration "VaultOnly", "SQLOnly", "Both"
::2:	SET ServerConfig=Both
::2:.
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
::2:	::=======================================================================================================================================================================================================
	
	FOR /f "delims=::2: tokens=*" %%A IN ('findstr /b ::2: "%~f0"') DO @ECHO%%A>>%BackupSettings%
	
	(
		exit /b
	)	
	
:Updater
	:: INPUT THE LOCAL VERSION HERE (replace local's "1.0") also replace link with your own.
	set local=%scriptversion%
	SET local=!local:.=!
	set localtwo=%local%
	SET localtwo=!localtwo:.=!
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
		curl %updatelink% --output %CD%\version.bat >>%VerboseLog% 2>nul
		CALL version.bat
		SET local=!local:.=!
		goto updater-check-2

	:: updater-check-2 is where it checks if your remote matches with your local.
	:updater-check-2
		IF %local% LEQ %localtwo% goto :updater-no
		IF %local% GTR %localtwo% goto :updater-yes

	:updater-no
		DEL /Q %CD%\version.bat >>%VerboseLog% 2>nul
		exit /b
		
	:updater-yes
		DEL /Q %CD%\version.bat >>%VerboseLog% 2>nul
		curl %downloadlink% --output %CD%\VaultBackup.bat >>%VerboseLog% 2>nul
		call :SendNotification "%CompanyName% Vault Backup Script has been updated!" "Autodesk Vault %VaultType% %VaultVersion%" "Information"
		exit /b
		
:CreateNotificationTestScript
::3:	@echo off
::3:	TITLE Cadac Group B.V. - Vault Notifications test script
::3:	setlocal enabledelayedexpansion
::3:	SET BackupSettings=BackupSettings.bat
::3:	SET "SwithMail=%CD%\SwithMail.exe"
::3:.
::3:	:: Check admin
::3:	call :BatchGotAdmin
::3:.
::3:	:: Check cURL
::3:	call :checkCURL
::3:.
::3:	:: Import Settings
::3:	IF NOT EXIST "BackupSettings.bat" (
::3:		echo Settings file not found!
::3:		echo run VaultBackup.bat to create BackupSettings.bat with default settings.
::3:		pause
::3:		exit
::3:	) ELSE (
::3:		for /f "delims=" %%x in (%BackupSettings%) do %%x> nul 2> nul
::3:	)
::3:.
::3:	if "%UseSSL%"=="Yes" (
::3:		SET SSL=/SSL
::3:	) else (
::3:		SET SSL=
::3:	)
::3:.
::3:	SET SubjectTest=Vault Notifications test
::3:	SET AttachmentTest=This is the content of an attachment
::3:	ECHO %AttachmentTest%>>test.txt
::3:	SET BodyTest=Hello world
::3:	ECHO %BodyTest%>>tempbody.txt
::3:	ECHO ^<br /^>>>tempbody.txt
::3:	FOR /F "tokens=* delims=" %%x in (test.txt) DO (ECHO %%x >> tempbody.txt) > nul 2> nul
::3:	if "%EnableMail%"=="Yes" (
::3:		if "%Attachment%"=="Yes" (
::3:			"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /a "%CD%/test.txt" /sub "%SubjectTest%" /b "%BodyTest%" /html
::3:		)
::3:		if "%Attachment%"=="No" (
::3:			"%SwithMail%" /s /from "%EMailFrom%" /name "%CompanyName% Vault Server" /u "%SvrUser%" /pass "%SvrPass%" /server "%ExchSvr%" /p "%SrvPort%" %SSL% /to "%EmailToFail%" /sub "%SubjectTest%" /btxt "%CD%/tempbody.txt" /html
::3:		)
::3:	)
::3:.	
::3:	del tempbody.txt
::3:	del test.txt
::3:.
::3:	call :SendNotification "%BodyTest%" "%SubjectTest%" "Information"
::3:.
::3:	:SendNotification <Message> <Title> <Icon>
::3:		if "%EnableTelegram%"=="Yes" (
::3:			endlocal
::3:			curl -s -X POST https://api.telegram.org/bot%TelegramToken%/sendMessage -d chat_id=%TelegramChatID% -d text="%~1" > nul 2> nul
::3:			setlocal enabledelayedexpansion
::3:		)
::3:		if "%EnablePushOver%"=="Yes" (
::3:			endlocal
::3:			curl --form-string "token="%PushOverToken%"" --form-string "user="%PushOverUser%"" --form-string "html=1" --form-string "message=%~1" --form-string "title=%CompanyName% Vault %VaultType% %VaultVersion% Server" --form-string "priority=-1" https://api.pushover.net/1/messages.json > nul 2> nul
::3:			setlocal enabledelayedexpansion
::3:		)
::3:		if "%EnableWindowsNotification%"=="Yes" (
::3:			endlocal
::3:			set WinTitle=%~2
::3:			Set WinMessage=%~1
::3:			::You can replace the WinIcon value by Information, error, warning and none
::3:			Set WinIcon=%~3
::3:			EVENTCREATE /T %~3 /L APPLICATION /so "%~2" /ID 100 /D "%~1" > nul 2> nul
::3:			call :WinNot
::3:			setlocal enabledelayedexpansion
::3:		)
::3:		(
::3:			exit /b
::3:		)
::3:.
::3:	:WinNot
::3:		for /f "delims=" %%a in ('powershell -c "[reflection.assembly]::loadwithpartialname('System.Windows.Forms');[reflection.assembly]::loadwithpartialname('System.Drawing');$notify = new-object system.windows.forms.notifyicon;$notify.icon = [System.Drawing.SystemIcons]::%WinIcon%;$notify.visible = $true;$notify.showballoontip(10,'%WinTitle%','%WinMessage%',[system.windows.forms.tooltipicon]::None)"') do set $=
::3:		exit /b
::3:.
::3:	:BatchGotAdmin
::3:		:: Check for permissions
::3:		IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
::3:		>NUL 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
::3:		) ELSE (
::3:		>NUL 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
::3:		)
::3:.
::3:		:: If error flag SET, we do not have admin.
::3:		IF '%errorlevel%' NEQ '0' (
::3:			ECHO %White%Requesting administrative privileges...
::3:			GOTO UACPrompt
::3:		) ELSE ( GOTO gotAdmin )
::3:.
::3:		:UACPrompt
::3:			ECHO SET UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
::3:			SET params = %*:"=""
::3:			ECHO UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
::3:.
::3:			"%temp%\getadmin.vbs"
::3:			DEL "%temp%\getadmin.vbs"
::3:			exit /b
::3:.
::3:		:gotAdmin
::3:			PUSHD "%CD%"
::3:			CD /D "%~dp0"
::3:			exit /b
::3:.
::3:	:: Checks if curl is installed. If not, download chocolatey package manager to install latest version of curl.
::3:	:checkCURL
::3:		if "%EnablePushOver%"=="Yes" (
::3:			if not exist %SYSTEMROOT%\System32\curl.exe (
::3:				if not exist %PROGRAMDATA%\chocolatey\choco.exe (
::3:					@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
::3:					start "" "%~f0"
::3:					exit
::3:				)
::3:				if not exist %PROGRAMDATA%\chocolatey\lib\curl (
::3:					choco install curl -y
::3:				)
::3:			)
::3:		)
::3:		(
::3:			exit /b
::3:		)
	
	FOR /f "delims=::3: tokens=*" %%A IN ('findstr /b ::3: "%~f0"') DO @ECHO%%A>>NotificationsTest.bat
	
	(
		exit /b
	)	

:QUIT
EXIT
