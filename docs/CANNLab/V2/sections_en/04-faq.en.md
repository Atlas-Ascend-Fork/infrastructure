## 4.1 WebIDE Connection Issues

### Q1: A periodic prompt appears: "Network unstable, webide recovering, please wait (28 seconds)"

The following error appears every few seconds when entering WebIDE:

![Network Unstable Prompt](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/10_webide_network_unstable.png)

**【Root Cause】**
Network instability causes the connection between the WebIDE client and server to disconnect.

**【Troubleshooting】** Check whether the network environment is normal from the following aspects:
- Are you using proxy or VPN software? **Disable the proxy** and check whether the connection returns to normal.
- Try changing the network environment, such as switching from Wi-Fi to wired network, or testing with a mobile hotspot.
- Try opening WebIDE in a different browser. Chrome is recommended.
- If none of the above methods resolve the issue, provide the current page URL and error screenshot, and contact technical support.

### Q2: During use, the page suddenly prompts: "WebIDE environment preparing, approximately 1-2 minutes, please wait patiently"

![WebIDE Preparing](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/11_webide_preparing.png)

**【Troubleshooting】**
- Open browser developer tools with F12, click the "Network" tab, press F5 to refresh the page, and check whether the shim interface is pending and cannot be called.

![Shim Interface Pending](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/12_webide_network_pending.png)

- Try connecting with VSCode:
  - If VSCode connects successfully, the backend codeArts-server process of the instance has been killed. Use the recovery methods below.
  - If VSCode also fails to connect, provide the current page URL and error screenshot, and contact operations personnel to investigate the backend cause.

**【Recovery Methods for a Killed codearts-server Process】**
- 【Possible Causes】
  - Running high-load tasks caused CPU or memory to be exhausted, and the process was killed.
  - The codeArts-server process starts with a default max-memory value of 4 GB. If a single process exceeds 4 GB, the process exits.
- 【Recovery Methods】
  - Method 1: If VSCode can connect normally, manually restart the process through the SSH terminal without shutting down the instance. This is suitable when the environment contains important data and cannot be shut down directly.
  - Method 2: Shut down and restart the instance. The process will be restarted automatically. This is suitable when the environment does not contain important data, because data in non-persistent directories will be lost during shutdown.
  - 【Platform Recommendation】 Recreate the instance with the latest image. The latest image increases the process max-memory startup parameter to 6 GB or 8 GB, reducing the chance of this process being killed.

### Q3: Popup error: "Connection preempted. You may have opened multiple windows. Try reconnecting."

![Connection Preempted](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/13_webide_preempted.png)

**【Troubleshooting】**
- A single instance supports up to 3 WebIDE windows. If more than 3 windows are opened, this prompt appears. Close extra windows and try again.

### Q4: Popup error: "Cloud development environment network connection is unstable. You can try reconnecting (or restarting) to restore the connection."

![Network Connection Unstable](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/14_webide_conn_error.png)

**【Troubleshooting】**
1. Click "Reconnect".
2. If the connection still fails, refer to the troubleshooting steps in **Q1**.

## 4.2 VSCode Connection Issues

### Q1: VSCode shows "WebSocket connection failed" in the lower-right corner

VSCode shows "WebSocket connection failed" in the lower-right corner.

Error prompt 1:

![WebSocket Connection Failed](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/15_vscode_websocket_error.png)

Error prompt 2:

![WebSocket Connection Failed 2](https://raw.gitcode.com/cann/infrastructure/raw/master/docs/CANNLab/V2/images/16_vscode_websocket_error2.png)

**【Troubleshooting】**
- Confirm whether this is the first time using VSCode to connect to the development environment.
- If so, check whether the proxy and remote-ssh configurations of the AtomGit Dev Space plugin are correct.

### Q2: VSCode disconnects after a period of inactivity and requires GitCode authorization again

**【Feature Description】**

VSCode connects to the server through remote-ssh. If the network disconnects, you may need to reconnect to the remote server after reopening the VSCode window.
The developer plugin has an automatic idle logout feature for the developer account. The current idle time is 24 hours, so in principle the connection will not be interrupted as long as there is activity within 24 hours.

**【Troubleshooting】**

- If VSCode disconnects frequently, check whether network jitter exists. Possible causes include computer sleep, unstable overseas proxy settings, and other network factors.

- If reconnecting after a VSCode disconnection still redirects to GitCode for login, check:
   - Whether the plugin version is the latest. Older versions have an idle time of 2 hours.

## 4.3 Other Issues

### Q1: Header files cannot be found when compiling operators

**【Troubleshooting】** Load the CANN environment variables.

```bash
source /home/developer/Ascend/ascend-toolkit/set_env.sh
```

### Q2: Insufficient resources when creating an instance

**Solution:** The current resource pool has no available resources. Try a different compute specification.

### Q3: Cannot find the code project directory

**Troubleshooting:** Run `ls /mnt/workspace` to check whether the code directory exists. If it was not automatically pulled, submit an Issue for feedback.
