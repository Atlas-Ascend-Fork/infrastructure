# CANNLab 用户手册

## 文档版本记录

| 版本 | 日期 | 作者 | 说明 |
|:---|:---|:---|:---|
| V1.0 | 2026-05-28 | maoyuanxing | 初始版本 |
| V2.0 | 2026-07-03 | miaoxuedan | 修订版本 |

---

## 目录

- [CANNLab 用户手册](#cannlab-用户手册)
  - [文档版本记录](#文档版本记录)
  - [目录](#目录)
  - [1. 产品简介](#1-产品简介)
    - [1.1 概述](#11-概述)
    - [1.2 产品特点](#12-产品特点)
    - [1.3 应用场景](#13-应用场景)
    - [1.4 基本概念](#14-基本概念)
  - [2. 快速入门](#2-快速入门)
    - [2.1 前提条件](#21-前提条件)
    - [2.2 操作步骤](#22-操作步骤)
      - [2.2.1 创建环境](#221-创建环境)
      - [2.2.2 使用环境](#222-使用环境)
        - [2.2.2.1 WebIDE 连接](#2221-webide-连接)
        - [2.2.2.2 本地 VSCode 连接](#2222-本地-vscode-连接)
    - [2.3 验证结果](#23-验证结果)
  - [3. 用户指南](#3-用户指南)
    - [3.1 环境生命周期管理](#31-环境生命周期管理)
    - [3.2 算力资源管理](#32-算力资源管理)
      - [3.2.1 资源规格](#321-资源规格)
      - [3.2.2 使用规则](#322-使用规则)
      - [3.2.3 资源申请限制](#323-资源申请限制)
    - [3.3 CANN 软件栈管理](#33-cann-软件栈管理)
      - [3.3.1 查询 CANN 版本](#331-查询-cann-版本)
      - [3.3.2 查询驱动版本](#332-查询驱动版本)
      - [3.3.3 升级 CANN 版本](#333-升级-cann-版本)
      - [3.3.4 驱动版本升级](#334-驱动版本升级)
    - [3.4 数据管理](#34-数据管理)
      - [3.4.1 持久化存储](#341-持久化存储)
      - [3.4.2 文件上传与下载](#342-文件上传与下载)
      - [3.4.3 代码自动拉取](#343-代码自动拉取)
    - [3.5 代码工程管理](#35-代码工程管理)
      - [3.5.1 切换工程目录](#351-切换工程目录)
      - [3.5.2 分支管理](#352-分支管理)
      - [3.5.3 Git 免密操作](#353-git-免密操作)
    - [3.6 内置开发工具](#36-内置开发工具)
      - [3.6.1 Huawei OP DevTools（算子开发插件）](#361-huawei-op-devtools算子开发插件)
      - [3.6.2 PyPTO Toolkit](#362-pypto-toolkit)
      - [3.6.3 OpenCode](#363-opencode)
    - [3.7 镜像管理](#37-镜像管理)
      - [3.7.1 查看当前镜像版本](#371-查看当前镜像版本)
      - [3.7.2 镜像版本更新](#372-镜像版本更新)
  - [4. 常见问题](#4-常见问题)
    - [4.1 WebIDE 连接类问题](#41-webide-连接类问题)
      - [Q1：页面隔一段时间，提示："网络不稳定，webide恢复中，请稍后（28秒）"](#q1页面隔一段时间提示网络不稳定webide恢复中请稍后28秒)
      - [Q2：使用过程中，页面突然提示："WebIDE环境准备中，大约需要1-2分钟，请您耐心等待"](#q2使用过程中页面突然提示webide环境准备中大约需要1-2分钟请您耐心等待)
      - [Q3：页面弹窗报"连接错误"，报错："连接被抢占，您可能打开了多个窗口连接，可尝试重新连接。"](#q3页面弹窗报连接错误报错连接被抢占您可能打开了多个窗口连接可尝试重新连接)
      - [Q4：页面弹窗报"连接错误"，报错："云开发环境网络连接不稳定，您可以再次尝试连接（或者重启）以恢复连接。"](#q4页面弹窗报连接错误报错云开发环境网络连接不稳定您可以再次尝试连接或者重启以恢复连接)
    - [4.2 VSCode 连接类问题](#42-vscode-连接类问题)
      - [Q1：VSCode右下角报错："WebSocket connection failed"](#q1vscode右下角报错websocket-connection-failed)
      - [Q2：VSCode窗口弹窗：无法与"xxx"建立连接：端口转发已禁用（Port forwarding is disabled）](#q2vscode窗口弹窗无法与xxx建立连接端口转发已禁用port-forwarding-is-disabled)
      - [Q3：VSCode 隔一段时间不操作会断连，且需要再次进行 GitCode 授权](#q3vscode-隔一段时间不操作会断连且需要再次进行-gitcode-授权)
    - [4.3 其它问题](#43-其它问题)
      - [Q1：编译算子时提示找不到头文件](#q1编译算子时提示找不到头文件)
      - [Q2：创建实例时提示资源不足](#q2创建实例时提示资源不足)
      - [Q3：找不到代码工程目录](#q3找不到代码工程目录)
  - [5. 问题反馈](#5-问题反馈)
    - [5.1 问题反馈](#51-问题反馈)
  - [6. 约束与限制](#6-约束与限制)
    - [6.1 约束与限制](#61-约束与限制)
  - [7. 附录](#7-附录)
    - [7.1 附录](#71-附录)

---

## 1. 产品简介

### 1.1 概述

CANNLab 是 CANN 社区推出的基于云开发者空间提供 NPU 算力资源的一站式云开发平台。平台面向 CANN 生态的算子开发、模型训练与推理、AI 应用构建等场景，为开发者提供**开箱即用**的云端开发环境。

开发者无需在本地安装 CANN 工具链，通过 [GitCode](https://gitcode.com/cann) 上的 CANN 开源仓库入口即可进入平台，按需申请算力，使用 WebIDE 或本地 VSCode 远程连接进行开发。

### 1.2 产品特点

| 特点 | 说明 |
|:---|:---|
| **零配置开发环境** | 预装 WebIDE、Git、CANN 基础包（当前为 9.0.0 正式版本）及算子开发插件，开箱即用 |
| **多种算力规格** | 支持 A2、A3 昇腾算力实例以及 950 CPU仿真实例 |
| **双端连接** | 支持 WebIDE（浏览器直接使用）与本地 VSCode Remote-SSH 远程连接 |
| **数据持久化** | 持久化目录 `/mnt/workspace` 和 `/home` 在实例关机后数据保留，保障代码安全 |
| **免费算力** | 开发者享有初始 100 卡时免费额度，后续可以通过积分兑换卡时 |
| **工具链集成** | 内置 Huawei OP DevTools 算子开发插件，PyPTO Toolkit、CANNBot Toolkit 等辅助工具 |

### 1.3 应用场景

**场景一：昇腾算子开发**

基于预置的 CANN 环境和 Huawei OP DevTools 插件，在云端完成 Ascend C 自定义算子的开发、编译、调试与性能调优。支持标准自定义算子和 pyasc 算子的新建、编译、异常检测与性能分析。

**场景二：模型训练与推理**

利用 A2/A3 NPU 算力，进行轻量级大模型的 SFT 微调、推理部署及模型评估。支持1卡和8卡两种规格。

### 1.4 基本概念

| 术语 | 说明 |
|:---|:---|
| **实例（Instance）** | CANNLab 提供的云端计算单元，包含 CANN 软件栈及开发工具 |
| **镜像（Image）** | 预装好开发环境的模板，包含 CANN 基础包、Python 环境及其他内置工具 |
| **卡时（Card-Hours）** | 算力资源的计量单位，1卡时 = NPU 卡数量 × 使用时长（小时） |
| **工作空间** | 挂载在 `/mnt/workspace` 和 `/home` 的持久化存储目录，实例关机后数据保留 |
| **NPU 实例** | 搭载昇腾 NPU 卡的计算实例，支持 A2 和 A3 |
| **CPU 仿真环境** | 搭载 ARM CPU 的计算环境，用于无 NPU 依赖的算子逻辑验证与 UT 测试 |

## 2. 快速入门

### 2.1 前提条件

**注册 GitCode 账号**

1. 访问 [GitCode 官网](https://gitcode.com)
2. 点击页面右上角 **"注册"** 按钮
3. 选择注册方式：支持手机号、邮箱或微信注册
4. 按提示完成注册流程

**访问环境**

- 如果您的开发习惯是在浏览器 IDE 中在线开发（如 Code Server），建议提前安装Chrome 浏览器。
- 如果您的开发习惯是在本地 IDE 中进行开发（如 VSCode、Jetbrains），建议提前安装 VSCode。

### 2.2 操作步骤

#### 2.2.1 创建环境

1. 进入 CANN 开源组织 https://gitcode.com/cann
2. 点击导航栏中的 **CANNLab** 页签后，正式进入 CANNLab 主页。

![CANN 开源组织](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/01_cannlab_portal_v2.png)

3. 左侧导航栏切换到**我的环境**，点击**新建环境**可创建 NPU 环境或 CPU 环境

![CANNLab 入口](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/02_cannlab_create_v2.png)

当您选择创建一个 NPU 开发环境，即选 **NPU A2** 或者 **NPU A3**，如果选择分设版镜像模板，系统会自动帮您同时创建一对 CPU & NPU 环境，这两个环境指向同一个物理环境，可供用户按需灵活切换 NPU 环境和 CPU 环境。
![CANNLab 入口](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/03_cannlab_createnpuenv_v2.png)

环境创建完成后，CPU 环境会自动启动，NPU 环境按需手动启动，启动后即可连接进入开发环境
![CANNLab 入口](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/04_cannlab_trnon_connectenv_v2.png)

#### 2.2.2 使用环境

![CANNLab 入口](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/05_cannlab_connectenv_v2.png)

环境创建成功后，点击 **"连接"**，选择一种连接方式：

| 方式 | 适用场景 | 说明 |
|:---|:---|:---|
| **WebIDE** | 轻量开发、跨设备使用 | 浏览器直接打开，无需安装任何软件 |
| **Visual Studio Code** | 重度开发、习惯本地编辑器 | 需安装连接云端开发环境的插件 |

##### 2.2.2.1 WebIDE 连接

1. 点击 **"连接"** -> 选择 **"WebIDE"**
2. 等待页面加载完成，即可进入浏览器内 IDE
3. WebIDE 支持同时开启最多 **3 个**独立工作窗口，但不推荐开启多个工作窗口
4. 连接成功后，展示如下：

   ![WebIDE 连接成功页面](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/06_webide_connected.png)

> **说明**
> - 目前支持 Chrome 浏览器
> - 如遇到页面卡住或连接断开，可尝试关机再开机恢复实例

##### 2.2.2.2 本地 VSCode 连接

1. 点击 **"连接"** -> 选择 **"Visual Studio Code"**
2. 首次使用需安装 AtomGit Dev Space 和 Remote SSH 插件，根据提示允许即可
3. 点击插件图标 -> "登录"，在浏览器中选择GitCode账号授权

   ![VSCode 插件登录界面](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/07_vscode_login.png)

4. 登录成功后，可以点击此处进行远程连接

   ![VSCode 远程连接](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/08_vscode_connect.png)

5. 点击插件图标 -> "安装" -> 选择 **"Linux"** -> "信任文件夹并继续"

6. 连接成功后，即可看到如下窗口：

   ![VSCode 连接成功窗口](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/09_vscode_connected.png)

> **说明**
> - 插件闲时未操作自动退出时间为 24 小时，24 小时内有操作不会断连

### 2.3 验证结果

连接成功后（无论使用 WebIDE 还是 VSCode），可在终端中执行以下命令验证环境：

```bash
# 查看 NPU 信息
npu-smi info

# 查看 CANN 版本
env | grep ASCEND

# 查看镜像版本
cat /home/developer/image-version.txt
```

## 3. 用户指南

### 3.1 环境生命周期管理

CANNLab 实例存在以下状态：

| 状态 | 说明 | 是否消耗卡时 |
|:---|:---|:---|
| **运行中** | 实例正在运行，可进行开发操作 | 是 |
| **关机** | 实例已停止，`/mnt/workspace` 和 `/home` 数据保留 | 否 |
| **休眠** | 长时间无操作自动挂起，数据保留 | 否 |
| **已删除** | 实例已销毁，数据不可恢复 | - |

**操作说明：**

- **关机**：停止实例运行，释放算力资源。`/mnt/workspace` 和 `/home` 下的数据持久化保留，其他目录数据丢失。
- **开机**：重新启动已关机或休眠的实例。
- **删除**：彻底销毁实例。**删除后所有数据不可恢复**，请提前备份或 Push 代码至 Git 仓库。

> **说明**
> - NPU 资源类型（A2/A3）不支持直接切换，需关机、删除后重新创建。

### 3.2 算力资源管理

#### 3.2.1 资源规格

| 资源类型 | 芯片型号 | 规格选项 | 使用时长 | 说明 |
|:---|:---|:---|:---|:---|
| **NPU (A2)** | 昇腾 A2 | 1卡：16vCPUs/32GiB | 100卡时 | 通用 NPU 算力 |
| | | 1卡：32vCPUs/32GiB | | |
| | | 8卡：192vCPUs/1536GiB | | |
| **NPU (A3)** | 昇腾 A3 | 1卡：40vCPUs/240GiB | 100卡时 | 高配 NPU 算力 |
| | | 8卡：320vCPUs/1920GiB | | |
| **CPU (ARM)** | 鲲鹏 | 16vCPUs/32GiB | 720核时 | 仅支持 ARM，不支持 x86 |

#### 3.2.2 使用规则

**开发者：**
- 总计 100 卡时，卡时消耗完将**自动关机**并释放资源
- 算力消耗以"卡时"为单位，如创建 2 卡实例，最多可用 50 小时
- **建议闲时及时关机或删除，避免配额无谓消耗**

#### 3.2.3 资源申请限制

- NPU 和 CPU 资源**可各申请一个**
- NPU 资源类型切换（如 A2 → A3）需关机、删除后重新创建
- **注意：实例删除时，`/mnt/workspace` 和 `/home` 数据不会保存**

### 3.3 CANN 软件栈管理

#### 3.3.1 查询 CANN 版本

CANN 包已预装，安装路径为 `/home/developer/Ascend`（注意：区别于自行安装的默认路径 `/usr/local/Ascend`）。

**方式一：查询环境变量**
```bash
env | grep ASCEND
```

**方式二：查看版本文件**
```bash
cat /home/developer/Ascend/ascend-toolkit/latest/opp/version.info
```

#### 3.3.2 查询驱动版本

当前驱动版本为 **25.5.1**，安装路径为 `/usr/local/Ascend/driver`。

```bash
cat /usr/local/Ascend/driver/version.info | grep Version
```

#### 3.3.3 升级 CANN 版本

**方式一：控制台一键升级（推荐）**

1. 在 CANNLab 实例列表，点击 **"CANN包升级"** 按钮
2. 选择可升级的 CANN 包版本（如 9.0.0 正式版、master 分支构建版本）
3. 确认升级结果：

```bash
cd /home/developer/.cann
./manage_cann_pkg.sh --version
```

返回 `task.status = 1` 且 `process = 100%` 表示升级成功。

**方式二：手动安装**

通过WebIDE或者VSCode连接后，在终端中可手动下载安装。

#### 3.3.4 驱动版本升级

暂不支持个人实例的驱动版本升级，由平台统一规划。如有驱动版本依赖，欢迎在 [Dev-experience](https://gitcode.com/cann/Dev-experience/issues) 仓库提 Issue 反馈。

### 3.4 数据管理

#### 3.4.1 持久化存储

| 目录 | 持久化 | 说明 |
|:---|:---|:---|
| `/mnt/workspace` | ✅ 持久化 | 实例关机后数据保留，实例**删除**后数据清除 |
| `/home` | ✅ 持久化 | 实例关机后数据保留，实例**删除**后数据清除 |
| 其他系统目录 | ❌ 非持久化 | 实例**删除**后数据丢失 |

> **重要提示**
> - 请将所有代码工程、数据集、模型文件等重要文件存放于 `/mnt/workspace` 或 `/home` 目录下
> - 实例删除操作不可逆，请提前备份重要数据

#### 3.4.2 文件上传与下载

支持通过 WebIDE 界面或 VSCode 插件直接上传/下载文件。

#### 3.4.3 代码自动拉取

在新建环境时，可以**添加预加载代码仓**，在环境实例化时，会**自动 clone 该仓库的代码**至 `/mnt/workspace`，无需手动拉取。如果在新建环境时没有添加预加载代码仓，环境实例化将不会 clone 任何代码仓。

### 3.5 代码工程管理

#### 3.5.1 切换工程目录

在 WebIDE 中：文件（File）-> 打开项目（Open Project）-> 选择对应仓库目录。

#### 3.5.2 分支管理

当前自动 clone 的代码为 **master** 分支，如需其他分支请手动切换。指定分支的功能正在开发中。

#### 3.5.3 Git 免密操作

平台基于 GitCode 账号绑定自动完成 SSH 公私钥配置，`git clone` / `git push` 全程免密。

### 3.6 内置开发工具

#### 3.6.1 Huawei OP DevTools（算子开发插件）

预装于云开发环境中，提供：

| 功能 | 说明 |
|:---|:---|
| **工程创建** | 支持 pyasc 算子和标准自定义算子一键新建 |
| **编译与执行** | 可视化编译运行，支持芯片类型配置（A3/A5） |
| **调试** | 支持 DumpTensor 调试，数据落盘与可视化 |
| **异常检测** | 检测代码异常，支持错误定位与跳转 |
| **性能调优** | 性能泳道分析与结果拼图 |
| **精度对比** | DumpTensor 数据可视化精度对比 |
| **UT 测试** | 标准自定义算子单元测试 |

**升级方式**

连接到环境后，左侧栏"扩展"中搜索 "Huawei OP DevTools"，在搜索到的 "Huawei OP DevTools" 插件上如果有"更新"图标，说明发布了新版本，在插件详情页面更新版本。为了简化操作，建议在插件详情页面勾选"自动更新"选项，后续插件将静默升级。

#### 3.6.2 PyPTO Toolkit

预装于云开发环境中，面向 AI 加速器的高性能编程框架，简化复杂融合算子及模型网络的开发流程。

| 功能 | 说明 |
|:---|:---|
| **Tile 编程模型** | 基于硬件感知数据块（Tile）的编程范式，充分利用 NPU 并行能力 |
| **多层级 IR 编译** | Tensor Graph → Tile Graph → Block Graph → Execution Graph 自动编译优化 |
| **自动代码生成** | 编译生成 PTO 虚拟指令，再编译为目标平台可执行代码 |
| **分层抽象** | 算法开发者用 Tensor 层，性能专家用 Tile 层，系统开发者用 Block 层 |
| **精度验证** | Golden 参考生成、精度对比与定位、二分对比 |
| **性能调优** | 实测性能数据分析、瓶颈定位、迭代优化 |

**适用场景**

- 复杂融合算子开发（如 FlashAttention、MLA 等）
- 大模型算子级实现与优化
- 需要极致性能调优的算子开发

**升级方式**

连接到环境后，左侧栏"扩展"中搜索 "PyPTO Toolkit"，在搜索到的 "PyPTO Toolkit" 插件上如果有"更新"图标，说明发布了新版本，在插件详情页面更新版本。为了简化操作，建议在插件详情页面勾选"自动更新"选项，后续插件将静默升级。

#### 3.6.3 OpenCode

终端内置 OpenCode 工具，支持自然语言交互式编码辅助。

**配置方法**

1. 验证环境是否已内置 opencode：

```bash
opencode --version
```

2. 打开配置文件：

```
/home/developer/.config/opencode/opencode.json
```

3. 在配置文件中添加 provider 配置（以 GLM-4-7 为例）：

```json
"provider": {
    "myprovider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "volcengine",
      "options": {
        "baseURL": "https://ark.cn-beijing.volces.com/api/v3",
        "apiKey": "***"
      },
      "models": {
        "<END_POINT_ID>": {
          "name": "GLM-4-7-<END_POINT_ID>"
        }
      }
    }
}
```

4. 终端执行 `opencode`，输入 `/models` 选择模型即可开始使用。

**升级方式**

连接到环境后，左侧栏"扩展"中搜索 "CANNBot Toolkit"，在搜索到的 "CANNBot Toolkit" 插件上如果有"更新"图标，说明发布了新版本，在插件详情页面更新版本。为了简化操作，建议在插件详情页面勾选"自动更新"选项，后续插件将静默升级。

### 3.7 镜像管理

#### 3.7.1 查看当前镜像版本

**方式一：** 在 CANNLab 实例列表页，鼠标移至"镜像/规格"查看详情

**方式二：** 在环境内执行命令

```bash
cat /home/developer/image-version.txt
```

#### 3.7.2 镜像版本更新

| 场景 | 操作方式 |
|:---|:---|
| 需要全新环境 | 关机 -> 删除实例 -> 重新创建（注意备份数据） |
| 仅升级 CANN 包 | 使用"CANN包升级"按钮 |
| 仅升级算子插件 | 在"扩展"中搜索插件名称更新 |
| 仅升级 OpenCode | 在"扩展"中搜索 "CANNBot Toolkit" 更新 |

> **注意：** 暂不支持直接升级镜像。

## 4. 常见问题

### 4.1 WebIDE 连接类问题

#### Q1：页面隔一段时间，提示："网络不稳定，webide恢复中，请稍后（28秒）"

进入WebIDE时隔几秒钟就会出现以下错误：

![网络不稳定提示](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/10_webide_network_unstable.png)

**【问题原因】**
网络不稳定，导致webide客户端与服务端的连接断开。

**【解决思路】** 确认网络环境是否正常？请从以下几个方面进行排查：
- 是否使用科学上网软件？**请关闭代理**，确认连接是否恢复正常
- 尝试更换网络环境（如从 Wi-Fi 切换到有线网络，或切换到手机热点测试）
- 尝试使用不同浏览器（推荐 Chrome）打开 WebIDE
- 如果以上方法均无法解决，请反馈当前页面的 URL 和报错截图，联系技术支持

#### Q2：使用过程中，页面突然提示："WebIDE环境准备中，大约需要1-2分钟，请您耐心等待"

![WebIDE环境准备中](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/11_webide_preparing.png)

**【问题排查】**
- 请使用浏览器F12打开，点击"Network"页签，F5刷新页面，确认：shim接口是否为pending状态，无法调用。

![shim接口pending状态](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/12_webide_network_pending.png)

- 尝试使用 VSCode 进行连接：
  - VSCode 连接成功，则说明该实例后台codeArts-server进程被kill，请使用以下方式恢复。
  - VSCode 连接失败，请您反馈当前页面的URL和报错截图，联系运维人员从后台排查具体原因。

**【codearts-server进程被kill的恢复手段】**
- 【可能原因】
  - 执行高负载任务导致CPU或者内存被打满，该进程被kill；
  - codearts-server进程启动时默认的max-memory是4G，单进程超过4G，导致进程退出。
- 【恢复手段】
  - 方法一：若使用VSCode可以正常连接，可以通过SSH终端手动拉起该进程，实例无需关机（适用于环境中有重要数据，无法直接关机）
  - 方法二：实例关机、再开机后可自动拉起该进程，自动恢复（适用于环境中无重要数据的场景。因为关机时，非持久化目录中的数据会丢失）
  - 【平台建议】建议重新创建实例，使用最新版本的镜像，该镜像已将该进程的max-memory启动参数调大至6G或者8G，后续使用该进程被kill的几率会降低

#### Q3：页面弹窗报"连接错误"，报错："连接被抢占，您可能打开了多个窗口连接，可尝试重新连接。"

![连接被抢占](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/13_webide_preempted.png)

**【解决思路】**
- 同一个实例最多支持开3个WebIDE窗口，如果超过3个将出现以上提示。请关闭窗口再重试。

#### Q4：页面弹窗报"连接错误"，报错："云开发环境网络连接不稳定，您可以再次尝试连接（或者重启）以恢复连接。"

![网络连接不稳定](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/14_webide_conn_error.png)

**【解决思路】**
1. 点击重新连接
2. 如无法连接，请参考 **Q1** 的排查步骤

### 4.2 VSCode 连接类问题

#### Q1：VSCode右下角报错："WebSocket connection failed"

VSCode右下角报错："WebSocket 连接失败"

错误提示一：

![WebSocket连接失败](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/15_vscode_websocket_error.png)

错误提示二：

![WebSocket连接失败2](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/16_vscode_websocket_error2.png)

**【解决思路】**
- 确认是否为首次使用 VSCode 方式连接开发环境；
- 若是，检查 AtomGit Dev Space 插件的 proxy 和 remote-ssh 的配置是否正确。

#### Q2：VSCode窗口弹窗：无法与"xxx"建立连接：端口转发已禁用（Port forwarding is disabled）

错误提示一：

![端口转发已禁用](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/17_vscode_port_forwarding.png)

错误提示二：

![端口转发已禁用2](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/18_vscode_port_forwarding2.png)

**【解决思路】**
当前版本已知问题，问题详情：https://gitcode.com/cann/Dev-experience/issues/487

如果是1.2.1及以前的版本可以尝试使用以下方式解决：

1. 升级插件版本到1.3.1版本及以上。升级完，打开文件`C:\Users\账号目录\.atomgitdevenv\.ssh\config`，确认配置：`UserKnownHostsFile /dev/null`

2. 如果配置是：`UserKnownHostsFile NUL`，请尝试在该目录创建known_hosts目录后，再次升级。
![known_hosts配置](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/19_vscode_known_hosts.png)

#### Q3：VSCode 隔一段时间不操作会断连，且需要再次进行 GitCode 授权

**【功能说明】**

VSCode 连接服务器通过 remote-ssh 连接，如果出现网络断开，可能会导致再次打开 VSCode 窗口时需要重新连接远程服务器。
开发者插件有闲时不操作的自动退出开发者账号功能，当前闲时时间为24小时，因此只要24小时内有操作，原则上不会断开。

**【解决思路】**

- 如果 VSCode 频繁断连，需要排查是否存在网络抖动。可能原因有：电脑休眠、电脑设置国外代理网络不稳定等诸多因素；

- 如果 VSCode 断连后，重新连接还需要跳转 GitCode 进行登录，需要确认：
   - 插件版本是否为最新版本，旧版本的闲时时间为2小时；

### 4.3 其它问题

#### Q1：编译算子时提示找不到头文件

**【解决思路】** 加载 CANN 环境变量

```bash
source /home/developer/Ascend/ascend-toolkit/set_env.sh
```

#### Q2：创建实例时提示资源不足

**解决：** 当前资源池已无可用资源，请更换算力规格重试。

#### Q3：找不到代码工程目录

**排查：** 执行 `ls /mnt/workspace` 查看是否存在代码目录。如未自动拉取，请提 Issue 反馈。

## 5. 问题反馈

### 5.1 问题反馈

| 用户类型 | 反馈方式 |
|:---|:---|
| **社区用户** | 在 [infrastructure](https://gitcode.com/cann/infrastructure/issues) 仓库提 Issue |

> **注意：** CANN 开源仓自身的问题（如 ops-math、mindspore 等），请提至对应仓库。

## 6. 约束与限制

### 6.1 约束与限制

| 约束项 | 说明 |
|:---|:---|
| **浏览器** | 推荐使用 Chrome 最新版，不支持 Firefox |
| **用户权限** | 操作用户为 `developer`，不支持直接使用 root 登录。可通过 `sudo` 命令切换到 root |
| **NPU 资源** | NPU 和 CPU 资源可各申请一个，不支持直接切换资源类型 |
| **镜像升级** | 暂不支持直接升级镜像，需关机、删除实例后重新创建 |
| **驱动升级** | 暂不支持个人实例的驱动版本升级，由平台统一规划 |

> **说明：** 以上约束可能随平台版本更新而调整，请关注 CANN 社区动态获取最新信息。

## 7. 附录

### 7.1 附录

- **CANN 开源仓库**：https://gitcode.com/cann
- **infrastructure 仓库**（社区基础设施与会议信息）：https://gitcode.com/cann/infrastructure

> 如有本文档未覆盖的问题，欢迎通过上述渠道反馈，我们将持续完善文档内容。
