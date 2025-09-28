<#=================================================================================================
  Scripts/vcpkg-helper.psm1 (Windows PowerShell 7.2+)
  - vcpkg 관련 공통 Helper 함수 모듈
=================================================================================================#>


# =================================================================================================
# 함수 정의부
# =================================================================================================

function Assert-File([string]$Path, [string]$Name) {
    if (-not (Test-Path $Path)) { throw "$Name not found: $Path" }
}


function Assert-AbsPath([string]$Path) {
    if (-not [System.IO.Path]::IsPathRooted($Path)) { throw "Path must be absolute: '$Path'" }
}

function Resolve-PathWithBaseOrThrow {
    [CmdletBinding()]
    param(
        # 반드시 절대경로여야 하는 기준 경로
        [Parameter(Mandatory)]
        [string]$BaseAbsolutePath,

        # 검사/변환할 경로 (절대/상대 모두 허용)
        [Parameter(Mandatory)]
        [string]$PathToCheck
    )

    if ([string]::IsNullOrWhiteSpace($BaseAbsolutePath)) {
        throw "BaseAbsolutePath must be a non-empty string."
    }
    if ([string]::IsNullOrWhiteSpace($PathToCheck)) {
        throw "PathToCheck must be a non-empty string."
    }

    # 기준 경로는 반드시 절대 경로 형식 이다 !!!
    if (-not [System.IO.Path]::IsPathFullyQualified($BaseAbsolutePath)) {
        throw "BaseAbsolutePath must be an absolute path. Current: $BaseAbsolutePath"
    }

    try {
        $baseFull = [System.IO.Path]::GetFullPath($BaseAbsolutePath)

        if ([System.IO.Path]::IsPathFullyQualified($PathToCheck)) {
            # 절대 경로: 존재 여부 무관, 정규화해서 반환
            return [System.IO.Path]::GetFullPath($PathToCheck)
        }
        else {
            # 상대 경로: 기준 절대 경로와 합쳐 정규화해서 반환
            $combined = [System.IO.Path]::Combine($baseFull, $PathToCheck)
            return [System.IO.Path]::GetFullPath($combined)
        }
    }
    catch {
        # 경로 형식 불량, 잘못된 문자, 너무 김 등 .NET 예외를 감싸서 전달
        throw "Path resolution failed. base=$BaseAbsolutePath, input=$PathToCheck → $($_.Exception.Message)"
    }
}


function Ensure-AbsPath([string]$Path) {
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        throw "Path must be absolute: '$Path'"
    }
    try { return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path }
    catch { throw "Absolute path does not exist or cannot be resolved: '$Path'. $_" }
}


function Test-PathWithBase {
    [CmdletBinding()]
    param(
        # 반드시 절대경로여야 하는 기준 경로(존재하는 디렉터리)
        [Parameter(Mandatory)]
        [string]$BaseAbsolutePath,

        # 검사할 경로 (상대/절대 모두 허용)
        [Parameter(Mandatory)]
        [string]$CheckPath
    )

    try {
        # 기준 경로 검증
        if (-not [System.IO.Path]::IsPathRooted($BaseAbsolutePath)) {
            throw "BaseAbsolutePath must be an absolute path. Current: '$BaseAbsolutePath'"
        }
        $baseResolved = (Resolve-Path -LiteralPath $BaseAbsolutePath -ErrorAction Stop).Path
        if (-not (Test-Path -LiteralPath $baseResolved -PathType Container)) {
            throw "BaseAbsolutePath must point to an existing directory. Current: '$baseResolved'"
        }

        # 상대/절대 판단 후 절대경로로 변환
        $resolved = if ([System.IO.Path]::IsPathRooted($CheckPath)) {
            try { (Resolve-Path -LiteralPath $CheckPath -ErrorAction Stop).Path }
            catch { [System.IO.Path]::GetFullPath($CheckPath) }
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $baseResolved $CheckPath))
        }

        # 존재 확인(없으면 예외)
        if (-not (Test-Path -LiteralPath $resolved)) {
            throw "Resolved path does not exist: '$resolved' (from '$CheckPath' with base '$baseResolved')"
        }

        # 존재가 보장된 절대 경로만 반환
        return $resolved
    }
    catch {
        throw "Path check failed: $($_.Exception.Message)"
    }
}


