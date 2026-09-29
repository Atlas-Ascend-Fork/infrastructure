# pre-commit配置指导书

[TOC]
--

## 1 概述

本指导书主要用于指导CANN社区在代码仓中部署pre-commit能力（主要包括代码格式化及OAT扫描能力），并指导社区贡献者如何在本地使用。


### 1.1 GitCode 镜像仓库说明

**重要**: 由于国内网络环境，访问 GitHub 可能受限，CANN 社区已将常用的 pre-commit hooks 仓库镜像到 GitCode。

**常用镜像仓库对照表**:

| GitHub 原仓库 / 来源 | GitCode 仓库 | 说明 |
|---------------------|-------------|------|
| `https://github.com/pre-commit/pre-commit-hooks` | `https://gitcode.com/pre-commit/pre-commit-hooks` | 基础检查 hooks |
| `https://github.com/pre-commit/mirrors-clang-format` | `https://gitcode.com/pre-commit-clang/mirrors-clang-format` | C++ 格式化 |
| `https://github.com/astral-sh/ruff-pre-commit` | `https://gitcode.com/gh_mirrors/ru/ruff-pre-commit` | Python lint/format |
| `https://github.com/codespell-project/codespell` | `https://gitcode.com/gh_mirrors/co/codespell` | 拼写检查 |
| `https://github.com/crate-ci/typos` | `https://gitcode.com/gh_mirrors/ty/typos` | typos 检查 |
| `https://github.com/pylint-dev/pylint` | `https://gitcode.com/gh_mirrors/pyl/pylint` | Python 代码检查 |
| `https://github.com/PyCQA/bandit` | `https://gitcode.com/gh_mirrors/ba/bandit` | Python 安全检查 |
| HiAgent compliance（OAT） | `https://gitcode.com/HiAgent/compliance` | **OAT 远程 pre-commit hook** |

**使用建议**: 在国内开发时，推荐使用 GitCode 镜像 / 托管仓库，避免网络访问问题。

## 2 代码仓中部署pre-commit能力指导

1、在代码仓根目录下创建".pre-commit-config.yaml"文件，如果已经存在，表示该代码仓中已经启用pre-commit能力，可参考后续步骤配置代码格式化及OAT检查能力；

2、在".pre-commit-config.yaml"文件中配置C++代码格式化能力：

- **在".pre-commit-config.yaml"文件添加如下配置：**

```
repos:
  - repo: https://gitcode.com/pre-commit-clang/mirrors-clang-format
    rev: v18.1.8
    hooks:
      - id: clang-format
        files: \.(c|h|cpp|hpp|cc|hh|cxx|hxx)$
```

**说明**：
- 对于空的".pre-commit-config.yaml"直接拷贝上述内容
- 如果已经有配置，请忽略首行的"repos:"
- **重要**: 使用 GitCode 镜像仓库替代 GitHub 仓库，避免国内网络访问问题

- **将".clang-format"配置文件拷贝至代码仓根目录下**
配套提供的".clang-format"为与CANN社区编程规范配套的格式化模板文件，如果代码仓有与规范不匹配的代码风格，可自主调整配置参数。

3、在".pre-commit-config.yaml"文件中配置OAT扫描能力（**推荐：远程 Python hook**）：

- **在".pre-commit-config.yaml"文件添加如下配置：**

```yaml
  - repo: https://gitcode.com/HiAgent/compliance
    rev: v1.0.6
    hooks:
      - id: oat-check
        pass_filenames: true
        stages: [pre-commit]
        verbose: true
```

- **无需**再将 `oat_check.sh` 拷贝到本仓 `scripts/` 目录。
- pre-commit 会自动克隆 `compliance` 仓库，在 hook 虚拟环境中安装 OAT，并执行 `oat-precommit`。
- 建议将项目 `OAT.xml` 放在仓库**根目录**或 `scripts/` 目录（工具会自动查找）。

**说明**：
- `rev` 请使用 compliance 仓发布的版本标签（如 `v1.0.6`）；升级 hook 后如本地缓存未更新，可执行 `pre-commit clean` 后再 `pre-commit install`。
- 完整示例可参考本目录配套的 [`.pre-commit-config.yaml`](./.pre-commit-config.yaml)。
- 旧版本地脚本方式（`repo: local` + `bash scripts/oat_check.sh`）已废弃，**新接入请统一使用上述远程 hook**。

4、至此将完成在代码仓中配置pre-commit机制下的代码格式化、OAT检查配置，如果还需要其他功能，可继续在".pre-commit-config.yaml"中配置。

## 3 社区贡献者使用pre-commit能力

