# Import the Active Directory module
Import-Module ActiveDirectory

# Check if the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

# Prompt for admin and user passwords securely
$ADMIN_PASSWORD = Read-Host -AsSecureString -Prompt "Enter ADMIN password"
$USER_PASSWORD = Read-Host -AsSecureString -Prompt "Enter USER password"

# Define domain users and their passwords
$Users = @{
    "representative" = $ADMIN_PASSWORD
    "senator" = $ADMIN_PASSWORD
    "attache" = $ADMIN_PASSWORD
    "ambassador" = $ADMIN_PASSWORD
    "foreignaffairs" = $USER_PASSWORD
    "intelofficer" = $USER_PASSWORD
    "delegate" = $USER_PASSWORD
    "advisor" = $USER_PASSWORD
    "lobbyist" = $USER_PASSWORD
    "aidworker" = $USER_PASSWORD
}

# Change passwords for specified domain users
foreach ($User in $Users.Keys) {
    if (Get-ADUser -Identity $User -ErrorAction SilentlyContinue) {
        try {
            Set-ADAccountPassword -Identity $User -NewPassword $Users[$User] -Reset
            Write-Host "Password successfully changed for user: $User"
        } catch {
            Write-Error "Failed to change password for user: $User. $_"
        }
    } else {
        Write-Warning "Domain user $User does not exist. Skipping."
    }
}

# Disable login for all other domain users
Get-ADUser -Filter * | Where-Object {
    $_.Enabled -eq $true -and $_.SamAccountName -notin $Users.Keys
} | ForEach-Object {
    try {
        Disable-ADAccount -Identity $_.SamAccountName
        Write-Host "Login disabled for user: $($_.SamAccountName)"
    } catch {
        Write-Error "Failed to disable login for user: $($_.SamAccountName). $_"
    }
}

Write-Host "Process completed."
