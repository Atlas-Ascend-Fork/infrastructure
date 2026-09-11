# 分层定位与定界报告模板

## 失败定位与定界报告（流程A）

```markdown
# 流水线分析报告 — {repo} run#{num}

## 概览
- 状态/工作流/触发事件/分支/PR/触发者/时间区间
- Job 执行统计（COMPLETED x / FAILED y / INIT z）
- 触发链：{作者} /compile 第 {k} 次重试

## 分层路径
L2 stage: {name} (FAILED, {X}min)
L3 job: {job_name} [{identifier}] —— message: {分类结论}
L4 step: {step_name} ({X}min, FAILED)
L5 日志: {job_id 前8位}.zip → {步骤日志文件}（末尾回溯至根因行）

## 失败 Job 明细
| Job | 编译目标/任务 | 耗时 | 根因组 |
|-----|--------------|------|--------|
| Compile_A5_x86 | roi_align | 3.1min | #1 |
| Compile_A5_arm | roi_align | 3.3min | #1 |
（多 Job 同因 → 同一根因组编号，只报一次）

## 失败根因分析
### 根因组 #N: {大类} / {小类} — {算子/文件/用例名}
- 判据: {命中的分类判据}
- 影响 Job: {列表}
- 根因证据: {日志原文代码块，含文件/行号/算子名}

## 定界结论
- 失败类型: **{代码|工程|环境}问题 / {小类}**
- 根因: {一句话}
- 处置建议: {该谁修 + 具体动作}
- 可否重试: {环境问题必填：可重试/需人工}
- **排除项**:
  - 非环境问题: {证据，如 "ccache miss=0、其余 46 job 同机通过"}
  - 非工程问题: {证据，如 "同 workflow 其他 PR 运行正常"}

## 修复建议
{最小改动方案，落到文件级}
{需人工确认的点}
```

## 慢 run 报告（流程B）追加段

```markdown
## 耗时分解
| 层 | 对象 | 耗时 | 占比 |
|----|------|------|------|
| stage | compile | 112.0min | 93% |
| job | Compile_experimental_950_arm | 112.0min | 关键路径 |
| step | compile_acc | 111.2min | 99% |

## 缓存统计
- total={N} remote_hit={H} miss={M}（miss率 {P}%）
- 判读：{全量重编 / 命中但构建慢 / ...}

## 算子/目标级时间线
| 完成时间 | target | 间隔 |
|---------|--------|------|
| ... | ... | ... |

## 根因
{如：44 头文件变更 → ccache key 失效 → 长尾算子 kernel 实例化}
```

## 包安装失败报告（流程C）追加段

```markdown
## 安装自检失败
- 缺失库：{libX.so}
- 包内实际：{存在的库列表}
- 打包条件：{cmake 中的 if (TARGET X) 等}

## target 生成链反查
{X 由谁创建} → {跳过点：already compiled / 条件宏} → {根因}

## 对照组
{同仓库通过算子的结构差异}

定界：代码问题（PR 构建配置错误）；排除项：ccache miss=0（非缓存/环境）、
其余 46 job 通过（非工程/平台）
```

## Failed_Reason 好坏对照

**好**（引用日志原文 + 技术细节）：
```
[编译错误]: objdetect/roi_align/op_host/arch35/roi_align_tiling.cpp 编译被跳过
  （already compiled roi_align, skip），导致 libcust_opmaster_rt2.0.so 未入包
[LLT测试失败]: UT_AuthService_testLogin testLogin_001 用例失败, expected:<true> but was:<false>
[编译错误]: src/ops/gnn.cpp:142:5: error: 'kGiouCoeff' was not declared in this scope
```

**坏**（总结行，等于让人再翻日志）：
```
[ERROR] UT build/test failed          ← 汇总不是根因
构建失败                                ← 无任何细节
ASSERT FAILED: Build ops-cv            ← 平台收尾信号
```

## 报告纪律

1. 每个结论必须挂日志原文证据（行号或位置）；文件名/行号/用例名/算子名禁止推测
2. 区分"根因"与"连锁失败"；不把总结行/平台错误当根因
3. 多失败 Job 全部分析并按根因聚合；同因只报一次
4. 未定界时如实说明，建议补充判据规则，不编造分类
5. 修复建议给到文件/行级，并注明需人工确认的部分
6. 涉及 token/IP 输出前脱敏（access_token=、172.27.x.x）
7. 只读边界：所有建议供人工执行，本技能不回写远端