### 3.1 pre-commit安装步骤

步骤 1: 安装 pre-commit 框架

```bash
# 使用 pip（推荐）
pip install pre-commit

# 验证安装
pre-commit --version
# 输出: pre-commit 3.x.x
```

**Windows 用户**: 确保已安装 Python 和 pip。

步骤 2: 进入项目目录

```bash
cd /path/to/your/project

# 例如
cd d:\complianceRepo\CANN
```

步骤 3: 安装 Git Hooks

```bash
# 在项目根目录运行
pre-commit install
```

步骤 4: 验证安装（可选）

```bash
# 测试 hook（不会真正提交）
git commit --allow-empty -m "test pre-commit"
```

后续在提交代码前会自动进行代码格式化处理及触发OAT检查。

### 3.2 OAT使用指导

**OAT（Open Source Audit Tool）Python 版** 通过 **compliance 远程 pre-commit hook**（`oat-check`）集成到 Git 提交流程中。被扫描仓库只需配置 `.pre-commit-config.yaml` 与项目 `OAT.xml`，**无需本仓维护 Bash 脚本**。

#### 3.2.1 检查内容

**文件类型检查** - 禁止提交二进制文件（.so, .dll, .exe 等）
**许可证头检查** - 验证源代码文件包含合规的许可证声明

#### 3.2.2 核心特点

- **增量检查** - 仅检查 pre-commit / CI 传入的变更文件（`pass_filenames: true`）
- **自动触发** - 每次 `git commit` 自动运行
- **详细报告** - 生成 `oat_reports/result.txt` 摘要报告；CI 多批次扫描会自动聚合成一份结果
- **零拷贝脚本** - 依赖由 pre-commit 从 `compliance` 仓安装到 hook 虚拟环境
- **跨平台** - Windows / Linux / macOS（Python 3.9+，由 pre-commit 管理 hook 环境）

#### 3.2.3 必需软件

| 软件 | 版本要求 | 用途 | 安装方式 |
|------|---------|------|----------|
| **Python** | 3.9+ | pre-commit / OAT hook 运行时 | 通常已安装；参见下方安装指导 |
| **Git** | 2.0+ | 版本控制 | 通常已安装 |
| **pre-commit** | 4.0+ | Hook 框架 | `pip install pre-commit` |
| **compliance oat-check** | `rev: v1.0.6`（示例） | OAT 远程 hook | 由 `.pre-commit-config.yaml` 引用，首次运行自动拉取安装 |

> 说明：无需在业务仓手动 `pip install oat-py`。远程 hook 会从 `https://gitcode.com/HiAgent/compliance` 安装所需依赖。

#### 3.2.4 远程 hook 工作方式（简述）

```
业务仓 .pre-commit-config.yaml
  → pre-commit 克隆 compliance（rev 标签）
  → pip install .（注册 oat-precommit）
  → 传入变更文件路径（pass_filenames: true）
  → oat.precommit 增量扫描 + 写入 oat_reports/result.txt
```

首次在本机启用时，pre-commit 会下载并安装 hook（通常几十秒，取决于网络）。之后复用本地缓存。

#### 3.2.5 手动运行检查

```bash
# 推荐：通过 pre-commit 触发 oat-check
pre-commit run oat-check

# 对暂存区 / 指定文件
pre-commit run oat-check --files path/to/file.cpp

# 全量（慎用，仓库很大时较慢）
pre-commit run oat-check --all-files
```

升级 `rev` 或远程标签刷新后，如未生效可清理缓存：

```bash
pre-commit clean
pre-commit install
pre-commit run oat-check
```

#### 3.2.6 合规性问题（阻止提交）

**重要**: 以下问题会**阻止提交**，必须修复。

**1) 发现无效文件类型**

**场景**: 尝试提交二进制文件（.so, .dll, .exe 等）。

**输出**:
```
====================================================================
  OAT: Compliance issues found. Commit blocked.
====================================================================

[OAT] Cumulative scan: 1 file(s) checked, 1 issue(s).

[OAT] Report:
---
===================================
OAT Scan Result Summary
===================================
Scan Time: 2026-03-25 14:30:15
Project: CANN
Files Checked: 1

-----------------------------------
Invalid File Type Total Count: 1
...

-----------------------------------
License Header Invalid Total Count: 0
===================================
---
Fix the issues and recommit, or skip with:
  git commit --no-verify
```

**行为**: **阻止提交，必须修复**

**查看详情**:
```bash
cat oat_reports/result.txt
```

