# 分层判据明细

## L0 → L1：从 PR 找 Run

| 信号 | 判据 | 动作 |
|------|------|------|
| PR labels 含 `ci-pipeline-failed` | CI 失败过 | 需定位 |
| PR labels 含 `ci-pipeline-passed` | 最新 run 通过 | 失败是历史，翻重试链 |
| cann-robot 评论 `CI 流水线已启动` | 内含 run 链接 | 提取 workflow_run_id（URL 尾部 32 hex） |
| 用户多次 `/compile` | 重试链 | **以最后一次运行为准**，前几次作为对照 |
| `api-check-failed` 标签 | api-check 门禁失败 | 单独看 api-check step（非编译问题） |

## L1：Run 级判据

| status | 含义 |
|--------|------|
| `COMPLETED` | 全绿；若耗时异常 → 流程B（慢 run） |
| `FAILED` | 有失败 job → 继续 L2 |
| `CANCELED` | 用户取消（通常有新提交重触发）；但部分 CANCELED 是失败连带，看 stages |

耗时基线：各仓库 p50（参考值，2026-09 实测）：
- ops-transformer ~12min、ops-nn ~16min、ops-math ~16.5min、ops-cv ~11min
- 超过基线 5 倍 → 慢 run 值得分析

## L2：Stage 级判据

典型 stage 序列：`PreBuild → compile → ut → ut_report → 后处理阶段`

- `compile FAILED` → 编译问题（最常见）
- `ut FAILED` → 用例问题，ut job 日志
- stage `INIT` = 前序失败未执行（不是根因）

## L3：Job 级判据

job 命名规律：
- `Compile_<matrix>`：x86 / arm / experimental / monitor_9xx / kirinx90 / A5(ascend950) × ubuntu24
- 外层 `Compile_A5_x86 [JOB_a5_compile]` + 内层 `Compile [JOB_a5_compile_0]` 成对
- **只有内层（identifier 带 `_0`）有日志**；外层 message 是 sub_pipeline 引用

message 分类（优先级从上到下）：

```
"Sub-pipeline execution failed, parent_job_run_id:..., sub_pipeline_run_id:..., error_details: unknown"
    → 加速子流水线基础设施错误（重试大概率恢复；同 PR 相邻 run 对照）
"步骤compile_acc执行失败，错误信息：点击任务查看详情"
    → 真实构建失败，必须下日志
"步骤<其它>执行失败"
    → 对应步骤失败，下日志
```

关键路径判断（耗时流程）：同 stage 内 jobs 按 exec_min 降序，
取最长者；典型模式 `arm ≈ 1.8 × x86`，若同倍率整体变慢 → 疑似全量重编。

## L4：Step 级判据

jobs API 返回每个 job 的 steps[]：

| step | 失败含义 |
|------|---------|
| `compile_acc [build-accelerate]` | 构建真失败（核心分析对象） |
| `Checkout` | 代码/网络问题 |
| `download` (obs-download) | OBS 依赖下载问题 |
| `rename_package` / `verify_package` | 产物问题 |
| `api-check` | API 签名/符号门禁 |
| `upload` (obs-upload) | 上传问题 |

- `IGNORED` = 前序失败被跳过，**不是根因**
- `compile_acc` 耗时 ≈ job 总耗时 → 时间都在构建里（慢 run 下钻到日志）

## L5：日志级判据

见 [log_patterns.md](log_patterns.md)（末尾回溯跳过信号）与
[classification_rules.md](classification_rules.md)（三级定界判据库）。核心顺序：
1. **末尾回溯**定位真实根因行（跳过平台错误/总结行/make 级联/后置检查）
2. 根因行匹配三级定界判据（代码→工程→环境，首次命中生效）
3. cmake 语义消息（`already compiled` 类注册冲突）是代码问题的高价值子类
4. 耗时问题看尾部 CloudCache JSON + Built target 时间线
5. 包问题看 CPack 清单 + 安装自检段 → 定界为代码问题（PR 构建配置）

## 判据优先级原则

1. 有真实错误行 > 只有失败状态
2. 日志内最早错误 > 最后的连锁错误（`ASSERT FAILED` 是收尾不是根因）
3. 多 job 同败 → 找共同根因（同一构建脚本/配置），不逐 job 重复分析
4. message 分类优先于日志（子流水线 unknown ≠ 代码问题）
