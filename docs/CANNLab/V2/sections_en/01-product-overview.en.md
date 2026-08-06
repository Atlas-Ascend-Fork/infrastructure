## 1.1 Overview

CANNLab is a one-stop cloud development platform launched by the CANN community, providing NPU computing resources based on the Cloud Developer Space. The platform targets scenarios such as operator development, model training and inference, and AI application development within the CANN ecosystem, offering developers an **out-of-the-box** cloud development environment.

Developers do not need to install the CANN toolchain locally. They can access the platform through the CANN open-source repository entry on [AtomGit](https://gitcode.com/cann), apply for computing resources on demand, and develop through WebIDE or local VSCode remote connection.

## 1.2 Product Features

| Feature | Description |
|:---|:---|
| **Zero-configuration development environment** | Pre-installed with WebIDE, Git, CANN base package (currently v9.0.0 official release), and operator development plugins; ready to use out of the box |
| **Multiple compute specifications** | Supports A2 and A3 Ascend compute instances, as well as 950 CPU simulation instances |
| **Dual connection methods** | Supports WebIDE (used directly in the browser) and local VSCode Remote-SSH remote connection |
| **Data persistence** | Persistent directories `/mnt/workspace` and `/home` retain data after instance shutdown, protecting code and data |
| **Free compute quota** | Developers receive an initial 100 card-hour free quota, and can later exchange points for additional card-hours |
| **Toolchain integration** | Built-in Ascend C Toolkit operator development plugin, PyPTO Toolkit, CANNBot Toolkit, and other auxiliary tools |

## 1.3 Application Scenarios

**Scenario 1: Ascend Operator Development**

Based on the pre-installed CANN environment and Ascend C Toolkit plugin, complete Ascend C custom operator development, compilation, debugging, and performance tuning in the cloud. Supports creation, compilation, anomaly detection, and performance analysis of standard custom operators and pyasc operators.

**Scenario 2: Model Training and Inference**

Leverage A2/A3 NPU computing power for lightweight large model SFT fine-tuning, inference deployment, and model evaluation. Supports 1-card and 8-card specifications.

**Scenario 3: AI Application Development (Planned)**

Build AI application scenarios such as RAG retrieval-augmented generation, AI Agent orchestration, and multimodal applications based on the CANNLab cloud environment.

## 1.4 Basic Concepts

| Term | Description |
|:---|:---|
| **Instance** | Cloud computing unit provided by CANNLab, including CANN software stack and development tools |
| **Image** | Pre-installed development environment template, including the CANN base package, Python environment, and other built-in tools |
| **Card-Hours** | Unit of measurement for compute resources. 1 card-hour = number of NPU cards x usage duration (hours) |
| **Workspace** | Persistent storage directories mounted at `/mnt/workspace` and `/home`; data is retained after instance shutdown |
| **NPU Instance** | Computing instance equipped with Ascend NPU cards, supports A2 and A3 |
| **CPU Simulation Environment** | Computing environment with ARM CPU, used for operator logic verification and UT testing without NPU dependency |
