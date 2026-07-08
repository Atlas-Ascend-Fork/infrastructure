## 2.1 Prerequisites

**Register a GitCode Account**

1. Visit the [GitCode website](https://gitcode.com)
2. Click the **"Register"** button in the upper right corner
3. Choose a registration method: phone number, email, or WeChat
4. Complete the registration process as prompted

**Environment Access**

- If you prefer browser-based online development, such as Code Server, install Chrome in advance.
- If you prefer local IDE development, such as VSCode or JetBrains IDEs, install VSCode in advance.

## 2.2 Operation Steps

### 2.2.1 Create an Environment

1. Go to the CANN open-source organization at https://gitcode.com/cann.
2. Click the **CANNLab** tab in the navigation bar to enter the CANNLab homepage.

![CANN Open-Source Organization](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/01_cannlab_portal_v2.png)

3. In the left navigation bar, switch to **My Environments** and click **New Environment** to create an NPU environment or a CPU environment.

![CANNLab Entry](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/02_cannlab_create_v2.png)

When creating an NPU development environment, select **NPU A2** or **NPU A3**. If you select a split image template, the system automatically creates a pair of CPU and NPU environments. These two environments point to the same physical environment, allowing you to switch between the NPU and CPU environments as needed.

![CANNLab Entry](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/03_cannlab_createnpuenv_v2.png)

After the environment is created, the CPU environment starts automatically. The NPU environment must be started manually when needed. After startup, you can connect to the development environment.

![CANNLab Entry](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/04_cannlab_trnon_connectenv_v2.png)

### 2.2.2 Use the Environment

![CANNLab Entry](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/05_cannlab_connectenv_v2.png)

After the environment is created successfully, click **"Connect"** and select a connection method.

| Method | Use Case | Description |
|:---|:---|:---|
| **WebIDE** | Lightweight development, cross-device use | Open directly in browser, no software installation required |
| **Visual Studio Code** | Heavy development, prefer local editor | Requires plugins for connecting to the cloud development environment |
|

#### 2.2.2.1 WebIDE Connection

1. Click **"Connect"** -> Select **"WebIDE"**
2. Wait for the page to load, then enter the in-browser IDE
3. WebIDE supports up to **3** independent work windows simultaneously, but opening multiple work windows is not recommended
4. After successful connection, it will display as follows:

   ![WebIDE Connected Page](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/06_webide_connected.png)

> **Note**
> - Currently supports Chrome browser
> - If the page freezes or disconnects, try shutting down and restarting the instance

#### 2.2.2.2 Local VSCode Connection

1. Click **"Connect"** -> Select **"Visual Studio Code"**
2. On first use, install the AtomGit Dev Space and Remote SSH plugins as prompted.
3. Click the plugin icon -> "Login", then authorize with your GitCode account in the browser.

   ![VSCode Plugin Login](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/07_vscode_login.png)

4. After successful login, click here for remote connection

   ![VSCode Remote Connection](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/08_vscode_connect.png)

5. Click the plugin icon -> "Install" -> Select **"Linux"** -> "Trust folder and continue"

6. After successful connection, you will see the following window:

   ![VSCode Connected Window](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/09_vscode_connected.png)

> **Note**
> - The plugin's idle logout time is 24 hours; operation within 24 hours will not cause disconnection

## 2.3 Verification

After successful connection (whether using WebIDE or VSCode), run the following commands in the terminal to verify the environment:

```bash
# View NPU information
npu-smi info

# View CANN version
env | grep ASCEND

# View image version
cat /home/developer/image-version.txt
```
