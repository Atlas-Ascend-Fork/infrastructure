## 8.1 Version History

### August 2026

- **[2026/08/31]** Version 830 released with the following features:
  - Added split-image environments: one CPU + one NPU environment with shared data, enabling CPU development and NPU verification
  - WebIDE environment includes built-in [cann-learning-hub](https://gitcode.com/cann/cann-learning-hub) and [cann-judge](https://gitcode.com/cann/cann-judge) portals, supporting on-platform tutorials and one-click access to cann-judge for operator development practice
  - Single-card NPU environment: automatically shuts down after 30 minutes of continuous idle time
  - A5 simulation (CPU) environment default user changed to developer (was root user before version 830)
  - Enhanced image capabilities: ①Added built-in triton-ascend and tilelang wheel packages; ②Upgraded built-in development plugins; ③ Git configuration optimization: ~/.gitconfig now includes user.name and user.email information
- **[2026/08/03]** CANNLab new version fully launched:
  - Single-account access: Login-free to Huawei Cloud, use CANNLab directly with GitCode account
  - Enhanced user experience: Added "CANNLab" entry on CANN homepage to access environments, launched "Help Documentation"
  - VSCode connection: Upgraded to CANNLab Dev Space plugin

### July 2026

- **[2026/07/22]** Enhanced NPU single-card and CPU image capabilities: ①Added built-in Jupyter functionality, supporting notebook execution
- **[2026/07/04]** A3 NPU environment driver upgraded to HDK25.5.5, mainly fixing A3 graph mode card drop issue and dvpp file access causing container restart issue

### June 2026

- **[2026/06/24]** NPU and CPU image packages updated, supporting `/mnt/workspace` and `/home` directory persistence with 200G disk size; added "CANN Package Upgrade" feature
- **[2026/06/12]** May version released:
  - New features: Supports `/mnt/workspace` and `/home` directory persistence, both with 200G disk size
  - Bug fix: Fixed issue where codearts-server process being killed prevented WebIDE page access
  - Others: Built-in pre-commit to support code standard checking requirements; upgraded torch_npu version to fix issues

### May 2026

- **[2026/05/15]** Added support for GitCode account and Huawei Cloud account binding, enabling password-free Huawei Cloud login after one-time binding

### April 2026

- **[2026/04/30]** April version released with the following features:
  - Image package upgraded to support CANN 9.0.0 official version
  - Image includes built-in nnal package and gcc-13 installation
- **[2026/04/21]** Added support for A3 environment and A5 simulation environment (CPU), built-in operator development plugin huawei-op-devtools-vscode-plugin updated to version 1.2.9
- **[2026/04/14]** CANNLab March version released with the following features:
  - Image package upgraded with built-in npm and tmux tools
  - Added "CANN Package Upgrade" feature
  - Added GitCode repository permission authorization mechanism: automatically configures git ssh public/private keys based on GitCode account binding, enabling password-free git clone/push operations
  - 【Local VSCode scenario】Huawei Developer Space plugin version 1.3.0 released, fixing known issues
  - 【Operator development plugin】huawei-op-devtools-vscode-plugin version 1.2.7 released

### March 2026

- **[2026/03/23]** February version released with the following features:
  - Image package upgraded, fixing git configuration, adding liblzma-dev system package, and upgrading pip
  - 【Operator development plugin】Built-in operator development plugin (Huawei OP DevTools) version 1.2.5 released
  - 【Local VSCode scenario】Huawei Developer Space plugin version 1.2.1 released, optimizing local VSCode connection to computing platform by extending idle timeout from 2 hours to 24 hours

### February 2026

- **[2026/02/14]** Added support for different image version selection, image package includes built-in opencode
- **[2026/02/09]** Official version launched, fully open to CANN community, no whitelist required for usage

### January 2026

- **[2026/01/30]** January beta version launched with data persistence capability, 100 card-hours quota, and local VsCode support (blue zone portable use only), with the following optimizations:
  - Login verification prompts "Enable two-factor authentication", with option to disable reminder for 30 days
  - Supports WebIDE multi-window operation (up to 3 windows)

### December 2025

- **[2025/12/15]** Beta version launched, GitCode opened "Cloud Development" entry, whitelist-based beta testing
