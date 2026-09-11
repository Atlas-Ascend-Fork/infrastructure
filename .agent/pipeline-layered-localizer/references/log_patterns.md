# 日志特征模式库

针对 `3_compile_acc.log`（构建主日志）。所有模式忽略大小写除非注明。
噪音过滤：`ge_error_codes.h`（CANN 头文件弃用告警，全日志刷屏）、`warning`。

## 0. 末尾回溯跳过信号（果不是因，见到继续向前）

| 模式 | 类别 | 原因 |
|------|------|------|
| `DEV-CODECI-\d+`、`查询 step status 失败` | fallback_only | 前面步骤挂了平台才查不到状态 |
| `ASSERT FAILED: Build <repo>`、`execute pkg error`、`\[ERROR\] UT build/test failed`、`N FAILED TEST` | generic | 汇总输出，根因在其上方 |
| `gmake\[\d+\]: \*\*\* .* Error 2` | make 级联 | 子 make 退出码，找更早的 Error 1 |
| `ls: cannot access 'build_out/'` | 后置检查 | 产物检查是编译失败的连锁 |
| `BuildAccelerate 执行失败，退出码: \d+` | 收尾 | 构建命令最终退出码 |

回溯到**第一个具体错误**（文件:行号 / 算子名 / 用例名 / 缺失库名）才停下，进入 §1 判据匹配。

## 1. 失败锚点（按优先级）

| 模式 | 含义 | 后续 |
|------|------|------|
| `::error::` | 平台级错误标注（含退出码） | 取其上一行上下文 |
| `ASSERT FAILED: Build <repo> \(expected=\d+, actual=\d+\)` | 构建断言失败（收尾信号） | 向上找第一个真错误 |
| `\[ERROR\]` / `\[OPS_CUSTOM\].*ERROR` | 组件级错误（如 ops_custom 安装器） | 直接根因段 |
| `error[:：]`（排除 warning 行） | 编译器错误 | 取错误文件:行号 |
| `undefined reference to` | 链接错误 | 符号反查 |
| `cannot find -l(\S+)` / `No such file` | 库/文件缺失 | 依赖问题 |
| `collect2: error: ld returned 1 exit status` | 链接器退出 | 向上找第一个 undefined |
| `gmake\[\d+\]: \*\*\* .* Error \d+` | make 失败（连锁） | 向上找源头 |
| `execute pkg error` | .run 安装自检失败 | 见 §4 |
| `BuildAccelerate 执行失败，退出码: \d+` | 构建命令最终退出 | 汇总信号 |

## 2. cmake 语义消息（构建系统根因，最易漏）

| 模式 | 含义 |
|------|------|
| `already compiled (\S+), skip` | **算子被先执行的宏注册，后续宏被去重跳过**——新旧宏共存冲突的铁证 |
| `\[(\S+)\] skipped, not in ascend_op_name list: (\S+)` | 正常按需编译（--ops=xx 筛选），非错误 |
| `don't need add tiling sources` | tiling 源被 DISABLE_IN_OPP 逻辑跳过 |
| `compile project with library` | BUILD_WITH_INSTALLED_DEPENDENCY_CANN_PKG=ON（安装库模式） |
| `compile project with src` | 源码模式 |
| `COMPUTE_UNIT: (\S+)` | 本次目标芯片 |
| `CMAKE_ARGS: (.*)` | **完整构建参数**（--ops 筛选、ASCEND_COMPUTE_UNIT 等） |

**目标缺失反查法**：日志中搜 `Built target <X>`；若包清单应有产物 X 的 Built target 不存在
→ 反查谁创建 target X（cmake/symbol.cmake 等）→ 其创建条件被哪个消息/分支跳过。

## 3. 耗时与缓存统计

### CloudCache JSON（日志尾部）

```json
[CloudCache] ... [
  {"type": "c", "total": "18652", "remote_hit": "2465",
   "remote_avg_cost": "4ms", "local_hit": {"direct": "16"},
   "miss": "16005", "skip": "166"}
]
```

