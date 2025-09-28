<#=================================================================================================
  install-vcpkg-classic.ps1 (Windows PowerShell 5.1 + 이상)
  - Scripts\setup-vcpkg-classic.ps1 호출 및 파라메터 설정
=================================================================================================#>

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------------------------------------
# 콘솔 인코딩 체크 (한글 깨짐 방지)
# -------------------------------------------------------------------------------------------------
try { [Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false) } catch {}
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch {}
try { chcp 65001 | Out-Null } catch {}


# -------------------------------------------------------------------------------------------------
# 1. setup-vcpkg-classic.ps1 파라메터 설정
# -------------------------------------------------------------------------------------------------

# CMake의 MSVS 설정
$Generator = "Visual Studio 17 2022,x64,v143,14.44.35207"
# vcpkg 주요 경로 설정
$VcpkgRoot = "E:\Library\vcpkg"

$Triplets = @("x64-windows-static-mt","x64-windows")
$Ports = @("curl[core,ssl,sspi]","openssl","boost-filesystem")

# -------------------------------------------------------------------------------------------------
# 2. setup-vcpkg-classic.ps1 호출 및 파라메터 전달
# -------------------------------------------------------------------------------------------------

$setupScript = Join-Path $PSScriptRoot '..\Scripts\setup-vcpkg-classic.ps1'
if (-not (Test-Path $setupScript)) {
    throw "setup script not found: $setupScript"
}

Set-ExecutionPolicy -Scope Process Bypass -Force
& $setupScript `
    -Generator $Generator `
    -VcpkgRoot $VcpkgRoot `
    -Triplets $Triplets `
    -Ports $Ports