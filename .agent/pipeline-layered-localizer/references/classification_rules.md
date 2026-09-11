# 三级定界判据库

> 大类顺序：代码问题 → 工程问题 → 环境问题；小类/判据按排列顺序**首次命中生效**。
> 匹配前先按 SKILL.md「末尾回溯原则」定位真实根因行。

## 匹配机制

| 机制 | 说明 |
|------|------|
| **首次命中生效** | 判据按序匹配，命中即定类，不继续 |
| **generic（总结性判据）** | 如 `UT build/test failed`、`make *** Error`——是汇总不是根因，**仅兜底**（未找到具体根因时），证据取日志中最近的具体错误行 |
| **fallback_only（平台错误）** | 如 `DEV-CODECI-*`、`查询 step status 失败`——是结果不是根因，回溯时跳过，仅在无真实错误时归「环境问题/平台内部错误」 |
| **Job 名兜底** | 日志未命中判据时按 Job 名判定（表见 SKILL.md） |
| **Job 名改判** | 命中后按 Job 名细化（如 UT/ST 任务中的编译错误 → LLT编译失败） |

---

## 代码问题（code）—— PR 变更导致，提交者修

### 编译错误（compile_error）

Job 名兜底：`(?i)^(?:Compile|Build)(?:[-_\s]|$)`；Job 名改判：`(?i)^(?:UT|ST)(?:[_\s\d]|$)` → llt_compile_fail

| 判据（正则） | 说明 |
| --- | --- |
| `(?:\S+\.(?:cpp|cc|cxx|h|hpp)):\d+:\d+:\s*(?:fatal\s+)?error` | 源文件编译报错 |
| `undefined reference to` | 链接符号未定义 |
| `multiple definition of `([^']+)'` | 符号重复定义 |
| `cannot find -l(\S+)` / `library not found for -l(\S+)` | 链接库缺失 |
| `undefined symbol: (\S+)` | 动态符号未定义 |
| `collect\d*: error: ld returned` | 链接失败 |
| `compilation terminated` | 编译中止 |
| `internal compiler error` | 编译器内部崩溃 |
| `Exception occured, \(\{'errCode': '[^']*', 'op_name': '(\w+)'` | 算子 TBE 参数校验异常 |
| `exe_task: build kernel FAILED, op name: (\S+)\.` | 算子 kernel 编译失败（总结性，仅兜底） |
| `(?:cc1plus?|cicc|ccec|bisheng|clang|gcc)[^\n]{0,80}[Ss]egmentation fault` | 编译器段错误 |
| `make\[?\d*\]?:\s*\*\*\*.{0,80}Error` | make 失败（总结性，仅兜底） |
| `cp: cannot stat '([^']+)'` | 构建产物未生成（上游未产出） |

**cmake 语义判据（本技能特有，注册/选择类根因）**：
| 判据 | 说明 |
| --- | --- |
| `already compiled (\S+), skip` | 新旧宏注册冲突：算子被先执行的宏注册，后续宏被去重跳过 |
| `CMake Error` | cmake 配置/依赖错误 |
| `add_library cannot create target "(\S+)"` | target 重复定义（CMP0002） |

### 代码检查错误（code_check）

Job 名兜底：`(?i)codecheck|antipoison|staticcheck|静态检查`

| 判据 | 说明 |
| --- | --- |
| `codecheck result: no pass` / `结果.*不通过` | 检查不通过 |
| `存在.{0,8}文件格式错误` | precommit 格式不合规 |
| `(\S+) 被修改了，但 (\S+) 未在.{0,10}同步修改` | 双语文档未同步 |
| `Discovered \d+ warnings` | 静态检查告警 |

### LLT测试失败（llt_fail）

Job 名兜底：`(?i)^(?:UT|ST)(?:[_\s\d]|$)`

| 判据 | 说明 |
| --- | --- |
| `The following tests FAILED:` / `\[\s*FAILED\s*\]\s*(\S+)` | gtest 用例失败 |
| `FAILED (\S+::\S+)` | pytest 用例失败 |
| `Segmentation fault \(core dumped\)` | 用例执行崩溃 |
| `munmap_chunk\(\): invalid pointer\|double free or corruption` | 堆内存错误崩溃 |
| `UT (\S+) timed out after` | 用例挂死超时 |
| `UT build/test failed`（generic） | UT 汇总（仅兜底） |

### LLT编译失败（llt_compile_fail）

| 判据 | 说明 |
| --- | --- |
| `No SOURCES given to target: (\S+)` | UT target 无源文件 |
| `another target with the same name already exists` | CMake target 重复 |
| `编译 UT 失败`（generic） | 汇总（仅兜底） |

### 包安装卸载验证失败（pkg_install_fail）★ 本技能特有

| 判据 | 说明 |
| --- | --- |
| `\[ops_custom\] \[ERROR\] Required shared library '(\S+)' was not found` | 包缺库（配套反查：Built target 缺失 + already compiled/don't need tiling → cmake 注册类代码问题） |
| `execute pkg error`（generic） | 安装自检失败汇总（根因在其上 [ERROR] 行） |

### 其他小类

- 冒烟失败（smoke_fail）：Job 名 `PreSmoke_*`；`GET /health 返回 5xx` 类
- SCA（sca_fail）：`code sca.*no pass`、开源合规
- 覆盖率不足：`行覆盖率 X% 低于阈值`
- issue未关联：PR 未关联 issue

---

## 工程问题（eng）—— CI 配置/依赖/服务，维护者修

| 小类 | 判据（示例） |
| --- | --- |
| 依赖包下载失败 | `Failed to download`、OBS 超时（L4 `download` step 失败） |
| 代码下载失败 | `git clone` 超时、DNS 解析失败 |
| 镜像拉取失败 | `ImagePullBackOff`、registry 超时 |
| 配置错误 | workflow YAML 解析失败、trigger 分支不在白名单（`触发分支未在白名单`） |
| GitCode平台限流 | `TOO_MANY_REQUESTS`、HTTP 429 |
| CodeCheck服务问题 | `codecheck sync failed` |

---

## 环境问题（env）—— 运行环境异常，标注可否重试

| 小类 | 判据 | 可否重试 |
| --- | --- | --- |
| Runner/平台内部错误（fallback_only） | `DEV-CODECI-\d+`、`Sub-pipeline execution failed.*error_details: unknown`、`查询 step status 失败` | 可重试 |
| 超时被杀 | `timed out`、`TimeoutExpired`、context deadline | 可重试一次 |
| 内存不足 | `out of memory`、`cgroup oom`、`Killed process` | 需人工（降并行度） |
| 磁盘问题 | `No space left on device` | 需人工（清缓存） |
| 网络异常 | `Connection reset`、`curl: (7)` | 可重试 |
| 设备/NPU异常 | `EE9999`、npu-smi 错误、device 集群失联 | 需人工 |

**子流水线 unknown 判读**（高频）：`Sub-pipeline execution failed, error_details: unknown`
且同 PR 重试后恢复 → 环境问题·可重试；连续复现且多 PR 同发 → 升级疑似工程问题（基础设施）。

---

## 排除项写法（定界结论必备）

用证据说明为何**不是**其他类别，例：

- 「非环境问题：ccache miss=0（无重编压力）、其余 46 job 同机通过」
- 「非工程问题：同仓库其他 PR 的同 workflow 运行正常、依赖下载步骤 COMPLETED」
- 「非平台抖动：4/4 个 A5 job 稳定复现于 3 次重试 run」
