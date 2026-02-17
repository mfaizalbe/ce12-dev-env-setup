<#
========================================================
Script: setup-windows-oneclick.ps1
Purpose: Setup development environment on Windows
Created by: Muhammad Faizal Bin Ehsan
Contact: https://github.com/mfaizalbe
Date: 2026-02-16
========================================================
#>
# ---------------------------
# Colors
# ---------------------------
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# ---------------------------
# Log file
# ---------------------------
$logFile = "setup-windows-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
Start-Transcript -Path $logFile -Append

Write-Host "${BLUE}=====================================${NC}"
Write-Host "${BLUE} One-Click Dev Environment Setup - Windows${NC}"
Write-Host "${BLUE}Log file: $logFile${NC}"
Write-Host "${BLUE}=====================================${NC}"

# ---------------------------
# Admin check
# ---------------------------
If (-NOT ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "${RED}Please run PowerShell as Administrator.${NC}"
    Stop-Transcript
    Break
}

# ---------------------------
# Progress bar function
# ---------------------------
function Show-Progress {
    param (
        [string]$Message,
        [int]$Seconds
    )
    Write-Host -NoNewline "$Message "
    for ($i=0; $i -lt 20; $i++) {
        Write-Host -NoNewline "▮"
        Start-Sleep -Seconds ($Seconds / 20)
    }
    Write-Host "${GREEN} Done!${NC}"
}

# ---------------------------
# Install WSL
# ---------------------------
Write-Host "${YELLOW}`nChecking WSL installation...${NC}"
if (-not (wsl -l -v 2>$null)) {
    Write-Host "${BLUE}Installing WSL + Ubuntu...${NC}"
    wsl --install -d Ubuntu
    Write-Host "${YELLOW}Restart your PC and re-run this script.${NC}"
    Stop-Transcript
    exit
} else {
    Write-Host "${GREEN}WSL is already installed.${NC}"
}

# ---------------------------
# Install Git
# ---------------------------
Write-Host "${YELLOW}`nChecking Git installation...${NC}"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Show-Progress "Installing Git via winget..." 10
    winget install --id Git.Git -e --source winget
    if ($?) { Write-Host "${GREEN}Git installed successfully!${NC}" }
    else { Write-Host "${RED}❌ Failed to install Git.${NC}" }
} else {
    Write-Host "${GREEN}Git is already installed.${NC}"
}

# ---------------------------
# Copy Linux script and run in WSL
# ---------------------------
$linuxScript = "$PSScriptRoot/setup-dev-environment.sh"
if (Test-Path $linuxScript) {
    Show-Progress "Copying setup-dev-environment.sh into WSL..." 3
    wsl cp "$(Resolve-Path $linuxScript)" /home/$env:USERNAME/setup-dev-environment.sh

    Write-Host "${BLUE}Running Linux setup inside WSL...${NC}"
    wsl bash /home/$env:USERNAME/setup-dev-environment.sh
} else {
    Write-Host "${RED}Error: setup-dev-environment.sh not found.${NC}"
}

# ---------------------------
# Verification in PowerShell
# ---------------------------
Write-Host "${YELLOW}`nVerification in Windows PowerShell...${NC}"
$commands = @("git", "wsl", "docker")

foreach ($cmd in $commands) {
    Show-Progress "Checking $cmd..." 3
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $path = (Get-Command $cmd).Source
        Write-Host "${GREEN}$cmd is installed at: $path${NC}"
        & $cmd --version 2>$null
    } else {
        Write-Host "${RED}❌ $cmd is NOT installed.${NC}"
    }
}

Write-Host "${GREEN}====================================="
Write-Host " Windows One-Click Setup Complete!"
Write-Host "Log file: $logFile"
Write-Host "=====================================${NC}"

Stop-Transcript
Pause