判读：
- `miss / total > 50%` → 缓存大面积失效（全量/近全量重编）——慢 run 最常见根因
- `miss ≈ 0, remote_hit 高` → 构建本身慢，看时间线
- `total` 本身 = 编译调用规模（千级 = 大包）

### 时间线重建

- `Built target (\S+)` 行自带时间戳（`[YYYY-MM-DD HH:MM:SS]` 前缀）
- 重建序列后找**最大间隔** → 长尾目标（如某算子 apt kernel 编译 73min）
- `\[\s*(\d+)%\]` 进度行可交叉定位卡在哪个百分比
- `Building CXX object` 数量 = 实际编译 TU 数（少量 + 长耗时 = 单 TU 巨慢）

### 构建命令头（定位构建形态）

```
[LOG_DO] bash build.sh <args>          # 或 scripts/ci/compile_a5_pkg.sh 等包装
[compile_a5_pkg] executing build_cmd: bash build.sh --pkg --ops=roi_align --soc=ascend950 ...
```
- `--ops=<x>` → 只构建指定算子（PR 增量）
- `--PR_PKG pr_filelist.txt` → 按改动文件增量
- `GE_ST_RT2` / `task_name` → job 身份（experimental_950 / A5 等）

## 4. 包安装自检（.run 自检段）

```
./build_out/<pkg>.run --install-path=/tmp        ← CI 冒烟安装
[ops_custom] [INFO] validate shared libraries before installation
[ops_custom] [ERROR] Required shared library 'libcust_opmaster_rt2.0.so' was not found in package path.
[ops_custom] [ERROR] Shared library validation failed. To skip ... --force.
execute pkg error
```

判读流程：
1. 缺失库名 → 2. CPack 包清单（`./packages/vendors/<vendor>/...` 逐文件行）确认确实缺
   → 3. 仓库 cmake 找该库打包条件（如 `if (TARGET cust_opmaster)`）
   → 4. 反查 target 创建链（谁 npu_op_library 创建、什么条件 return）
   → 5. 结合 §2 的 cmake 消息（already compiled / don't need add tiling）定位跳过点

常见库的语义：
- `libcust_opsproto_rt2.0.so` —— proto 定义库
- `libcust_opmaster_rt2.0.so` —— tiling/ophost 宿主库（有 tiling 的算子包必需）
- `libcust_opapi.so` —— L7 opapi 库

## 5. zip 结构与其他步骤日志

| 文件 | 内容 | 何时看 |
|------|------|--------|
| `3_compile_acc.log` | 构建主日志（BuildAccelerate 包装） | 首选 |
| `1_Checkout.log` | 检出 | Checkout 步骤失败 |
| `2_download.log` | OBS 依赖下载 | download 步骤失败 |
| `5_api-check.log` | API 门禁 | api-check-failed 标签 |
| `6_verify_package.log` | 包校验 | verify 步骤失败 |

zip 内文件名可能因编码显示乱码（中文步骤名），按序号定位即可。

## 6. 解包与提取代码片段

```python
import zipfile, re
zf = zipfile.ZipFile('<job>.zip')
c = zf.read('3_compile_acc.log').decode(errors='replace')
lines = c.splitlines()

# 失败锚点
for i, l in enumerate(lines):
    if re.search(r'::error::|\[ERROR\]|ASSERT FAILED', l):
        print(i, l[:200])

# ccache 统计（尾部 JSON）
tail = c[c.rfind('[CloudCache]'):]
m = re.search(r'"total": "(\d+)".*?"remote_hit": "(\d+)".*?"miss": "(\d+)"', tail, re.S)

# Built target 时间线
timeline = [l for l in lines if 'Built target' in l]

# 包清单（判断库是否入包）
pkg_files = [l.split('] ', 1)[-1] for l in lines if './packages/' in l]
```
