---
name: pipeline-layered-localizer
description: GitCode Actions PR门禁流水线失败的分层定位与定界技能。五层下钻模型（PR→Run→Stage→Job→Step→日志）+ 三级定界（代码/工程/环境→该谁修），含每层判据、只读API取数、失败job日志下载解包、末尾回溯定位真实根因、多Job同因聚合、ccache统计与cmake消息等日志处理逻辑，以及耗时定位（慢run）与包安装失败两类专项流程。触发词：PR失败、PR的CI失败、定位PR失败、某个PR失败、PR编译失败、PR为什么失败、PR门禁失败、门禁CI失败、流水线定位、run失败、stage失败、job失败、步骤失败、慢run、耗时异常、PR action执行久、ci-pipeline-failed、包安装失败、失败定界、根因分析、为什么失败、门禁挂了、download_log、compile_acc、ccache miss、already compiled。
---

# GitCode PR 门禁流水线分层定位与定界

对 GitCode（gitcode.com）`cann/*` 仓库 PR 门禁流水线（PR-pipeline_*）做**分层失败定位**、
**三级定界**与**耗时定位**。五层模型逐层下钻，每层有明确判据；**定位到 job 层后拉取
日志 zip 做根因分析**——zip 内按步骤分文件（首要 `3_compile_acc.log`），日志内末尾
回溯找真实根因，按"代码/工程/环境"定界并给出"该谁修"，多 Job 同因聚合输出。

## 适用与边界

- **适用**：GitCode Actions（v5/v8 API）、cann 组织各 ops 仓库的 PR 门禁、Nightly
- **不适用**：华为云 CodeArts 流水线（用 `pipeline-failure-analyzer` 技能）
- **边界**：全程只读（GET）；本技能不做任何远端修改；结论来自日志原文，禁止推测

## 触发场景路由

| 用户说 | 你做 |
|--------|------|
| "定位/检视 PR xxx 的失败" | L0 起钻：PR 详情 → 评论取最新 run → 逐层下钻 → 定界报告 |
| "这个 PR 的 CI 为什么失败" | 同上（先看 labels 与重试链） |
| "PR action 执行很久 / 慢 run" | 流程B（耗时定位） |
| "最近有哪些失败的流水线" | runs 列表按状态汇总（成功率/失败分布） |
| "把失败 Job 日志拉下来" | L3 定位 FAILED job → download_log 解包 |
| "这份日志为什么挂 / 帮我定界" | 直接进 L5：末尾回溯 → 三级定界 |
| "xx 仓库门禁健康吗" | runs 拉近 N 条 → 状态统计 + 基线对照 |

路由原则：要**事实**（跑了什么/挂了哪个/日志内容）→ 分层下钻；
要**判断**（什么类型/该谁修）→ 三级定界；端到端排障 → 组合。

## 分层模型与判据总表

**最常见入口：用户给 PR 号**（如"定位 ops-cv PR 1310 的失败"）——直接从 L0 开始，
按"PR 详情 → PR 评论取最新 run 链接 → 逐层下钻"执行。

```
L0 PR          → 找到目标 run（评论里机器人贴的 run 链接 / labels）
L1 Run         → 状态、总耗时、触发人/sha
L2 Stage       → 哪个 stage 失败/超时（compile/ut/后处理…）
L3 Job         → 哪些 job 失败，message 初分类
L4 Step        → 哪个步骤失败（compile_acc/Checkout/upload…）
L5 Log(zip)    → 末尾回溯定位真实根因 → 三级定界 → 聚合
```

