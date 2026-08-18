# memoZ skill: 安装/同步/校验 AGENTS.md 中的"项目记忆体系"章节（Windows 版）。
# 标准副本（唯一事实源）是 ../references/agents-chapter.md，与 scripts/sync.sh 语义一致。
#
# 用法:
#   powershell -File sync.ps1 [项目根目录]          安装或同步章节（幂等，默认当前目录）
#   powershell -File sync.ps1 -Check [项目根目录]   仅校验；章节缺失/被篡改/与标准副本不一致时退出码 1
param(
    [switch]$Check,
    [string]$Root = "."
)
$ErrorActionPreference = "Stop"

$SkillDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ChapterFile = Join-Path $SkillDir "..\references\agents-chapter.md"
$Start = '<!-- memoZ:start'
$End = '<!-- memoZ:end -->'
$Agents = Join-Path $Root "AGENTS.md"

function Test-Chapter {
    (Test-Path $Agents) -and (Select-String -Path $Agents -Pattern ([regex]::Escape($Start)) -Quiet)
}

function Get-Chapter {
    param([string]$Path)
    $inC = $false
    $lines = @()
    foreach ($line in (Get-Content $Path -Encoding UTF8)) {
        if ($line.Contains($Start)) { $inC = $true }
        if ($inC) { $lines += $line }
        if ($line.Contains($End)) { $inC = $false }
    }
    return ($lines -join "`n").TrimEnd()
}

$chapterLines = Get-Content $ChapterFile -Encoding UTF8
$chapter = ($chapterLines -join "`n").TrimEnd()

if ($Check) {
    if (-not (Test-Chapter)) {
        Write-Output "MISSING: $Agents 中没有项目记忆体系章节"
        exit 1
    }
    if ((Get-Chapter $Agents) -eq $chapter) {
        Write-Output "OK: $Agents 章节与标准副本一致"
        exit 0
    } else {
        Write-Output "STALE: $Agents 章节与标准副本不一致，运行 sync.ps1 重新同步"
        exit 1
    }
}

if (Test-Chapter) {
    $out = @()
    $skip = $false
    foreach ($line in (Get-Content $Agents -Encoding UTF8)) {
        if ($line.Contains($Start)) { $out += $chapterLines; $skip = $true; continue }
        if ($line.Contains($End)) { $skip = $false; continue }
        if (-not $skip) { $out += $line }
    }
    $out | Set-Content $Agents -Encoding UTF8
    Write-Output "已同步: $Agents"
} else {
    if (Test-Path $Agents) {
        Add-Content $Agents "" -Encoding UTF8
        Add-Content $Agents $chapterLines -Encoding UTF8
    } else {
        Set-Content $Agents $chapterLines -Encoding UTF8
    }
    Write-Output "已写入: $Agents"
}
