#!/usr/bin/env bash
# 初始化「知识库主文档」(跨课汇总+管勾选)。需先准备好 hub.xml
# 用法: bash scripts/lark/create-hub.sh [hub.xml路径] [输出json路径]
set -euo pipefail
source "$(dirname "$0")/00-env.sh"
HUB_XML="${1:-data/hub.xml}"
OUT_JSON="${2:-data/hub-create.json}"

PARENT_ARG=""
[ -n "${TARGET_FOLDER_TOKEN}" ] && PARENT_ARG="--parent-token ${TARGET_FOLDER_TOKEN}"

lark-cli docs +create --as user $PARENT_ARG \
  --content "@${HUB_XML}" --format json > "$OUT_JSON"

echo "=== 主文档已创建 ==="
grep -oE '"(document_id|url)":"[^"]+"' "$OUT_JSON"
echo "把上面的 document_id 填回 00-env.sh 的 HUB_DOC_TOKEN，后续幂等更新会用到。"
