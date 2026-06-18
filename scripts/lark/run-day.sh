#!/usr/bin/env bash
# 处理任意一节课的流程入口（流程向导，打印每步该做什么）。
# 用法: DAY=4 bash scripts/lark/run-day.sh   或   bash scripts/lark/run-day.sh 4 ["搜索词"]
set -euo pipefail
DAY="${1:-${DAY:-3}}"
KEY="${2:-你的课程 Day $DAY}"

cat <<EOF
===================================================
 lark-study-card · 处理 Day $DAY
===================================================

【第1步】搜课堂记录文档，拿 token：
  lark-cli docs +search --query "$KEY" --as user --format json \\
    --jq '.data.results[] | {title:.title_highlighted, type:.result_meta.doc_types, token:.result_meta.token}'

【第1步附】搜该 Day 的「全部」课件（共享文件夹也可读），把每个课件的 token+url 都收齐：
  lark-cli docs +search --query "<课件名关键词>" --as user --format json \\
    --jq '.data.results[] | {title:.title_highlighted, type:.result_meta.doc_types, token:.result_meta.token, url:.result_meta.url}'

【第2步】把 token 填进 scripts/lark/00-env.sh（RECORD_TOKEN / COURSEWARE_TOKENS / DAY），再抓正文：
  DAY=$DAY bash scripts/lark/fetch-source.sh
  # HTML 课件需 drive +download 下载后用 shoot-slides.mjs 截图：
  #   lark-cli drive +download --as user --file-token <HTML课件token> --output data/day$DAY/courseware.html
  #   node scripts/lark/shoot-slides.mjs data/day$DAY/courseware.html data/day$DAY/slides

【第3步】AI 读 data/day$DAY/record.md + courseware-*.md + slides-text，产出 data/day$DAY/outline.md
         结构见 RUNBOOK.md「第3步」

【第4步】把 outline 转成 card.xml（每条知识点 = checkbox + 整段原文 callout），建学习卡：
  bash scripts/lark/create-card.sh data/day$DAY/card.xml
  # 再上传幻灯片图并 block_move_after 移到对应知识点下，详见 RUNBOOK.md「第4步」

【第5步】把 Day$DAY 章节幂等追加到知识库主文档（保留已勾选），详见 RUNBOOK.md「第5步」

完整命令与模板: RUNBOOK.md
EOF