| 层 | 数据源 | 判据（定位信号） |
|----|--------|-----------------|
| L0 | PR 详情/评论/labels | `ci-pipeline-failed` 标签；cann-robot 评论 `CI 流水线已启动` 内含 run 链接（取 workflow_run_id）；多次 `/compile` = 重试历史，**以最后一次运行为准** |
| L1 | run 详情 API | `status=FAILED/CANCELED`；`(end-start)/60000` vs 仓库基线（异常慢→慢run流程） |
| L2 | run.stages[] | `stage.status=FAILED`；stage `exec_min` 排序（耗时流程） |
| L3 | stage.jobs[] | `job.status=FAILED`；`job.message` 初分类（见下）；job `exec_min` 排序 |
| L4 | jobs API 的 steps[] | `step.status=FAILED`；`IGNORED` 是失败后的正常跳过不算根因；step 起止时间 |
| L5 | download_log zip | 末尾回溯 → 真实根因行 → 三级定界（见 references/classification_rules.md） |

### L3 job.message 初分类判据（关键）

| message 特征 | 含义 | 后续动作 |
|--------------|------|---------|
| `Sub-pipeline execution failed ... error_details: unknown` | 加速子流水线基础设施错误 | 换 run 对比；多为重试可恢复 |
| `步骤compile_acc执行失败，错误信息：点击任务查看详情` | 真实构建失败 | **必须下日志**（其外层 job 的内层 job 才有日志） |
| `步骤ut执行失败` / 类似 | UT 失败 | 下 ut job 日志 |
| 无 message + FAILED | 日志缺失或详情未含 | 直接下日志看 |

注意：`Compile_A5_x86`（外层 job）与 `Compile`（内层 job，identifier `*_0`）成对出现；
**日志挂在 identifier 带 `_0` 的内层 job 上**，外层只有 sub_pipeline 引用。

## 三级定界（L5 出口：什么类型 + 该谁修）

| 大类 | 含义 | 处置建议 | 典型小类 |
|------|------|---------|---------|
| **代码问题** | PR 变更导致 | 通知 PR 提交者修复（附具体文件/用例/算子） | 编译错误（含算子 TBE 参数校验）、LLT测试/编译失败、代码检查、SCA、冒烟、覆盖率、包安装卸载验证、issue未关联 |
| **工程问题** | CI 配置/依赖/服务 | 转 CI 维护者（附缺失依赖/配置点） | 依赖包下载、代码下载、镜像拉取、配置错误、平台限流、CodeCheck服务 |
| **环境问题** | 运行环境异常 | 标注可否重试（平台/网络类可重试，磁盘/设备类需人工介入） | Runner异常、平台内部错误（仅兜底）、超时、OOM、网络、设备/NPU、磁盘 |

完整判据（大类→小类→正则，首次命中生效）见
[references/classification_rules.md](references/classification_rules.md)。

**Job 名兜底/改判**（日志未命中或需细化时）：
- `UT`/`ST_*` → LLT测试失败（其中的编译错误 → LLT编译失败）
- `PreSmoke_*` → 冒烟；含 `codecheck`/`Antipoison` → 代码检查；`SCA` → SCA检查
- `Compile`/`Build` → 编译错误

**特殊边界情形**：构建成功但 `.run` 安装自检失败（`[ops_custom] ERROR Required shared library`）
→ 归**代码问题**（PR 的构建配置错误，如 cmake 注册缺失导致产物缺库），
处置对象是 PR 提交者而非环境/平台。

## 末尾回溯原则（果不是因）

日志从**末尾往前**回溯，找最先触发失败的那一行。以下都是"果"，见到跳过继续向前：

| 跳过信号 | 原因 |
|----------|------|
| 平台内部错误（`DEV-CODECI-*`、`查询 step status 失败`） | 前面步骤挂了平台才查不到状态 |
| 总结性报错（`[ERROR] UT build/test failed`、`ASSERT FAILED`、`execute pkg error`、`N FAILED TEST`） | 构建脚本/平台的汇总输出 |
| make 级联（`] Error 2`） | 子 make 退出码，根因在更早的 Error 1 |
| 失败后置检查（`ls: cannot access 'build_out/'`） | 产物检查报错是编译失败的连锁 |

**严禁只报平台错误码或总结行**——必须回溯到真实构建错误（哪个文件/行号/算子/用例/缺哪个库）。
确实只有平台错误时才归「环境问题/平台内部错误」。

