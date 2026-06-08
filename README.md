# Skill Collection

个人常用 AI agent skills 集合。仓库本身是长期保存的 skill 源，`setup` 负责把 `skills/*` 安装到 Codex、Claude Code 或两者。

这个安装方式参考了 `garrytan/gstack` 的模型：先把仓库 clone 到本机一个稳定位置，再运行 `./setup --host ...`。这样默认用 symlink 连接 skill，后续 `git pull && ./setup` 就能刷新安装结果。

## Install

推荐安装到持久目录：

```bash
git clone --single-branch --depth 1 https://github.com/wind22/Skill_Collection.git ~/.skill-collection
cd ~/.skill-collection
./setup --host auto
```

全量安装到 Codex 和 Claude Code：

```bash
cd ~/.skill-collection
./setup --host both --all
```

只安装某个 skill：

```bash
cd ~/.skill-collection
./setup --host codex --skill improve-questions
```

也可以用兼容的远程 bootstrap。它会把仓库 clone 或更新到 `~/.skill-collection`，然后转交给 `./setup`：

```bash
curl -fsSL https://raw.githubusercontent.com/wind22/Skill_Collection/main/install.sh \
  | bash -s -- --host auto
```

## Setup Commands

列出仓库里的 skills：

```bash
./setup --list
```

交互式选择 host 和 skill：

```bash
./setup
```

自动检测本机已有 Codex / Claude Code：

```bash
./setup --host auto --all
```

默认在 macOS/Linux 上用 symlink 安装。想复制一份快照而不是链接源仓库：

```bash
./setup --host both --all --copy
```

覆盖已有的非 symlink skill。旧目录会先备份成 `*.backup.YYYYmmddHHMMSS`：

```bash
./setup --host both --skill improve-questions --overwrite
```

## Layout

```text
Skill_Collection/
├── setup
├── install.sh
├── scripts/
│   └── import-local-skills.sh
├── skills/
│   └── improve-questions/
│       ├── SKILL.md
│       └── agents/
│           └── openai.yaml
└── README.md
```

`setup` 会自动扫描 `skills/*/SKILL.md`。目录名就是安装后的 skill 名称。

## Import Existing Skills

如果你已经在当前机器的 Codex 或 Claude Code 里装过一些 skill，可以交互式导入到这个仓库：

```bash
./scripts/import-local-skills.sh
```

导入 Codex 里的全部 skills：

```bash
./scripts/import-local-skills.sh --from codex --all
```

只导入 Claude Code 里的某个 skill：

```bash
./scripts/import-local-skills.sh --from claude --skill your-skill
```

导入后先检查 `skills/` 里的内容，确认没有不该进仓库的密钥、内部地址或敏感业务信息，再提交和推送。

## Install Locations

- Codex: `${CODEX_SKILLS_DIR}`，或 `${CODEX_HOME}/skills`，默认 `~/.codex/skills`
- Claude Code: `${CLAUDE_SKILLS_DIR}`，或 `${CLAUDE_HOME}/skills`，默认 `~/.claude/skills`

需要自定义路径时：

```bash
./setup --codex-dir /path/to/codex/skills --claude-dir /path/to/claude/skills
```

## Add A Skill

新建目录：

```bash
mkdir -p skills/my-skill
```

写 `skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when ...
---

# My Skill

具体工作流写在这里。
```

提交并推送后，其他设备就可以通过 `git pull && ./setup --host auto` 更新安装。

安装完成后，重启 Codex 或 Claude Code，让新 skill 生效。
