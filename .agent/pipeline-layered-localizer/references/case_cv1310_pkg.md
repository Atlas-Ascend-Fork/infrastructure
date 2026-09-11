# 案例：ops-cv PR 1310 run#1134 包安装失败定位

类型：流程C（包安装失败）｜已验证（2026-09-10）

## 背景

- PR 1310「add ROIAlign operator」（A5/ascend950 新算子，arch35）
- 最新 run #1134 FAILED，labels: ci-pipeline-failed + api-check-failed
- 用户疑问："是不是安装的 xml 没有配置好？"

## 分层路径

```
L0 PR 评论 → 最后一次 /compile(16:37) → run 043f81e6
L1 run#1134 FAILED 3.0min
L2 stage: compile FAILED（46 job 中仅 8 失败：4×A5 编译矩阵全挂，
          x86/arm/experimental/monitor 全过）
L3 job: Compile_A5_x86 等外层报 Sub-pipeline execution failed；
        内层 Compile [JOB_a5_compile_0] 报 步骤compile_acc执行失败 → 下日志
L4 step: compile_acc FAILED（3min 处）
L5 日志: cc5ef259…(内层job).zip → 3_compile_acc.log
```

注意 L2 判据价值：**只有 A5 矩阵挂** → 问题在 ascend950 专属构建路径，
非公共编译问题。

## L5 日志证据链

### 1. 构建与打包其实成功

```
[LOG_DO] bash scripts/ci/compile_a5_pkg.sh pr_filelist.txt -j16
[compile_a5_pkg] executing build_cmd: bash build.sh --pkg --ops=roi_align --soc=ascend950 ...
Self-extractable archive "cann-ops-cv-custom-linux.x86_64.run" successfully created.
```

ccache 统计 `miss: 0`（全命中）——排除编译问题。

### 2. 失败点在 .run 安装自检

```
./build_out/cann-ops-cv-custom-linux.x86_64.run --install-path=/tmp
[ops_custom] [INFO] validate shared libraries before installation
[ops_custom] [ERROR] Required shared library 'libcust_opmaster_rt2.0.so' was not found in package path.
[ops_custom] [ERROR] Shared library validation failed.
execute pkg error
::error::ASSERT FAILED: Build ops-cv (expected=0, actual=1)
```

### 3. 包清单确认缺库（CPack 段）

包内仅有 `op_proto/lib/linux/x86_64/libcust_opsproto_rt2.0.so`；
无 `libcust_opmaster_rt2.0.so`（tiling/ophost 宿主库）。

### 4. 编译产物反查（目标缺失）

`Building CXX object` 全列表：roi_align_def.cpp（gen 库）、roi_align_infershape.cpp
（ophost_cv_infer_obj）都编了；**roi_align_tiling.cpp 从未编译，无 cust_opmaster target**。

### 5. cmake 语义消息定根因

```
-- already compiled roi_align, skip        ← 铁证
```

根因链：
1. PR 在 `objdetect/roi_align/CMakeLists.txt` 顶层新增**新宏**
   `add_all_modules_sources(... TILING_DIR arch35 DISABLE_IN_OPP TRUE)`
2. 但未删除遗留的 `op_host/CMakeLists.txt`，其中是**旧宏**
   `add_modules_sources(OPTYPE roi_align ACLNNTYPE aclnn_exclude)`
   （旧宏 tiling glob 只扫 `op_host/*_tiling*.cpp` 顶层，不含 arch35 子目录）
3. 顶层 CMakeLists 的 foreach 先 `add_subdirectory(op_host)` → 旧宏先跑：
   infershape 编了、arch35 tiling 没收集、roi_align 标记进 COMPILED_OPS
4. 新宏被 `already compiled, skip` 跳过 → tiling 源永不编译
5. 无 tiling_obj → 无 cust_opmaster target → 打包条件 `if (TARGET cust_opmaster)`
   为假 → 库不入包 → 安装自检失败

### 6. 对照验证

CI 通过的 A5 算子（d_io_u_grad / g_io_u_grad / extract_glimpse_v2 / roi_align_grad）
全部**没有** `op_host/CMakeLists.txt`，只由顶层新宏注册 —— 本 PR 是唯一带遗留文件的。

## 结论与定界

**不是安装 xml 配置问题**（安装器必需库校验是正确的，包里真缺库）。
根因 = CMake 新旧宏注册冲突。修复 = 删除 `objdetect/roi_align/op_host/CMakeLists.txt`
（一行改动，让新宏全权接管）。

**定界输出示例**（三级定界 + 排除项）：

```markdown
## 定界结论
- 失败类型: 代码问题 / 包安装卸载验证失败（pkg_install_fail）
- 根因: PR 新增顶层新宏 add_all_modules_sources(TILING_DIR arch35)，
  但遗留 op_host/CMakeLists.txt 的旧宏 add_modules_sources 先执行并
  将 roi_align 标记已编译（"already compiled roi_align, skip"），
  tiling 源未编译 → cust_opmaster target 未生成 → 库未入包
- 影响 Job: 4 个 A5 编译矩阵（x86/arm × 默认/ubuntu24），根因组 #1（同因）
- 处置建议: 通知 PR 提交者删除 objdetect/roi_align/op_host/CMakeLists.txt
- 排除项:
  - 非环境问题: ccache miss=0（无重编压力）、其余 46 job 同机通过
  - 非工程问题: 同 workflow 其他 PR 运行正常、依赖下载步骤 COMPLETED
```

## 方法论沉淀

1. `ASSERT FAILED`/`execute pkg error` 是收尾信号（generic），真正根因在其上方的 [ERROR] 段
2. "构建成功+安装失败" 组合 → 直接跳到包清单比对，别在编译错误上浪费时间
3. `already compiled X, skip` 出现 + 产物缺失 = 注册冲突类根因（最高价值信号）
4. 目标缺失反查法：日志搜 `Built target <X>` 无果 → 查 target 创建条件 → 查跳过消息
5. 对照组方法：找同仓库结构相同且 CI 通过的算子比目录/宏用法差异
6. "只有特定芯片矩阵挂"（本例仅 A5）→ 优先查该芯片专属路径（soc 筛选/专属宏）
7. 多 Job 同因聚合：4 个 A5 job 归入同一根因组，报告只展开一次
8. 排除项用数据说话：miss=0、其余 job 通过——定界结论才立得住
