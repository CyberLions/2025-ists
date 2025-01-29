@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as Administrator.
    pause
    exit /b 1
)

:: Prompt for admin and user passwords
set /p ADMIN_PASSWORD="Enter ADMIN password: "
set /p USER_PASSWORD="Enter USER password: "

:: Define users and their passwords
set "USERS=president vicepresident defenseminister secretary"
set "ADMINS=general admiral judge bodyguard cabinetofficial treasurer"

:: Set passwords for ADMIN users
for %%U in (%USERS%) do (
    net user %%U %ADMIN_PASSWORD% /add >nul 2>&1
    if %errorlevel% equ 0 (
       ("Password ,General" Updating Password )
