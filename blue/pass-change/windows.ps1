# Check if the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting."
    exit 1
}

# Prompt for admin and user passwords securely
$ADMIN_PASSWORD = Read-Host -AsSecureString -Prompt "Enter ADMIN password"
$USER_PASSWORD = Read-Host -AsSecureString -Prompt "Enter USER password"

# Define users and their passwords
$Users = @{
    "president" = $ADMIN_PASSWORD
    "vicepresident" = $ADMIN_PASSWORD
    "defenseminister" = $ADMIN_PASSWORD
    "secretary" = $ADMIN_PASSWORD
    "general" = $USER_PASSWORD
    "admiral" = $USER_PASSWORD
    "judge" = $USER_PASSWORD
    "bodyguard" = $USER_PASSWORD
    "cabinetofficial" = $USER_PASSWORD
    "treasurer" = $USER_PASSWORD
}

# Change passwords for specified users
foreach ($User in $Users.Keys) {
    if (Get-LocalUser -Name $User -ErrorAction SilentlyContinue) {
        try {
            Set-LocalUser -Name $User -Password $Users[$User]
            Write-Host "Password successfully changed for user: $User"
        } catch {
            Write-Error "Failed to change password for user: $User. $_"
        }
    } else {
        Write-Warning "User $User does not exist. Skipping."
    }
}

# Disable login for all other users
Get-LocalUser | Where-Object {
    $_.Enabled -eq $true -and $_.Name -notin $Users.Keys
} | ForEach-Object {
    try {
        Disable-LocalUser -Name $_.Name
        Write-Host "Login disabled for user: $($_.Name)"
    } catch {
        Write-Error "Failed to disable login for user: $($_.Name). $_"
    }
}

Write-Host "Process completed."
