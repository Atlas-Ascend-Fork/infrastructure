# 🤖 AI 技能（Agent Skills）

本目录托管 CANN 社区基础设施团队的 **AI 技能资产**：将门禁 CI 看护、流水线排障等
基础设施运维方法论沉淀为可复用技能，供 CannBot 及各类 AI 代理（opencode / Claude /
Codex）在处理社区 CI 问题时按需加载，也供开发者作为排障手册查阅。

## 技能清单

| 技能 | 用途 | 适用场景 | 来源案例 |
|------|------|---------|---------|
| [pipeline-layered-localizer](./pipeline-layered-localizer/SKILL.md) | GitCode PR 门禁流水线失败分层定位与定界（PR→Run→Stage→Job→Step→日志五层下钻；代码/工程/环境三级定界；慢 run / 包安装失败专项流程） | PR 的 CI 失败定位、慢 run 分析、包安装自检失败 | ops-transformer PR 11316（慢 run 119.9min）、ops-cv PR 1310（opmaster 缺库） |

## 与社区文档体系的关系

技能判据与社区既有文档同源，互为补充（文档面向人工阅读，技能面向 AI 加载执行）：

| 技能知识点 | 对应社区文档 | 说明 |
|-----------|-------------|------|
| L0 判据：`/compile` 触发流水线、`ci-pipeline-failed` 标签、重试链 | [robot使用指南](../docs/robot/robot使用指南.md) | 机器人命令表与标签语义 |
| L2~L4 判据：检查项分类（静态检查/编译构建/测试）、任务状态含义 | [CI工程检查项概览](../docs/ci/ci_guide.md) | Compile_{xxx}/UT_{xxx}/PreSmoke_{xxx} 任务命名与状态 |
| 流水线部署与配置 | [CI流水线配置指导](../docs/ci/CI流水线配置指导.md) | 定位到工程配置类根因时转人工渠道 |
| 失败后联系谁 | [基础设施支撑矩阵](../docs/services.md) | 定界结论的处置出口（CIE/支撑人） |

## 使用方式

**AI 代理加载**（以 opencode 为例，其他工具参照各自 skill 目录约定）：

```bash
# 单技能链接（推荐）
mkdir -p ~/.config/opencode/skills
ln -s $(pwd)/.agent/pipeline-layered-localizer ~/.config/opencode/skills/pipeline-layered-localizer
```

**人工阅读**：直接打开对应技能的 `SKILL.md`（方法论总纲），深入细节看 `references/`
（分层判据、日志模式库、实战案例、报告模板）。

## 技能规范

- 每个技能一个目录：`SKILL.md`（frontmatter 含 name 与 description 触发词）+ `references/`
- 命名 kebab-case；触发词覆盖真实用户表述（如"定位某个 PR 的失败"）
- 案例类内容必须来自已验证的实战（附日志证据），不接受臆造

## 版本与贡献

技能在本目录内直接维护演进；新增或修订技能请在本仓库提 PR
（commit 注明变更内容与来源案例）。

## 🔍 FAQ

**Q：技能和 docs/ 下的服务文档是什么关系？**
A：同一知识体系的两种形态——docs/ 面向人（怎么用 CI/机器人），技能面向 AI（怎么自动
定位问题）。技能判据引用的知识以 docs/ 文档为源头，两边同步演进。

**Q：我不是 AI 代理使用者，这些内容对我有用吗？**
A：有用。`SKILL.md` 及其 references 本质是结构化的排障手册与判据库，可按
"分层模型"章节人工逐层排查 CI 失败。

**Q：如何贡献新技能？**
A：在本仓库提 PR（规范见上方"技能规范"与"版本与贡献"章节）。
