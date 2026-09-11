# 案例：ops-transformer PR 11316 run#5816 慢 run 定位（119.9 分钟）

类型：流程B（耗时定位）｜已验证（2026-09-05）

## 背景

- PR 11316「MicroAPI替换为Reg（experimental/attention 第1批 44 文件）」
- run #5816 COMPLETED 但 119.9min（仓库 p50=11.6min，10.4 倍）
- 同 PR 前一 run #5801 FAILED（子流水线 unknown），17:14 重试后成功但极慢

## 分层路径

```
L1 run#5816 COMPLETED 119.9min（超基线 5 倍 → 慢 run 流程）
L2 stage: compile 112.0min（其余 stage <6min）
L3 job: Compile_experimental_950_arm 112.0min ←关键路径
        （同型: arm_u24 111.9 / x86 62.0 / x86_u24 61.9；其余 30+ job 均 <4min）
L4 step: compile_acc [build-accelerate] 111.2min（Checkout+打包 <1min）
L5 日志: e4ce7fea…(arm950 job).zip → 3_compile_acc.log
```

## L5 日志证据

### 1. CloudCache 统计（尾部）

```json
{"total": "18652", "remote_hit": "2465", "local_hit": {"direct": "16"},
 "miss": "16005", "skip": "166"}
[CloudCache] build success, cost 6671.88 s
```

**miss 率 86%** —— 44 个被广泛包含的头文件（MicroAPI→Reg）使全部相关 TU 缓存 key 失效，
18,652 次编译几乎全量真实执行。x86 job miss=15193（62min），ARM 慢 1.8 倍符合机器差。

### 2. Built target 时间线（算子级）

```
17:21:21 kv_quant_sparse_attn_sharedkv      (1min)
17:24:31 compressor (4 variants)            (3min)
18:37:44 flash_attention_score_grad_apt_ascend950_2   ← 单 target 73min
19:06:12 flash_attention_score_grad_apt_ascend950_1   ← 29min
19:06:47 flash_attention_score_grad_apt_ascend950_0 / 打包
```

`Generating ... Done` 统计：FlashAttentionScoreGrad 11 个 kernel bin，
首个 17:16:44 启动、末个 19:06:47 完成 —— 一个算子占全程。

### 3. 历史对照（关键佐证）

该 job（JOB_arm_experimental_950_compile）近 500 次运行全部 1.1~1.5min（纯缓存命中）。
仅 2 个 run 异常：#5663（PR 11240，master 首次带上 MicroAPI→Reg 第 0 批，109.4min 同型）与本 run。
→ 结论：非流水线退化，是**该系列改动导致的必然全量重编**。

## 结论输出（节选）

```
根因：PR 修改 44 个 experimental/attention 头文件 → ccache key 全变 →
6 算子 1.6 万 TU 真实重编（miss 86%）→ flash_attention_score_grad apt
kernel 模板实例化为长尾（102min）→ ARM 执行机为关键路径。
```

## 方法论沉淀

1. 慢 run ≠ 流水线故障：先查 miss 统计排除缓存失效（最常见根因）
2. Built target 时间戳是算子级时间线的唯一可靠来源
3. 历史基线对照（本地 pipeline-data 或 API 翻历史 runs）区分"偶发"与"必然"
4. message 里 `Sub-pipeline execution failed`（#5801）是基础设施错误，
   与慢 run 无关但会叠加重试延迟——分层报告要分开陈述
