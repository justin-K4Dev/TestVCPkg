<#=================================================================================================
  install-vcpkg-solution.ps1 (Windows PowerShell 5.1 + 이상
  - 솔루션 루트에 vcpkg.env-solution.props 생성(SSOT)
  - Scripts\setup-vcpkg-solution.ps1 호출하여 다중 트립릿 설치
=================================================================================================#>

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩(한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
try {
  [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
} catch {}
try { chcp 65001 | Out-Null } catch {}


# -------------------------------------------------------------------------------------------------
# 1. setup-vcpkg-solution.ps1 파라메터 설정
# -------------------------------------------------------------------------------------------------

# CMake의 MSVS 설정
$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207"

# vcpkg 주요 경로 설정
$VcpkgRoot = "E:\Library\vcpkg"
$SolutionRoot = $PSScriptRoot
$InstallBasePath = "vcpkg_installed"

# manifest + triplet + binarycache
$Triplets = @("x64-windows-static","x64-windows")
$BinarySources = "clear;files,$SolutionRoot\vcpkg-BinaryCache,readwrite"

# -------------------------------------------------------------------------------------------------
# 2. vcpkg.env-solution.props 생성/갱신 (솔루션 루트)
# -------------------------------------------------------------------------------------------------

$envPropsPath = Join-Path $SolutionRoot 'vcpkg.env-solution.props'
$envProps = @"
<Project>
    <PropertyGroup>
        <!-- Single Source of Truth (솔루션 범위) -->
        <VcpkgEnableManifest>true</VcpkgEnableManifest>
        <VcpkgManifestRoot>`$(MSBuildThisFileDirectory)</VcpkgManifestRoot>
        <VcpkgSolInstalledDir>`$(VcpkgManifestRoot)$InstallBasePath\</VcpkgSolInstalledDir>
    </PropertyGroup>
</Project>
"@

New-Item -ItemType Directory -Force -Path $envPropsPath | Out-Null
Set-Content -Path $envPropsPath -Value $envProps -Encoding UTF8
Write-Host "Wrote: $envPropsPath"

# -------------------------------------------------------------------------------------------------
# 3. setup-vcpkg-manifest.ps1 호출 및 파라메터 전달
# -------------------------------------------------------------------------------------------------
$setupScript = Join-Path $SolutionRoot 'Scripts\setup-vcpkg-manifest.ps1'
if (-not (Test-Path $setupScript)) {
    throw "setup script not found: $setupScript"
}

# Triplet 설치
Set-ExecutionPolicy -Scope Process Bypass -Force
& $setupScript `
    -Generator $Generator `
    -VcpkgRoot $VcpkgRoot `
    -ProjectRoot $SolutionRoot -InstallBasePath $InstallBasePath `
    -Triplets $Triplets `
    -BinarySources $BinarySources
