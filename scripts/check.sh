#!/usr/bin/env bash
# memoZ skill: .memoZ/ 记忆体系的内容层机器校验（对应 sync.sh --check 的元数据校验）。
# 覆盖机器能判的防腐项，把体检清单里"数行数、对索引"这类活从人/agent 手里接过来。
#
# 用法: check.sh [项目根目录]（默认当前目录）
# 退出码: 0 = 无发现；1 = 有发现（逐条 WARN 输出）或 .memoZ/ 缺失
set -uo pipefail

ROOT="${1:-.}"
ROOT="${ROOT%/}"
MEMO="$ROOT/.memoZ"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 阈值与 SKILL.md 健康线保持一致，调阈值只改这里
IMPL_LINES=30       # 单个 impl 文档一屏
ARCH_LINES=60       # ARCHITECTURE 一页
PROGRESS_DOING=4    # PROGRESS"进行中"条数上限
PENDING_MERGE=4     # "待合并"堆积告警线
IMPL_FILES=12       # impl 文件总数告警线
STALE_DAYS=30       # 体检超期 / 草稿老化天数

FINDINGS=0
warn() { echo "WARN: $1"; FINDINGS=$((FINDINGS + 1)); }
shopt -s nullglob

[[ -d "$MEMO" ]] || { echo "MISSING: $MEMO 不存在（记忆体系未初始化或仍是旧版根目录布局，请先迁移到 .memoZ/）"; exit 1; }

# 1. AGENTS.md 章节一致性（复用 sync.sh --check，不重复实现）
if ! bash "$SKILL_DIR/sync.sh" --check "$ROOT" >/dev/null 2>&1; then
  warn "AGENTS.md 章节缺失/被篡改/过期 → 重跑 sync.sh 同步"
fi

# 2. decision/：INDEX ↔ ADR 文件互查（archive/ 是冷存储，不查）
INDEX="$MEMO/decision/INDEX.md"
if [[ -f "$INDEX" ]]; then
  for f in "$MEMO"/decision/[0-9]*.md; do
    n="$(basename "$f" | grep -oE '^[0-9]+')"
    grep -qE "^\| *$n " "$INDEX" || warn "decision/$(basename "$f") 未登记 INDEX.md（漏登记）"
  done
  while read -r n; do
    compgen -G "$MEMO/decision/$n-*.md" >/dev/null || warn "INDEX.md 行 $n 无对应 ADR 文件（幽灵条目）"
  done < <(grep -oE '^\| *[0-9]{4} ' "$INDEX" | tr -d '| ')
else
  warn "decision/INDEX.md 缺失"
fi

# 3. decision/：草稿老化（mtime 超 STALE_DAYS，提醒用户核对——理由必须人来核）
for f in "$MEMO"/decision/[0-9]*.md; do
  if grep -q '状态.*草稿' "$f" && [[ -n "$(find "$f" -mtime +$STALE_DAYS)" ]]; then
    warn "decision/$(basename "$f") 草稿悬挂超 ${STALE_DAYS} 天 → 提醒用户核对，别让草稿烂在堆里"
  fi
done

# 4. impl/：单文件行数健康线 + 文件总数（含 conventions.md）
impl_count=0
for f in "$MEMO"/impl/*.md; do
  impl_count=$((impl_count + 1))
  lines="$(wc -l < "$f" | tr -d ' ')"
  [[ "$lines" -le "$IMPL_LINES" ]] || warn "impl/$(basename "$f") ${lines} 行，超 ${IMPL_LINES} 行健康线 → 超了说明是两个职责，拆"
done
[[ "$impl_count" -le "$IMPL_FILES" ]] || warn "impl/ 共 ${impl_count} 个文件（>${IMPL_FILES}）→ 在镜像代码结构的信号，退一步合并"

# 5. ARCHITECTURE.md：一页以内
if [[ -f "$MEMO/ARCHITECTURE.md" ]]; then
  arch_lines="$(wc -l < "$MEMO/ARCHITECTURE.md" | tr -d ' ')"
  [[ "$arch_lines" -le "$ARCH_LINES" ]] || warn "ARCHITECTURE.md ${arch_lines} 行，超一页（${ARCH_LINES} 行）→ 只留入口地图，超过就删"
else
  warn "ARCHITECTURE.md 缺失"
fi

# 6. PROGRESS.md：进行中条数 / 待合并堆积
if [[ -f "$MEMO/PROGRESS.md" ]]; then
  doing="$(awk '/^## /{ sec = ($0 ~ /进行中/) ? 1 : 0 } sec && /^- /{ n++ } END{ print n + 0 }' "$MEMO/PROGRESS.md")"
  [[ "$doing" -le "$PROGRESS_DOING" ]] || warn "PROGRESS.md「进行中」共 ${doing} 条（>${PROGRESS_DOING}）→ 该收口或拆分"
  pending="$(grep -c '待合并' "$MEMO/PROGRESS.md" || true)"
  [[ "$pending" -le "$PENDING_MERGE" ]] || warn "PROGRESS.md「待合并」共 ${pending} 条（>${PENDING_MERGE}）→ 合并节奏可能已停，提醒用户处理"
else
  warn "PROGRESS.md 缺失"
fi

# 7. 体检超期（.last-audit 由体检收尾时覆写）
AUDIT="$MEMO/.last-audit"
if [[ ! -f "$AUDIT" ]]; then
  warn ".memoZ/.last-audit 不存在 → 从未体检或记录丢失，建议做一次记忆体检"
elif [[ -n "$(find "$AUDIT" -mtime +$STALE_DAYS)" ]]; then
  warn "距上次体检超 ${STALE_DAYS} 天 → 建议做一次记忆体检"
fi

# 8. 易碎行号："文件:行" 写进文档的瞬间就是负债（archive/ 不查；含 // 的是 URL 的 host:port，不算）
fragile="$(grep -rnoE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+' "$MEMO" --include='*.md' --exclude-dir=archive | grep -vE '//' | head -10 || true)"
[[ -z "$fragile" ]] || warn "疑似「文件:行」行号（一改就过期，写接口名不写行号）:
$fragile"

if [[ "$FINDINGS" -eq 0 ]]; then
  echo "OK: .memoZ/ 机器校验通过"
  exit 0
fi
echo "---"
echo "共 ${FINDINGS} 项发现（均为健康线告警，按 SKILL.md 对应规则处理）"
exit 1
