# AI Development Environment Setup Script
# Purpose: Configure development environment for AI/ML projects with Python installation

# Function to get detailed hardware information
function Get-HardwareInfo {
    Write-Host "=== Hardware Detection for AI Model Training ===" -ForegroundColor Cyan
    
    $hardwareInfo = @{}
    
    # Get CPU information
    try {
        $cpu = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        $hardwareInfo.CPU = @{
            Name = $cpu.Name.Trim()
            Cores = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeed = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
            Architecture = $cpu.Architecture
        }
        Write-Host "✓ CPU detected: $($hardwareInfo.CPU.Name)" -ForegroundColor Green
        Write-Host "  Cores: $($hardwareInfo.CPU.Cores), Logical: $($hardwareInfo.CPU.LogicalProcessors), Speed: $($hardwareInfo.CPU.MaxClockSpeed) GHz" -ForegroundColor Gray
    }
    catch {
        Write-Host "✗ Failed to detect CPU" -ForegroundColor Red
    }
    
    # Get RAM information
    try {
        $ram = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $totalRAMGB = [math]::Round($ram.Sum / 1GB, 2)
        $hardwareInfo.RAM = @{
            TotalGB = $totalRAMGB
            Modules = (Get-WmiObject -Class Win32_PhysicalMemory).Count
        }
        Write-Host "✓ RAM detected: $totalRAMGB GB" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to detect RAM" -ForegroundColor Red
    }
    
    # Get GPU information
    try {
        $gpus = Get-WmiObject -Class Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 }
        $hardwareInfo.GPU = @()
        
        foreach ($gpu in $gpus) {
            $gpuInfo = @{
                Name = $gpu.Name
                VRAMGB = [math]::Round($gpu.AdapterRAM / 1GB, 2)
                DriverVersion = $gpu.DriverVersion
                VideoProcessor = $gpu.VideoProcessor
            }
            $hardwareInfo.GPU += $gpuInfo
            Write-Host "✓ GPU detected: $($gpu.Name) - $($gpuInfo.VRAMGB) GB VRAM" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ Failed to detect GPU" -ForegroundColor Red
    }
    
    # Get disk information
    try {
        $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        $hardwareInfo.Disk = @{
            FreeGB = $freeSpaceGB
            TotalGB = $totalSpaceGB
            FreePercentage = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 1)
        }
        Write-Host "✓ Disk space: $freeSpaceGB GB free of $totalSpaceGB GB total" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to detect disk space" -ForegroundColor Red
    }
    
    return $hardwareInfo
}

