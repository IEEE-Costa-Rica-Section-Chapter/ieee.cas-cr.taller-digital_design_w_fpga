<#
.SYNOPSIS
  Install and verify the course toolchain on Windows 10/11.

.DESCRIPTION
  Safe to run again: every step is skipped when it is already done.
    1. OSS CAD Suite    downloaded from GitHub and unpacked in C:\oss-cad-suite
    2. GNU make         `winget install ezwinports.make` (an existing make or mingw32-make is used if found)
    3. VSCode           `winget install Microsoft.VisualStudioCode` plus the two extensions
    4. USB driver       checks whether Windows sees the board with the WinUSB driver (does NOT change drivers)
    5. Verification     copies project-template to a temp folder and runs make doctor, make sim, make build
  It never edits your PATH permanently: the course Makefile finds the suite by itself.

  Run it from the course repository, in PowerShell:
    powershell -ExecutionPolicy Bypass -File 0-Configuration\scripts\setup-windows.ps1

.PARAMETER SuiteDir     Where the suite lives (default C:\oss-cad-suite). Use a short path WITHOUT spaces.
.PARAMETER SkipVSCode   Do not install VSCode or its extensions.
.PARAMETER SkipMake     Do not install make.
.PARAMETER SkipVerify   Do not run the test build.
.PARAMETER InstallZadig Also install Zadig (winget akeo.ie.Zadig). It is only installed, never launched.
.PARAMETER Check        Change nothing; only verify what is installed.
.PARAMETER DryRun       Print what would be done; change nothing.

.NOTES
  Environment variable OSS_CAD_URL (a URL to the Windows .tgz) overrides the GitHub lookup.
  ASCII only on purpose: Windows PowerShell 5.1 reads BOM-less files as ANSI.