function Ensure-Dir([string]$Path) {
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        throw "Path must be absolute: '$Path'"
    }
    try { return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path }
    catch { throw "Absolute path does not exist or cannot be resolved: '$Path'. $_" }
}


function Remove-Path([string]$Path, [string]$What, [switch]$DryRun, [switch]$Force) {
    if (-not $Path) { throw "Remove-Path: Path is null." }
    if (-not (Test-Path $Path)) { return }
    if ($DryRun) { Write-Host "[DRYRUN] Remove {$What}: $Path"; return }
    if (-not $Force) {
        $ans = Read-Host "Remove $What? (Y/n) `n  $Path"
        if ($ans -and $ans.ToLowerInvariant().StartsWith('n')) { return }
    }
    Write-Host "Removing {$What}: $Path"
    try { Remove-Item $Path -Recurse -Force -ErrorAction Stop }
    catch { Write-Warning "Failed to remove {$What}: $Path`n  -> $($_.Exception.Message)" }
}


function Join-Semicolon([string[]]$paths) {
    if (-not $paths -or $paths.Count -eq 0) { return "" }
    $acc = @()
    foreach ($p in $paths) {
        try { $acc += (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path }
        catch { $acc += $p } # 이미 존재 안 해도 vcpkg 인수에 상대/미존재가 올 수 있으니 fallback 유지
    }
    ($acc -join ";")
}


function Read-InstalledPortsFromInfoDir([string]$TripletRoot) {
    $infoDir = Join-Path $TripletRoot "vcpkg\info"
    if (-not (Test-Path $infoDir)) { return @() }
    Get-ChildItem $infoDir -Filter *.list -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            # 파일명 예: zlib_x64-windows-static-mt.list → 첫 '_' 앞까지가 포트명
            $name.Split('_')[0]
        } | Where-Object { $_ } | Sort-Object -Unique
}


function Get-InstallBucket([string]$Triplet, [string]$InstallBasePath) {
    if ([string]::IsNullOrWhiteSpace($Triplet))             { throw "Triplet is empty." }
    if ([string]::IsNullOrWhiteSpace($InstallBasePath))     { throw "InstallBasePath is empty." }

    if (-not [System.IO.Path]::IsPathFullyQualified($InstallBasePath)) {
        throw "InstallBasePath must be an absolute path. Current: $InstallBasePath"
    }

    $t = $Triplet.ToLower()
    if ($t.Contains("-static")) { return (Join-Path $InstallBasePath "static") }
    else                        { return (Join-Path $InstallBasePath "dynamic") }
}