**解决方案**:
```bash
# 方法 1: 移除二进制文件
git reset HEAD lib/libtest.so

# 方法 2: 将二进制文件添加到 .gitignore
echo "*.so" >> .gitignore
echo "*.dll" >> .gitignore
echo "*.exe" >> .gitignore

# 重新提交
git add .gitignore
git commit -m "update: add binary files to gitignore"
```

**2) 许可证头无效**

**场景**: 源代码文件缺少或许可证头格式不正确。

**行为**: **阻止提交，必须修复**

**查看详情**:
```bash
cat oat_reports/result.txt
```

**解决方案**:

在文件顶部添加许可证头，例如 CANN-2.0：

```cpp
/**
 * This program is free software, you can redistribute it and/or modify it under the terms and conditions of
 * CANN Open Software License Agreement Version 2.0 (the "License").
 * Please refer to the License for details. You may not use this file except in compliance with the License.
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE.
 * See LICENSE in the root of the software repository for the full text of the License.
 */

```

**重新提交**:
```bash
git add src/main.cpp src/utils.cpp
git commit -m "fix: add license headers"
```

更多告警解读与 `OAT.xml` 配置方法，参见 [OAT使用指南](../OAT/OAT使用指南.md)。

---

#### 3.2.7 报告查看

**报告文件位置**

| 报告类型 | 文件路径 | 内容 |
|---------|---------|------|
| **摘要报告** | `oat_reports/result.txt` | 关键问题汇总（多批次 CI 为聚合结果） |

> 建议将 `oat_reports/` 加入仓库 `.gitignore`，避免扫描产物被误提交。

**查看命令**

```bash
# 查看报告
cat oat_reports/result.txt

# 使用编辑器查看
code oat_reports/result.txt
vim oat_reports/result.txt
```

**摘要报告内容**

```
===================================
OAT Scan Result Summary
===================================
Scan Time: 2026-03-25 14:30:15
Project: CANN
Files Checked: 3

-----------------------------------
Invalid File Type Total Count: 0

-----------------------------------
License Header Invalid Total Count: 0

===================================
```

#### 3.2.8 环境与安装问题

**1) Python 未安装或版本过低**

**场景**: 系统未安装 Python，或版本低于 3.9，导致 pre-commit / hook 环境无法创建。

**行为**: hook 安装或执行失败，需先安装 Python 3.9+（参见下方《Python 安装指导》）。

安装完成后验证：

```bash
pre-commit run oat-check
```

---

**2) 无法拉取 compliance 远程仓库**

**场景**: 网络或权限导致无法访问 `https://gitcode.com/HiAgent/compliance`。

**解决方案**:
- 确认可访问 GitCode，并具备对 compliance 仓的只读权限；
- 检查 `.pre-commit-config.yaml` 中 `repo` / `rev` 是否正确；
- 清理后重试：`pre-commit clean && pre-commit install`

---

**3) OAT 扫描执行异常**

**场景**: hook 运行时报错，或 `oat_reports/result.txt` 未生成。

**解决方案**:
```bash
# 步骤 1: 单独跑 oat-check，查看完整输出
pre-commit run oat-check --verbose

# 步骤 2: 确认 rev 对应版本可用
# 打开 https://gitcode.com/HiAgent/compliance 核对标签

# 步骤 3: 清理缓存后重装
pre-commit clean
pre-commit install
pre-commit run oat-check
```

调试远程 hook 详细日志时可设置：

```bash
export OAT_PRECOMMIT_VERBOSE=1
pre-commit run oat-check
```

---

##### Python 安装指导

OAT / pre-commit 需要 **Python 3.9+**，以下提供各平台安装方式。

**Linux**

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install python3 python3-pip

# CentOS / RHEL
sudo yum install python3 python3-pip

# 验证
python3 --version
```

**macOS**

```bash
# 推荐使用 Homebrew
brew install python@3.11

# 验证
python3 --version
```

**Windows**

**方式一：官网安装包（推荐）**

1. 访问 [https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/)
2. 下载最新 Python 3.x（3.9 及以上均可）的 **Windows installer (64-bit)**
3. 双击安装，**务必勾选"Add Python to PATH"**
4. 安装完成后重启终端，验证：
   ```powershell
   python --version
   pip --version
   ```

**方式二：使用 Scoop 包管理器**

```powershell
# 安装 Scoop（首次使用）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# 安装 Python
scoop install python

# 验证
python --version
```

**方式三：使用 Winget（Windows 11 / Windows 10 内置）**

```powershell
winget install Python.Python.3.11
```

> **国内网络备用下载**：
> 华为镜像：[https://mirrors.huaweicloud.com/python/](https://mirrors.huaweicloud.com/python/)
