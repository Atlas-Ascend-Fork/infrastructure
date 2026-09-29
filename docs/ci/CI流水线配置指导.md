# CANN 仓库 CI 流水线配置指导

本指导文档面向需要在 CANN 系列仓库上配置 GitCode CI 流水线的开发者，说明流水线的基本概念、整体流程，以及官方 Action 和 CANN 自定义 Action 的使用方法。

> **平台概念**：GitCode Action 的触发事件、上下文、表达式、Runner 标签等平台级概念，参见 [GitCode 官方文档 · 流水线](https://docs.gitcode.com/docs/help/home/org_project/pipeline/)。本文仅聚焦 CANN CI 场景的配置要点，完整平台概念映射见 [附录 · 参考文档](#参考文档)。

---

## 目录

- [1. 基本概念](#1-基本概念)
  - [1.1 流水线触发](#11-流水线触发)
  - [1.2 Stage / Job / Step](#12-stage--job--step)
  - [1.3 关键环境变量](#13-关键环境变量)
  - [1.4 OBS 制品中转机制](#14-obs-制品中转机制)
- [2. 流水线整体流程](#2-流水线整体流程)
- [3. 配置步骤](#3-配置步骤)
  - [3.1 前置准备](#31-前置准备)
  - [3.2 镜像配置](#32-镜像配置)
  - [3.3 主入口 Workflow](#33-主入口-workflow)
  - [3.4 编译 Workflow](#34-编译-workflow)
  - [3.5 代码检查 Workflow](#35-代码检查-workflow)
  - [3.6 静态检查 Workflow](#36-静态检查-workflow)
  - [3.7 单元测试 Workflow](#37-单元测试-workflow)
  - [3.8 覆盖率报告 Workflow（可选）](#38-覆盖率报告-workflow可选)
  - [3.9 覆盖率分类规则文件](#39-覆盖率分类规则文件)
- [4. 官方 Action 使用](#4-官方-action-使用)
- [5. CANN 自定义 Action 使用](#5-cann-自定义-action-使用)
- [6. 附录](#6-附录)

---

## 1. 基本概念

### 1.1 流水线触发

流水线通过 **PR 评论触发**。在 Pull Request 下评论 `/compile` 即可启动编译流水线：

```yaml
on:
  pr_comment:
    types: [ created ]
    keyword: '^(?:\/)?compile$'
  pull_request_comment:
    types: [created]
    branches: [ '*' ]
    comments: [ '^(?:\/)?compile$' ]
```

> 两个事件作用不同，需同时配置：
> - `pr_comment`：用于标识预合并（pre-merge），CI 系统据此将本次运行标记为预合并流水线。
> - `pull_request_comment`：标准 PR 评论触发事件，`comments` 字段为正则过滤，决定何时启动流水线。
>
> 详见 [GitCode 官方文档 · 配置触发条件](https://docs.gitcode.com/docs/help/home/org_project/pipeline/writing-pipelines/configure-triggers)。

### 1.2 Stage / Job / Step

流水线由多个 **Stage** 串行组成，每个 Stage 内可包含多个 **Job** 并行执行，每个 Job 内包含多个 **Step** 顺序执行。

```
stages:
  stage1:              # Stage 1
    jobs:
      JOB_image:       # Job A（并行）
        steps:
          - name: ...  # Step 1
          - name: ...  # Step 2
      JOB_pr:          # Job B（与 A 并行）
        steps:
          - name: ...
```

- **Stage 间串行**：`stage2` 依赖 `stage1` 全部完成（`fail-fast` 控制是否在失败时终止后续）。
- **Job 间并行**：同一 Stage 内的 Job 并行执行，可通过 `jobs.<job_id>.outputs` 引用其他 Job 的输出。
- **Job 间调用**：可通过 `uses: .gitcode/workflows/xxx_action.yml` 调用子 workflow，实现复用。

> **常见字段说明**：
> - `if: "${{ default() }}"`：Job 默认执行条件，等价于不写 `if`。仅当需要条件跳过时才替换为自定义表达式（如 `if: env.TARGET_BRANCH == 'master'`）。
> - `pre: [{ type: auto }]`：Stage 前置钩子，`type: auto` 为自动调度，无需修改。
> - `fail-fast`：`true` 表示任一 Job 失败立即终止同 Stage 其他 Job；`false` 允许其他 Job 继续执行。

### 1.3 关键环境变量

流水线中的变量分为两类：一类需要**在 workflow 的 `env` 中显式声明**（从 `atomgit` 上下文提取 PR 信息）；另一类由 CI 系统自动注入（如 `COMMIT_ID`），无需声明即可在脚本中引用。

| 变量 | 来源 | 说明 |
| --- | --- | --- |
| `MERGE_ID` | `env` 声明：`${{ atomgit.event.pull_request.number }}` | PR 编号 |
| `TARGET_BRANCH` | `env` 声明：`${{ atomgit.base_ref }}` | PR 目标分支 |
| `SOURCE_BRANCH` | `env` 声明：`${{ atomgit.head_ref }}` | PR 源分支 |
| `COMMIT_ID` | CI 系统注入 | 合并 commit hash |
| `org_name` | workflow `env` 定义 | 组织名称，如 `cann` |
| `repo_name` | workflow `env` 定义 | 仓库名称 |
| `obs_path` | workflow `env` 定义 | OBS 制品路径前缀，如 `test/<repo_name>/package/${{ env.MERGE_ID }}` |
| `secrets.GIT_TOKEN` | 仓库 Secret | 私有仓库访问 token |
| `secrets.AK` / `secrets.SK` | 仓库 Secret | OBS 访问密钥 |
| `vars.CI_PATH` | 仓库 Variable | CI 仓库地址，如 `https://gitcode.com/cann/.gitcode.git` |

> **注意**：`MERGE_ID`、`TARGET_BRANCH`、`SOURCE_BRANCH` 必须在 `env` 中显式声明后，才能在 `${{ env.xxx }}` 表达式和子 workflow 中引用。若仅靠 CI 系统注入，在子 workflow（`workflow_call`）中可能无法获取。声明方式见 [§3.3 主入口 Workflow](#33-主入口-workflow)。

### 1.4 OBS 制品中转机制

由于每个 Job 运行在独立的容器中，**工作区不共享**。Job 间通过 OBS（对象存储）传递产物：

```
Job A 产出文件 → obs-upload 上传到 OBS
                          ↓
Job B 启动 → obs-download 从 OBS 拉取文件 → 消费
```

- **上传**：`artifact-path` 指定本地文件，`object-prefix` 指定 OBS 路径前缀。
- **下载**：`key` 指定 OBS 上的文件，`path` 指定本地下载目录。

典型中转产物：`pr_filelist.txt`、编译包 `*.run`、覆盖率包 `ut_cov_*.tar.gz` 等。

---

## 2. 流水线整体流程

```
PR 评论 /compile
       │
       ▼
┌─────────────────────────────────────────────┐
│  Stage 1: 准备                              │
│  ┌──────────────┐   ┌────────────────────┐ │
│  │ JOB_image    │   │ JOB_pr             │ │
│  │ revise-img   │   │ checkout → get-pr  │ │
│  │ (解析各阶段  │   │ → obs-upload       │ │
│  │  镜像)       │   │ (上传变更文件清单) │ │
│  └──────┬───────┘   └────────────────────┘ │
│         │ outputs.*.image                  │
└─────────┼───────────────────────────────────┘
          ▼
┌─────────────────────────────────────────────┐
│  Stage 2: 编译 + 检查                       │
│  ┌──────────────┐ ┌──────────────┐         │
│  │ x86_compile  │ │ arm_compile  │ 并行    │
│  │ build →      │ │ build →      │         │
│  │ verify-pkg → │ │ verify-pkg → │         │
│  │ upload       │ │ upload       │         │
│  └──────────────┘ └──────────────┘         │
│  ┌──────────────┐ ┌──────────────┐         │
│  │ codecheck    │ │ staticcheck  │ 并行    │
│  │ precommit    │ │ markdown /   │         │
│  │ check-pr     │ │ codespell /  │         │
│  │ sca /        │ │ link / ...   │         │
│  └──────────────┘ └──────────────┘         │
└─────────────────────────────────────────────┘
          ▼
┌─────────────────────────────────────────────┐
│  Stage 3: 单元测试                          │
│  ┌──────────────┐ ┌──────────────┐         │
│  │ ut_type_A    │ │ ut_type_B    │ 并行    │
│  │ build-acc →  │ │ build-acc →  │         │
│  │ ut-cov-report│ │ ut-cov-report│         │
│  │ (cov) →      │ │ (cov) →      │         │
│  │ upload       │ │ upload       │         │
│  └──────────────┘ └──────────────┘         │
└─────────────────────────────────────────────┘
          ▼ (可选)
┌─────────────────────────────────────────────┐
│  Stage 4: 覆盖率报告                        │
│  ┌──────────────────────────────────┐      │
│  │ ut-cov-report (report)           │      │
│  │ download 各模块覆盖率 →          │      │
│  │ lcov 合并 → 增量覆盖率报告 →     │      │
│  │ upload                           │      │
│  └──────────────────────────────────┘      │
└─────────────────────────────────────────────┘
```

---

## 3. 配置步骤

### 3.1 前置准备

在目标仓库中创建以下目录结构：

```
<repo>/
├── .gitcode/
│   ├── workflows/
│   │   ├── <repo>_action.yml        # 主入口 workflow
│   │   ├── codecheck_action.yml     # 代码检查子 workflow
│   │   ├── x86_compile_action.yml   # x86 编译子 workflow
│   │   ├── arm_compile_action.yml   # arm 编译子 workflow
│   │   ├── staticcheck_action.yml   # 静态检查子 workflow
│   │   └── llt_action.yml           # 单元测试子 workflow
│   └── scripts/                     # 编译/测试执行脚本
│       ├── x86_compile.sh           # x86 编译脚本
│       ├── arm_compile.sh           # arm 编译脚本
│       └── ut.sh                    # 单元测试脚本
```
同时在 CI 仓库（`cann/.gitcode`）中配置镜像：

```
.gitcode/
└── image-conf/
    └── <target_branch>/
        └── images.yaml              # 镜像配置
```

### 3.2 镜像配置

在 `cann/.gitcode/image-conf/<target_branch>/images.yaml` 中为目标仓库添加 `stages` 配置。每个 stage 声明其使用的镜像引用（格式 `os_ver:arch:tag`），脚本据此在 `global.os_mirror` / `gray_global.os_mirror` / 仓库级 `os_mirror` 中查找实际镜像。

```yaml
repos:
  <repo_name>:
    os_mirror:                    # 仓库级覆盖（可选）
      ubuntu24.04:
        x86:
          api_check: ubuntu24.04.3_x86:lv6_v1.1076
    stages:
      Compile_Ascend_X86:
        ubuntu24.04:x86:lv6
      Compile_Ascend_X86_ubuntu24:
        ubuntu24.04:x86:lv6
      Compile_Ascend_ARM:
        ubuntu24.04:arm:lv6
      Compile_Ascend_ARM_ubuntu24:
        ubuntu24.04:arm:lv6
      UT_Test:
        ubuntu24.04:x86:lv6
```

> 完整字段说明参见 [revise-img README](https://gitcode.com/cann/.gitcode/blob/master/actions/revise-img/README.md)。

### 3.3 主入口 Workflow

创建 `<repo>_action.yml`，定义流水线的触发条件、全局变量、以及各 Stage 的 Job 编排。

```yaml
name: <repo>_action

on:
  pr_comment:
    types: [ created ]
    keyword: '^(?:\/)?compile$'
  pull_request_comment:
    types: [created]
    branches: [ '*' ]
    comments: [ '^(?:\/)?compile$' ]

env:
  org_name: "cann"
  repo_name: "<repo_name>"
  MERGE_ID: ${{ atomgit.event.pull_request.number }}
  TARGET_BRANCH: ${{ atomgit.base_ref }}
  SOURCE_BRANCH: ${{ atomgit.head_ref }}
  obs_path: "test/<repo_name>/package/${{ env.MERGE_ID }}"

stages:
  stage1:
    name: image
    jobs:
      JOB_image:
        name: image
        steps:
          - name: revise_image
            identifier: revise_image
            uses: cann/.gitcode/actions/revise-img@master
            with:
              repo_name: ${{ env.repo_name }}
              target_branch: ${{ env.TARGET_BRANCH }}
              repo_url: ${{ vars.CI_PATH }}
          - name: show_output
            run: |
              echo "image: ${{ steps.revise_image.outputs.Compile_Ascend_X86 }}"
        if: "${{ default() }}"
        runs-on: ["codearts-hosted", "ubuntu-latest", "x64", "large"]

      JOB_pr:
        name: get_pr_files
        steps:
          - name: Checkout
            identifier: process_checkout
            uses: checkout
            with:
              ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
              token: ${{ secrets.GIT_TOKEN }}
          - name: get_pr
            identifier: get_pr
            uses: cann/.gitcode/actions/get-pr@master
            with:
              workspace: ${{ steps.process_checkout.outputs.path }}
              target_branch: ${{ env.TARGET_BRANCH }}
              git_token: ${{ secrets.GIT_TOKEN }}
          - name: upload
            uses: obs-upload
            with:
              endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
              bucket: "ascend-ci"
              access-key: ${{ secrets.AK }}
              secret-key: ${{ secrets.SK }}
              artifact-path: |
                ${{ steps.process_checkout.outputs.path }}/pr_filelist.txt
                ${{ steps.process_checkout.outputs.path }}/pr_filelist_mod.txt
                ${{ steps.process_checkout.outputs.path }}/pr_filelist_precommit.txt
                ${{ steps.process_checkout.outputs.path }}/update_file_detail.txt
              object-prefix: ${{ env.obs_path }}/
        runs-on: [default]

      JOB_shell:
        name: get_shell_files
        steps:
          - name: Checkout
            identifier: process_checkout
            uses: checkout
            with:
              ref: master
              token: ${{ secrets.GIT_TOKEN }}
          - name: upload
            uses: obs-upload
            with:
              endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
              bucket: "ascend-ci"
              access-key: ${{ secrets.AK }}
              secret-key: ${{ secrets.SK }}
              artifact-path: |
                ${{ steps.process_checkout.outputs.path }}/.gitcode/scripts/*
              object-prefix: ${{ env.obs_path }}/
        if: "${{ default() }}"
        runs-on: [default]
    pre:
    - type: auto
    fail-fast: true

  stage2:
    name: compile
    jobs:
      JOB_codecheck_action:
        name: codecheck_action
        uses: .gitcode/workflows/codecheck_action.yml
        with:
          precommit_image_version: ${{ jobs.JOB_image.outputs.precommit }}
          codecheck_image_version: ${{ jobs.JOB_image.outputs.codecheck }}
      JOB_x86_compile:
        name: x86_compile
        uses: .gitcode/workflows/x86_compile_action.yml
        with:
          task_name: 'x86_compile'
          image_version: ${{ jobs.JOB_image.outputs.Compile_Ascend_X86 }}
      JOB_staticcheck_markdown:
        name: staticcheck_markdown
        uses: .gitcode/workflows/staticcheck_action.yml
        with:
          check_type: 'markdown'
          image_version: ${{ jobs.JOB_image.outputs.staticcheck }}
    pre:
    - type: auto
    fail-fast: false

  stage3:
    name: ut
    jobs:
      JOB_UT_Test:
        name: UT_Test
        uses: .gitcode/workflows/llt_action.yml
        with:
          ut_type: '<ut_type>'
          image_version: ${{ jobs.JOB_image.outputs.UT_Test }}
    pre:
    - type: auto
    fail-fast: false
```

> **要点**：
> - `env` 中必须显式声明 `MERGE_ID`、`TARGET_BRANCH`、`SOURCE_BRANCH`，从 `atomgit` 上下文提取 PR 信息，供所有下游 Job/子 workflow 引用。
> - `JOB_image` 的输出通过 `${{ jobs.JOB_image.outputs.<stage_name> }}` 传递给下游 Job。
> - `obs_path` 以 `MERGE_ID` 为子目录，确保不同 PR 的产物隔离。
> - `JOB_shell` 从 **master 分支**检出代码并上传 `.gitcode/scripts/*` 到 OBS，供编译/UT 子 workflow 下载执行。使用 master 分支而非 PR 合并 commit，保证脚本始终以仓库主干版本为准。

### 3.4 编译 Workflow

#### x86_compile_action.yml

```yaml
name: x86_compile_action

on:
  workflow_call:
    inputs:
      task_name:
        required: true
        type: string
      image_version:
        required: true
        type: string

jobs:
  JOB_compile:
    name: compile
    steps:
      - name: Checkout
        identifier: process_checkout
        uses: checkout
        with:
          ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
          token: ${{ secrets.GIT_TOKEN }}
      - name: download
        uses: obs-download
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          key: |
            ${{ env.obs_path }}/pr_filelist.txt
            ${{ env.obs_path }}/pr_filelist_mod.txt
            ${{ env.obs_path }}/update_file_detail.txt
            ${{ env.obs_path }}/x86_compile.sh
          path: ${{ steps.process_checkout.outputs.path }}
      - name: x86_compile_acc
        identifier: compile
        uses: build-accelerate
        with:
          command: |
            export WORKSPACE=${{ steps.process_checkout.outputs.path }}
            cd ${{ steps.process_checkout.outputs.path }}
            export task_name=${{ inputs.task_name }}
            BuildAccelerate bash x86_compile.sh
          AC_SERVER_IP: ${{ vars.AC_SERVER_IP }}
      - name: verify_package
        uses: cann/.gitcode/actions/verify-package@master
        with:
          workspace: ${{ steps.process_checkout.outputs.path }}
          package_type: run  # 产物包扩展名，默认 run；Python whl 包传 whl
      - name: upload
        uses: obs-upload
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          artifact-path: "${{ steps.process_checkout.outputs.path }}/build_out/*"
          object-prefix: ${{ env.obs_path }}/
    if: "${{ default() }}"
    runs-on: [dedicate-hosted, x64, large]
    container:
      image: swr.cn-north-4.myhuaweicloud.com/ci_cann/${{ inputs.image_version }}
```

#### 编译脚本

编译逻辑抽取到 `.gitcode/scripts/x86_compile.sh` 中，通过 `build-accelerate` 的 `command` 下载并调用该脚本。`task_name` 作为环境变量传入脚本，脚本内部据此区分编译场景。**实际编译命令前必须加 `BuildAccelerate` 关键字**以启用编译加速：

```bash
#!/bin/bash
cd "${WORKSPACE}"

# gcc 版本：ubuntu24 用 gcc-14，否则用 devtoolset-7
echo $(grep -E "^VERSION_ID=" /etc/os-release | cut -d'"' -f2)
if [[ "${task_name}" == *ubuntu24* ]]; then
    sudo update-alternatives --set gcc /usr/bin/gcc-14
    package_name="<repo>_linux-x86_64_ubuntu24.run"
else
    if [[ -f "/opt/rh/devtoolset-7/enable" ]]; then
        echo "source devtoolset"
        source /opt/rh/devtoolset-7/enable
    fi
    package_name="<repo>_linux-x86_64.run"
fi
echo "package_name=${package_name}" >> "$ATOMGIT_OUTPUT"
gcc --version

# CANN 环境
source /home/jenkins/Ascend/cann/bin/setenv.bash

set +e
bash build.sh --cann_3rd_lib_path="/home/jenkins/opensource" -f "pr_filelist.txt"
ret=$?

# 200 表示跳过编译，属于正常情况
if [ "$ret" -eq 200 ]; then
    echo "not need compile"
    mkdir build_out
    touch build_out/${package_name}
    exit 0
fi
if [ "$ret" -eq 0 ]; then
    compile_package_name=$(ls "${WORKSPACE}/build_out"/*.run 2>/dev/null | head -n1)
    if [ -z "${compile_package_name}" ]; then
        echo "compile package (*.run) not found" >&2
        exit 1
    fi
    if ! mv -- "${compile_package_name}" "${WORKSPACE}/build_out/${package_name}"; then
        echo "failed to rename compile package" >&2
        exit 1
    fi
fi
echo "ret=$ret" >> "$ATOMGIT_OUTPUT"
exit "$ret"
```

> **脚本要点**：
> - 通过 `$WORKSPACE`、`$task_name` 等环境变量接收 workflow 传入的参数（在 `command` 中 `export`）。
> - 产物包名通过 `echo "package_name=xxx" >> "$ATOMGIT_OUTPUT"` 输出，供 upload 步骤引用 `${{ steps.compile.outputs.package_name }}`。
> - 返回码 `200` 表示按文件清单无需编译，脚本创建占位包后正常退出。
> - arm 编译 workflow (`arm_compile_action.yml`) 结构与 x86 相同，下载 `arm_compile.sh` 并执行，仅 `runs-on` 改为 `[dedicate-hosted, arm64, xlarge]`。

### 3.5 代码检查 Workflow

`codecheck_action.yml` 通常包含以下 Job：

| Job | 说明 | 使用的 Action |
| --- | --- | --- |
| `JOB_precommit` | pre-commit 格式检查 | `precommit` |
| `JOB_check_pr` | 二进制文件 + Markdown 链接检查 | `check-pr` |
| `JOB_sca` | 安全合规扫描 | CI 脚本（`codescan_gitcode.py`） |
| `JOB_antiposion` | 防病毒扫描 | CI 脚本（`anti_virus_gitcode.py`） |
| `JOB_codecheck` | 代码检查 | CI 脚本（`codecheck_gitcode.py`） |

```yaml
name: codecheck_action

on:
  workflow_call:
    inputs:
      precommit_image_version:
        required: true
        type: string
      codecheck_image_version:
        required: true
        type: string

jobs:
  JOB_precommit:
    name: precommit
    steps:
      - name: Checkout
        identifier: process_checkout
        uses: checkout
        with:
          ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
          token: ${{ secrets.GIT_TOKEN }}
      - name: download
        uses: obs-download
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          key: "${{ env.obs_path }}/pr_filelist_precommit.txt"
          path: ${{ steps.process_checkout.outputs.path }}
      - name: precommit
        identifier: precommit
        uses: cann/.gitcode/actions/precommit@master
        with:
          merge_id: ${{ env.MERGE_ID }}
          repo_name: ${{ env.repo_name }}
          workspace: ${{ steps.process_checkout.outputs.path }}
      - name: upload
        uses: obs-upload
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          artifact-path: "${{ steps.process_checkout.outputs.path }}/pre-commit*.txt"
          object-prefix: ${{ env.obs_path }}/
    if: "${{ default() }}"
    runs-on: [dedicate-hosted, x64, large]
    container:
      image: swr.cn-north-4.myhuaweicloud.com/ci_cann/${{ inputs.precommit_image_version }}

  JOB_check_pr:
    name: check_pr
    steps:
      - name: Checkout
        identifier: process_checkout
        uses: checkout
        with:
          ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
          token: ${{ secrets.GIT_TOKEN }}
      - name: download
        uses: obs-download
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          key: |
            ${{ env.obs_path }}/pr_filelist.txt
            ${{ env.obs_path }}/pr_filelist_mod.txt
          path: ${{ steps.process_checkout.outputs.path }}
      - name: check-pr
        identifier: check-pr
        uses: cann/.gitcode/actions/check-pr@master
        with:
          repo_name: ${{ env.repo_name }}
          workspace: ${{ steps.process_checkout.outputs.path }}
    runs-on: [dedicate-hosted, x64, large]
    container:
      image: swr.cn-north-4.myhuaweicloud.com/ci_cann/${{ inputs.codecheck_image_version }}
```

> `JOB_sca`、`JOB_antiposion`、`JOB_codecheck` 需要额外 checkout CI 仓库（`${{ vars.CI_PATH }}`）以获取扫描脚本，可参考 `ops-nn` / `runtime` 中的实现。

### 3.6 静态检查 Workflow

```yaml
name: staticcheck_action

on:
  workflow_call:
    inputs:
      check_type:
        required: true
        type: string
      image_version:
        required: true
        type: string

jobs:
  JOB_staticcheck:
    name: staticcheck
    steps:
      - name: Checkout
        identifier: process_checkout
        uses: checkout
        with:
          ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
          token: ${{ secrets.GIT_TOKEN }}
      - name: download
        uses: obs-download
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          key: |
            ${{ env.obs_path }}/pr_filelist.txt
            ${{ env.obs_path }}/pr_filelist_mod.txt
            ${{ env.obs_path }}/update_file_detail.txt
          path: ${{ steps.process_checkout.outputs.path }}
      - name: staticcheck
        identifier: staticcheck
        uses: cann/.gitcode/actions/staticcheck@master
        with:
          check_type: ${{ inputs.check_type }}
          target_branch: ${{ env.TARGET_BRANCH }}
          repo_name: ${{ env.repo_name }}
          merge_id: ${{ env.MERGE_ID }}
          commit_id: ${{ env.COMMIT_ID }}
          workspace: ${{ steps.process_checkout.outputs.path }}
      - name: upload
        uses: obs-upload
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          artifact-path: |
            ${{ steps.process_checkout.outputs.path }}/*.csv
            ${{ steps.process_checkout.outputs.path }}/StaticCheck_*.json
          object-prefix: ${{ env.obs_path }}/
    if: "${{ default() }}"
    runs-on: [dedicate-hosted, x64, large]
    container:
      image: swr.cn-north-4.myhuaweicloud.com/static_check/${{ inputs.image_version }}
```

可用的 `check_type` 值：`markdown`、`codespell_check`、`tag_closed_check`、`resource_existence_check`、`link_validity_check`。每种类型在主入口 workflow 中作为一个独立 Job 调用。

### 3.7 单元测试 Workflow

```yaml
name: llt_action

on:
  workflow_call:
    inputs:
      ut_type:
        required: true
        type: string
      ut_package:
        type: string
        default: 'ut_cov_*.tar.gz'
      image_version:
        required: true
        type: string

jobs:
  JOB_ut:
    name: ut
    steps:
      - name: Checkout
        identifier: process_checkout
        uses: checkout
        with:
          ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
          token: ${{ secrets.GIT_TOKEN }}
      - name: download
        uses: obs-download
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          key: |
            ${{ env.obs_path }}/pr_filelist.txt
            ${{ env.obs_path }}/pr_filelist_mod.txt
            ${{ env.obs_path }}/ut.sh
          path: ${{ steps.process_checkout.outputs.path }}
      - name: ut_acc
        identifier: ut
        run: |
          export WORKSPACE=${{ steps.process_checkout.outputs.path }}
          cd ${{ steps.process_checkout.outputs.path }}
          export ut_type=${{ inputs.ut_type }}
          bash ut.sh
      - name: ut_cov
        identifier: ut_cov
        uses: cann/.gitcode/actions/ut-cov-report@master
        with:
          ut_process: ${{ steps.ut.outputs.ut_process }}
          workspace: ${{ steps.process_checkout.outputs.path }}
          ut_type: ${{ inputs.ut_type }}
          target_branch: ${{ env.TARGET_BRANCH }}
          git_token: ${{ secrets.GIT_TOKEN }}
      - name: upload
        uses: obs-upload
        with:
          endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
          bucket: "ascend-ci"
          access-key: ${{ secrets.AK }}
          secret-key: ${{ secrets.SK }}
          artifact-path: |
            ${{ steps.process_checkout.outputs.path }}/${{ inputs.ut_package }}
          object-prefix: ${{ env.obs_path }}/
    if: "${{ default() }}"
    runs-on: [dedicate-hosted, x64, xlarge]
    container:
      image: swr.cn-north-4.myhuaweicloud.com/ci_cann/${{ inputs.image_version }}
```

#### UT 脚本

UT 逻辑抽取到 `.gitcode/scripts/ut.sh` 中，通过 `ut_type` 环境变量分发到不同的测试目标。脚本通过 `$ATOMGIT_OUTPUT` 输出 `ut_process` 变量，供下游 `ut-cov-report` action 消费：

```bash
#!/bin/bash
set +e

# gcc 切换 + CANN 环境
echo $(grep -E "^VERSION_ID=" /etc/os-release | cut -d'"' -f2)
sudo update-alternatives --set gcc /usr/bin/gcc-14
gcc --version
source /home/jenkins/Ascend/cann/bin/setenv.bash

# 按 ut_type 分发执行
case "${ut_type}" in
    acl)
        bash tests/build_ut.sh --ut=acl --target=ascendcl_utest -c -f "pr_filelist.txt" --cann_3rd_lib_path="/home/jenkins/opensource"
        ret=$?
        ;;
    rts_v201)
        bash tests/build_ut.sh --ut=runtime --target=runtime_ut_v201 -c -f "pr_filelist.txt" --cann_3rd_lib_path="/home/jenkins/opensource"
        ret=$?
        coverage_save="true"
        ;;
    *)
        echo "unknown ut_type: ${ut_type}"
        exit 1
        ;;
esac

if [ "$ret" -ne 200 ] && [ "$ret" -ne 0 ]; then
    echo "run ut fail"
    exit 1
fi
if [ "$ret" -eq 0 ]; then
    if [ "$coverage_save" = "true" ]; then
        echo "ut_process=coverage" >> $ATOMGIT_OUTPUT
    else
        echo "ut_process=ut_cov" >> $ATOMGIT_OUTPUT
    fi
fi
exit 0
```

> **UT 执行约定**：UT 逻辑抽取到 `ut.sh` 脚本中，通过 `ut_type` 环境变量分发到不同的测试目标。产出覆盖率的 UT 类型需通过 `$ATOMGIT_OUTPUT` 文件输出 `ut_process` 变量，供下游 `ut-cov-report` action 消费：
> ```bash
> echo "ut_process=coverage" >> $ATOMGIT_OUTPUT
> ```
> 不产覆盖率的类型（如 clang/asan 模式）无需输出。
>
> **`ut_package` 参数**：控制 upload 步骤上传哪些产物文件。
> - 产出 `coverage.info` 的 UT 类型传 `'coverage_*.info'`（供 stage4 合并报告）
> - 其他 UT 类型保持默认 `'ut_cov_*.tar.gz'`

### 3.8 覆盖率报告 Workflow（可选）

当存在多个 UT 模块时，可增加 `ut_report` Stage，合并各模块覆盖率并生成增量报告：

```yaml
stage4:
  name: ut_report
  jobs:
    JOB_ut_report:
      name: ut_report
      steps:
        - name: Checkout
          identifier: process_checkout
          uses: checkout
          with:
            ref: ${{ atomgit.event.pull_request.merge_commit_sha }}
            token: ${{ secrets.GIT_TOKEN }}
        - name: download
          uses: obs-download
          with:
            endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
            bucket: "ascend-ci"
            key: |
              ${{ env.obs_path }}/pr_filelist.txt
              ${{ env.obs_path }}/pr_filelist_mod.txt
            path: ${{ steps.process_checkout.outputs.path }}
        - name: ut_report
          identifier: ut-report
          uses: cann/.gitcode/actions/ut-cov-report@master
          with:
            workspace: ${{ steps.process_checkout.outputs.path }}
            cov_mode: "report"
            ut_field: "<business_field>"
            modules: "<module_a> <module_b>"
            source_branch: ${{ env.SOURCE_BRANCH }}
            target_branch: ${{ env.TARGET_BRANCH }}
            obs_path: ${{ env.obs_path }}
            git_token: ${{ secrets.GIT_TOKEN }}
        - name: upload
          uses: obs-upload
          with:
            endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
            bucket: "ascend-ci"
            access-key: ${{ secrets.AK }}
            secret-key: ${{ secrets.SK }}
            artifact-path: |
              ${{ steps.process_checkout.outputs.path }}/ut_cov_*.tar.gz
            object-prefix: ${{ env.obs_path }}/
      if: env.TARGET_BRANCH == 'master'
      runs-on: [dedicate-hosted, x64, large]
      container:
        image: swr.cn-north-4.myhuaweicloud.com/ci_cann/${{ jobs.JOB_image.outputs.UT_Test_report }}
```

> `modules` 参数列出需要合并的 UT 模块名（空格分隔），对应 `stage3` 中各 `llt_action` 的 `ut_type`，仅包含产出覆盖率（`ut_process=coverage`）的 UT 类型。`ut_field` 为业务域标识。
>
> **镜像引用**：stage4 的 `container.image` 应通过 `${{ jobs.JOB_image.outputs.UT_Test_report }}` 引用 stage1 解析的镜像，而非硬编码。需在 `images.yaml` 中为 `UT_Test_report` stage 配置镜像。

---

## 4. 官方 Action 使用

GitCode CI 平台提供以下官方 Action：

### checkout

代码检出。

```yaml
- name: Checkout
  identifier: process_checkout
  uses: checkout
  with:
    ref: ${{ atomgit.event.pull_request.merge_commit_sha || atomgit.sha }}
    token: ${{ secrets.GIT_TOKEN }}
```

- `identifier` 设置后可通过 `${{ steps.<identifier>.outputs.path }}` 获取检出路径。
- 检出 CI 仓库（获取脚本）时使用 `repository` + `path` 参数：
  ```yaml
  - name: Checkout CI
    uses: checkout
    with:
      repository: ${{ vars.CI_PATH }}
      ref: refs/heads/master
      path: "./runner/CI"
  ```

### obs-upload

上传制品到 OBS。

```yaml
- name: upload
  uses: obs-upload
  with:
    endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
    bucket: "ascend-ci"
    access-key: ${{ secrets.AK }}
    secret-key: ${{ secrets.SK }}
    artifact-path: |
      ${{ steps.process_checkout.outputs.path }}/pr_filelist.txt
      ${{ steps.process_checkout.outputs.path }}/build_out/*.run
    object-prefix: ${{ env.obs_path }}/
```

- `artifact-path` 支持多行（每行一个文件/通配符）。
- `object-prefix` 为 OBS 路径前缀，通常用 `obs_path` 保证 PR 隔离。

### obs-download

从 OBS 下载制品。

```yaml
- name: download
  uses: obs-download
  with:
    endpoint: "https://obs.cn-north-4.myhuaweicloud.com"
    bucket: "ascend-ci"
    access-key: ${{ secrets.AK }}
    secret-key: ${{ secrets.SK }}
    key: |
      ${{ env.obs_path }}/pr_filelist.txt
      ${{ env.obs_path }}/pr_filelist_mod.txt
    path: ${{ steps.process_checkout.outputs.path }}
```

- `key` 指定 OBS 上的文件路径，支持多行。
- `path` 指定本地下载目录。

### build-accelerate

编译加速执行器，用于包装编译/测试命令。`uses: build-accelerate` 声明使用加速插件，实际编译命令需在 `command` 中以 **`BuildAccelerate` 关键字前缀**调用，两者配合才能启用编译加速：

```yaml
- name: compile
  uses: build-accelerate
  with:
    command: |
      export WORKSPACE=${{ steps.process_checkout.outputs.path }}
      cd ${{ steps.process_checkout.outputs.path }}
      export task_name=${{ inputs.task_name }}
      BuildAccelerate bash x86_compile.sh
    AC_SERVER_IP: ${{ vars.AC_SERVER_IP }}
```

- `uses: build-accelerate`：声明该步骤使用加速插件。
- `command` 中通过 `export` 注入环境变量，编译命令前加 `BuildAccelerate` 关键字触发加速。编译/测试逻辑建议抽取到 `.gitcode/scripts/` 下的脚本中（见 [§3.4](#34-编译-workflow)），通过 `JOB_shell` 上传到 OBS 后在此下载执行。
- `AC_SERVER_IP` 为编译加速服务器地址，通过仓库 Variable 配置。

---

## 5. CANN 自定义 Action 使用

CANN 自定义 Action 统一存放在 `cann/.gitcode/actions/` 目录下，引用方式为 `cann/.gitcode/actions/<action_name>@master`。各 Action 的详细参数说明参见对应目录下的 README。

### get-pr

拉取目标分支并生成 PR 变更文件清单（`pr_filelist.txt`、`pr_filelist_mod.txt` 等），是所有后续检查步骤的基础。

```yaml
- uses: cann/.gitcode/actions/get-pr@master
  with:
    workspace: ${{ steps.process_checkout.outputs.path }}
    target_branch: ${{ env.TARGET_BRANCH }}
    git_token: ${{ secrets.GIT_TOKEN }}
```

> 详细文档：[get-pr/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/get-pr/README.md)

### revise-img

解析 CI 仓库 `image-conf` 中目标仓库各构建阶段对应的镜像，输出供下游 Job 引用。

```yaml
- uses: cann/.gitcode/actions/revise-img@master
  with:
    repo_name: ${{ env.repo_name }}
    target_branch: ${{ env.TARGET_BRANCH }}
    repo_url: ${{ vars.CI_PATH }}
```

> 输出通过 `${{ jobs.JOB_image.outputs.<stage_name> }}` 在下游 Job 中引用。详细文档：[revise-img/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/revise-img/README.md)

### check-pr

检查 PR 变更内容：二进制文件路径校验 + Markdown 链接有效性检查。依赖 `get-pr` 产出的 `pr_filelist.txt`。

```yaml
- uses: cann/.gitcode/actions/check-pr@master
  with:
    repo_name: ${{ env.repo_name }}
    workspace: ${{ steps.process_checkout.outputs.path }}
```

> 详细文档：[check-pr/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/check-pr/README.md)

### staticcheck

按 `check_type` 分发到 MarkdownLint 或 docs-ci 文档规范检查。

```yaml
- uses: cann/.gitcode/actions/staticcheck@master
  with:
    check_type: ${{ inputs.check_type }}
    target_branch: ${{ env.TARGET_BRANCH }}
    repo_name: ${{ env.repo_name }}
    merge_id: ${{ env.MERGE_ID }}
    commit_id: ${{ env.COMMIT_ID }}
    workspace: ${{ steps.process_checkout.outputs.path }}
```

> 支持 `markdown`、`codespell_check`、`tag_closed_check`、`resource_existence_check`、`link_validity_check`。详细文档：[staticcheck/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/staticcheck/README.md)

### precommit

基于仓库 `.pre-commit-config.yaml` 执行代码格式检查。依赖 `get-pr` 产出的 `pr_filelist_precommit.txt`。

```yaml
- uses: cann/.gitcode/actions/precommit@master
  with:
    merge_id: ${{ env.MERGE_ID }}
    repo_name: ${{ env.repo_name }}
    workspace: ${{ steps.process_checkout.outputs.path }}
```

> 详细文档：[precommit/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/precommit/README.md)

### api-check

API 文档生成与上报 / PR 接口校验。含 `compile` 且同时含 `ubuntu24` 时执行 API 文档生成上报；不含 `compile` 时执行 PR 接口校验。

```yaml
- uses: cann/.gitcode/actions/api-check@master
  with:
    org_name: ${{ env.org_name }}
    task_name: compile
    repo_name: ${{ env.repo_name }}
    merge_id: ${{ env.MERGE_ID }}
    workspace: ${{ steps.process_checkout.outputs.path }}
    source_branch: ${{ env.SOURCE_BRANCH }}
    target_branch: ${{ env.TARGET_BRANCH }}
```

> 详细文档：[api-check/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/api-check/README.md)

### verify-package

校验编译产物包的安装与卸载。在编译步骤后调用。

| 参数 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `workspace` | 是 | - | 代码检出根目录 |
| `package_path` | 否 | `build_out` | 包所在目录 |
| `package_type` | 否 | `run` | 包扩展名类型（CANN `.run` 包用 `run`；Python `.whl` 包用 `whl`） |

```yaml
# CANN .run 包（默认）
- uses: cann/.gitcode/actions/verify-package@master
  with:
    workspace: ${{ steps.process_checkout.outputs.path }}

# Python .whl 包
- uses: cann/.gitcode/actions/verify-package@master
  with:
    workspace: ${{ steps.process_checkout.outputs.path }}
    package_type: whl
```

> 详细文档：[verify-package/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/verify-package/README.md)

### ut-cov-report

单元测试覆盖率处理，支持 `cov`（打包覆盖率）和 `report`（合并生成报告）两种模式。

- `cov` 模式根据 `ut_process` 进一步区分：
  - `coverage`：查找 `coverage_filtered.info` / `ops.info` / `coverage.info` 并重命名为 `coverage_<ut_type>.info`，供 report 模式合并。UT 命令需输出 `ut_process=coverage`。
  - `ut_cov`：统计增量覆盖率，打包 `ut_cov_<ut_type>.tar.gz`。UT 命令需输出 `ut_process=ut_cov`。
  - 空（未输出 `ut_process`）：跳过覆盖率打包。

```yaml
# cov 模式（UT 执行后调用）
- uses: cann/.gitcode/actions/ut-cov-report@master
  with:
    ut_process: ${{ steps.ut.outputs.ut_process }}
    workspace: ${{ steps.process_checkout.outputs.path }}
    ut_type: ${{ inputs.ut_type }}
    target_branch: ${{ env.TARGET_BRANCH }}
    git_token: ${{ secrets.GIT_TOKEN }}

# report 模式（合并各模块覆盖率）
- uses: cann/.gitcode/actions/ut-cov-report@master
  with:
    workspace: ${{ steps.process_checkout.outputs.path }}
    cov_mode: "report"
    ut_field: "<business_field>"
    modules: "<module_a> <module_b>"
    source_branch: ${{ env.SOURCE_BRANCH }}
    target_branch: ${{ env.TARGET_BRANCH }}
    obs_path: ${{ env.obs_path }}
    git_token: ${{ secrets.GIT_TOKEN }}
```

> `modules` 仅列出产出覆盖率（`ut_process=coverage`）的模块；不产覆盖率的 UT 类型不应列入。

> 详细文档：[ut-cov-report/README.md](https://gitcode.com/cann/.gitcode/blob/master/actions/ut-cov-report/README.md)

---

## 6. 附录

### 完整配置清单

| 文件 | 位置 | 说明 |
| --- | --- | --- |
| `<repo>_action.yml` | 仓库 `.gitcode/workflows/` | 主入口 workflow，定义触发和 Stage 编排 |
| `codecheck_action.yml` | 仓库 `.gitcode/workflows/` | 代码检查子 workflow |
| `x86_compile_action.yml` | 仓库 `.gitcode/workflows/` | x86 编译子 workflow |
| `arm_compile_action.yml` | 仓库 `.gitcode/workflows/` | arm 编译子 workflow |
| `staticcheck_action.yml` | 仓库 `.gitcode/workflows/` | 静态检查子 workflow |
| `llt_action.yml` | 仓库 `.gitcode/workflows/` | 单元测试子 workflow |
| `x86_compile.sh` | 仓库 `.gitcode/scripts/` | x86 编译执行脚本（由 `JOB_shell` 上传到 OBS） |
| `arm_compile.sh` | 仓库 `.gitcode/scripts/` | arm 编译执行脚本 |
| `ut.sh` | 仓库 `.gitcode/scripts/` | 单元测试执行脚本 |
| `images.yaml` | CI 仓库 `image-conf/<branch>/` | 镜像配置 |

### 常见问题

**Q: 为什么每个 Job 都要 checkout + download？**

A: 每个 Job 运行在独立容器中，工作区不共享。需要重新 checkout 代码并从 OBS 下载前置步骤产出的文件（包括 `JOB_pr` 上传的文件清单和 `JOB_shell` 上传的执行脚本）。

**Q: 如何新增一个编译任务？**

A: 1) 在 `images.yaml` 中添加 stage；2) 在 `.gitcode/scripts/` 对应编译脚本中添加 `task_name` 的处理逻辑；3) 在主入口 workflow 中添加 Job 调用编译子 workflow。

**Q: 为什么编译/UT 脚本要放在 scripts 目录而不是 inline 在 workflow 中？**

A: 将脚本抽取到独立文件有以下好处：①脚本可独立调试，与 workflow YAML 解耦；②脚本变更走正常 PR 检视流程，通过 `JOB_shell` 上传主干版本到 OBS，避免 PR 中篡改脚本带来的安全风险；③workflow YAML 结构更简洁，只保留编排逻辑。

**Q: `JOB_shell` 为什么从 master 分支检出而不是 PR 合并 commit？**

A: 编译/UT 脚本属于 CI 基础设施，应始终使用仓库主干版本，避免 PR 提交者通过修改脚本绕过检查或执行非预期操作。

**Q: `fail-fast` 如何设置？**

A: `stage1` 设为 `true`（准备阶段失败则终止全部）；`stage2`/`stage3` 设为 `false`（允许部分 Job 失败不阻塞其他 Job）。

**Q: 如何只保留必要检查项？**

A: 在主入口 workflow 中按需删减 `stage2`/`stage3` 中的 Job。例如不需要 UT 则去掉 `stage3`；不需要覆盖率报告则去掉 `stage4`。

**Q: verify-package 如何校验 Python whl 包？**

A: 传 `package_type: whl` 参数。默认 `package_type: run` 适用于 CANN `.run` 包。

### 参考文档

本文聚焦 CANN CI 场景的配置要点。GitCode Action 平台级概念（触发事件、上下文、表达式、Runner、变量与密钥等）请参考官方文档：

| 平台概念 | 对应本文章节 | 官方文档 |
| --- | --- | --- |
| 流水线总览 | — | [流水线](https://docs.gitcode.com/docs/help/home/org_project/pipeline/) |
| 工作流 / Stage / Job / Step | §1.2 | [核心概念：工作流、任务、步骤和 Action](https://docs.gitcode.com/docs/help/home/org_project/pipeline/core-concepts/workflow-job-step-action) |
| 触发事件 | §1.1 | [配置触发条件](https://docs.gitcode.com/docs/help/home/org_project/pipeline/writing-pipelines/configure-triggers) |
| 变量与密钥 | §1.3 | [使用变量和密钥](https://docs.gitcode.com/docs/help/home/org_project/pipeline/writing-pipelines/using-variables-secrets) |
| 上下文与表达式 | 全文 | [上下文](https://docs.gitcode.com/docs/help/home/org_project/pipeline/syntax-reference/context) · [表达式](https://docs.gitcode.com/docs/help/home/org_project/pipeline/syntax-reference/expressions) |
| Runner 与运行环境 | 全文 | [Runner 和运行环境](https://docs.gitcode.com/docs/help/home/org_project/pipeline/core-concepts/runner-and-environment) |
| Action 插件使用 | §4 · §5 | [使用 Action 插件](https://docs.gitcode.com/docs/help/home/org_project/pipeline/writing-pipelines/using-actions) |
| 工作流命令（`$ATOMGIT_OUTPUT` 等） | §3.7 | [工作流命令](https://docs.gitcode.com/docs/help/home/org_project/pipeline/syntax-reference/workflow-commands) |
