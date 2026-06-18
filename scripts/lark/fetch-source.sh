#!/usr/bin/env bash
# 抓取课堂记录与课件正文到 data/day$DAY/
# 用法: source scripts/lark/00-env.sh 后  bash scripts/lark/fetch-source.sh
#   或: DAY=4 RECORD_TOKEN=xxx COURSEWARE_TOKENS=a,b bash scripts/lark/fetch-source.sh
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

: "${RECORD_TOKEN:?请在 00-env.sh 填入 RECORD_TOKEN（课堂记录文档 token）}"
OUT="data/day${DAY}"; mkdir -p "$OUT"

# 课堂记录正文 -> markdown
lark-cli docs +fetch --doc "$RECORD_TOKEN" --doc-format markdown --as user \
  --jq '.data.document.content' > "$OUT/record.md"
echo "record.md: $(wc -c < "$OUT/record.md") bytes"

# 课件（逗号分隔的文档 token）。只有 DOCX 类能 fetch 正文；HTML 课件请用 drive +download + shoot-slides.mjs
if [ -n "${COURSEWARE_TOKENS}" ]; then
  IFS=',' read -ra TOKS <<< "$COURSEWARE_TOKENS"
  i=1
  for t in "${TOKS[@]}"; do
    [ -z "$t" ] && continue
    lark-cli docs +fetch --doc "$t" --doc-format markdown --as user \
      --jq '.data.document.content' > "$OUT/courseware-$i.md" 2>/dev/null \
      && echo "courseware-$i.md: $(wc -c < "$OUT/courseware-$i.md") bytes" \
      || echo "courseware-$i: 非 DOCX，无法 fetch 正文（若是 HTML 课件请改用 drive +download + shoot-slides.mjs）"
    i=$((i+1))
  done
else
  echo "（无课件 token，跳过课件抓取）"
fi
