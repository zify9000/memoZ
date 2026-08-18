#!/usr/bin/env bash
# memoZ skill: 安装/同步/校验 AGENTS.md 中的"项目记忆体系"章节。
# 标准副本（唯一事实源）是 ../references/agents-chapter.md。
#
# 用法:
#   sync.sh [项目根目录]          安装或同步章节（幂等，默认当前目录）
#   sync.sh --check [项目根目录]  仅校验；章节缺失/被篡改/与标准副本不一致时退出码 1
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHAPTER_FILE="$SKILL_DIR/../references/agents-chapter.md"
START='<!-- memoZ:start'
END='<!-- memoZ:end -->'

CHECK=0
if [[ "${1:-}" == "--check" ]]; then CHECK=1; shift; fi
ROOT="${1:-.}"
AGENTS="$ROOT/AGENTS.md"

has_chapter() { [[ -f "$AGENTS" ]] && grep -qF "$START" "$AGENTS"; }

extract_chapter() {
  awk -v s="$START" -v e="$END" '
    index($0, s) { in_c=1 }
    in_c { print }
    index($0, e) { in_c=0 }
  ' "$AGENTS"
}

if [[ "$CHECK" -eq 1 ]]; then
  if ! has_chapter; then
    echo "MISSING: $AGENTS 中没有项目记忆体系章节"
    exit 1
  fi
  if [[ "$(extract_chapter)" == "$(cat "$CHAPTER_FILE")" ]]; then
    echo "OK: $AGENTS 章节与标准副本一致"
    exit 0
  else
    echo "STALE: $AGENTS 章节与标准副本不一致，运行 sync.sh 重新同步"
    exit 1
  fi
fi

if has_chapter; then
  awk -v s="$START" -v e="$END" -v f="$CHAPTER_FILE" '
    BEGIN { while ((getline l < f) > 0) c = c l "\n" }
    index($0, s) { printf "%s", c; skip=1; next }
    index($0, e) { skip=0; next }
    !skip { print }
  ' "$AGENTS" > "$AGENTS.tmp"
  mv "$AGENTS.tmp" "$AGENTS"
  echo "已同步: $AGENTS"
else
  if [[ -f "$AGENTS" ]]; then
    printf '\n%s\n' "$(cat "$CHAPTER_FILE")" >> "$AGENTS"
  else
    printf '%s\n' "$(cat "$CHAPTER_FILE")" > "$AGENTS"
  fi
  echo "已写入: $AGENTS"
fi
