# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an administrator."
    exit 1
}

# Define paths and variables
$LogDir = "C:\PowerShellLogs"
$JEARolePath = "C:\Program Files\WindowsPowerShell\Modules\JEARoles"
$RoleFilePath = "$JEARolePath\MyJEARole.psrc"
$SessionConfigName = "MyJEAConfig"
$LogFile = "C:\ScriptExecutionLog.txt"

# Function to log script actions
function Log {
    param([string]$Message)
    Add-Content -Path $LogFile -Value "$(Get-Date) - $Message"
}

Log "Script execution started."

try {
    # 1. Restrict WinRM Execution Policy
    Write-Host "Setting WinRM execution policy to 'Restricted'..."
    Set-Item -Path WSMan:\localhost\Shell\MaxConcurrentOperationsPerUser -Value 0 -ErrorAction Stop
    Log "WinRM execution policy set to 'Restricted'."
} catch {
    Log "Failed to set WinRM execution policy: $_"
}

try {
    # 2. Enable PowerShell Logging
    Write-Host "Enabling PowerShell logging..."

    # Create the log directory if it doesn't exist
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force
        Log "Log directory created at $LogDir."
    }

    # Enable module logging
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1 -Force -ErrorAction Stop
    Log "Module logging enabled."

    # Configure modules to log
    if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "ModuleNames" -Force
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Name "*" -Value "*" -Force -ErrorAction Stop
    Log "PowerShell module logging configured."

    # Enable script block logging
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -Force -ErrorAction Stop
    Log "Script block logging enabled."

    # Enable transcription logging
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" -Name "EnableTranscripting" -Value 1 -Force -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" -Name "OutputDirectory" -Value $LogDir -Force -ErrorAction Stop
    Log "Transcription logging enabled."
} catch {
    Log "Failed to enable PowerShell logging: $_"
}

try {
    # 3. Enable SMB Signing
    Write-Host "Enabling SMB signing..."

    # Configure SMB signing for the client
    if ((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue).RequireSecuritySignature -ne 1) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1 -Force -ErrorAction Stop
        Log "SMB signing enabled for client."
    }

    # Configure SMB signing for the server
    if ((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -ErrorAction SilentlyContinue).RequireSecuritySignature -ne 1) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1 -Force -ErrorAction Stop
        Log "SMB signing enabled for server."
    }
} catch {
    Log "Failed to enable SMB signing: $_"
}

try {
    # 4. Configure JEA (Just Enough Administration)
    Write-Host "Configuring Just Enough Administration (JEA)..."

    # Install JEA if not already installed
    if (-not (Get-WindowsFeature -Name RSAT-JEA | Where-Object { $_.InstallState -eq "Installed" })) {
        Install-WindowsFeature -Name RSAT-JEA -IncludeManagementTools -ErrorAction Stop
        Log "JEA installed."
    }

    # Create the JEA role capability directory if it doesn't exist
    if (-not (Test-Path $JEARolePath)) {
        New-Item -ItemType Directory -Path $JEARolePath -Force
        Log "JEA role capability directory created."
    }

    # Create a role capability file
    $RoleContent = @"
@{
    VisibleCmdlets = 'Get-Service', 'Restart-Service', 'Stop-Service'
    VisibleFunctions = '*'
    VisibleAliases = '*'
    RoleCapabilities = '*'
}
"@
    Set-Content -Path $RoleFilePath -Value $RoleContent -ErrorAction Stop
    Log "JEA role capability file created at $RoleFilePath."

    # Secure the JEA role capability directory
    icacls $JEARolePath /inheritance:r /grant:r "Administrators:F" | Out-Null
    Log "JEA role capability directory permissions secured."

    # Register a JEA session configuration
    New-PSSessionConfigurationFile -Path "C:\ProgramData\MyJEAConfig.pssc" -SessionType RestrictedRemoteServer -RoleDefinitions @{ 'Everyone' = @{ RoleCapabilities = 'MyJEARole' } } -ErrorAction Stop
    Register-PSSessionConfiguration -Name $SessionConfigName -Path "C:\ProgramData\MyJEAConfig.pssc" -Force -ErrorAction Stop
    Log "JEA session configuration registered as $SessionConfigName."
} catch {
    Log "Failed to configure JEA: $_"
}

Write-Host "All configurations have been successfully applied."
Log "Script execution completed successfully."
