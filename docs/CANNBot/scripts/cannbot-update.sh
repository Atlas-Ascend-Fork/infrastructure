 #!/bin/bash
# ============================================================
#  cannbot-update.sh
#  自动下载并安装最新版 cannbot-toolkit 插件
#  用法：bash cannbot-update.sh
# ============================================================

set -e

# ---------- 颜色输出 ----------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------- 配置 ----------
VERSION_URL="https://cannbot-obs.obs.cn-north-4.myhuaweicloud.com/packages/version.txt"

# 自动获取最新版本号
info "正在获取最新版本号..."
if command -v curl &>/dev/null; then
    VSIX_VERSION=$(curl -fsSL "$VERSION_URL" | tr -d '[:space:]') \
        || error "获取版本号失败，请检查网络或 URL：$VERSION_URL"
elif command -v wget &>/dev/null; then
    VSIX_VERSION=$(wget -qO- "$VERSION_URL" | tr -d '[:space:]') \
        || error "获取版本号失败，请检查网络或 URL：$VERSION_URL"
else
    error "系统中未找到 curl 或 wget，无法获取版本号。"
fi

if [ -z "$VSIX_VERSION" ]; then
    error "版本号为空，请检查 $VERSION_URL 内容是否正确。"
fi
info "最新版本号：$VSIX_VERSION"

# -------------- 检测系统架构 --------------
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        VSIX_ARCH="arm64"
        ;;
    x86_64|amd64)
        VSIX_ARCH="x64"
        ;;
    *)
        error "不支持的系统架构：$ARCH（仅支持arm64 / x64）"
        ;;
esac
info "系统架构：${ARCH} -> ${VSIX_ARCH}"

VSIX_FILENAME="cannbot-toolkit-linux-${VSIX_ARCH}-${VSIX_VERSION}.vsix"
VSIX_URL="https://cannbot-obs.obs.cn-north-4.myhuaweicloud.com/packages/${VSIX_VERSION}/${VSIX_FILENAME}"
VSIX_PATH="/tmp/${VSIX_FILENAME}"
CODEARTS_BIN="$HOME/codearts/bin/codearts-server"

# ---------- 检查 codearts-server ----------
if [ ! -f "$CODEARTS_BIN" ]; then
    error "未找到 codearts-server：$CODEARTS_BIN\n       请确认 CodeArts IDE 已正确安装，或修改脚本顶部的 CODEARTS_BIN 路径。"
fi

# ---------- 下载 vsix ----------
info "开始更新 cannbot-toolkit ..."
info "下载地址：$VSIX_URL"

# 优先用 curl，其次 wget
if command -v curl &>/dev/null; then
    curl -fSL --progress-bar -o "$VSIX_PATH" "$VSIX_URL" \
        || error "下载失败，请检查网络或 URL 是否可访问。"
elif command -v wget &>/dev/null; then
    wget -q --show-progress -O "$VSIX_PATH" "$VSIX_URL" \
        || error "下载失败，请检查网络或 URL 是否可访问。"
else
    error "系统中未找到 curl 或 wget，无法下载文件。"
fi

# 验证文件是否下载成功且非空
if [ ! -s "$VSIX_PATH" ]; then
    error "下载的文件为空，请检查下载地址是否有效。"
fi

FILESIZE=$(du -sh "$VSIX_PATH" 2>/dev/null | cut -f1)
info "下载完成，文件大小：${FILESIZE}，路径：$VSIX_PATH"

# ---------- 安装插件 ----------
info "开始安装插件..."
"$CODEARTS_BIN" --install-extension "$VSIX_PATH" \
    || error "插件安装失败，请查看上方输出信息。"

info "✅ cannbot-toolkit 安装成功！"

# ---------- 清理临时文件 ----------
rm -f "$VSIX_PATH"
info "已清理临时文件：$VSIX_PATH"

# ---------- 同步到 ~/.vscode-server/extensions ----------
CODEARTS_EXT_DIR="$HOME/.codearts-server/extensions"
VSCODE_EXT_DIR="$HOME/.vscode-server/extensions"
EXT_ID="cann-pub.cannbot-toolkit"
EXT_DIRNAME="${EXT_ID}-${VSIX_VERSION}"


# 确保目标目录存在
mkdir -p "$VSCODE_EXT_DIR"

# 复制插件目录（覆盖）
info "正在同步插件目录到 $VSCODE_EXT_DIR ..."
rm -rf "${VSCODE_EXT_DIR:?}/${EXT_DIRNAME}"
cp -r "$CODEARTS_EXT_DIR/$EXT_DIRNAME" "$VSCODE_EXT_DIR/$EXT_DIRNAME"
info "插件目录同步完成"

# ---------- 更新 ~/.vscode-server/extensions/extensions.json ----------
VSCODE_EXT_JSON="$VSCODE_EXT_DIR/extensions.json"

# 如果 extensions.json 不存在则初始化为空数组
if [ ! -f "$VSCODE_EXT_JSON" ]; then
    echo "[]" > "$VSCODE_EXT_JSON"
fi

# 获取当前安装时间戳（毫秒）
TIMESTAMP=$(date +%s%3N)

# JSON 构造完全在 Python 内完成，避免 bash heredoc 变量替换问题
python3 - "$VSCODE_EXT_JSON" "$EXT_ID" "$VSIX_VERSION" "$VSCODE_EXT_DIR/$EXT_DIRNAME" "$EXT_DIRNAME" "$TIMESTAMP" <<'PYEOF'
import json, sys

json_path, ext_id, version, ext_path, rel_location, timestamp = sys.argv[1:]

with open(json_path, "r") as f:
    data = json.load(f)

# 过滤掉旧的同 id 条目
data = [e for e in data if e.get("identifier", {}).get("id") != ext_id]

# 构造新条目（参考 pypto-toolkit 在 vscode-server 中的格式）
new_entry = {
    "identifier": {"id": ext_id},
    "version": version,
    "location": {"$mid": 1, "path": ext_path, "scheme": "file"},
    "relativeLocation": rel_location,
    "metadata": {
        "installedTimestamp": int(timestamp),
        "pinned": True,
        "source": "vsix"
    }
}

data.append(new_entry)

with open(json_path, "w") as f:
    json.dump(data, f, separators=(",", ":"))

PYEOF

info "✅ cannbot-toolkit 更新完成！"