# Azure Virtual Desktop Session Host Initialization Script
# This script performs required configuration for AVD session hosts
# StorageAccountFQDN is passed as a variable from Terraform

param(
    [string]$StorageAccountFQDN
)

# Logging setup
$logPath = "C:\Windows\Temp\avd-initialize.log"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
    Write-Host "[$timestamp] $Message"
}

Write-Log "Starting AVD Session Host Initialization"

try {
    # 1. Enable Microsoft Entra Kerberos ticket retrieval
    Write-Log "Configuring Microsoft Entra Kerberos ticket retrieval..."
    $kerberosRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
    
    # Create registry path if it doesn't exist
    if (-not (Test-Path $kerberosRegPath)) {
        New-Item -Path $kerberosRegPath -Force | Out-Null
    }
    
    New-ItemProperty -Path $kerberosRegPath -Name CloudKerberosTicketRetrievalEnabled `
        -PropertyType DWORD -Value 1 -Force | Out-Null
    Write-Log "[OK] Microsoft Entra Kerberos enabled"

    # 2. Configure FSLogix authentication in Credential Manager
    Write-Log "Configuring FSLogix authentication settings..."
    $azureAdAccountRegPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
    
    # Create registry path if it doesn't exist
    if (-not (Test-Path $azureAdAccountRegPath)) {
        New-Item -Path $azureAdAccountRegPath -Force | Out-Null
    }
    
    New-ItemProperty -Path $azureAdAccountRegPath -Name LoadCredKeyFromProfile `
        -PropertyType DWORD -Value 1 -Force | Out-Null
    Write-Log "[OK] FSLogix authentication configured"

    # # 3. Install FSLogix
    # Write-Log "Installing FSLogix..."
    # $fslogixDownloadUrl = "https://aka.ms/fslogix-latest"
    # $fslogixInstallPath = "C:\Temp\FSLogixInstaller"
    # $fslogixZipPath = "$fslogixInstallPath\FSLogix.zip"
    
    # # Create temp directory
    # if (-not (Test-Path $fslogixInstallPath)) {
    #     New-Item -ItemType Directory -Path $fslogixInstallPath -Force | Out-Null
    # }
    
    # # Download FSLogix
    # Write-Log "Downloading FSLogix from $fslogixDownloadUrl..."
    # $ProgressPreference = 'SilentlyContinue'
    # try {
    #     Invoke-WebRequest -Uri $fslogixDownloadUrl -OutFile $fslogixZipPath -UseBasicParsing
    #     Write-Log "✓ FSLogix download completed"
    # }
    # catch {
    #     Write-Log "⚠ FSLogix download failed: $_"
    # }
    
    # # Extract and install FSLogix if download succeeded
    # if (Test-Path $fslogixZipPath) {
    #     Write-Log "Extracting FSLogix installer..."
    #     try {
    #         Expand-Archive -Path $fslogixZipPath -DestinationPath $fslogixInstallPath -Force
    #     }
    #     catch {
    #         Write-Log "⚠ FSLogix extraction failed: $_"
    #     }
        
    #     # Run Release/FSLogixAppsSetup.exe with unattended options.
    #     $fslogixExePath = Join-Path $fslogixInstallPath "x64\Release\FSLogixAppsSetup.exe"
    #     if (-not (Test-Path $fslogixExePath)) {
    #         $fslogixExePath = Get-ChildItem -Path $fslogixInstallPath -Filter "FSLogixAppsSetup.exe" -Recurse -ErrorAction SilentlyContinue |
    #             Where-Object { $_.FullName -match "\\Release\\" } |
    #             Select-Object -ExpandProperty FullName -First 1
    #     }

    #     if ($fslogixExePath -and (Test-Path $fslogixExePath)) {
    #         Write-Log "Installing FSLogix EXE: $fslogixExePath"
    #         $fslogixInstallerLogPath = "C:\Windows\Temp\FSLogixAppsSetup.log"
    #         $installArgs = @(
    #             "/install",
    #             "/quiet",
    #             "/norestart",
    #             "/log",
    #             $fslogixInstallerLogPath
    #         )
    #         $process = Start-Process -FilePath $fslogixExePath -ArgumentList $installArgs -Wait -PassThru
            
    #         if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
    #             Write-Log "✓ FSLogix installation completed"
    #         }
    #         else {
    #             Write-Log "⚠ FSLogix installation returned exit code: $($process.ExitCode)"
    #         }
    #     }
    #     else {
    #         Write-Log "⚠ Release/FSLogixAppsSetup.exe not found in FSLogix package"
    #     }
    # }

    # 4. Configure FSLogix Profile Container
    Write-Log "Configuring FSLogix profile container..."
    $fslogixRegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
    
    # Create registry path if it doesn't exist
    if (-not (Test-Path $fslogixRegPath)) {
        New-Item -Path $fslogixRegPath -Force | Out-Null
    }
    
    # Enable profile containers
    New-ItemProperty -Path $fslogixRegPath -Name Enabled `
        -PropertyType DWORD -Value 1 -Force | Out-Null
    
    # Configure VHD locations - use storage account FQDN variable
    if ($StorageAccountFQDN) {
        $profileUNCPath = "\\$StorageAccountFQDN\profiles"
        New-ItemProperty -Path $fslogixRegPath -Name VHDLocations `
            -PropertyType MultiString -Value $profileUNCPath -Force | Out-Null
        
        Write-Log "[OK] FSLogix profile container configured"
        Write-Log "  - Profile UNC Path: $profileUNCPath"
    }
    else {
        Write-Log "[WARN] Storage account FQDN not provided, skipping VHD location configuration"
    }

    # Additional FSLogix optimizations
    Write-Log "Applying FSLogix optimizations..."
    
    # Delete local cache when user logs off
    New-ItemProperty -Path $fslogixRegPath -Name DeleteLocalProfileWhenVHDShouldApply `
        -PropertyType DWORD -Value 1 -Force | Out-Null
    
    # Use VHDX format
    New-ItemProperty -Path $fslogixRegPath -Name VolumeType `
        -PropertyType String -Value "VHDX" -Force | Out-Null
    
    # Set concurrent user sessions
    New-ItemProperty -Path $fslogixRegPath -Name ConcurrentUserSessions `
        -PropertyType DWORD -Value 1 -Force | Out-Null
    
    Write-Log "[OK] FSLogix optimizations applied"

    Write-Log "[OK] AVD Session Host Initialization completed successfully"
    exit 0
}
catch {
    Write-Log "[ERROR] Error during initialization: $_"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
