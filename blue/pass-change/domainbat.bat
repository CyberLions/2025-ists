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
set "ADMINS=representative senator attache ambassador"
set "USERS=foreignaffairs intelofficer delegate advisor lobbyist aidworker"

:: Set passwords for ADMIN users
for %%U in (%ADMINS%) do (
    net user %%U %ADMIN_PASSWORD% /domain
    if %errorlevel% equ 0 (
        echo Password successfully updated for ADMIN user: %%U
    ) else (
        echo Failed to update password for ADMIN user: %%U
    )
)

:: Set passwords for USER users
for %%U in (%USERS%) do (
    net user %%U %USER_PASSWORD% /domain
    if %errorlevel% equ 0 (
        echo Password successfully updated for USER user: %%U
    ) else (
        echo Failed to update password for USER user: %%U
    )
)

:: Disable login for all other users in the domain
for /f "tokens=*" %%U in ('net user /domain ^| findstr /v "User accounts" ^| findstr /v "The command completed successfully"') do (
    set "USERNAME=%%U"
    setlocal enabledelayedexpansion
    if /i not "!USERNAME!"=="representative" if /i not "!USERNAME!"=="senator" if /i not "!USERNAME!"=="attache" if /i not "!USERNAME!"=="ambassador" if /i not "!USERNAME!"=="foreignaffairs" if /i not "!USERNAME!"=="intelofficer" if /i not "!USERNAME!"=="delegate" if /i not "!USERNAME!"=="advisor" if /i not "!USERNAME!"=="lobbyist" if /i not "!USERNAME!"=="aidworker" (
        net user "!USERNAME!" /active:no /domain
        echo Disabled login for user: !USERNAME!
    )
    endlocal
)

echo Process completed.
pause