#>
[CmdletBinding()]
param(
  [string]$SuiteDir = 'C:\oss-cad-suite',
  [switch]$SkipVSCode,
  [switch]$SkipMake,
  [switch]$SkipVerify,
  [switch]$InstallZadig,
  [switch]$Check,
  [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir   = (Resolve-Path (Join-Path $ScriptDir '..\..')).Path
$Template  = Join-Path $RepoDir 'project-template'
$Extensions = @('mshr-h.veriloghdl', 'surfer-project.surfer')
$script:Results = New-Object System.Collections.ArrayList
$script:Failed = $false

function Step($t)  { Write-Host ""; Write-Host "== $t" }
function Add-Result($st, $key, $msg) { [void]$script:Results.Add([pscustomobject]@{ Status = $st; Key = $key; Message = $msg }) }
function Pass($key, $m) { Write-Host "   [ok]   $m";   Add-Result 'PASS' $key $m }
function Skip($key, $m) { Write-Host "   [skip] $m";   Add-Result 'SKIP' $key $m }
function Warn($key, $m) { Write-Host "   [warn] $m";   Add-Result 'WARN' $key $m }
function Bad($key, $m)  { Write-Host "   [FAIL] $m";   Add-Result 'FAIL' $key $m; $script:Failed = $true }
function Refresh-Path {
  $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $u = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$m;$u"
}
function Find-Cmd($name) { $c = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1; if ($c) { $c.Source } else { $null } }
function Get-SuiteRoot {
  foreach ($d in @($env:OSS_CAD_SUITE, $SuiteDir, (Join-Path $SuiteDir 'oss-cad-suite'))) {
    if ($d -and (Test-Path (Join-Path $d 'bin\yosys.exe'))) { return $d }
  }
  return $null
}
function Run-Tool($exe, $argList, $workDir, $name) {
  # runs a native command, returns exit code; output goes to <log>.out / <log>.err
  $o = Join-Path $workDir "$name.out"; $e = Join-Path $workDir "$name.err"
  $p = Start-Process -FilePath $exe -ArgumentList $argList -WorkingDirectory $workDir -NoNewWindow -Wait -PassThru -RedirectStandardOutput $o -RedirectStandardError $e
  return $p.ExitCode
}
function Show-Tail($workDir, $name) {
  foreach ($ext in 'err', 'out') {
    $f = Join-Path $workDir "$name.$ext"
    if ((Test-Path $f) -and (Get-Item $f).Length -gt 0) { Get-Content $f -Tail 10 | ForEach-Object { Write-Host "        $_" } }
  }
}

Write-Host "Digital Design with FPGA - setup (Windows)"
Write-Host "  suite folder : $SuiteDir"
Write-Host "  course repo  : $RepoDir"
if ($DryRun) { Write-Host '  DRY RUN: nothing will be changed' }
if ($Check)  { Write-Host '  CHECK ONLY: nothing will be installed' }
if ($SuiteDir -match '\s' -or $SuiteDir -match 'OneDrive') { Write-Host '  warning: use a short path without spaces and outside OneDrive' }
if ($PSVersionTable.PSVersion.Major -lt 5) { Write-Host 'PowerShell 5 or newer is required.'; exit 2 }

$change = -not ($Check -or $DryRun)   # true when we are allowed to change the system

# ------------------------------------------------------------ 1. OSS CAD Suite
Step '1/5 OSS CAD Suite'
$root = Get-SuiteRoot
if ($root) {
  Pass 'suite' "already installed in $root"
} elseif ($Check) {
  Bad 'suite' "not found in $SuiteDir"
} else {
  $url = $env:OSS_CAD_URL
  $name = $null
  if (-not $url) {
    Write-Host '   asking GitHub for the latest release...'
    try {
      $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest' -Headers @{ 'User-Agent' = 'ddfpga-setup' }
      $asset = $rel.assets | Where-Object { $_.name -match '^oss-cad-suite-windows-x64-\d+\.(tgz|exe)$' } | Select-Object -First 1
      if ($asset) { $url = $asset.browser_download_url; $name = $asset.name }
    } catch { Write-Host "   $($_.Exception.Message)" }
  }
  if (-not $url) {
    Bad 'suite' "could not find the download URL (network, proxy or GitHub rate limit). Download oss-cad-suite-windows-x64-<date>.tgz from https://github.com/YosysHQ/oss-cad-suite-build/releases/latest and rerun with `$env:OSS_CAD_URL=<url>, or unpack it to $SuiteDir yourself"
  } else {
    if (-not $name) { $name = Split-Path $url -Leaf }
    Write-Host "   download: $url"
    $parent = Split-Path -Parent $SuiteDir
    $drive = Get-PSDrive -Name ($parent.Substring(0, 1)) -ErrorAction SilentlyContinue
    if ($drive -and $drive.Free -lt 4GB) {
      Bad 'suite' "less than 4 GB free on drive $($parent.Substring(0,1)):"
    } elseif ($DryRun) {
      Write-Host "   (dry-run) would download ($name, ~0.6 GB) and unpack into $SuiteDir"
      Skip 'suite' 'dry run'
    } else {
      $tmp = Join-Path $parent ('ddtmp' + (Get-Random -Maximum 9999))
      New-Item -ItemType Directory -Force -Path $tmp | Out-Null
      $file = Join-Path $tmp $name
      $curl = Find-Cmd 'curl.exe'
      Write-Host '   downloading (this takes a few minutes)...'
      if ($curl) { & $curl -fL --retry 3 -o $file $url } else { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
      $okDl = (Test-Path $file) -and ((Get-Item $file).Length -gt 100MB)
      if (-not $okDl) {
        Bad 'suite' 'download failed or incomplete'
      } else {
        Write-Host '   unpacking (several thousand files; antivirus can make this slow)...'
        if ($name -like '*.tgz') {
          $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
          if (-not (Test-Path $tar)) { $tar = Find-Cmd 'tar.exe' }
          & $tar -xzf $file -C $tmp
        } else {
          & $file -y "-o$tmp" | Out-Null
        }
        $inner = Join-Path $tmp 'oss-cad-suite'
        if (Test-Path (Join-Path $inner 'bin\yosys.exe')) {
          if (Test-Path $SuiteDir) { Remove-Item -Recurse -Force $SuiteDir }
          Move-Item $inner $SuiteDir
          Pass 'suite' "installed in $SuiteDir"
        } else {
          Bad 'suite' 'unpacked, but oss-cad-suite\bin\yosys.exe was not found'
        }
      }
      Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
  }
}
$root = Get-SuiteRoot

# ------------------------------------------------------------------ 2. make
Step '2/5 GNU make'
$make = Find-Cmd 'make'
if (-not $make) { $make = Find-Cmd 'mingw32-make' }
if ($make) {
  Pass 'make' "found: $make"
} elseif ($SkipMake) {
  Skip 'make' '-SkipMake given'
} elseif ($Check) {
  Bad 'make' 'not found (install: winget install ezwinports.make)'
} elseif ($DryRun) {
  Write-Host '   (dry-run) winget install ezwinports.make'; Skip 'make' 'dry run'
} elseif (-not (Find-Cmd 'winget')) {
  Bad 'make' 'make not found and winget is not available. Install GNU make for Windows by hand (see step 0.1 of Module 0)'
} else {
  Write-Host '   installing GNU make with winget...'
  & winget install --id ezwinports.make -e --accept-package-agreements --accept-source-agreements | Out-Null
  Refresh-Path
  $make = Find-Cmd 'make'
  if ($make) { Pass 'make' "installed: $make" } else { Bad 'make' 'installed but not found; close and reopen the terminal, then run this script again' }
}

# --------------------------------------------------------------- 3. VSCode
Step '3/5 VSCode'
if ($SkipVSCode) {
  Skip 'vscode' '-SkipVSCode given'
} else {
  $code = Find-Cmd 'code.cmd'
  if (-not $code) { $code = Find-Cmd 'code' }
  if (-not $code) {
    $guess = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'
    if (Test-Path $guess) { $code = $guess }
  }
  if (-not $code -and $change -and (Find-Cmd 'winget')) {
    Write-Host '   installing VSCode with winget...'
    & winget install --id Microsoft.VisualStudioCode -e --accept-package-agreements --accept-source-agreements | Out-Null
    Refresh-Path
    $code = Find-Cmd 'code.cmd'
    if (-not $code) { $guess = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'; if (Test-Path $guess) { $code = $guess } }
  }
  if (-not $code) {
    Warn 'vscode' "VSCode ('code' command) not found. Install it from https://code.visualstudio.com (tick 'Add to PATH'), or rerun without -Check / -DryRun"
  } else {
    $have = @(& $code --list-extensions 2>$null)
    foreach ($e in $Extensions) {
      if ($have -contains $e) { Pass 'vscode' "extension $e present" }
      elseif (-not $change) { Warn 'vscode' "extension $e missing" }
      else {
        & $code --install-extension $e | Out-Null
        if ($LASTEXITCODE -eq 0) { Pass 'vscode' "extension $e installed" } else { Warn 'vscode' "could not install $e (search for it in the Extensions view)" }
      }
    }
  }
}

# ----------------------------------------------------- 4. USB driver (check)
Step '4/5 USB driver for the board'
if ($InstallZadig -and $change -and (Find-Cmd 'winget')) {
  & winget install --id akeo.ie.Zadig -e --accept-package-agreements --accept-source-agreements | Out-Null
  Write-Host '   Zadig installed (not launched). Use it only if the check below asks you to.'
}
try {
  $devs = @(Get-PnpDevice -PresentOnly -ErrorAction Stop | Where-Object { $_.InstanceId -match 'VID_0403&PID_6010' })
  if ($devs.Count -eq 0) {
    Warn 'driver' 'the board (USB 0403:6010) is not visible to Windows. Connect it with a data-capable USB-C cable (step 0.4). Not needed for simulation or make build.'
  } else {
    $winusb = $false
    foreach ($d in $devs) {
      $svc = (Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Service' -ErrorAction SilentlyContinue).Data
      Write-Host "   $($d.InstanceId)  driver service: $svc"
      if ($svc -eq 'WinUSB') { $winusb = $true }
    }
    if ($winusb) { Pass 'driver' 'a WinUSB interface exists for the board' }
    else { Warn 'driver' 'no WinUSB interface: openFPGALoader cannot open the board yet. Replace the driver of interface 0 (Zadig entry 'USB Debugger (Interface 0)', USB ID 0403 6010) with WinUSB (step 0.4).' }
  }
} catch {
  Warn 'driver' "could not query USB devices: $($_.Exception.Message)"
}

# ----------------------------------------------------------- 5. verification
Step '5/5 Verification (test build of the course template)'
if ($SkipVerify -or $DryRun) {
  Skip 'verify' 'verification skipped'
} elseif (-not (Test-Path $Template)) {
  Bad 'verify' "project-template not found at $Template (run this script from the course repository)"
} elseif (-not $root) {
  Bad 'verify' 'cannot verify: the suite is not installed'
} elseif (-not $make) {
  Bad 'verify' 'cannot verify: make is missing'
} else {
  $env:OSS_CAD_SUITE = $root
  $base = $env:TEMP
  if ($base -match '\s') { $base = 'C:\' }
  $W = Join-Path $base ('ddfpga-verify-' + (Get-Random -Maximum 99999))
  New-Item -ItemType Directory -Force -Path $W | Out-Null
  Copy-Item -Path (Join-Path $Template '*') -Destination $W -Recurse -Force
  if (Test-Path (Join-Path $W 'build')) { Remove-Item -Recurse -Force (Join-Path $W 'build') }

  $rc = Run-Tool $make 'doctor' $W 'doctor'
  if ($rc -eq 0) { Pass 'doctor' 'make doctor: every tool prints its version' } else { Bad 'doctor' "make doctor failed (exit $rc)"; Show-Tail $W 'doctor' }

  $rc = Run-Tool $make 'sim' $W 'sim'
  if ($rc -eq 0 -and (Select-String -Path (Join-Path $W 'sim.out') -Pattern 'PASS' -Quiet)) { Pass 'sim' 'make sim: testbench printed PASS' } else { Bad 'sim' "make sim failed (exit $rc)"; Show-Tail $W 'sim' }

  $rc = Run-Tool $make 'build' $W 'build'
  $fs = Join-Path $W 'build\top.fs'
  if ($rc -eq 0 -and (Test-Path $fs) -and (Get-Item $fs).Length -gt 0) {
    Pass 'build' "make build: bitstream created ($((Get-Item $fs).Length) bytes)"
    Get-Content (Join-Path $W 'build.out') | Where-Object { $_ -match 'LUT4|DFF|Max frequency' } | Select-Object -First 5 | ForEach-Object { Write-Host ("        " + ($_ -replace '^Info:\s*', '')) }
  } else { Bad 'build' "make build failed (exit $rc)"; Show-Tail $W 'build' }

  $scan = & (Join-Path $root 'bin\openFPGALoader.exe') --scan-usb 2>&1 | Out-String
  if ($scan -match '0403') { Pass 'board' 'board detected by openFPGALoader' }
  else { Warn 'board' 'board not detected by openFPGALoader (fine if it is not connected or the driver is not installed yet; step 0.4)' }

  Remove-Item -Recurse -Force $W -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------ summary
Step 'Summary'
foreach ($r in $script:Results) { Write-Host ("   {0,-5} {1,-8} {2}" -f $r.Status, $r.Key, $r.Message) }
Write-Host ''
if (-not $script:Failed) {
  Write-Host 'Result: everything required is OK.'
  if ($SuiteDir -ne 'C:\oss-cad-suite') { Write-Host "Because you used a custom folder, set the environment variable OSS_CAD_SUITE to $root." }
  Write-Host 'Next: copy project-template to a short path, open it in VSCode and continue with step 0.5 of Module 0.'
  exit 0
} else {
  Write-Host 'Result: something failed. Fix the [FAIL] lines above (Module 0, step 0.7 lists common causes) and run the script again.'
  exit 1
}
