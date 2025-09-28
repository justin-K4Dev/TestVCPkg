<#=================================================================================================
  Scripts/setup-vcpkg-classic.ps1 (Windows PowerShell 5.1 호환)
  - vcpkg "클래식 모드"로 원하는 포트들을 트립릿별 설치
  - 포트 예: "curl", "curl[core,ssl,sspi]", "openssl", "zlib", "boost-filesystem"
  - 버전 고정은 클래식 모드에선 불가(매니페스트 모드 필요)
  - 설치 위치: <VCPKG_ROOT>\installed\<triplet>

  [core 의미]
  - `port[core]`         : 기본 기능(default features) 끄고 최소만 설치
  - `port[core,feat...]` : 기본 기능 끄고, 명시한 feat만 설치
  - `port`               : 기본 기능 포함 설치
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
    [string[]]$Triplets = @("x64-windows-static","x64-windows"),

    # 설치 포트들: 한 개 이상, 각 항목은 공백이 아닌 문자열이어야 함
    [Parameter(Mandatory)]
    [ValidateScript({
        if (-not $_ -or $_.Count -eq 0) { throw "Ports must contain at least one item." }
        foreach ($p in $_) {
            if ([string]::IsNullOrWhiteSpace($p)) {
                throw "Ports contains an empty or whitespace item."
            }
        }
        $true
    })]
    [string[]]$Ports = @("boost-filesystem"),

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
                        , [string[]]$Ports
                        , [bool]$Clean, [bool]$Wait ) {
    if (-not $Ports -or $Ports.Count -eq 0) { throw "No packages specified for triplet '$Triplet'." }

    $pkgSpecs = @()
    foreach($p in $Ports){ $pkgSpecs += ("{0}:{1}" -f $p, $Triplet) }

    $args = @("install","--classic")
    $args += $pkgSpecs

    if ($Clean) 
    { 
        $args += "--clean-buildtrees-after-build"
        $args += "--clean-packages-after-build" 
    }
    if ($Wait)  { $args += "--x-wait-for-lock" }

    Write-Host ""
    Write-Host ("=== vcpkg install (classic) : triplet = {0} ===" -f $Triplet)
    Write-Host ($VcpkgExe + " " + ($args -join ' '))

    & $VcpkgExe @args
    if ($LASTEXITCODE -ne 0) { throw ("vcpkg install failed for {0} ({1})" -f $Triplet,$LASTEXITCODE) }

    $vcpkgRoot = Split-Path -Parent $VcpkgExe
    $installPath = Join-Path $vcpkgRoot "installed"
    Write-Host ("Installed to: {0}\{1} (기본)" -f $installPath, $Triplet)
    Show-InstallTree -Root $installPath -Triplet $Triplet
}

# =================================================================================================
# 메인 (엔트리 포인트)
# =================================================================================================
$ErrorActionPreference = 'Stop'

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
Assert-AbsPath $VcpkgRoot
$vcpkgExe = Join-Path $VcpkgRoot $vcpkgExeName
Assert-File $vcpkgExe $vcpkgExeName

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
        -Ports $Ports `
        -Clean $CleanAfterBuild `
        -Wait $WaitForLock
}

$env:PATH = $prevPATH

Write-Host "`nAll done."
