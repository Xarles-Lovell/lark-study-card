#!/usr/bin/env bash
# 生成单课「学习卡」飞书文档。需先准备好 card.xml
# 用法: bash scripts/lark/create-card.sh <card.xml路径> [输出json路径]
# 例:   bash scripts/lark/create-card.sh data/day3/card.xml
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
CARD_XML="${1:?用法: create-card.sh <card.xml路径>}"
OUT_JSON="${2:-${CARD_XML%.xml}-create.json}"

PARENT_ARG=""
[ -n "${TARGET_FOLDER_TOKEN}" ] && PARENT_ARG="--parent-token ${TARGET_FOLDER_TOKEN}"

lark-cli docs +create --as user $PARENT_ARG \
  --content "@${CARD_XML}" --format json | tee "$OUT_JSON"

echo ""
echo "=== 文档已创建 ==="
grep -oE '"url":"[^"]+"' "$OUT_JSON"
