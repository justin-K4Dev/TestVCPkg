<#=================================================================================================
  Scripts/setup-vcpkg-solution.ps1  (Windows PowerShell 5.1 호환)
  - 솔루션 루트에서 매니페스트 모드로 vcpkg.json 참조하여 지정된 트립릿들을 설치
  - 트립릿별로 설치 루트를 분리:
    * Triplet에 '-static' 포함 → <SolutionRoot>\vcpkg_installed\static\<triplet>
    * 그 외                    → <SolutionRoot>\vcpkg_installed\dynamic\<triplet>
  - Wait-for-lock, Clean-after-build, Binary Cache 지원
=================================================================================================#>

[CmdletBinding()]
param(
    # vcpkg.exe 경로
    [string]$VcpkgRoot = "E:\Library\vcpkg",

    # 설치할 트립릿 목록
    [string[]]$Triplets = @("x64-windows-static","x64-windows"),

    # 솔루션 루트
    [string]$SolutionRoot = ".",

    # 설치할 상대 루트 (기본: vcpkg_installed)
    [string]$InstallDir = "vcpkg_installed",

    # (선택) 바이너리 캐시 속성들
    [string]$BinaryCacheArgs = "",

    # 빌드 후 buildtrees/packages 정리
    [bool]$CleanAfterBuild = $true,

    # (선택) 다른 프로세스의 vcpkg 락을 기다림
    [bool]$WaitForLock  = $true
)

# =================================================================================================
# 내부 함수 정의부
# =================================================================================================

function Assert-File([string]$Path, [string]$Name) {
    if (-not (Test-Path $Path)) { throw "$Name not found: $Path" }
}

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path | Out-Null }
}

function Get-InstallBucket([string]$Triplet, [string]$SolRoot, [string]$InstallDir) {
    $installRoot = Join-Path $SolRoot $InstallDir

    $t = $Triplet.ToLower()
    if ($t.Contains("-static")) {
        return (Join-Path $installRoot "static")
    } else {
        return (Join-Path $installRoot "dynamic")
    }
}

function Set-BinaryCache([string]$Path) {
    if (-not $Path -or $Path.Trim() -eq "") { return }

    Ensure-Dir $Path
    $env:VCPKG_DEFAULT_BINARY_CACHE = $Path
    cmd /c "setx VCPKG_DEFAULT_BINARY_CACHE `"$Path`"" | Out-Null
    Write-Host "VCPKG_DEFAULT_BINARY_CACHE = $Path"
}

function Install-Triplet( [string]$VcpkgRoot
                        , [string]$Triplet
                        , [string]$SolRoot, [string]$InstallDir
                        , [string]$BinaryCacheArgs
                        , [bool]$Clean, [bool]$Wait){
    $bucketPath = Get-InstallBucket -Triplet $Triplet -SolRoot $SolRoot -InstallDir $InstallDir
    Ensure-Dir $bucketPath

    $args = @(
        "install",
        "--triplet", $Triplet,
        "--x-manifest-root=$SolRoot",
        "--x-install-root=$bucketPath",
        "--binarysource=$BinaryCacheArgs"
    )

    if ($Clean) { 
        $args += "--clean-buildtrees-after-build"
        $args += "--clean-packages-after-build" 
    }
    if ($Wait)  { $args += "--x-wait-for-lock" }

    # Debug/Release 동시 설치를 위해 BUILD_TYPE 고정하지 않음
    $env:VCPKG_FEATURE_FLAGS = "manifests,registries,binarycaching"

    $vcpkgExe = (Join-Path $VcpkgRoot "vcpkg.exe")

    Write-Host "`n===== vcpkg install Solution (triplet:$Triplet) ====="
    $cmdLine = "$vcpkgExe $($args -join ' ')"
    Write-Host $cmdLine

    & $vcpkgExe @args
    if ($LASTEXITCODE -ne 0) { throw "vcpkg install failed for Solution (triplet:$Triplet) ($LASTEXITCODE)" }

    $tripRoot = Join-Path $bucketPath $Triplet
    $inc = Join-Path $tripRoot "include"
    $lib = Join-Path $tripRoot "lib"
    $dbg = Join-Path $tripRoot "debug\lib"

    Write-Host "Installed to: $tripRoot"
    Write-Host ("  {0} -> {1}" -f $inc, (Test-Path $inc  | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
    Write-Host ("  {0} -> {1}" -f $lib, (Test-Path $lib  | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
    Write-Host ("  {0} -> {1}" -f $dbg, (Test-Path $dbg  | ForEach-Object { if($_){"OK"} else {"MISSING"} }))
}

# =================================================================================================
# 메인 (엔트리 포인트)
# =================================================================================================
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
# 솔루션 루트 경로 설정
# -------------------------------------------------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SolutionRoot -or $SolutionRoot.Trim() -eq "") {
    $SolutionRoot = Split-Path -Parent $ScriptDir
}

# -------------------------------------------------------------------------------------------------
# 주요 설정 예외 체크
# -------------------------------------------------------------------------------------------------
Assert-File $VcpkgRoot "vcpkg.exe"
Assert-File (Join-Path $SolutionRoot "vcpkg.json") "vcpkg.json"

# -------------------------------------------------------------------------------------------------
# 주요 초기화
# -------------------------------------------------------------------------------------------------
if ($BinaryCache -and $BinaryCache.Trim() -ne "") { Set-BinaryCache $BinaryCache }

# -------------------------------------------------------------------------------------------------
# Triplets 설치 실행
# -------------------------------------------------------------------------------------------------
foreach($t in $Triplets){
    Write-Host ("Triplet -> {0}" -f $t)
    Install-Triplet -Triplet $t
                    -VcpkgRoot $VcpkgRoot
                    -SolRoot $SolutionRoot -InstallDir $InstallDir
                    -BinaryCacheArgs $BinaryCacheArgs
                    -Clean:$CleanAfterBuild
                    -Wait:$WaitForLock
}

Write-Host "`nAll done."