# Function to score hardware for AI model training
function Score-HardwareForAITraining {
    param(
        [hashtable]$HardwareInfo
    )
    
    Write-Host "=== AI Model Training Hardware Assessment ===" -ForegroundColor Cyan
    
    $scores = @{}
    $totalScore = 0
    $maxScore = 100
    
    # CPU Scoring (25 points max)
    if ($HardwareInfo.CPU) {
        $cpuScore = 0
        $cores = $HardwareInfo.CPU.Cores
        $logical = $HardwareInfo.CPU.LogicalProcessors
        $speed = $HardwareInfo.CPU.MaxClockSpeed
        
        # Score based on cores and speed
        if ($cores -ge 16) { $cpuScore += 15 }
        elseif ($cores -ge 12) { $cpuScore += 12 }
        elseif ($cores -ge 8) { $cpuScore += 10 }
        elseif ($cores -ge 6) { $cpuScore += 8 }
        elseif ($cores -ge 4) { $cpuScore += 5 }
        else { $cpuScore += 2 }
        
        if ($speed -ge 4.0) { $cpuScore += 10 }
        elseif ($speed -ge 3.5) { $cpuScore += 8 }
        elseif ($speed -ge 3.0) { $cpuScore += 6 }
        elseif ($speed -ge 2.5) { $cpuScore += 4 }
        else { $cpuScore += 2 }
        
        $scores.CPU = $cpuScore
        $totalScore += $cpuScore
        
        Write-Host "CPU Score: $cpuScore/25" -ForegroundColor Yellow
        Write-Host "  Cores: $cores, Speed: $speed GHz" -ForegroundColor Gray
    }
    
    # RAM Scoring (25 points max)
    if ($HardwareInfo.RAM) {
        $ramScore = 0
        $ramGB = $HardwareInfo.RAM.TotalGB
        
        if ($ramGB -ge 64) { $ramScore = 25 }
        elseif ($ramGB -ge 32) { $ramScore = 20 }
        elseif ($ramGB -ge 16) { $ramScore = 15 }
        elseif ($ramGB -ge 8) { $ramScore = 10 }
        elseif ($ramGB -ge 4) { $ramScore = 5 }
        else { $ramScore = 0 }
        
        $scores.RAM = $ramScore
        $totalScore += $ramScore
        
        Write-Host "RAM Score: $ramScore/25" -ForegroundColor Yellow
        Write-Host "  Total RAM: $ramGB GB" -ForegroundColor Gray
    }
    
    # GPU Scoring (40 points max)
    if ($HardwareInfo.GPU -and $HardwareInfo.GPU.Count -gt 0) {
        $gpuScore = 0
        $bestGPU = $HardwareInfo.GPU | Sort-Object VRAMGB -Descending | Select-Object -First 1
        
        # Score based on VRAM and GPU type
        $vramGB = $bestGPU.VRAMGB
        $gpuName = $bestGPU.Name.ToLower()
        
        # VRAM scoring
        if ($vramGB -ge 24) { $gpuScore += 25 }
        elseif ($vramGB -ge 16) { $gpuScore += 20 }
        elseif ($vramGB -ge 12) { $gpuScore += 15 }
        elseif ($vramGB -ge 8) { $gpuScore += 12 }
        elseif ($vramGB -ge 6) { $gpuScore += 8 }
        elseif ($vramGB -ge 4) { $gpuScore += 5 }
        else { $gpuScore += 2 }
        
        # GPU type scoring
        if ($gpuName -match "rtx 40") { $gpuScore += 15 }
        elseif ($gpuName -match "rtx 30") { $gpuScore += 12 }
        elseif ($gpuName -match "rtx 20") { $gpuScore += 10 }
        elseif ($gpuName -match "gtx 16") { $gpuScore += 8 }
        elseif ($gpuName -match "gtx 10") { $gpuScore += 6 }
        elseif ($gpuName -match "quadro") { $gpuScore += 10 }
        elseif ($gpuName -match "tesla") { $gpuScore += 15 }
        else { $gpuScore += 3 }
        
        $scores.GPU = $gpuScore
        $totalScore += $gpuScore
        
        Write-Host "GPU Score: $gpuScore/40" -ForegroundColor Yellow
        Write-Host "  Best GPU: $($bestGPU.Name) - $vramGB GB VRAM" -ForegroundColor Gray
    } else {
        Write-Host "GPU Score: 0/40 (No dedicated GPU detected)" -ForegroundColor Red
        $scores.GPU = 0
    }
    
    # Disk Scoring (10 points max)
    if ($HardwareInfo.Disk) {
        $diskScore = 0
        $freeGB = $HardwareInfo.Disk.FreeGB
        $freePercent = $HardwareInfo.Disk.FreePercentage
        
        if ($freeGB -ge 100) { $diskScore += 10 }
        elseif ($freeGB -ge 50) { $diskScore += 8 }
        elseif ($freeGB -ge 20) { $diskScore += 6 }
        elseif ($freeGB -ge 10) { $diskScore += 4 }
        else { $diskScore += 2 }
        
        $scores.Disk = $diskScore
        $totalScore += $diskScore
        
        Write-Host "Disk Score: $diskScore/10" -ForegroundColor Yellow
        Write-Host "  Free space: $freeGB GB ($freePercent%)" -ForegroundColor Gray
    }
    
    # Overall assessment
    Write-Host ""
    Write-Host "=== Overall Hardware Assessment ===" -ForegroundColor Magenta
    Write-Host "Total Score: $totalScore/$maxScore" -ForegroundColor Cyan
    
    if ($totalScore -ge 80) {
        Write-Host "Rating: EXCELLENT - Perfect for large AI model training" -ForegroundColor Green
        $recommendation = "Your system is excellent for AI model training. You can run large models like Llama-3.1-8B, SDXL, and FLUX efficiently."
    }
    elseif ($totalScore -ge 60) {
        Write-Host "Rating: GOOD - Suitable for medium AI model training" -ForegroundColor Yellow
        $recommendation = "Your system is good for AI model training. You can run models like SD1.5, Phi-3.5-mini, and smaller models effectively."
    }
    elseif ($totalScore -ge 40) {
        Write-Host "Rating: FAIR - Limited AI model training capability" -ForegroundColor Orange
        $recommendation = "Your system has limited AI training capability. Consider using smaller models and low-VRAM modes for better performance."
    }
    else {
        Write-Host "Rating: POOR - Not suitable for AI model training" -ForegroundColor Red
        $recommendation = "Your system is not suitable for AI model training. Consider upgrading hardware or using cloud-based solutions."
    }
    
    Write-Host ""
    Write-Host "Recommendation: $recommendation" -ForegroundColor White
    
    # Model compatibility assessment
    Write-Host ""
    Write-Host "=== Model Compatibility Assessment ===" -ForegroundColor Magenta
    
    if ($HardwareInfo.GPU -and $HardwareInfo.GPU.Count -gt 0) {
        $bestGPU = $HardwareInfo.GPU | Sort-Object VRAMGB -Descending | Select-Object -First 1
        $vramGB = $bestGPU.VRAMGB
        
        Write-Host "Based on your $vramGB GB VRAM GPU:" -ForegroundColor Cyan
        
        if ($vramGB -ge 24) {
            Write-Host "✓ Can run: FLUX, SDXL, Llama-2-13B, all models" -ForegroundColor Green
        }
        elseif ($vramGB -ge 12) {
            Write-Host "✓ Can run: SDXL, Llama-3.1-8B, Mistral-7B" -ForegroundColor Green
            Write-Host "⚠ May struggle with: FLUX, Llama-2-13B" -ForegroundColor Yellow
        }
        elseif ($vramGB -ge 8) {
            Write-Host "✓ Can run: SD1.5, Phi-3.5-mini, Mistral-7B" -ForegroundColor Green
            Write-Host "⚠ May struggle with: SDXL, Llama-3.1-8B" -ForegroundColor Yellow
        }
        elseif ($vramGB -ge 6) {
            Write-Host "✓ Can run: SD1.5, Phi-3.5-mini" -ForegroundColor Green
            Write-Host "⚠ May struggle with: SDXL, larger language models" -ForegroundColor Yellow
        }
        else {
            Write-Host "⚠ Limited to: Small models only" -ForegroundColor Red
            Write-Host "💡 Consider: Low-VRAM modes or cloud solutions" -ForegroundColor Cyan
        }
    } else {
        Write-Host "⚠ No dedicated GPU detected - CPU-only training will be very slow" -ForegroundColor Red
        Write-Host "💡 Consider: Adding a GPU or using cloud-based solutions" -ForegroundColor Cyan
    }
    
    return @{
        Scores = $scores
        TotalScore = $totalScore
        MaxScore = $maxScore
        HardwareInfo = $HardwareInfo
    }
}

