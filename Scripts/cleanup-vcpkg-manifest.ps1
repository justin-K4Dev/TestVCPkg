<#=================================================================================================
  Scripts/cleanup-vcpkg-manifest.ps1 (Windows PowerShell 7.2+)
  - manifest 모드에서 설치된 산출물 제거
  - manifest + overlay + custom install root (vcpkg_installed) 기준 정리
  - buildtrees/packages/binary cache 선택적 정리
=================================================================================================#>

[CmdletBinding(SupportsShouldProcess)]
param(
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

    # 대상 트립렛들
    [string[]]$Triplets = @("x64-windows-static"),

    # 절대경로 or 상대경로, 상대경로일 경우 ($ProjectRoot/$BinaryCachePath)
    [string]$BinaryCachePath = "vcpkg-BinaryCache",

    # (선택) 정리 스위치
    [bool]$PurgeBuildTrees = $true,
    [bool]$PurgePackages = $true,
    [bool]$PurgeBinaryCache = $false,

    # (선택) 안전장치
    [switch]$DryRun = $false,
    [switch]$Force = $true
)

Import-Module "$PSScriptRoot\vcpkg-helper.psm1" -Force

# =================================================================================================
# 메인 (엔트리 포인트)
# =================================================================================================
$ErrorActionPreference = "Stop"

$vcpkgExeName = "vcpkg.exe"
$vcpkgExe = Join-Path $VcpkgRoot $vcpkgExeName
Assert-File $vcpkgExe $vcpkgExeName

$InstallBasePath = Resolve-PathWithBaseOrThrow -BaseAbsolutePath $ProjectRoot -PathToCheck $InstallBasePath
$BinaryCachePath = Resolve-PathWithBaseOrThrow -BaseAbsolutePath $ProjectRoot -PathToCheck $BinaryCachePath

$vcpkgJsonName = "vcpkg.json"
$vcpkgJsonPath = Join-Path $ProjectRoot $vcpkgJsonName
Assert-File $vcpkgJsonPath $vcpkgJsonName

Write-Host "===== vcpkg uninstall (overlay/manifest) ====="
Write-Host "VcpkgRoot   : $VcpkgRoot"
Write-Host "ProjectRoot : $ProjectRoot"
Write-Host "InstallDir  : $InstallBasePath"
Write-Host "Triplets    : $([string]::Join(', ', $Triplets))"
Write-Host "Options     : PurgeBuildTrees=$PurgeBuildTrees PurgePackages=$PurgePackages PurgeBinaryCache=$PurgeBinaryCache DryRun=$DryRun"

foreach ($t in $Triplets) {
    Write-Host "`n----- Triplet: $t -----"

    $installBucketPath = Get-InstallBucket -Triplet $t -InstallBasePath $InstallBasePath
    $tripletRoot = Join-Path $installBucketPath $t
    if (-not (Test-Path $tripletRoot)) {
        Write-Host "Nothing installed at: $tripletRoot"
        continue
    }

    # 1) 설치된 포트 목록 추출
    $ports = Read-InstalledPortsFromInfoDir -TripletRoot $tripletRoot
    if ($ports.Count -eq 0) {
        Write-Host "No port info files found at: $(Join-Path $tripletRoot 'vcpkg\info')"
    } else {
        Write-Host ("Installed ports: " + ($ports -join ", "))
    }

    # 2) vcpkg_installed/<bucket>/<triplet> 제거
    Remove-Path -Path $tripletRoot -What "installed($t)" -DryRun:$DryRun -Force:$Force

    # 3) buildtrees/<port> 제거 (선택)
    if ($PurgeBuildTrees -and $ports.Count -gt 0) {
        foreach ($p in $ports) {
            $bt = Join-Path $VcpkgRoot ("buildtrees\" + $p)
            Remove-Path -Path $bt -What "buildtrees($p)" -DryRun:$DryRun -Force:$Force
        }
    }

    # 4) packages/<port>_*_<triplet> 제거 (선택)
    if ($PurgePackages -and $ports.Count -gt 0) {
        foreach ($p in $ports) {
            $glob = Join-Path $VcpkgRoot ("packages\" + ($p + "_*_" + $t))
            # 와일드카드 매칭 결과별 제거
            Get-ChildItem $glob -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Path -Path $_.FullName -What "packages($($_.Name))" -DryRun:$DryRun -Force:$Force
            }
        }
    }

    # 5) vcpkg_installed/<bucket> 아래 남은 빈 디렉터리 정리(선택)
    $maybeBucket = Get-ChildItem $installBucketPath -Force -ErrorAction SilentlyContinue
    if ($maybeBucket.Count -eq 0) {
        Remove-Path -Path $bucket -What "empty bucket dir" -DryRun:$DryRun -Force:$Force
    }
}

# 6) Binary cache 정리(선택)
if ($PurgeBinaryCache) {
    if (Test-Path $BinaryCachePath) {
        Remove-Path -Path $BinaryCachePath -What "binary cache folder" -DryRun:$DryRun -Force:$Force
    } else {
        Write-Host "BinaryCache not found: $BinaryCachePath"
    }
}

Write-Host "`nAll done."
