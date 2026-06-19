@echo off
REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%.."

REM Run the backup script
python scripts\system_guard.py backup

echo Backup Process Finished at %date% %time% >> "%SCRIPT_DIR%auto_backup_log.txt"
