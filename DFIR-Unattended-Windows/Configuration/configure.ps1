Write-Host "Windows10-Autounattend"

$runOnceRegistryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

# Change Power Plan
powercfg -change -monitor-timeout-ac 0 | Out-Null
powercfg -change -monitor-timeout-dc 0 | Out-Null
powercfg -change -disk-timeout-ac 0 | Out-Null
powercfg -change -disk-timeout-dc 0 | Out-Null
powercfg -change -standby-timeout-ac 0 | Out-Null
powercfg -change -standby-timeout-dc 0 | Out-Null
powercfg -change -hibernate-timeout-ac 0 | Out-Null
powercfg -change -hibernate-timeout-dc 0 | Out-Null

# Install Nuget PackageProvider
#if (-Not (Get-PackageProvider -Name NuGet)) {
    Write-Host "Install Nuget PackageProvider"
    Install-PackageProvider -Name NuGet -Confirm:$false -Force | Out-Null
#}

# Install PendingReboot Module
if (-Not (Get-Module -ListAvailable -Name PendingReboot)) {
    Write-Host "Install PendingReboot Module"
    Install-Module PendingReboot -Confirm:$false -Force | Out-Null
}

# Import PendingReboot Module
Import-Module PendingReboot

# Install WindowsUpdate Module
if (-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Install WindowsUpdate Module"
    Install-Module PSWindowsUpdate -Confirm:$false -Force | Out-Null
}

# Check is busy
while ((Get-WUInstallerStatus).IsBusy) {
    Write-Host "Windows Update installer is busy, wait..."
    Start-Sleep -s 10
}

# Install available Windows Updates (less 1GB)
Write-Host "Start installation system updates..."
Write-Host "This job will be automatically canceled if it takes longer than 15 minutes to complete"
Set-ItemProperty $runOnceRegistryPath -Name "UnattendInstall!" -Value "cmd /c powershell -ExecutionPolicy ByPass -File $PSCommandPath" | Out-Null

$updateJobTimeoutSeconds = 900

$code = {
    if ((Get-WindowsUpdate -MaxSize 1073741824 -Verbose).Count -gt 0) {
        try {
            $status = Get-WindowsUpdate -MaxSize 1073741824 -Install -AcceptAll -Confirm:$false
            if (($status | Where Result -eq "Installed").Length -gt 0)
            {
                Restart-Computer -Force
                return
            }
            
            if ((Test-PendingReboot).IsRebootPending) {
                Restart-Computer -Force
                return
            }
        } catch {
            Write-Host "Error:`r`n $_.Exception.Message"
            Restart-Computer -Force
        }
    }
}

$updateJob = Start-Job -ScriptBlock $code
if (Wait-Job $updateJob -Timeout $updateJobTimeoutSeconds) { 
    Receive-Job $updateJob
} else {
    Write-Host "Timeout exceeded"
    Receive-Job $updateJob
    Start-Sleep -s 10
}
Remove-Job -force $updateJob


# Install Chocolatey
if (-Not (Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install FlareVM Package Repo
choco sources add -n="FlareVm" -s "https://www.myget.org/F/vm-packages/api/v2" --priority 1
choco feature enable -n allowGlobalConfirmation
choco feature enable -n allowEmptyChecksums

# Required Chocolatey packages
$requiredPackages = @([pscustomobject]@{Name="notepadplusplus";Trust=$False},
                      [pscustomobject]@{Name="librewolf";Trust=$False},
                      [pscustomobject]@{Name="googlechrome";Trust=$True},
		      [pscustomobject]@{Name="ublockorigin-chrome";Trust=$True},
		      [pscustomobject]@{Name="winscp";Trust=$True},
		      [pscustomobject]@{Name="peazip";Trust=$True},
		      [pscustomobject]@{Name="docker-desktop";Trust=$True},
		      [pscustomobject]@{Name="putty";Trust=$True},
		      [pscustomobject]@{Name="winscp";Trust=$True},
		      [pscustomobject]@{Name="superputty";Trust=$True},
		      [pscustomobject]@{Name="vlc";Trust=$True},
		      [pscustomobject]@{Name="bleachbit";Trust=$True},
                      [pscustomobject]@{Name="capa.vm";Trust=$True}
                      [pscustomobject]@{Name="yara.vm";Trust=$True},
                      [pscustomobject]@{Name="hxd.vm";Trust=$True},
                      [pscustomobject]@{Name="cmder.vm";Trust=$True})
					  

# Load installed packages
$installedPackages = New-Object Collections.Generic.List[String]
$installedPackagesPath = Join-Path -Path $PSScriptRoot -ChildPath "installedPackages.txt"
if (Test-Path $installedPackagesPath -PathType Leaf) {
    $installedPackages.AddRange([string[]](Get-Content $installedPackagesPath))
}

# Calculate missing packages
$missingPackages = $requiredPackages | Where-Object { $installedPackages -NotContains $_.Name }

foreach ($package in $missingPackages) {
    if ((Test-PendingReboot).IsRebootPending) {
        Set-ItemProperty $runOnceRegistryPath -Name "UnattendInstall!" -Value "cmd /c powershell -ExecutionPolicy ByPass -File $PSCommandPath"
        Restart-Computer -Force
        return
    }

    if ($package.Trust) {
        Write-Host "Install Package without checksum check"
        choco install $package.Name -y --ignore-checksums
    } else {
        Write-Host "Install Package with checksum check"
        choco install $package.Name -y
    }

    # Add package to installed package list
    $installedPackages.Add($package.Name)

    # Save update to file
    $installedPackages | Out-File $installedPackagesPath
}

Remove-ItemProperty $runOnceRegistryPath -Name "UnattendInstall!"

Write-Host "Installation done"
Start-Sleep -s 60
