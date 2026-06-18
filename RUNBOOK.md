# 学习卡工作流 · 操作手册 (RUNBOOK)

把任意一节课的「课堂记录(妙记/录音转写导出的飞书文档)+课件」处理成飞书文档：
单课「学习卡」(每条知识点配整段课堂原文+幻灯片图) + 跨课「知识库主文档」。

> 本手册既是给人看的操作步骤，也是给 AI（Claude/Codex 等）照做的指令。
> 全文用 `<占位符>` 表示要替换的真实值，真实 token/路径填在 `scripts/lark/00-env.sh`。

## 前置

- 已装 [lark-cli](https://github.com/...) (v1.0.54+)，并用你的飞书身份授权（`--as user`）
- 已授予所需权限：`docs +search/+fetch/+create/+update`、`drive +download`、`search:docs:read`
- 本机装有 Chrome/Chromium（截图 HTML 幻灯片用）。路径填在 `00-env.sh` 的 `CHROME_PATH`，留空则自动探测
- Node.js（跑 `shoot-slides.mjs`）、Python3（提取幻灯片文字，可选）
- 复制 `scripts/lark/00-env.sh.example` 为 `scripts/lark/00-env.sh` 并填好

---

## 学习卡核心结构（最重要，先理解）

每条知识点 = **三件套**：
1. **复选框**：`<checkbox done="false">知识点一句话概括</checkbox>`，默认未勾，用户自己勾
2. **整段课堂原文**：灰色 callout 框，标时间区间。**写整段相关内容，不是一句话**
3. **课件幻灯片图**（若有对应页）：标注页码

三种情况：
- **有对应 PPT 页** → 复选框 + 原文 + 幻灯片图(标页码)
- **无对应 PPT 页（纯口述）** → 复选框 + 原文，注明"课件无对应页"
- **HTML缺图但DOC有** → 从 DOC 课件补原文(含图)，标章节名而非页码

---

## 第1步：定位素材

课堂记录（你把课程妙记/转写导出成的飞书文档）：
```bash
lark-cli docs +search --query "<你的课程 Day N>" --as user --format json \
  --jq '.data.results[] | {title:.title_highlighted, type:.result_meta.doc_types, token:.result_meta.token, owner:.result_meta.owner_name}'
```
取 owner 为自己、type 为 DOCX 的 token。

课件（共享文件夹里别人分享的、有读权限的也能读），每个 Day 通常有 DOCX + HTML 两种：
```bash
lark-cli docs +search --query "<课件名关键词>" --as user --format json \
  --jq '.data.results[] | {title:.title_highlighted, type:.result_meta.doc_types, token:.result_meta.token, url:.result_meta.url}'
```
- DOCX 课件(type=DOCX)：能 `docs +fetch` 读正文
- HTML 课件(type=FILE，文件名 .html)：需 `drive +download` 下载后截图

**重要：把该 Day 子文件夹下的「全部」课件 token + url 都收齐**（不只 DOCX/HTML 各一个）。有的 Day 子文件夹里有多个课件(分上下两讲、附加资料等)，学习卡顶部 callout 要为「每一个」课件都附独立超链接，让用户不用再回去翻文件夹。搜索时多换几个关键词(Day编号、课件标题、章节名)确保不漏。记下每个课件的 `url`(search 结果里的 `result_meta.url`，形如 `https://<域名>.feishu.cn/docx/<token>` 或 `/file/<token>`)。

把 token 填进 `scripts/lark/00-env.sh`（多个课件用逗号分隔）。

## 第2步：抓正文 + 截图幻灯片

### 2a. 抓课堂记录 + DOCX 课件正文
```bash
source scripts/lark/00-env.sh
bash scripts/lark/fetch-source.sh    # 按 00-env.sh 的 DAY/RECORD_TOKEN/COURSEWARE_TOKENS 抓取
```
验证：`head data/day$DAY/record.md`，开头应是课程标题。

### 2b. 下载 HTML 课件并逐页截图
```bash
lark-cli drive +download --as user --file-token "<HTML课件token>" --output data/day$DAY/courseware.html
node scripts/lark/shoot-slides.mjs data/day$DAY/courseware.html data/day$DAY/slides
```
产出 `data/day$DAY/slides/slide-00.png` ...，每张对应一页幻灯片。

> 注意：`shoot-slides.mjs` 默认假设 HTML 课件用 `<section class="canvas-card">` 标记每页、页脚是 `<div class="slide-footer">N / M</div>`。
> 若你的 HTML 课件结构不同，改脚本里的选择器即可（脚本顶部有注释）。

### 2c. 提取幻灯片文字（用于知识点配对，可选）
```bash
python3 -c "
import re
html=open('data/day$DAY/courseware.html',encoding='utf-8').read()
for i,s in enumerate(re.findall(r'<section[^>]*>(.*?)</section>',html,re.DOTALL)):
    t=re.search(r'<h[12][^>]*>(.*?)</h[12]>',s)
    f=re.search(r'slide-footer\">(.*?)</div>',s)
    print(f'slide-{i:02d} 页码={f.group(1).strip() if f else \"\"} 标题={re.sub(chr(60)+\"[^\"+chr(62)+\"]+\"+chr(62),\"\",t.group(1)) if t else \"\"}')
" > data/day$DAY/slides-text.txt
```

## 第3步：AI 归纳 + 知识点↔幻灯片配对

AI 通读 `record.md`(口述细节) + `courseware-*.md`(课件) + `slides-text.txt`(幻灯片页码标题)，产出 `data/day$DAY/outline.md`。
结构见 [`examples/outline.sample.md`](examples/outline.sample.md)：

```markdown
## 知识点清单
- [知识点] 一句话概括
  - 课堂原文时间区间: MM:SS~MM:SS
  - 课堂原文: (整段相关内容,可多段)
  - 对应幻灯片: slide-NN (第X页) | 或"无对应页"

## 作业与课堂练习
- (同上结构)
```

配对原则：
- 知识点的课堂原文要**写整段**(把相关的连续发言都包含进来)，不是一句话
- 幻灯片配对看 slides-text.txt 的标题/页码，语义匹配
- 课件没讲到的纯口述知识点 → 标"无对应页"，只放原文

## 第4步：生成单课学习卡（文本框架 + 配图）

### 4a. 写学习卡 XML（只含文本，图片后插）
**写 XML 前必读**飞书文档 XML 规范（lark-cli 自带：`lark-cli skills read lark-doc references/lark-doc-xml.md`）。
**可参考样板** [`examples/card.sample.xml`](examples/card.sample.xml)（含"有PPT页"和"无PPT页"两种知识点写法）。

顶部 callout 必须把该 Day 的「全部」课件做成超链接（第1步收齐的每个课件都要列），用 ` · ` 分隔、注明格式：
```xml
<callout emoji="books" background-color="light-blue" border-color="blue">
<p><b>课程名 Day N · 课程主题</b></p>
<p>课堂记录：<a href="<记录url>">Day N 妙记</a> ｜ 课件：<a href="<课件1url>">课件1（DOC版）</a> · <a href="<课件2url>">课件2（HTML版）</a> · <a href="<课件3url>">课件3</a></p>
</callout>
```

每条知识点模板（grey callout 背景色填 `gray`，不是 `light-grey`）：
```xml
<checkbox done="false">知识点一句话概括</checkbox>
<callout emoji="speaking_head" background-color="gray" border-color="grey">
<p><b>📢 课堂原文 MM:SS~MM:SS</b></p>
<p>整段课堂原文...</p>
</callout>
```
(图片不在 XML 里写，因为 create 时还没有图片 token，第4c步再插)

### 4b. 创建文档
```bash
bash scripts/lark/create-card.sh data/day$DAY/card.xml
```
记下返回 url 和 document_id。

### 4c. 上传幻灯片图并插到对应知识点下
对每个"有对应 PPT 页"的知识点：
```bash
# 1) 读文档拿到该知识点原文 callout 的 block-id（锚点）
lark-cli docs +fetch --doc "<学习卡token>" --detail with-ids --as user --jq '.data.document.content' > data/day$DAY/card-ids.xml

# 2) 上传幻灯片图到文档末尾，拿 image block-id
lark-cli docs +media-insert --doc "<学习卡token>" --file "data/day$DAY/slides/slide-NN.png" \
  --caption "课件第X页：幻灯片标题" --width 720 --as user --format json --jq '.data.block_id'

# 3) 把图从末尾移到锚点(原文callout)后面
lark-cli docs +update --doc "<学习卡token>" --command block_move_after \
  --block-id "<原文callout的id>" --src-block-ids "<图片block_id>" --as user
```

### 4d. 验证
```bash
lark-cli docs +fetch --doc "<学习卡token>" --doc-format markdown --as user --jq '.data.document.content' | head -40
```
确认每条知识点下：复选框 → 原文 → 幻灯片图，顺序正确。

## 第5步：追加到知识库主文档（幂等，保留已勾选）

主文档只放精简版知识点(不含原文/图)，每条链接回单课学习卡。幂等更新核心：先读主文档现有内容，识别已有条目，只追加新条目，不重写整篇。

### 5a. 首次创建主文档
```bash
bash scripts/lark/create-hub.sh data/hub.xml
# 把返回的 document_id 填回 00-env.sh 的 HUB_DOC_TOKEN
```

### 5b. 读主文档当前状态
```bash
lark-cli docs +fetch --doc "<主文档token>" --detail with-ids --as user \
  --jq '.data.document.content' > data/hub-current.xml
```
解析提取所有 `<checkbox ...>` 的 `id`、`done` 值和文本。

### 5c. 对比新旧
- 条目文本完全相同 → 跳过(保留用户勾选)
- 条目文本不存在 → 追加
- 相似但不完全相同 → 视为新条目追加(宁可重复不可遗漏)

### 5d. 追加新条目
```bash
lark-cli docs +update --doc "<主文档token>" --block-id "<锚点block-id>" \
  --command block_insert_after \
  --content "<checkbox done=\"false\">新知识点</checkbox>" \
  --as user
```
锚点通常是该 Day 章节最后一个 checkbox 的 id。

### 5e. 验证
```bash
lark-cli docs +fetch --doc "<主文档token>" --doc-format markdown --as user --jq '.data.document.content' | head -30
```
确认新条目出现，原有已勾选条目保持不变。

## 脚本清单

- `00-env.sh.example` — token/路径变量模板（复制为 `00-env.sh` 填用）
- `fetch-source.sh` — 抓课堂记录 + DOCX 课件正文
- `shoot-slides.mjs` — Chrome 无头逐页截图 HTML 课件
- `create-card.sh` — 创建学习卡文档
- `create-hub.sh` — 创建/初始化知识库主文档
- `run-day.sh` — 流程入口向导（打印每步该做什么）

### 后续可扩展
- 定时推送：cron 或飞书机器人定时推送新知识点到飞书/微信
- 群聊分析：`lark-cli im +search` 搜群聊、归纳问题与解决方案
- 批量处理：对历史 Day 补跑

---

## 附录：常见问题

**Q: 课堂记录文档 token 变了？**
A: 重新 `docs +search --query "<课程 Day N>"`，取 owner 为自己的那条。

**Q: HTML 课件截图失败？**
A: 确认 `00-env.sh` 的 `CHROME_PATH` 正确，或确认系统已装 Chrome。检查 `courseware.html` 是否下载完整。若幻灯片结构非默认选择器，改 `shoot-slides.mjs` 顶部的选择器。

**Q: 课件是 PDF 无法处理？**
A: PDF 不能 fetch 也不能截图。降级：知识点只配课堂原文，注明课件为 PDF。

**Q: 图片插错位置了？**
A: media-insert 总是插到文档末尾，必须再用 block_move_after 移到锚点(原文 callout 的 block-id)后。确认锚点 id 取对。

**Q: 怎么确认飞书 CLI 装好/连通？**
A: 插件/技能里输入 lark 能搜到打勾技能=装好；`docs +search --query "test" --as user` 有结果=连通。

**Q: 飞书授权在哪通过？**
A: 飞书开发者助手里看到所有权限并点通过，或在弹出链接里通过。授权过期重新 `auth login --scope "<scope>"`。
