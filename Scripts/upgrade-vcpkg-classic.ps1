<#=================================================================================================
  Scripts/upgrade-vcpkg-classic.ps1
  - vcpkg update 실행 후, 업그레이드 필요하면 upgrade --no-dry-run 자동 실행
  - 바이너리 캐시/오버레이/트립렛 옵션 전달 가능
=================================================================================================#>

[CmdletBinding()]
param(
    # CMake for MSVS
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (-not $_ -or -not ($_.Trim())) {
            throw "Parameter -Generator must be a non-empty, non-whitespace string."
        }
        $true
    })]
    [string]$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207",

    # vcpkg 루트 경로 (vcpkg.exe, buildtrees, packages, downloads 위치)
    [ValidateScript({
        if (-not $_) { throw "VcpkgRoot is empty." }
        if (-not [System.IO.Path]::IsPathRooted($_)) {
            throw "VcpkgRoot must be an absolute path. Given: '$_'"
        }
        if (-not (Test-Path $_)) {
            throw "VcpkgRoot not found: $_"
        }
        $true
    })]  
    [string]$VcpkgRoot = "E:\Library\vcpkg",

    # 대상 트립렛(비우면 전체/기본)
    [string[]]$Triplets = @(),

    # overlay + triplet + binarycache
    [string[]]$OverlayPorts = @(),
    [string[]]$OverlayTriplets = @(),
    [string]$BinarySources = "clear;files,.\vcpkg-BinaryCache,readwrite",

    # (선택) 업그레이드 후 buildtrees/packages 정리
    [switch]$CleanAfterBuild = $true,
    # (선택) 다른 프로세스의 vcpkg 락을 기다림
    [switch]$WaitForLock = $true
)

Import-Module "$PSScriptRoot\vcpkg-helper.psm1" -Force

# =================================================================================================
# 메인 (엔트리 포인트)
# =================================================================================================

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩 체크 (한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
try { [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false) } catch {}
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
try { chcp 65001 | Out-Null } catch {}

# -------------------------------------------------------------------------------------------------
# 주요 설정 예외 체크
# -------------------------------------------------------------------------------------------------

$vcpkgExeName = "vcpkg.exe"
$vcpkgExe = (Join-Path $VcpkgRoot $vcpkgExeName)
Assert-File $vcpkgExe $vcpkgExeName

$prevPATH = $env:PATH
Init-VcpkgMsvcEnvironment $Generator

# -------------------------------------------------------------------------------------------------
# Triplets 업그레이드 실행
# -------------------------------------------------------------------------------------------------

# 공통 인자 구성
$commonArgs = @()
if ($OverlayPorts)          { $commonArgs += "--overlay-ports=$((($OverlayPorts | ForEach-Object { $_ }) -join ';'))" }
if ($OverlayTriplets)       { $commonArgs += "--overlay-triplets=$((($OverlayTriplets | ForEach-Object { $_ }) -join ';'))" }
if ($BinarySources)         { $commonArgs += "--binarysource=$BinarySources" }
if ($WaitForLock.IsPresent) { $commonArgs += "--x-wait-for-lock" }

# 업그레이드 전용 인자
$upgradeOnlyArgs = @()
if ($CleanAfterBuild) {
    $upgradeOnlyArgs += "--clean-buildtrees-after-build"
    $upgradeOnlyArgs += "--clean-packages-after-build"
}

# 트립렛 별로 수행(미지정이면 전체 1회)
$tripletList = @()
if ($Triplets -and $Triplets.Count -gt 0)   { $tripletList = $Triplets } 
else                                        { $tripletList = @($null) }

$overallUpgraded = $false
foreach ($t in $tripletList) {
    $argsUpdate = @("update") + $commonArgs
    $argsUpgrade = @("upgrade","--no-dry-run") + $commonArgs

    if ($t) { 
        $argsUpdate  += @("--triplet", $t)
        $argsUpgrade += @("--triplet", $t)
        Write-Host "===== Checking updates for triplet: $t ====="
    } else {
        Write-Host "===== Checking updates (all triplets) ====="
    }

    # vcpkg update
    $upd = & $vcpkgExe @argsUpdate 2>&1
    $needs = Needs-Upgrade ($upd -join "`n")

    if (-not $needs) {
        if ($t) { Write-Host "[$t] No upgrade required." }
        else    { Write-Host "No upgrade required." }
        continue
    }

    if ($t) { Write-Host "[$t] Upgrades available: running 'vcpkg upgrade --no-dry-run'..." }
    else    { Write-Host "Upgrades available: running 'vcpkg upgrade --no-dry-run'..." }

    # vcpkg upgrade --no-dry-run
    & $vcpkgExe @argsUpgrade
    if ($LASTEXITCODE -ne 0) {
        throw ("vcpkg upgrade failed{0} (exit {1})" -f ($(if($t){" for $t"}else{""}), $LASTEXITCODE))
    }
    $overallUpgraded = $true
}

$env:PATH = $prevPATH

if ($overallUpgraded)   { Write-Host "`nAll done." } 
else                    { Write-Host "`nEverything is up to date." }
