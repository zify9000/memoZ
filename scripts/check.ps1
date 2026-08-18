# memoZ skill: .memoZ/ 记忆体系的内容层机器校验（Windows 版，与 scripts/check.sh 语义一致）。
#
# 用法: powershell -File check.ps1 [项目根目录]（默认当前目录）
# 退出码: 0 = 无发现；1 = 有发现（逐条 WARN 输出）或 .memoZ/ 缺失
param(
    [string]$Root = "."
)
$ErrorActionPreference = "Stop"

$Memo = Join-Path $Root ".memoZ"
$SkillDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 阈值与 SKILL.md 健康线保持一致，调阈值只改这里（与 check.sh 同步修改）
$ImplLines = 30       # 单个 impl 文档一屏
$ArchLines = 60       # ARCHITECTURE 一页
$ProgressDoing = 4    # PROGRESS"进行中"条数上限
$PendingMerge = 4     # "待合并"堆积告警线
$ImplFiles = 12       # impl 文件总数告警线
$StaleDays = 30       # 体检超期 / 草稿老化天数

$script:Findings = 0
function Warn([string]$Msg) { Write-Output "WARN: $Msg"; $script:Findings++ }

if (-not (Test-Path $Memo -PathType Container)) {
    Write-Output "MISSING: $Memo 不存在（记忆体系未初始化或仍是旧版根目录布局，请先迁移到 .memoZ/）"
    exit 1
}

# 1. AGENTS.md 章节一致性（复用 sync.ps1 -Check，不重复实现）
& (Join-Path $SkillDir "sync.ps1") -Check $Root | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn "AGENTS.md 章节缺失/被篡改/过期 → 重跑 sync.ps1 同步"
}

# 2. decision/：INDEX ↔ ADR 文件互查（archive/ 是冷存储，不查）
$DecisionDir = Join-Path $Memo "decision"
$Index = Join-Path $DecisionDir "INDEX.md"
$adrFiles = @()
if (Test-Path $DecisionDir -PathType Container) {
    $adrFiles = @(Get-ChildItem $DecisionDir -File -Filter "*.md" | Where-Object { $_.Name -match '^\d{4}' })
}
if (Test-Path $Index) {
    $indexLines = Get-Content $Index -Encoding UTF8
    foreach ($f in $adrFiles) {
        $n = ([regex]::Match($f.Name, '^\d+')).Value
        if (-not ($indexLines | Select-String -Pattern "^\|\s*$n " -Quiet)) {
            Warn "decision/$($f.Name) 未登记 INDEX.md（漏登记）"
        }
    }
    foreach ($line in $indexLines) {
        $m = [regex]::Match($line, '^\|\s*(\d{4}) ')
        if ($m.Success) {
            $n = $m.Groups[1].Value
            if (-not ($adrFiles | Where-Object { $_.Name -like "$n-*" })) {
                Warn "INDEX.md 行 $n 无对应 ADR 文件（幽灵条目）"
            }
        }
    }
} else {
    Warn "decision/INDEX.md 缺失"
}

# 3. decision/：草稿老化（LastWriteTime 超 StaleDays，提醒用户核对——理由必须人来核）
foreach ($f in $adrFiles) {
    if ((Select-String -Path $f.FullName -Pattern '状态.*草稿' -Quiet) -and
        ($f.LastWriteTime -lt (Get-Date).AddDays(-$StaleDays))) {
        Warn "decision/$($f.Name) 草稿悬挂超 $StaleDays 天 → 提醒用户核对，别让草稿烂在堆里"
    }
}

# 4. impl/：单文件行数健康线 + 文件总数（含 conventions.md）
$ImplDir = Join-Path $Memo "impl"
$implAll = @()
if (Test-Path $ImplDir -PathType Container) {
    $implAll = @(Get-ChildItem $ImplDir -File -Filter "*.md")
}
foreach ($f in $implAll) {
    $lines = (Get-Content $f.FullName -Encoding UTF8).Count
    if ($lines -gt $ImplLines) {
        Warn "impl/$($f.Name) $lines 行，超 $ImplLines 行健康线 → 超了说明是两个职责，拆"
    }
}
if ($implAll.Count -gt $ImplFiles) {
    Warn "impl/ 共 $($implAll.Count) 个文件（>$ImplFiles）→ 在镜像代码结构的信号，退一步合并"
}

# 5. ARCHITECTURE.md：一页以内
$Arch = Join-Path $Memo "ARCHITECTURE.md"
if (Test-Path $Arch) {
    $archLineCount = (Get-Content $Arch -Encoding UTF8).Count
    if ($archLineCount -gt $ArchLines) {
        Warn "ARCHITECTURE.md $archLineCount 行，超一页（$ArchLines 行）→ 只留入口地图，超过就删"
    }
} else {
    Warn "ARCHITECTURE.md 缺失"
}

# 6. PROGRESS.md：进行中条数 / 待合并堆积
$Progress = Join-Path $Memo "PROGRESS.md"
if (Test-Path $Progress) {
    $doing = 0
    $sec = $false
    foreach ($line in (Get-Content $Progress -Encoding UTF8)) {
        if ($line -match '^## ') { $sec = ($line -match '进行中') }
        if ($sec -and $line -match '^- ') { $doing++ }
    }
    if ($doing -gt $ProgressDoing) {
        Warn "PROGRESS.md「进行中」共 $doing 条（>$ProgressDoing）→ 该收口或拆分"
    }
    $pending = @(Select-String -Path $Progress -Pattern '待合并').Count
    if ($pending -gt $PendingMerge) {
        Warn "PROGRESS.md「待合并」共 $pending 条（>$PendingMerge）→ 合并节奏可能已停，提醒用户处理"
    }
} else {
    Warn "PROGRESS.md 缺失"
}

# 7. 体检超期（.last-audit 由体检收尾时覆写）
$Audit = Join-Path $Memo ".last-audit"
if (-not (Test-Path $Audit)) {
    Warn ".memoZ/.last-audit 不存在 → 从未体检或记录丢失，建议做一次记忆体检"
} elseif ((Get-Item $Audit).LastWriteTime -lt (Get-Date).AddDays(-$StaleDays)) {
    Warn "距上次体检超 $StaleDays 天 → 建议做一次记忆体检"
}

# 8. 易碎行号："文件:行" 写进文档的瞬间就是负债（archive/ 不查；含 // 的是 URL 的 host:port，不算）
$mdFiles = @(Get-ChildItem $Memo -Recurse -File -Filter "*.md" | Where-Object { $_.FullName -notmatch 'archive' })
$fragile = @()
foreach ($hit in ($mdFiles | Select-String -Pattern '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+')) {
    foreach ($m in $hit.Matches) {
        if ($m.Value -notmatch '//') { $fragile += "$($hit.Path):$($hit.LineNumber): $($m.Value)" }
    }
}
$fragile = @($fragile | Select-Object -First 10)
if ($fragile.Count -gt 0) {
    Warn ("疑似「文件:行」行号（一改就过期，写接口名不写行号）:`n" + ($fragile -join "`n"))
}

if ($script:Findings -eq 0) {
    Write-Output "OK: .memoZ/ 机器校验通过"
    exit 0
}
Write-Output "---"
Write-Output "共 $script:Findings 项发现（均为健康线告警，按 SKILL.md 对应规则处理）"
exit 1
