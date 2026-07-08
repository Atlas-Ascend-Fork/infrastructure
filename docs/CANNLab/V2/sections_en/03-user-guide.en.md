## 3.1 Environment Lifecycle Management

CANNLab instances have the following states:

| State | Description | Consumes Card-Hours |
|:---|:---|:---|
| **Running** | Instance is running, development operations available | Yes |
| **Stopped** | Instance is stopped, `/mnt/workspace` and `/home` data retained | No |
| **Sleeping** | Auto-suspended after prolonged inactivity, data retained | No |
| **Deleted** | Instance is destroyed, data unrecoverable | - |
|

**Operations:**

- **Stop**: Stop the instance and release computing resources. Data under `/mnt/workspace` and `/home` is persisted; data in other directories is lost.
- **Start**: Restart a stopped or sleeping instance.
- **Delete**: Permanently destroy the instance. **All data is unrecoverable after deletion.** Please back up or push code to a Git repository in advance.

> **Note**
> - NPU resource types (A2/A3) do not support direct switching. You need to stop, delete, and then recreate the instance.

## 3.2 Computing Resource Management

### 3.2.1 Resource Specifications

| Resource Type | Chip Model | Specification Options | Duration | Description |
|:---|:---|:---|:---|:---|
| **NPU (A2)** | Ascend A2 | 1-card: 16vCPUs/32GiB | 100 card-hours | General NPU computing |
| | | 1-card: 32vCPUs/32GiB | | |
| | | 8-card: 192vCPUs/1536GiB | | |
| **NPU (A3)** | Ascend A3 | 1-card: 40vCPUs/240GiB | 100 card-hours | High-end NPU computing |
| | | 8-card: 320vCPUs/1920GiB | | |
| **CPU (ARM)** | Kunpeng | 16vCPUs/32GiB | 720 core-hours | ARM only, x86 not supported |
|

### 3.2.2 Usage Rules

**Developers:**
- Total of 100 card-hours. When card-hours are exhausted, the instance will **automatically shut down** and release resources.
- Computing consumption is measured in "card-hours." For example, a 2-card instance can be used for a maximum of 50 hours.
- **It is recommended to stop or delete instances when not in use to avoid unnecessary quota consumption.**

### 3.2.3 Resource Application Limits

- You can apply for **one NPU resource and one CPU resource**.
- Switching NPU resource types (e.g., A2 → A3) requires stopping, deleting, and recreating the instance.
- **Note: When an instance is deleted, `/mnt/workspace` and `/home` data are not retained.**

## 3.3 CANN Software Stack Management

### 3.3.1 Check CANN Version

The CANN package is pre-installed at `/home/developer/Ascend` (note: this differs from the default installation path `/usr/local/Ascend`).

**Method 1: Check environment variables**
```bash
env | grep ASCEND
```

**Method 2: View version file**
```bash
cat /home/developer/Ascend/ascend-toolkit/latest/opp/version.info
```

### 3.3.2 Check Driver Version

The current driver version is **25.5.1**, installed at `/usr/local/Ascend/driver`.

```bash
cat /usr/local/Ascend/driver/version.info | grep Version
```

### 3.3.3 Upgrade CANN Version

**Method 1: One-click upgrade from console (Recommended)**

1. In the CANNLab instance list, click the **"CANN Package Upgrade"** button.
2. Select the upgradable CANN package version (e.g., 9.0.0 official release, master branch build).
3. Verify the upgrade result:

```bash
cd /home/developer/.cann
./manage_cann_pkg.sh --version
```

A result of `task.status = 1` and `process = 100%` indicates a successful upgrade.

**Method 2: Manual installation**

After connecting via WebIDE or VSCode, manually download and install in the terminal.

### 3.3.4 Driver Version Upgrade

