<#=================================================================================================
  Scripts/upgrade-vcpkg-manifest.ps1  (Windows PowerShell 5.1 호환)
  - vcpkg update로 갱신 여부 점검
  - x-update-baseline 후, install로 적용
  - overlay/트립렛/바이너리캐시/락 대기/클린 옵션 지원
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

    # 대상 트립렛(비우면 전체/기본)
    [string[]]$Triplets = @(),

    # overlay/binary cache
    [string[]]$OverlayPorts = @(),
    [string[]]$OverlayTriplets = @(),
    [string]$BinarySources = "clear;files,.\vcpkg-BinaryCache,readwrite",

    # (선택) buildtrees/packages 정리
    [switch]$CleanAfterBuild = $true,
    # (선택) 다른 프로세스의 vcpkg 락을 기다림
    [switch]$WaitForLock = $true,

    # (선택) baseline 자동 갱신 시도
    [switch]$AutoUpdateBaseline = $true,
    # (선택) update 결과에 관계없이 install 강제 실행
    [switch]$ForceInstall = $true
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
$vcpkgExe = Join-Path $VcpkgRoot $vcpkgExeName
Assert-File $vcpkgExe $vcpkgExeName

$vcpkgJsonName = "vcpkg.json"
$vcpkgJsonPath = Join-Path $ProjectRoot $vcpkgJsonName
Assert-File $vcpkgJsonPath $vcpkgJsonName

$InstallBasePath = Test-PathWithBase -BaseAbsolutePath $ProjectRoot -PathToCheck $InstallBasePath

$prevPATH = $env:PATH
Init-VcpkgMsvcEnvironment $Generator

# -------------------------------------------------------------------------------------------------
# Triplets 업그레이드 실행
# -------------------------------------------------------------------------------------------------

# 공통 인자
$commonArgs = @()
if ($OverlayPorts)          { $commonArgs += "--overlay-ports=$(Join-Semicolon $OverlayPorts)" }
if ($OverlayTriplets)       { $commonArgs += "--overlay-triplets=$(Join-Semicolon $OverlayTriplets)" }
if ($BinarySources)         { $commonArgs += "--binarysource=$BinarySources" }
if ($WaitForLock.IsPresent) { $commonArgs += "--x-wait-for-lock" }

# 클린 옵션은 실제 빌드가 도는 명령(install/upgrade)에만 추가
$buildCleanArgs = @()
if ($CleanAfterBuild) {
    $buildCleanArgs += "--clean-buildtrees-after-build"
    $buildCleanArgs += "--clean-packages-after-build"
}

# update (전역)
Write-Host "===== vcpkg update ====="
$upd = & $vcpkgExe @("update") 2>&1
$updateText = ($upd -join "`n")
Write-Host $updateText

$needs = Needs-Upgrade $updateText

Write-Host "`n[Mode] Manifest (vcpkg.json detected at $ProjectRoot)"

# 매니페스트 모드 권장 환경변수
$env:VCPKG_FEATURE_FLAGS  = "manifests,registries,binarycaching"
$env:VCPKG_MANIFEST_INSTALL = "1"

# (옵션) baseline 자동 갱신
if ($AutoUpdateBaseline.IsPresent) {
    Write-Host "→ x-update-baseline 실행(필요 시 baseline 업데이트 안내/적용)"
    # add-initial-baseline 은 첫 설정시에만; 이미 있으면 최신 제안만 출력됩니다.
    & $vcpkgExe @("x-update-baseline","--add-initial-baseline","--x-manifest-root=$ProjectRoot") 2>&1 | Write-Host
    # 실제 vcpkg.json의 baseline/버전 제약 편집은 정책상 사람이 검토 후 반영하는 게 안전합니다.
}

# install 실행 기준 결정
if (-not $needs -and -not $ForceInstall.IsPresent) {
    Write-Host "No changes detected. Use -ForceInstall to run anyway."
    return
}

# 트립렛 목록(명시 없으면 1회)
$tripletList = if ($Triplets -and $Triplets.Count -gt 0) { $Triplets } else { @($null) }

foreach ($t in $tripletList) {
    # 매니페스트 모드에선 install로 적용
    $args = @("install",
              "--x-manifest-root=$ProjectRoot") + $commonArgs + $buildCleanArgs

    if ($t) {
        # 설치 버킷(프로젝트 하위 vcpkg_installed/static or dynamic)
        $installBucketPath = Get-InstallBucket -Triplet $t -InstallBasePath $InstallBasePath
        if (-not (Test-Path $installBucketPath)) { New-Item -ItemType Directory -Path $installBucketPath | Out-Null }        
        $args += @("--triplet",$t,"--x-install-root=$installBucketPath")
        Write-Host "[$t] Running install... (install-root: $installBucketPath)"
    } else {
        Write-Host "Running install..."
    }

    & $vcpkgExe @args
    if ($LASTEXITCODE -ne 0) {
        throw ("vcpkg install failed{0} (exit {1})" -f ($(if ($t) { " for $t" } else { "" }), $LASTEXITCODE))
    }
}

$env:PATH = $prevPATH

Write-Host "`nAll done."