function Import-VcVars {
    param(
        [Parameter(Mandatory)] [string]$VcvarsallBat,   # 예) "$vsPath\VC\Auxiliary\Build\vcvarsall.bat"
        [Parameter(Mandatory)] [ValidateSet('x64','x86','arm64','arm')] [string]$Platform,
        [Parameter(Mandatory)] [string]$VcVarsVer,      # 예) "14.44"
        # 길이 이슈를 줄이려면 필요한 키만 선택적으로 반영 (권장)
        [string[]]$OnlyKeys = @( 'PATH'
                               , 'INCLUDE', 'LIB', 'LIBPATH'
                               , 'WindowsSdkDir', 'WindowsSdkVersion'
                               , 'VCToolsInstallDir', 'VCINSTALLDIR', 'UniversalCRTSdkDir' )
    )

    if (!(Test-Path $VcvarsallBat)) { throw "vcvarsall.bat not found: $VcvarsallBat" }

    # cmd 호출 (유니코드/로캘 이슈 방지용 기본 옵션)
    $cmdLine = "`"$VcvarsallBat`" $Platform -vcvars_ver=$VcVarsVer && set"
    $envDump = & cmd.exe /d /s /c $cmdLine 2>&1

    if ($LASTEXITCODE -ne 0 -or -not $envDump) {
        throw "vcvarsall failed (exit $LASTEXITCODE). Check VS/SDK install."
    }

    $imported = 0
    foreach ($line in $envDump) {
        # 형식: NAME=VALUE
        $kv = $line -split '=', 2
        if ($kv.Length -ne 2) { continue }

        $name = $kv[0]
        $value = $kv[1]

        # 의사 환경변수 (=C:, =ExitCode 등) 무시
        if ($name.StartsWith('=')) { continue }

        # 필요한 키만 반영 (지정 안 하면 전체 반영)
        if ($OnlyKeys -and $OnlyKeys.Count -gt 0) {
            if ($OnlyKeys -notcontains $name) { continue }
        }

        try {
            # 1) 프로세스 환경 블록에 반영
            [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
            # 2) PowerShell $env:에도 즉시 반영 (일부 호스트에서 즉시 반영 보장)
            Set-Item -Path "Env:$name" -Value $value
            $imported++
        }
        catch {
            Write-Warning "Failed to import env '$name' (len=$($value.Length)): $($_.Exception.Message)"
        }
    }

    Write-Host ("[vcvars] Imported {0} variable(s): {1}" -f $imported, ($OnlyKeys -join ', '))
}


function Init-VcpkgMsvcEnvironment {
    <#
    .SYNOPSIS
        Generator 스펙을 해석해 VS/MSVC/SDK 경로를 찾고,
        vcpkg가 사용할 CMake/환경 변수를 현재 PowerShell 세션에 주입합니다.

    .PARAMETER Generator
        예) "Visual Studio 17 2022,x64,v143,14.44.35207"

    .OUTPUTS
        PSCustomObject
          - GenInfo, VsPath, MsvcPath, BinPath, Cl, Link, PrevPATH, KitsBinPath
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Generator
    )

    # -----------------------------------------------------------------------------------------------
    # 1) Generator 스펙 파싱
    # -----------------------------------------------------------------------------------------------
    $genInfo  = Parse-GeneratorSpec -Generator $Generator
    $platform = $genInfo.Platform

    # -----------------------------------------------------------------------------------------------
    # 2) VS/MSVC 경로 탐색 (vswhere)
    # -----------------------------------------------------------------------------------------------
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        throw "vswhere.exe를 찾을 수 없습니다: $vswhere"
    }

    $vsPath = & $vswhere -latest -products * `
                         -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
                         -version $genInfo.VsRange `
                         -property installationPath
    if (-not $vsPath) { throw "Visual Studio를 찾을 수 없습니다. VsRange=$($genInfo.VsRange)" }

    $msvcPath = Join-Path $vsPath "VC\Tools\MSVC\$($genInfo.MsvcVersion)"
    if (-not (Test-Path $msvcPath)) {
        throw "MSVC 툴셋 폴더를 찾을 수 없습니다: $msvcPath"
    }

    $binPath = Join-Path $msvcPath "bin\Host$platform\$platform"
    $cl   = Join-Path $binPath 'cl.exe';   Assert-File $cl   "cl.exe"
    $link = Join-Path $binPath 'link.exe'; Assert-File $link "link.exe"

    # -----------------------------------------------------------------------------------------------
    # 3) vcvars 환경(Include/Lib/SDK 등) 현재 세션(Process scope)에 주입
    # -----------------------------------------------------------------------------------------------
    $parts = ($genInfo.MsvcVersion -split '\.')
    $vcVer = if ($parts.Length -ge 2) { "$($parts[0]).$($parts[1])" } else { $genInfo.MsvcVersion }

    $vcVarsAll = Join-Path $vsPath 'VC\Auxiliary\Build\vcvarsall.bat'
    if (-not (Test-Path $vcVarsAll)) { throw "vcvarsall.bat not found: $vcVarsAll" }

    Import-VcVars -VcvarsallBat $vcVarsAll -Platform $platform -VcVarsVer $vcVer `
                  -OnlyKeys @( 'PATH','INCLUDE','LIB','LIBPATH'
                             , 'WindowsSdkDir','WindowsSdkVersion'
                             , 'VCToolsInstallDir','VCINSTALLDIR','UniversalCRTSdkDir' )

    # -----------------------------------------------------------------------------------------------
    # 4) vcpkg용 CMake 관련 환경변수 주입
    # -----------------------------------------------------------------------------------------------
    Write-Host "===== CMake 환경변수 재설정 ====="
    Write-Host "WindowsSdkDir      = $env:WindowsSdkDir"
    Write-Host "WindowsSdkVersion  = $env:WindowsSdkVersion"
    if ($env:INCLUDE) { Write-Host "INCLUDE (first) = $($env:INCLUDE.Split(';')[0])" }
    if ($env:LIB)     { Write-Host "LIB (first)     = $($env:LIB.Split(';')[0])" }
    if ($env:LIBPATH) { Write-Host "LIBPATH (first) = $($env:LIBPATH.Split(';')[0])" }

    $env:VCPKG_CMAKE_GENERATOR          = $genInfo.GeneratorText
    $env:VCPKG_CMAKE_GENERATOR_PLATFORM = $genInfo.CMakePlatform
    if ($genInfo.Toolset) {
        if ($genInfo.MsvcVersion) {
            $env:VCPKG_CMAKE_GENERATOR_TOOLSET = "$($genInfo.Toolset),version=$($genInfo.MsvcVersion)"
        } else {
            $env:VCPKG_CMAKE_GENERATOR_TOOLSET = $genInfo.Toolset
        }
    } else {
        Remove-Item Env:\VCPKG_CMAKE_GENERATOR_TOOLSET -ErrorAction SilentlyContinue
    }

    Write-Host ("VCPKG_CMAKE_GENERATOR          : " + $env:VCPKG_CMAKE_GENERATOR)
    Write-Host ("VCPKG_CMAKE_GENERATOR_PLATFORM : " + $env:VCPKG_CMAKE_GENERATOR_PLATFORM)
    Write-Host ("VCPKG_CMAKE_GENERATOR_TOOLSET  : " + $env:VCPKG_CMAKE_GENERATOR_TOOLSET)

    $env:VCPKG_MANIFEST_INSTALL = "1"
    $env:VCPKG_FEATURE_FLAGS    = "manifests,registries,binarycaching"
    $env:VCPKG_KEEP_ENV_VARS    = @( 'PATH','INCLUDE','LIB','LIBPATH'
                                   , 'WindowsSdkDir','WindowsSdkVersion','UniversalCRTSdkDir'
                                   , 'VCToolsInstallDir','VCINSTALLDIR' ) -join ';'

    Write-Host ("VCPKG_FEATURE_FLAGS    : " + $env:VCPKG_FEATURE_FLAGS)
    Write-Host ("VCPKG_MANIFEST_INSTALL : " + $env:VCPKG_MANIFEST_INSTALL)
    Write-Host ("VCPKG_KEEP_ENV_VARS    : " + $env:VCPKG_KEEP_ENV_VARS)

    # -----------------------------------------------------------------------------------------------
    # 5) PATH 정리 (SDK bin + MSVC bin 우선)
    # -----------------------------------------------------------------------------------------------
    $env:PATH = "C:\Windows\System32;C:\Windows;"   # 최소 기본 경로부터 시작
    $kitsBinPath = Join-Path $env:WindowsSdkDir "bin\$($env:WindowsSdkVersion)\$platform"
    if (Test-Path $kitsBinPath) {
        $env:PATH = "$kitsBinPath;$binPath;$env:PATH"
    } else {
        $env:PATH = "$binPath;$env:PATH"
    }

    # -----------------------------------------------------------------------------------------------
    # 6) 리턴(진단에 유용한 경로/정보)
    # -----------------------------------------------------------------------------------------------
    [PSCustomObject]@{
        GenInfo     = $genInfo
        VsPath      = $vsPath
        MsvcPath    = $msvcPath
        BinPath     = $binPath
        Cl          = $cl
        Link        = $link
        PrevPATH    = $prevPATH
        KitsBinPath = $kitsBinPath
    }
}


