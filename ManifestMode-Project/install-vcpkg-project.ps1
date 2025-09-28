<#=================================================================================================
  install-vcpkg-project.ps1 (Windows PowerShell 5.1 + 이상
  - vcpkg.env-project.props 파일을 프로젝트 루트에 생성(SSOT)
  - Scripts\setup-vcpkg-manifest.ps1 호출 및 파라메터 설정
=================================================================================================#>

$ErrorActionPreference = 'Stop'

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩 체크 (한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
try {
  [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
  [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
} catch {}
try { chcp 65001 | Out-Null } catch {}


# -------------------------------------------------------------------------------------------------
# 1. setup-vcpkg-project.ps1 파라메터 설정
# -------------------------------------------------------------------------------------------------

# CMake의 MSVS 설정
$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207"

# vcpkg 주요 경로 설정
$VcpkgRoot = "E:\Library\vcpkg"
$ProjectRoot = $PSScriptRoot
$InstallBasePath = "vcpkg_installed"

# manifest + triplet + binarycache
$Triplets = @("x64-windows-static","x64-windows")
$BinarySources = "clear;files,$ProjectRoot\vcpkg-BinaryCache,readwrite"


# -------------------------------------------------------------------------------------------------
# 2. vcpkg.env-project.props 생성/갱신 (프로젝트 루트)
# -------------------------------------------------------------------------------------------------

$envPropsPath = Join-Path $ProjectRoot "vcpkg.env-project.props"

$envPropsContent = @"
<Project>
    <PropertyGroup>
        <!-- Single Source of Truth -->
        <VcpkgEnableManifest>true</VcpkgEnableManifest>
        <VcpkgManifestRoot>`$(MSBuildThisFileDirectory)</VcpkgManifestRoot>
        <VcpkgProjInstalledDir>`$(VcpkgManifestRoot)$InstallBasePath\</VcpkgProjInstalledDir>
    </PropertyGroup>
</Project>
"@

# 파일 쓰기(UTF-8)
New-Item -ItemType Directory -Force -Path $envPropsPath | Out-Null
Set-Content -Path $envPropsPath -Value $envPropsContent -Encoding UTF8
Write-Host "Wrote: $envPropsPath"


# -------------------------------------------------------------------------------------------------
# 3. setup-vcpkg-manifest.ps1 호출 및 파라메터 전달
# -------------------------------------------------------------------------------------------------
$setupScript = Join-Path $ProjectRoot '..\Scripts\setup-vcpkg-manifest.ps1'
if (-not (Test-Path $setupScript)) {
    throw "setup script not found: $setupScript"
}

Set-ExecutionPolicy -Scope Process Bypass -Force
& $setupScript `
    -Generator $Generator `
    -VcpkgRoot $VcpkgRoot `
    -ProjectRoot $ProjectRoot -InstallBasePath $InstallBasePath `
    -Triplets $Triplets `
    -BinarySources $BinarySources
