<#
.SYNOPSIS
    Installs Claude Desktop on Windows if it is not already installed.

.DESCRIPTION
    Checks common install locations / Windows "Installed Apps" registry
    entries for Claude Desktop. If not found, downloads the official
    Windows installer from Anthropic and runs it silently.

.NOTES
    Run from an elevated or standard PowerShell prompt:
        powershell -ExecutionPolicy Bypass -File .\install-claude-desktop.ps1
#>

$ErrorActionPreference = "Stop"

$AppName        = "Claude"
$DownloadUrl    = "https://claude.ai/download"  # Official download page; redirects to the current Windows build
$InstallerPath  = Join-Path $env:TEMP "Claude-Setup.exe"

function Test-ClaudeInstalled {
    $uninstallKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($key in $uninstallKeys) {
        $match = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -like "*Claude*" }
        if ($match) { return $true }
    }

    $localAppDataPath = Join-Path $env:LOCALAPPDATA "AnthropicClaude"
    if (Test-Path $localAppDataPath) { return $true }

    return $false
}

Write-Host "Checking for existing Claude Desktop installation..."

if (Test-ClaudeInstalled) {
    Write-Host "Claude Desktop is already installed. Nothing to do."
    exit 0
}

Write-Host "Claude Desktop not found. Downloading installer..."

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing
}
catch {
    Write-Error "Failed to download the installer from $DownloadUrl. $_"
    exit 1
}

Write-Host "Running installer..."

try {
    Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait
}
catch {
    Write-Warning "Silent install failed or was unsupported, launching interactive installer instead."
    Start-Process -FilePath $InstallerPath -Wait
}

Write-Host "Installation complete. Launch Claude from the Start Menu."

Remove-Item $InstallerPath -ErrorAction SilentlyContinue