<#=================================================================================================
  Scripts/setup-vcpkg-manifest.ps1 (Windows PowerShell 7.5 + 이상)
  - vcpkg.exe install (Manifest + overlay + triplet)
  - ninja 연동 설치
  - overlay port 의 재정의 cmake 로직 실행
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

    # vcpkg.json 이 있는 프로젝트 루트 (반드시 절대경로)
    [ValidateScript({
        if (-not $_) { throw "ProjectRoot is empty." }
        if (-not [System.IO.Path]::IsPathRooted($_)) {
            throw "ProjectRoot must be an absolute path. Given: '$_'"
        }
        if (-not (Test-Path $_)) {
            throw "ProjectRoot not found: $_"
        }
        $true
    })]  
    [string]$ProjectRoot = "",

    # 절대경로 or 상대경로, 상대경로일 경우 ($ProjectRoot/$InstallBasePath)
    [string]$InstallBasePath = "vcpkg_installed",

    # 대상 트립렛들: 한 개 이상, 각 항목은 공백이 아닌 문자열이어야 함
    [ValidateScript({
        if (-not $_ -or $_.Count -eq 0) { throw "Triplets must contain at least one item." }
        foreach ($t in $_) {
            if ([string]::IsNullOrWhiteSpace($t)) {
                throw "Triplets contains an empty or whitespace item."
            }
        }
        $true
    })]
    [string[]]$Triplets = @(),

    [string[]]$OverlayPorts = @(),
    [string[]]$OverlayTriplets = @(),
    [string]$BinarySources = "clear;files,.\vcpkg-BinaryCache,readwrite",

    # (선택) 빌드 후 buildtrees/packages 정리
    [switch]$CleanAfterBuild = $true,
    # (선택) 다른 프로세스의 vcpkg 락을 기다림
    [switch]$WaitForLock = $true
)

Import-Module "$PSScriptRoot\vcpkg-helper.psm1" -Force

# =================================================================================================
# 내부 함수 정의부
# =================================================================================================

function Install-Triplet( [string]$VcpkgExe
                        , [string]$Triplet
                        , [string]$ProjectRoot, [string]$InstallBasePath
                        , [string]$OverlayPorts, [string]$OverlayTriplets
                        , [string]$BinarySources
                        , [bool]$Clean, [bool]$Wait ) {
    Write-Host "ProjectRoot = $ProjectRoot"
    Write-Host "InstallBasePath = $InstallBasePath"
    $installBucketPath = Get-InstallBucket -Triplet $Triplet -InstallBasePath $InstallBasePath

    $args = @(
        "install", 
        "--triplet", $Triplet,
        "--vcpkg-root=$VcpkgRoot",
        "--x-manifest-root=$ProjectRoot",
        "--x-install-root=$installBucketPath",
        "--binarysource=$BinarySources"
    )

    if($OverlayPorts)
    {
        $args += "--overlay-ports=$OverlayPorts"
    }
    if($OverlayTriplets)
    {
        $args += "--overlay-triplets=$OverlayTriplets"
    }

    if ($Clean) { 
        $args += "--clean-buildtrees-after-build"
        $args += "--clean-packages-after-build" 
    }
    if ($Wait) { $args += "--x-wait-for-lock" }

    Write-Host "`n===== vcpkg install Overlays (triplet:$Triplet) ====="
    $cmdLine = "$VcpkgExe $($args -join ' ')"
    Write-Host $cmdLine

    # vcpkg 명령어 실행
    & $VcpkgExe @args
    if ($LASTEXITCODE -ne 0) { throw "vcpkg install failed for Overlays (triplet:$Triplet) ($LASTEXITCODE)" }

    $tripletRoot = Join-Path $installBucketPath $Triplet
    $inc = Join-Path $tripletRoot "include"
    $lib = Join-Path $tripletRoot "lib"
    $dbg = Join-Path $tripletRoot "debug\lib"

    Write-Host "Installed to: $tripletRoot"
    Write-Host ("  {0} -> {1}" -f $inc, (Test-Path $inc | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
    Write-Host ("  {0} -> {1}" -f $lib, (Test-Path $lib | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
    Write-Host ("  {0} -> {1}" -f $dbg, (Test-Path $dbg | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
}


# =================================================================================================
# 메인(엔트리 포인트)
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
$vcpkgExe = Join-Path $VcpkgRoot $vcpkgExeName
Assert-File $vcpkgExe $vcpkgExeName

$installBasePath = Resolve-PathWithBaseOrThrow -BaseAbsolutePath $ProjectRoot -PathToCheck $InstallBasePath

$vcpkgJsonName = "vcpkg.json"
$vcpkgJsonPath = Join-Path $ProjectRoot $vcpkgJsonName
Assert-File $vcpkgJsonPath $vcpkgJsonName

Assert-VcpkgConfigStrict $ProjectRoot

$prevPATH = $env:PATH

Init-VcpkgMsvcEnvironment $Generator

# -------------------------------------------------------------------------------------------------
# Triplets 설치 실행
# -------------------------------------------------------------------------------------------------

foreach($t in $Triplets) {
    Write-Host ("Triplet -> {0}" -f $t)

    Install-Triplet `
        -Triplet $t `
        -VcpkgExe $vcpkgExe `
        -ProjectRoot $ProjectRoot -InstallBasePath $InstallBasePath `
        -OverlayPorts (Join-Semicolon $OverlayPorts) -OverlayTriplets (Join-Semicolon $OverlayTriplets) `
        -BinarySources $BinarySources `
        -Clean $CleanAfterBuild `
        -Wait $WaitForLock
}

$env:PATH = $prevPATH

Write-Host "`nAll done."