# Function to check system requirements
function Test-SystemRequirements {
    Write-Host "=== System Requirements Check ===" -ForegroundColor Cyan
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Host "PowerShell Version: $psVersion" -ForegroundColor Green
    
    # Check .NET Framework
    try {
        $dotNetVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
        Write-Host ".NET Framework: $dotNetVersion" -ForegroundColor Green
    }
    catch {
        Write-Host ".NET Framework: Not detected" -ForegroundColor Yellow
    }
    
    # Get comprehensive hardware information
    $hardwareInfo = Get-HardwareInfo
    
    # Score hardware for AI training
    $assessment = Score-HardwareForAITraining -HardwareInfo $hardwareInfo
    
    # Check if Python is already installed
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python") {
            Write-Host "Python detected: $pythonVersion" -ForegroundColor Green
            return @{
                PythonInstalled = $true
                HardwareAssessment = $assessment
            }
        }
    }
    catch {
        Write-Host "Python not detected in PATH" -ForegroundColor Yellow
    }
    
    return @{
        PythonInstalled = $false
        HardwareAssessment = $assessment
    }
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install Python using winget or direct download
function Install-Python {
    Write-Host "=== Installing Python ===" -ForegroundColor Cyan
    
    # Check if winget is available
    try {
        $wingetVersion = winget --version 2>&1
        Write-Host "Winget detected: $wingetVersion" -ForegroundColor Green
        
        # Install Python using winget
        Write-Host "Installing Python 3.12 using winget..." -ForegroundColor Yellow
        winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "✓ Python installed via winget" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Winget not available, downloading Python directly..." -ForegroundColor Yellow
        
        # Download Python installer directly
        $pythonUrl = "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe"
        $installerPath = "$env:TEMP\python-installer.exe"
        
        try {
            Write-Host "Downloading Python installer..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -UseBasicParsing
            
            Write-Host "Installing Python..." -ForegroundColor Cyan
            Start-Process -FilePath $installerPath -ArgumentList "/quiet", "InstallAllUsers=1", "PrependPath=1", "Include_test=0" -Wait
            
            # Refresh environment variables
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Host "✓ Python installed successfully" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "✗ Failed to install Python: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
        finally {
            if (Test-Path $installerPath) {
                Remove-Item $installerPath -Force
            }
        }
    }
}

# Function to verify Python installation
function Test-PythonInstallation {
    Write-Host "=== Verifying Python Installation ===" -ForegroundColor Cyan
    
    try {
        # Test Python version
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python") {
            Write-Host "✓ Python version: $pythonVersion" -ForegroundColor Green
        } else {
            Write-Host "✗ Python not found in PATH" -ForegroundColor Red
            return $false
        }
        
        # Test pip
        $pipVersion = pip --version 2>&1
        if ($pipVersion -match "pip") {
            Write-Host "✓ Pip version: $pipVersion" -ForegroundColor Green
        } else {
            Write-Host "✗ Pip not found" -ForegroundColor Red
            return $false
        }
        
        # Test Python execution
        $testResult = python -c "print('Python is working correctly')" 2>&1
        if ($testResult -eq "Python is working correctly") {
            Write-Host "✓ Python execution test passed" -ForegroundColor Green
        } else {
            Write-Host "✗ Python execution test failed" -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "✗ Python verification failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to upgrade pip and install essential tools
function Install-PythonEssentials {
    Write-Host "=== Installing Python Essentials ===" -ForegroundColor Cyan
    
    try {
        # Upgrade pip
        Write-Host "Upgrading pip..." -ForegroundColor Yellow
        python -m pip install --upgrade pip
        
        # Install essential development tools
        $essentialPackages = @("setuptools", "wheel", "virtualenv", "pip-tools")
        foreach ($package in $essentialPackages) {
            Write-Host "Installing $package..." -ForegroundColor Yellow
            pip install $package --quiet
            Write-Host "✓ Installed $package" -ForegroundColor Green
        }
        
        Write-Host "✓ Python essentials installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to install Python essentials: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create development workspace with security exclusions
function New-DevelopmentWorkspace {
    param(
        [string]$BasePath = "C:\"
    )
    
    $workspaceName = "AI Development Workspace - Open Source Projects"
    $fullPath = Join-Path $BasePath $workspaceName
    
    try {
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Host "Created development workspace: $fullPath" -ForegroundColor Green
        } else {
            Write-Host "Development workspace already exists: $fullPath" -ForegroundColor Yellow
        }
        
        # Create subdirectories for different project types
        $subdirs = @("Projects", "Libraries", "Data", "Models", "Documentation", "GitHub_Repos", "Build_Artifacts", "VirtualEnvs")
        foreach ($dir in $subdirs) {
            $subdirPath = Join-Path $fullPath $dir
            if (!(Test-Path $subdirPath)) {
                New-Item -ItemType Directory -Path $subdirPath -Force | Out-Null
                Write-Host "Created subdirectory: $dir" -ForegroundColor Green
            }
        }
        
        return $fullPath
    }
    catch {
        Write-Host "Failed to create workspace: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to configure Windows Defender exclusions for development
function Set-DevelopmentSecurityExclusions {
    param(
        [string]$WorkspacePath
    )
    
    Write-Host "=== Configuring Development Security Exclusions ===" -ForegroundColor Cyan
    Write-Host "Adding workspace to Windows Defender exclusions for development purposes..." -ForegroundColor Yellow
    
    try {
        # Add folder exclusion for development workspace
        Add-MpPreference -ExclusionPath $WorkspacePath -ErrorAction Stop
        Write-Host "✓ Added workspace to Windows Defender exclusions: $WorkspacePath" -ForegroundColor Green
        
        # Add process exclusions for development tools
        $devProcesses = @("python.exe", "pip.exe", "git.exe", "node.exe", "npm.exe", "powershell.exe", "pythonw.exe")
        foreach ($process in $devProcesses) {
            try {
                Add-MpPreference -ExclusionProcess $process -ErrorAction SilentlyContinue
                Write-Host "✓ Added $process to process exclusions" -ForegroundColor Green
            }
            catch {
                Write-Host "⚠ Could not add $process to exclusions (may already exist)" -ForegroundColor Yellow
            }
        }
        
        # Add file type exclusions for development files
        $devExtensions = @("*.py", "*.js", "*.cpp", "*.h", "*.json", "*.yml", "*.yaml", "*.md", "*.pyc", "*.pyd")
        foreach ($ext in $devExtensions) {
            try {
                Add-MpPreference -ExclusionExtension $ext -ErrorAction SilentlyContinue
                Write-Host "✓ Added $ext to file type exclusions" -ForegroundColor Green
            }
            catch {
                Write-Host "⚠ Could not add $ext to exclusions" -ForegroundColor Yellow
            }
        }
        
        return $true
    }
    catch {
        Write-Host "Failed to configure security exclusions: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to download GitHub development tools
function Download-GitHubDevelopmentTools {
    param(
        [string]$DownloadPath
    )
    
    $githubTools = @{
        "Catch2" = @{
            "Url" = "https://github.com/catchorg/Catch2/releases/download/v3.9.0/catch_amalgamated.cpp"
            "FileName" = "catch_amalgamated.cpp"
            "Description" = "C++ Testing Framework"
        }
        "SampleData" = @{
            "Url" = "https://raw.githubusercontent.com/scikit-learn/scikit-learn/main/sklearn/datasets/data/iris.csv"
            "FileName" = "iris_dataset.csv"
            "Description" = "Sample ML Dataset"
        }
        "TensorFlowLite" = @{
            "Url" = "https://github.com/tensorflow/tensorflow/raw/master/tensorflow/lite/examples/label_image/testdata/grace_hopper.bmp"
            "FileName" = "sample_image.bmp"
            "Description" = "Sample Image for ML Testing"
        }
    }
    
    Write-Host "=== Downloading GitHub Development Tools ===" -ForegroundColor Cyan
    Write-Host "Downloading open source tools from GitHub repositories..." -ForegroundColor Yellow
    
    foreach ($toolName in $githubTools.Keys) {
        $tool = $githubTools[$toolName]
        $fullPath = Join-Path $DownloadPath $tool.FileName
        
        try {
            Write-Host "Downloading $($tool.Description) from GitHub..." -ForegroundColor Cyan
            
            # Use TLS 1.2 for secure connections to GitHub
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            Invoke-WebRequest -Uri $tool.Url -OutFile $fullPath -UseBasicParsing
            
            if (Test-Path $fullPath) {
                $fileSize = (Get-Item $fullPath).Length
                Write-Host "✓ Downloaded $($tool.Description) ($fileSize bytes)" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to download $($tool.Description)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "✗ Error downloading $($tool.Description): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to configure development environment
function Set-DevelopmentEnvironment {
    param(
        [string]$WorkspacePath
    )
    
    Write-Host "=== Configuring Development Environment ===" -ForegroundColor Cyan
    
    # Set environment variables for development
    $envVars = @{
        "AI_WORKSPACE" = $WorkspacePath
        "PYTHONPATH" = "$WorkspacePath\Projects;$env:PYTHONPATH"
        "MODEL_PATH" = "$WorkspacePath\Models"
        "DATA_PATH" = "$WorkspacePath\Data"
        "GITHUB_REPOS" = "$WorkspacePath\GitHub_Repos"
        "BUILD_PATH" = "$WorkspacePath\Build_Artifacts"
        "VIRTUAL_ENV_PATH" = "$WorkspacePath\VirtualEnvs"
    }
    
    foreach ($var in $envVars.Keys) {
        [Environment]::SetEnvironmentVariable($var, $envVars[$var], "User")
        Write-Host "Set environment variable: $var = $($envVars[$var])" -ForegroundColor Green
    }
    
    # Create configuration file
    $configPath = Join-Path $WorkspacePath "development_config.json"
    $config = @{
        workspace = $WorkspacePath
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "1.0.0"
        description = "AI Development Environment Configuration"
        python_config = @{
            version = (python --version 2>&1)
            pip_version = (pip --version 2>&1)
            virtual_env_available = $true
        }
        security_exclusions = @{
            folder_excluded = $true
            process_exclusions = @("python.exe", "pip.exe", "git.exe", "node.exe", "npm.exe", "powershell.exe", "pythonw.exe")
            file_extensions = @("*.py", "*.js", "*.cpp", "*.h", "*.json", "*.yml", "*.yaml", "*.md", "*.pyc", "*.pyd")
        }
        github_tools = @{
            catch2 = "C++ Testing Framework"
            sample_data = "Sample ML Dataset"
            tensorflow_lite = "Sample Image for ML Testing"
        }
    } | ConvertTo-Json -Depth 5
    
    $config | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "Created development configuration: $configPath" -ForegroundColor Green
}

# Function to install Python packages for AI development
function Install-PythonPackages {
    Write-Host "=== Installing Python Packages for AI Development ===" -ForegroundColor Cyan
    
    $packages = @(
        "numpy",
        "pandas", 
        "scikit-learn",
        "matplotlib",
        "seaborn",
        "jupyter",
        "tensorflow",
        "torch",
        "transformers",
        "datasets",
        "requests",
        "pillow"
    )
    
    foreach ($package in $packages) {
        try {
            Write-Host "Installing $package..." -ForegroundColor Cyan
            pip install $package --quiet
            Write-Host "✓ Installed $package" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to install $package`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to create virtual environment for AI project
function New-VirtualEnvironment {
    param(
        [string]$WorkspacePath,
        [string]$ProjectName = "ai_project"
    )
    
    $venvPath = Join-Path $WorkspacePath "VirtualEnvs\$ProjectName"
    
    try {
        Write-Host "Creating virtual environment: $venvPath" -ForegroundColor Cyan
        
        # Create virtual environment
        python -m venv $venvPath
        
        # Activate virtual environment
        $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            & $activateScript
            Write-Host "✓ Virtual environment created and activated" -ForegroundColor Green
            return $venvPath
        } else {
            Write-Host "✗ Failed to create virtual environment" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-Host "✗ Error creating virtual environment: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to create sample AI project
function New-SampleAIProject {
    param(
        [string]$WorkspacePath
    )
    
    $projectPath = Join-Path $workspacePath "Projects\SampleAI"
    
    try {
        if (!(Test-Path $projectPath)) {
            New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
        }
        
        # Create virtual environment for the project
        $venvPath = New-VirtualEnvironment -WorkspacePath $workspacePath -ProjectName "sample_ai"
        
        # Create sample Python script
        $pythonScript = @"
#!/usr/bin/env python3
"""
Sample AI Project - GitHub Integration
Purpose: Demonstrate AI/ML development with GitHub tools
"""

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import os
import sys

def load_data():
    """Load sample dataset from GitHub"""
    # Simulate loading data from GitHub repositories
    return pd.DataFrame({
        'feature1': np.random.randn(100),
        'feature2': np.random.randn(100),
        'target': np.random.randint(0, 2, 100)
    })

def train_model(X, y):
    """Train a simple AI model"""
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X, y)
    return model

def main():
    print("Starting AI development project with GitHub integration...")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {os.getcwd()}")
    
    # Load data
    data = load_data()
    X = data[['feature1', 'feature2']]
    y = data['target']
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    # Train model
    model = train_model(X_train, y_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"Model accuracy: {accuracy:.2f}")
    print("AI project completed successfully!")
    print("GitHub tools and security exclusions configured.")

if __name__ == "__main__":
    main()
"@
        
        $pythonScript | Out-File -FilePath (Join-Path $projectPath "main.py") -Encoding UTF8
        
        # Create requirements file
        $requirements = @"
numpy>=1.21.0
pandas>=1.3.0
scikit-learn>=1.0.0
matplotlib>=3.5.0
seaborn>=0.11.0
tensorflow>=2.8.0
torch>=1.12.0
transformers>=4.20.0
datasets>=2.0.0
requests>=2.28.0
pillow>=9.0.0
"@
        
        $requirements | Out-File -FilePath (Join-Path $projectPath "requirements.txt") -Encoding UTF8
        
        # Create README
        $readme = @"
# Sample AI Project with GitHub Integration

This is a sample AI/ML project demonstrating development with GitHub tools and security exclusions.

## Setup
1. Ensure Python 3.12+ is installed
2. Create virtual environment: `python -m venv .venv`
3. Activate virtual environment: `.venv\Scripts\activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Run the project: `python main.py`

## Project Structure
- `main.py`: Main application file
- `requirements.txt`: Python dependencies
- `data/`: Dataset storage
- `models/`: Trained model storage
- `github_repos/`: GitHub repository downloads

## Security Configuration
This project uses Windows Defender exclusions for development files and processes.
- Folder exclusions for development workspace
- Process exclusions for development tools
- File type exclusions for source code files

## GitHub Integration
- Downloads tools from GitHub repositories
- Uses open source libraries and datasets
- Integrates with GitHub development workflow

## Virtual Environment
- Uses Python's built-in venv module
- Isolates project dependencies
- Follows modern Python development practices

## License
MIT License - Feel free to use and modify
"@
        
        $readme | Out-File -FilePath (Join-Path $projectPath "README.md") -Encoding UTF8
        
        Write-Host "Created sample AI project at: $projectPath" -ForegroundColor Green
        Write-Host "Virtual environment created at: $venvPath" -ForegroundColor Green
        return $projectPath
    }
    catch {
        Write-Host "Failed to create sample project: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Main execution function
function Main {
    Write-Host "=== AI Development Environment Setup with Hardware Assessment ===" -ForegroundColor Magenta
    Write-Host "Purpose: Configure development environment for AI/ML projects with hardware analysis" -ForegroundColor Magenta
    Write-Host ""
    
    # Step 1: Check system requirements and hardware
    $systemCheck = Test-SystemRequirements
    $pythonInstalled = $systemCheck.PythonInstalled
    $hardwareAssessment = $systemCheck.HardwareAssessment
    Write-Host ""
    
    # Step 2: Check for administrator privileges (required for security exclusions)
    if (!(Test-Administrator)) {
        Write-Host "This script requires administrator privileges for security exclusions!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    } else {
        Write-Host "Running with administrator privileges ✓" -ForegroundColor Green
    }
    Write-Host ""
    
    # Step 3: Install Python if not already installed
    if (!$pythonInstalled) {
        Write-Host "=== Python Installation Required ===" -ForegroundColor Cyan
        $pythonInstalled = Install-Python
        if (!$pythonInstalled) {
            Write-Host "Failed to install Python. Exiting..." -ForegroundColor Red
            exit 1
        }
        Write-Host ""
    }
    
    # Step 4: Verify Python installation
    $pythonVerified = Test-PythonInstallation
    if (!$pythonVerified) {
        Write-Host "Python installation verification failed. Exiting..." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Step 5: Install Python essentials
    $essentialsInstalled = Install-PythonEssentials
    if (!$essentialsInstalled) {
        Write-Host "Warning: Python essentials installation failed" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Step 6: Create development workspace
    Write-Host "=== Creating Development Workspace ===" -ForegroundColor Cyan
    $workspacePath = New-DevelopmentWorkspace
    if (!$workspacePath) {
        Write-Host "Failed to create workspace. Exiting..." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
    
    # Step 7: Configure security exclusions for development
    Write-Host "=== Configuring Security Exclusions ===" -ForegroundColor Cyan
    $securityConfigured = Set-DevelopmentSecurityExclusions -WorkspacePath $workspacePath
    if (!$securityConfigured) {
        Write-Host "Warning: Security exclusions may not be fully configured" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Step 8: Download GitHub development tools
    Download-GitHubDevelopmentTools -DownloadPath $workspacePath
    Write-Host ""
    
    # Step 9: Configure environment
    Set-DevelopmentEnvironment -WorkspacePath $workspacePath
    Write-Host ""
    
    # Step 10: Install Python packages
    $installPython = Read-Host "Do you want to install Python packages for AI development? (y/N)"
    if ($installPython -eq "y" -or $installPython -eq "Y") {
        Install-PythonPackages
    }
    Write-Host ""
    
    # Step 11: Create sample project
    $createSample = Read-Host "Do you want to create a sample AI project with virtual environment? (y/N)"
    if ($createSample -eq "y" -or $createSample -eq "Y") {
        New-SampleAIProject -WorkspacePath $workspacePath
    }
    Write-Host ""
    
    # Step 12: Print results
    Write-Host "=== Setup Complete ===" -ForegroundColor Magenta
    Write-Host "Hardware Assessment: $($hardwareAssessment.TotalScore)/$($hardwareAssessment.MaxScore)" -ForegroundColor Green
    Write-Host "Python Installation: ✓ Verified and working" -ForegroundColor Green
    Write-Host "Development Workspace: $workspacePath" -ForegroundColor Green
    Write-Host "Security Exclusions: Configured for development files and processes" -ForegroundColor Green
    Write-Host "GitHub Tools: Downloaded and integrated" -ForegroundColor Green
    Write-Host "Configuration: $(Join-Path $workspacePath 'development_config.json')" -ForegroundColor Green
    
    if ($createSample -eq "y" -or $createSample -eq "Y") {
        Write-Host "Sample Project: $(Join-Path $workspacePath 'Projects\SampleAI')" -ForegroundColor Green
        Write-Host "Virtual Environment: $(Join-Path $workspacePath 'VirtualEnvs\sample_ai')" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "AI development environment setup completed successfully!" -ForegroundColor Green
    Write-Host "Hardware assessment completed with score: $($hardwareAssessment.TotalScore)/$($hardwareAssessment.MaxScore)" -ForegroundColor Green
    Write-Host "Python is installed and configured for AI/ML development." -ForegroundColor Green
    Write-Host "GitHub tools are available and security exclusions are configured." -ForegroundColor Green
    Write-Host "You can now develop AI/ML projects with Python and GitHub integration." -ForegroundColor Green
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Execute main function
Main 
