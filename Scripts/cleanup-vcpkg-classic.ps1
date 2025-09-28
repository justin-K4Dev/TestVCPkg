<#=================================================================================================
  Scripts/cleanup-vcpkg-classic.ps1 (Windows PowerShell 7.2+)
  - classic 모드에서 설치된 산출물 정리
  - <vcpkg-root>\installed\<triplet> 기준 제거
  - buildtrees/packages/binary cache 선택적 정리
  - 기본값: 주요 산출물 제거 + buildtrees/packages 정리, 바이너리 캐시는 유지
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

    # 대상 트립렛들 (여러 개 가능)
    [string[]]$Triplets = @("x64-windows-static"),

    # 절대경로 ($BinaryCachePath)
    [string]$BinaryCachePath = "",

    # 선택 정리 스위치
    [bool]$PurgeBuildTrees = $true,
    [bool]$PurgePackages = $true,
    [bool]$PurgeBinaryCache = $false,

    # 안전장치
    [switch]$DryRun = $false,
    [switch]$Force = $true
)


Import-Module "$PSScriptRoot\vcpkg-helper.psm1" -Force

# =================================================================================================
# 메인 (엔트리 포인트)
# =================================================================================================
$ErrorActionPreference = "Stop"

$vcpkgExeName = "vcpkg.exe"
$VcpkgRoot = Ensure-AbsPath $VcpkgRoot
$vcpkgExe = Join-Path $VcpkgRoot $vcpkgExeName
Assert-File $vcpkgExe $vcpkgExeName

Write-Host "===== vcpkg uninstall (classic mode) ====="
Write-Host "VcpkgRoot   : $VcpkgRoot"
Write-Host "Triplets    : $([string]::Join(', ', $Triplets))"
Write-Host "Options     : PurgeBuildTrees=$PurgeBuildTrees PurgePackages=$PurgePackages PurgeBinaryCache=$PurgeBinaryCache DryRun=$DryRun"

foreach ($t in $Triplets) {
    Write-Host "`n----- Triplet: $t -----"

    # classic: <vcpkg-root>\installed\<triplet>
    $tripletRoot = Join-Path $VcpkgRoot ("installed\" + $t)
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

    # 2) installed/<triplet> 제거
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
            Get-ChildItem $glob -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Path -Path $_.FullName -What "packages($($_.Name))" -DryRun:$DryRun -Force:$Force
            }
        }
    }
}

# 5) Binary cache 정리(선택)
if ($PurgeBinaryCache) {
    if (Test-Path $BinaryCachePath) {
        Remove-Path -Path $BinaryCachePath -What "binary cache folder" -DryRun:$DryRun -Force:$Force
    } else {
        Write-Host "BinaryCachePath not found: $BinaryCachePath"
    }
}

Write-Host "`nAll done."