function Assert-VcpkgConfigStrict([string]$ProjectRoot) {
    $manifestPath = Join-Path $ProjectRoot 'vcpkg.json'
    $configPath   = Join-Path $ProjectRoot 'vcpkg-configuration.json'

    Assert-File $manifestPath 'vcpkg.json'

    # --- builtin-baseline 검사 ---
    $manifest = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $hasBuiltin = $false
    if ($manifest.PSObject.Properties.Name -contains 'builtin-baseline') {
        $sha = $manifest.'builtin-baseline'
        $hasBuiltin = [bool]($sha -and $sha -match '^[0-9a-f]{40}$' -and $sha -notmatch 'FILL_BY_COMMAND')
    }

    # --- custom 레지스트리 검사 ---
    $hasCustomRegistry = $false
    if (Test-Path $configPath) {
        $cfg = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # 1) 기본 레지스트리 비활성화($null) 재설정 체크
        if ($cfg.'default-registry' -eq $null) { $hasCustomRegistry = $true }

        # 2) 기본 레지스트리 재정의 (git + repository + baseline) 재설정 체크
        elseif (     $cfg.'default-registry' `
                -and $cfg.'default-registry'.kind -eq 'git' `
                -and $cfg.'default-registry'.repository `
                -and $cfg.'default-registry'.baseline ) { $hasCustomRegistry = $true }

        # 3) registries 배열에 유효 항목이 하나라도 있는가
        if (-not $hasCustomRegistry -and $cfg.registries) {
            foreach ($r in $cfg.registries) {
                if ($r.kind -eq 'git' -and $r.repository -and $r.baseline -and $r.packages) { $hasCustomRegistry = $true; break }
            }
        }
    }

    # --- 오류 조건 체크 ---
    if (-not $hasBuiltin -and -not $hasCustomRegistry) {
        throw @"
[vcpkg] 구성 오류: 'builtin-baseline'도 없고, Custom 레지스트리 정보도 없습니다.
해결 방법 중 하나를 선택하세요.
  A) 기본(내장) 레지스트리를 사용할 경우:
     vcpkg x-update-baseline --add-initial-baseline --x-manifest-root="$ProjectRoot"
  B) 기본 레지스트리를 사용하지 않을 경우(예시):
     vcpkg-configuration.json 에 다음 중 하나를 설정
       1) "default-registry": null
       2) "default-registry": { "kind": "git", "repository": "<repo>", "baseline": "<sha>" }
       3) "registries": [{ "kind": "git", "repository": "<repo>", "baseline": "<sha>", "packages": ["zlib", ...] }]
"@
    }
}


function Show-InstallTree([string]$Root, [string]$Triplet) {
    $base = Join-Path $Root $Triplet
    $inc  = Join-Path $base "include"
    $lib  = Join-Path $base "lib"
    $dbg  = Join-Path $base "debug\lib"

    Write-Host "Installed tree:"

    $incStatus = "MISSING"; if (Test-Path $inc) { $incStatus = "OK" }
    $libStatus = "MISSING"; if (Test-Path $lib) { $libStatus = "OK" }
    $dbgStatus = "MISSING"; if (Test-Path $dbg) { $dbgStatus = "OK" }

    Write-Host ("  {0} -> {1}" -f $inc, $incStatus)
    Write-Host ("  {0} -> {1}" -f $lib, $libStatus)
    Write-Host ("  {0} -> {1}" -f $dbg, $dbgStatus)

    if (Test-Path $lib) {
        $libs = Get-ChildItem -Path $lib -Filter *.lib -ErrorAction SilentlyContinue
        if ($libs) { 
            Write-Host " libs:"
            foreach($f in $libs) { 
                Write-Host ("    - {0}" -f $f.Name) 
            } 
        }
    }

    if (Test-Path $dbg) {
        $libsD = Get-ChildItem -Path $dbg -Filter *.lib -ErrorAction SilentlyContinue
        if ($libsD) { 
            Write-Host " debug libs:"
            foreach($f in $libsD) { 
                Write-Host ("    - {0}" -f $f.Name) 
            } 
        }
    }
}


# update 출력 파싱(클래식/매니페스트 공통 신호로 사용)
function Needs-Upgrade([string]$updateOutput) {
    return -not ($updateOutput -match 'No packages need updating')
}


function Parse-GeneratorSpec {
    <#
    .SYNOPSIS
      "Visual Studio 17 2022, x64, v143, 14.44.35207" 등 임의 순서를 파싱

    .PARAMETER Generator
      "Visual Studio 17 2022[, <platform>|<toolset>|<msvcVersion> ...]"
      - platform: x64 | x86 | arm64 | arm | Win32(x86로 취급)
      - toolset : v###   예) v143
      - msvcVer : \d+.\d+.\d+  예) 14.44.35207
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Generator
    )

    # 1) 첫 토큰 = 제너레이터 문구, 나머지는 분류 대상
    $parts = $Generator -split ',', 5
    $genText = $parts[0].Trim()
    $rest    = @()
    if ($parts.Count -ge 2) { $rest = ($parts[1..($parts.Count-1)] | ForEach-Object { $_.Trim().Trim("'`"") }) }

    # 2) VS 주버전 추출 (예: 17)
    $vsMajor = $null
    if ($genText -match '^\s*Visual\s+Studio\s+(\d{2})\b') { $vsMajor = [int]$Matches[1] }

    # 3) 나머지 토큰을 패턴으로 분류 (순서 무관)
    $toolset = $null
    $msvcVersion = $null
    $platformRaw = $null

    foreach ($tok in $rest) {
        if (-not $tok) { continue }

        switch -Regex ($tok.ToLowerInvariant()) {
            # platform
            '^(x64|x86|win32|arm64|arm)$' {
                $platformRaw = $tok; continue
            }
            # toolset
            '^v\d{3}$' {
                $toolset = $tok; continue
            }
            # msvc folder version
            '^\d+\.\d+\.\d+$' {
                $msvcVersion = $tok; continue
            }
            default {
                Write-Warning "알 수 없는 토큰을 무시합니다: '$tok'"
            }
        }
    }

    # 4) vswhere 범위: [N.0, N+1.0)
    $vsRange = $null
    if ($vsMajor) { $vsRange = "[{0}.0,{1}.0)" -f $vsMajor, ($vsMajor + 1) }

    # 5) 플랫폼 정규화 + CMake -A 매핑
    $platNorm = $null
    if ($platformRaw) {
        switch -Regex ($platformRaw.ToLowerInvariant()) {
            '^x64$'   { $platNorm = 'x64' }
            '^x86$'   { $platNorm = 'x86' }
            '^win32$' { $platNorm = 'x86' }
            '^arm64$' { $platNorm = 'arm64' }
            '^arm$'   { $platNorm = 'arm' }
        }
    } elseif ($env:VSCMD_ARG_TGT_ARCH) {
        # 명시가 없으면 VS 개발자 셸 환경에서 추론
        switch -Regex ($env:VSCMD_ARG_TGT_ARCH.ToLowerInvariant()) {
            '^x64$'   { $platNorm = 'x64' }
            '^x86$'   { $platNorm = 'x86' }
            '^arm64$' { $platNorm = 'arm64' }
            '^arm$'   { $platNorm = 'arm' }
        }
    }

    $cmakeA = $null
    if ($vsMajor -and $platNorm) { $cmakeA = if ($platNorm -eq 'x86') { 'Win32' } else { $platNorm } }

    # 6) 검증(선택)
    if ($msvcVersion -and ($msvcVersion -notmatch '^\d+\.\d+\.\d+$')) {
        throw "MSVC 버전 형식이 올바르지 않습니다: '$msvcVersion' (예: 14.44.35207)"
    }
    if ($toolset -and ($toolset -notmatch '^v\d{3}$')) {
        Write-Warning "툴셋 문자열이 비표준일 수 있습니다: '$toolset' (예상: v143)"
    }

    [pscustomobject]@{
        GeneratorText  = $genText            # "Visual Studio 17 2022" / "Ninja" 등
        VsMajor        = $vsMajor            # 17 / 16 / null
        VsRange        = $vsRange            # "[17.0,18.0)" / null
        Toolset        = $toolset            # "v143" / null
        MsvcVersion    = $msvcVersion        # "14.44.35207" / null
        Platform       = $platNorm           # "x64"/"x86"/"arm64"/"arm"/null
        CMakePlatform  = $cmakeA             # VS 제너레이터일 때 -A 값("x64"/"Win32"/"ARM64"/"ARM")/null
        IsVisualStudio = [bool]$vsMajor
    }
}


Export-ModuleMember -Function `
    Assert-File, Assert-AbsPath, `
    Ensure-AbsPath, Resolve-PathWithBaseOrThrow, Test-PathWithBase, Ensure-Dir, Remove-Path, `
    Join-Semicolon, Read-InstalledPortsFromInfoDir, Get-InstallBucket, `
    Import-VcVars, Init-VcpkgMsvcEnvironment, Assert-VcpkgConfigStrict, Show-InstallTree, Needs-Upgrade, `
    Parse-GeneratorSpec