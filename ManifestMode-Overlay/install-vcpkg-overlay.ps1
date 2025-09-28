<#=================================================================================================
  install-vcpkg-overlay.ps1 (Windows PowerShell 5.1 + 이상)
  - Scripts\setup-vcpkg-manifest.ps1 호출 및 파라메터 설정
=================================================================================================#>

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩 체크 (한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
try { [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false) } catch {}
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
try { chcp 65001 | Out-Null } catch {}


# -------------------------------------------------------------------------------------------------
# 1. setup-vcpkg-manifest.ps1 파라메터 설정
# -------------------------------------------------------------------------------------------------

# CMake의 MSVS 설정
$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207"

# vcpkg 주요 경로 설정
$VcpkgRoot = "E:\Library\vcpkg"
$ProjectRoot = $PSScriptRoot
$InstallBasePath = "vcpkg_installed"

# manifest + overlay + triplet + binarycache
$Triplets = @("x64-windows-static-mt")
$OverlayPorts = @("$PSScriptRoot\overlays\ports")
$OverlayTriplets = @("$PSScriptRoot\overlays\triplets")
$BinarySources = "clear;files,$ProjectRoot\vcpkg-BinaryCache,readwrite"

# -------------------------------------------------------------------------------------------------
# 2. vcpkg.env-overlay.props 생성/갱신 (프로젝트 루트)
# -------------------------------------------------------------------------------------------------

$envPropsPath = Join-Path $ProjectRoot "vcpkg.env-overlay.props"

$envPropsContent = @"
<Project>
    <PropertyGroup>
        <!-- Single Source of Truth -->
        <VcpkgEnableManifest>true</VcpkgEnableManifest>
        <VcpkgManifestRoot>`$(MSBuildThisFileDirectory)</VcpkgManifestRoot>
        <VcpkgOverInstalledDir>`$(VcpkgManifestRoot)$InstallBasePath\</VcpkgOverInstalledDir>
    </PropertyGroup>
</Project>
"@

# 파일 쓰기(UTF-8)
New-Item -ItemType Directory -Force -Path $envPropsPath | Out-Null
Set-Content -Path $envPropsPath -Value $envPropsContent -Encoding UTF8
Write-Host "Wrote: $envPropsPath"


# -------------------------------------------------------------------------------------------------
# 3. setup-vcpkg-overlay.ps1 호출 및 파라메터 전달
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
    -OverlayPorts $OverlayPorts -OverlayTriplets $OverlayTriplets `
    -BinarySources $BinarySources