Personal instance driver version upgrades are not currently supported; upgrades are managed uniformly by the platform. If you have driver version dependencies, please submit an Issue in the [Dev-experience](https://gitcode.com/cann/Dev-experience/issues) repository.

## 3.4 Data Management

### 3.4.1 Persistent Storage

| Directory | Persistent | Description |
|:---|:---|:---|
| `/mnt/workspace` | ✅ Yes | Data retained after instance shutdown, cleared upon instance **deletion** |
| `/home` | ✅ Yes | Data retained after instance shutdown, cleared upon instance **deletion** |
| Other system directories | ❌ No | Data lost after instance deletion |
|

> **Important Notes**
> - Store important files such as code projects, datasets, and model files under `/mnt/workspace` or `/home`.
> - Instance deletion is irreversible. Please back up important data in advance.

### 3.4.2 File Upload and Download

File upload/download is supported directly via the WebIDE interface or VSCode plugin.

### 3.4.3 Automatic Code Pull

When creating an environment, you can **add a preloaded code repository**. During environment instantiation, the repository will be **automatically cloned** to `/mnt/workspace`, with no manual pull required. If no preloaded code repository is added when creating the environment, no repository will be cloned during instantiation.

## 3.5 Code Project Management

### 3.5.1 Switch Project Directory

In WebIDE: File -> Open Project -> Select the corresponding repository directory.

### 3.5.2 Branch Management

The automatically cloned code is from the **master** branch. For other branches, please switch manually. Branch specification functionality is currently under development.

### 3.5.3 Git Password-Free Operations

The platform automatically configures SSH public/private keys based on GitCode account binding, making `git clone` / `git push` password-free.

## 3.6 Built-in Development Tools

### 3.6.1 Huawei OP DevTools (Operator Development Plugin)

Pre-installed in the cloud development environment, providing:

| Feature | Description |
|:---|:---|
| **Project Creation** | One-click creation of pyasc operators and standard custom operators |
| **Compilation & Execution** | Visual compilation and execution, supports chip type configuration (A3/A5) |
| **Debugging** | Supports DumpTensor debugging, data persistence, and visualization |
| **Anomaly Detection** | Detects code anomalies, supports error location and navigation |
| **Performance Tuning** | Performance swimlane analysis and result charting |
| **Accuracy Comparison** | DumpTensor data visualization for accuracy comparison |
| **UT Testing** | Unit testing for standard custom operators |
|

**Upgrade Method**

After connecting to the environment, search for "Huawei OP DevTools" in the left sidebar "Extensions". If an "Update" icon appears on the "Huawei OP DevTools" plugin, a new version has been released. Update the version on the plugin details page. To simplify future operations, it is recommended to enable "Auto Update" on the plugin details page so later plugin versions are upgraded silently.

### 3.6.2 PyPTO Toolkit

Pre-installed in the cloud development environment, a high-performance programming framework for AI accelerators that simplifies the development of complex fused operators and model networks.

| Feature | Description |
|:---|:---|
| **Tile Programming Model** | Hardware-aware data block (Tile) programming paradigm, fully leveraging NPU parallel capabilities |
| **Multi-level IR Compilation** | Tensor Graph → Tile Graph → Block Graph → Execution Graph automatic compilation optimization |
| **Automatic Code Generation** | Compiles to generate PTO virtual instructions, then compiles to target platform executable code |
| **Layered Abstraction** | Tensor layer for algorithm developers, Tile layer for performance experts, Block layer for system developers |
| **Accuracy Verification** | Golden reference generation, accuracy comparison and localization, binary comparison |
| **Performance Tuning** | Measured performance data analysis, bottleneck localization, iterative optimization |
|

**Use Cases**

- Complex fused operator development (e.g., FlashAttention, MLA)
- Large model operator-level implementation and optimization
- Operator development requiring extreme performance tuning

**Upgrade Method**

After connecting to the environment, search for "PyPTO Toolkit" in the left sidebar "Extensions". If an "Update" icon appears on the "PyPTO Toolkit" plugin, a new version has been released. Update the version on the plugin details page. To simplify future operations, it is recommended to enable "Auto Update" on the plugin details page so later plugin versions are upgraded silently.

### 3.6.3 OpenCode

The OpenCode tool is built into the terminal, supporting natural language interactive coding assistance.

**Configuration Method**

1. Verify that opencode is built into the environment:

```bash
opencode --version
```

2. Open the configuration file:

```
/home/developer/.config/opencode/opencode.json
```

3. Add provider configuration to the file (using GLM-4-7 as an example):

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

4. Run `opencode` in the terminal and enter `/models` to select a model and start using.

**Upgrade Method**

After connecting to the environment, search for "CANNBot Toolkit" in the left sidebar "Extensions". If an "Update" icon appears on the "CANNBot Toolkit" plugin, a new version has been released. Update the version on the plugin details page. To simplify future operations, it is recommended to enable "Auto Update" on the plugin details page so later plugin versions are upgraded silently.

## 3.7 Image Management

### 3.7.1 View Current Image Version

**Method 1:** On the CANNLab instance list page, hover over "Image/Specification" to view details.

**Method 2:** Run the following command in the environment

```bash
cat /home/developer/image-version.txt
```

### 3.7.2 Image Version Update

| Scenario | Operation Method |
|:---|:---|
| Need a fresh environment | Stop -> Delete instance -> Recreate (back up data first) |
| Upgrade CANN package only | Use the "CANN Package Upgrade" button |
| Upgrade operator plugin only | Search for the plugin name in "Extensions" and update |
| Upgrade OpenCode only | Search for "CANNBot Toolkit" in "Extensions" and update |
|

> **Note:** Direct image upgrade is not currently supported.