## 根因聚合

多个失败 Job 先判断是否同一根因（错误模式/算子/文件相同 → 归组）：

- 同因只报一次，报告用根因组编号（#1 #2 …）串联 Job
- 典型：`4 个 A5 编译 Job → 1 个 cmake 注册问题`（案例 cv1310）
- 全部分析，不要只报第一个；也不要把同因失败重复罗列

## 数据获取（只读 API）

Token：环境变量 `GC_TOKEN`（或用户提供的查询 token）。

| 端点 | 用途 | base |
|------|------|------|
| `GET /repos/{org}/{repo}/pulls/{n}` | PR 详情：head/base sha、labels | v5 |
| `GET /repos/{org}/{repo}/pulls/{n}/comments` | 挖 run 链接、重试历史、评审意见 | v5 |
| `GET /repos/{org}/{repo}/pulls/{n}/files` | PR 改动面（根因关联） | v5 |
| `GET /repos/{org}/{repo}/actions/runs?workflow_id=..&page=..` | run 列表（run_number、status、PR 号） | **v8** |
| `GET /repos/{org}/{repo}/actions/runs/{run_id}` | **run 详情（含 stages[].jobs[]）** | **v8** |
| `GET /repos/{org}/{repo}/actions/runs/{run_id}/jobs` | job 列表含 steps[] 明细 | **v8** |
| `GET /repos/{org}/{repo}/actions/runs/{run_id}/jobs/{job_id}/download_log` | 失败 job 日志 zip | **v8** |

要点：
- **actions 端点只在 v8**（v5 返回 404）；PR/issue 在 v5
- `workflow_id` 可从 `GET .../actions/workflows` 发现（找 `PR-pipeline_<repo>`）
- run 详情一次返回全部 stage/job/时间戳，**优先用它**（jobs API 补 steps）

### 日志下载（L5 入口）

```
GET /api/v8/repos/{org}/{repo}/actions/runs/{rid}/jobs/{jid}/download_log
→ 302 Location: https://raw.gitcode.com/.../download-log?access_token=<token>
→ 跟随重定向拿 zip（~30KB-15MB）
```

- **只有 FAILED job 的日志会归档**；成功 job 下载返回 200 + 0 字节（空）
- 新 run（平台侧归档延迟/故障）也可能返回空——此时换更早的失败 run 或同 PR 其他 run
- zip 内按步骤分文件，首要分析 `3_compile_acc.log`（结构见 references/log_patterns.md）

## 日志处理逻辑（L5）

分析顺序：**末尾回溯定位根因行 → 三级定界分类 → 聚合 → 报告**。
特征模式库（失败锚点正则、cmake 语义消息、ccache 统计、Built target 时间线、
包清单比对）见 [references/log_patterns.md](references/log_patterns.md)。

### 根因关联（L5 → PR 改动）

定位到构建系统层后，拉 PR files diff 关联：
- 失败算子是否在 PR 改动列表 → CMakeLists/注册文件变更 → 对照**同仓库已通过的同类算子**的写法差异
- 典型：新增 `add_all_modules_sources`（新宏）但遗留 `op_host/CMakeLists.txt` 的旧宏 → 注册冲突（案例 cv1310）

## 专项流程

### 流程A：失败定位与定界（默认）

```
PR 评论 → run_id → run 详情 → FAILED stage/job → message 分类
→ 若"子流水线错误"：对照同 PR 相邻 run（重试是否恢复；恢复→环境问题·可重试）
→ 若"compile_acc 失败"：下内层 job(_0) 日志
→ 末尾回溯 → 真实根因行 → 三级定界（代码/工程/环境）
→ 多 Job 同因聚合 → PR files diff 关联 → 定界结论 + 排除项
```

### 流程B：耗时定位（慢 run）

