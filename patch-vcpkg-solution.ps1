<#=================================================================================================
  patch-vcpkg-solution.ps1 (Windows PowerShell 7.2+)
  - Scripts\upgrade-vcpkg-manifest.ps1 호출 및 파라미터 설정
=================================================================================================#>

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩 체크 (한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
try { [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false) } catch {}
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
try { chcp 65001 | Out-Null } catch {}


# -------------------------------------------------------------------------------------------------
# 1. upgrade-vcpkg-classic.ps1 파라메터 설정
# -------------------------------------------------------------------------------------------------

# CMake의 MSVS 설정
$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207"

# vcpkg 주요 경로 설정
$VcpkgRoot = "E:\Library\vcpkg"
$ProjectRoot = $PSScriptRoot
$InstallBasePath = "vcpkg_installed"

# manifest + overlay + triplet + binarycache
$Triplets = @("x64-windows-static","x64-windows")
$BinarySources = "clear;files,$ProjectRoot\vcpkg-BinaryCache,readwrite"


# -------------------------------------------------------------------------------------------------
# 2. upgrade-vcpkg-classic.ps1 호출 및 파라메터 전달
# -------------------------------------------------------------------------------------------------

$upgradeScript = Join-Path $PSScriptRoot '..\Scripts\upgrade-vcpkg-manifest.ps1'
if (-not (Test-Path $upgradeScript)) {
    throw "upgrade script not found: $upgradeScript"
}

Set-ExecutionPolicy -Scope Process Bypass -Force
& $upgradeScript `
    -Generator $Generator `
    -VcpkgRoot $VcpkgRoot `
    -ProjectRoot $ProjectRoot -InstallBasePath $InstallBasePath `
    -Triplets $Triplets `
    -$BinarySources $BinarySources
