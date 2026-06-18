# lark-study-card

把一节课的**课堂记录 + 课件**，自动整理成飞书里一份**可勾选的「学习卡」**和一篇跨课**知识库主文档**。

> 课时长、信息量大、课件一堆、群消息几千条——这套工作流让 AI 帮你筛一遍，
> 把每节课变成"勾掉已掌握的，剩下没勾的就是该专注学的"的 todo。

每条知识点长这样：

```
☐ 什么是 Workflow：把一个任务拆成多个步骤，让 AI 按顺序自动执行
  ┌─────────────────────────────────────────┐
  │ 📢 课堂原文 01:12~03:34                    │
  │ （整段相关的课堂原文，不是一句话……）        │
  └─────────────────────────────────────────┘
  [对应课件幻灯片图 · 第3页]
```

## 这是什么

一套基于 [lark-cli](https://github.com/larksuite/cli) 的**工作流模板**（不是某个具体 App）。它把"跟 AI 反复试错才摸索出来的流程"沉淀成了一份操作手册 + 一组脚本，clone 下来照着跑就能复用，不用再从零跟 AI 聊需求。

- **输入**：你导出到飞书的课堂记录（妙记/录音转写）+ 课件（DOC 正文 / HTML 幻灯片）
- **处理**：AI 按知识点归纳，每条配整段课堂原文 + 对应幻灯片图
- **输出**：① 单课「学习卡」② 跨课「知识库主文档」（管勾选、幂等更新）

## 适合谁

- 上信息密集的课程/训练营，想要可勾选的复习清单
- 课件和记录都在飞书（或愿意导入飞书）
- 装了 lark-cli、能用飞书 CLI 读写文档

## 快速上手

```bash
# 1. 装好 lark-cli 并授权（见 lark-cli 文档）
# 2. 克隆本仓库
git clone https://github.com/Xarles-Lovell/lark-study-card.git && cd lark-study-card

# 3. 配置：复制模板，填入你的 token
cp scripts/lark/00-env.sh.example scripts/lark/00-env.sh
#   编辑 00-env.sh：填 RECORD_TOKEN / COURSEWARE_TOKENS / DAY / CHROME_PATH 等

# 4. 看流程向导（打印每步该做什么）
bash scripts/lark/run-day.sh 1

# 5. 跟着 RUNBOOK.md 一步步跑，或直接把 RUNBOOK.md 丢给 AI 让它照做
```

完整步骤见 **[RUNBOOK.md](RUNBOOK.md)**，它既是给人看的操作手册，也是给 AI（Claude/Codex 等）照做的指令。

## 仓库结构

```
lark-study-card/
├── README.md                    本文件
├── RUNBOOK.md                   ⭐ 操作手册（人和 AI 都照它做）
├── LICENSE                      MIT
├── docs/
│   └── workflow-design.md       架构、产出物结构、关键决策
├── scripts/lark/
│   ├── 00-env.sh.example        token/路径变量模板（复制为 00-env.sh）
│   ├── fetch-source.sh          抓课堂记录 + DOCX 课件正文
│   ├── shoot-slides.mjs         Chrome 无头逐页截图 HTML 课件
│   ├── create-card.sh           创建学习卡文档
│   ├── create-hub.sh            创建/初始化知识库主文档
│   └── run-day.sh               流程入口向导
└── examples/
    ├── card.sample.xml          学习卡 XML 样板（虚构课程，看格式用）
    └── outline.sample.md        AI 归纳大纲样板
```

> 课程数据（课堂原文、课件、幻灯片截图）属版权/隐私内容，**不进仓库**——`data/` 已在 `.gitignore` 里。
> 你的真实 token 写在 `00-env.sh`（同样被忽略），仓库只提交 `.example` 模板。

## 路线图

- [x] 第一部分：课堂（课件 + 课堂记录 → 学习卡 + 知识库主文档）
- [ ] 第二部分：群聊分析（归纳大家踩的坑与解决办法）
- [ ] 第二部分：定时推送（cron / 飞书机器人，每天推新知识点到飞书/微信）

## License

[MIT](LICENSE) · 欢迎 PR 和 issue。