```
run 详情 → stage/job exec_min 排序 → 关键路径 job（常见 arm 编译最慢）
→ jobs API steps 耗时（compile_acc 占比 ~99% 即到日志层）
→ 下载日志 → CloudCache JSON（miss 率）→ Built target 时间线
→ 结论模板：总时长 / 关键路径 / miss 统计 / 根因（如头文件大改导致缓存失效）
→ 历史对照：该 job 正常态耗时（本地 pipeline-data 或 API 翻历史 run）
```

### 流程C：包安装失败

```
日志定位 [ops_custom] ERROR → 包清单确认缺失库
→ 仓库 cmake 分析：库的打包条件（if TARGET X）
→ target 生成链反查（谁创建 X、什么条件跳过）
→ cmake 消息佐证（already compiled / don't need add tiling）
→ 对照通过案例的同结构算子 → 定界：代码问题（PR 构建配置错误）
```

## 输出报告模板

见 [references/report_template.md](references/report_template.md)。要点：

- 概览 → 失败 Job 明细（表格含根因组编号）→ 按根因组聚合的分析（判据/影响 Job/日志原文证据）→ **定界结论（类型/根因/该谁修/可否重试）+ 排除项（用证据说明为何不是其他类别）**
- Failed_Reason 格式：`[小类]: <具体对象> <具体错误>`，引用日志原文含文件/行号/算子/用例名

## 纪律（Constraints）

1. 每个结论必须挂日志原文证据；文件名/行号/用例名/算子名禁止推测
2. 区分"根因"与"连锁失败"；不把总结行/平台错误当根因
3. 多失败 Job 全部分析并按根因聚合；同因只报一次
4. 未定界时如实说明（判据库未覆盖），建议补充规则，不编造分类
5. API 失败内置退避；连续失败报告网络/令牌问题，不无限重试
6. 涉及 token/IP 输出前脱敏；只读边界：建议供人工执行，不回写远端

## 参考文档

技能内文档：
- [references/api_endpoints.md](references/api_endpoints.md) —— API 端点与 token 细节、坑
- [references/layer_criteria.md](references/layer_criteria.md) —— 分层判据明细与时间戳换算
- [references/classification_rules.md](references/classification_rules.md) —— 三级定界判据库（大类→小类→正则 + 兜底机制）
- [references/log_patterns.md](references/log_patterns.md) —— 日志特征模式库（正则 + 解读）
- [references/case_pr11316_slow.md](references/case_pr11316_slow.md) —— 慢 run 案例（ops-transformer 119.9min）
- [references/case_cv1310_pkg.md](references/case_cv1310_pkg.md) —— 包安装失败案例（ops-cv PR1310 opmaster 缺失）
- [references/report_template.md](references/report_template.md) —— 完整报告模板（含定界结论/排除项/好坏示例）

社区关联文档（判据知识源头，随 infrastructure 仓库分发时适用）：
- [robot使用指南](../../docs/robot/robot使用指南.md) —— L0 判据源头：/compile 等命令、标签语义
- [CI工程检查项概览](../../docs/ci/ci_guide.md) —— L2~L4 判据源头：检查项分类与任务状态
- [基础设施支撑矩阵](../../docs/services.md) —— 定界结论的处置出口（该联系谁）

## 已验证案例

| 案例 | 类型 | 定界 | 根因 | 关键证据 |
|------|------|------|------|---------|
| ops-transformer PR 11316 run#5816 | 慢 run 119.9min | 工程特征（重试可恢复另见 #5801） | 44 头文件缓存失效全量重编 | miss=16005/18652 + Built target 时间线 |
| ops-transformer run#5801 | 基础设施失败 | 环境问题·可重试 | 子流水线 unknown 错误 | job.message + 重试 run 对比 |
| ops-cv PR 1310 run#1134 | 包安装失败 | **代码问题**（PR 构建配置） | CMake 新旧宏注册冲突致 opmaster 缺库 | already compiled skip + 包清单缺 .so；排除项：ccache miss=0、其余 46 job 通过 → 非环境/工程问题 |
