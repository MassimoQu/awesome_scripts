# Server Proxy Setup Guide (Non-Root)

这份文档记录了在 Linux 服务器（Ubuntu 18.04+）上，在**没有 sudo 权限**的情况下，配置 Clash Meta (Mihomo) 代理服务的完整流程。

## 1. 环境信息
* **核心程序**: Clash Meta (Mihomo) Linux-amd64
* **安装方式**: 用户空间 (User Space)，安装在 `~/.local/bin`
* **代理协议**: HTTP / SOCKS5
* **监听端口**: `57890`
* **Web UI 端口**: `9090` (仅限本地 127.0.0.1 访问)
* **Secret (密钥)**: `qu523`

## 2. 目录结构
所有相关文件均位于当前用户目录下，不污染系统：
* **可执行文件**: `~/.local/bin/clash`
* **配置文件**: `~/.config/mihomo/config.yaml`
* **日志文件**: `~/.config/mihomo/clash.log`
* **Geo 数据库**: `~/.config/mihomo/*.mmdb`

## 3. 快速安装 / 重置 (一键脚本)

创建并运行 `setup_clash.sh` 脚本即可自动完成下载、配置转换和启动。

### 脚本内容 (`setup_clash.sh`)

```bash
#!/bin/bash

# ================= 配置区域 =================
# 请将下方链接替换为真实的订阅地址
# 注意：为了安全，README 中不包含真实 Token，请在脚本中填入
SUB_URL="[https://dy11.baipiaoyes.com/api/v1/client/subscribe?token=](https://dy11.baipiaoyes.com/api/v1/client/subscribe?token=)******"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/mihomo"
PROXY_PORT=57890
UI_PORT=9090
SECRET="qu523"
# ===========================================

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# 1. 下载核心
echo ">>> Downloading Clash Meta..."
cd "$INSTALL_DIR"
rm -f clash clash.gz
wget -O clash.gz "[https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz](https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz)"
gunzip clash.gz && chmod +x clash

# 2. 下载订阅并处理配置
echo ">>> Processing Configuration..."
cd "$CONFIG_DIR"
wget --user-agent="ClashMeta" -O config.yaml "$SUB_URL"

# 清理旧配置并注入新端口设置
sed -i '/^port:/d' config.yaml
sed -i '/^socks-port:/d' config.yaml
sed -i '/^mixed-port:/d' config.yaml
sed -i '/^allow-lan:/d' config.yaml
sed -i '/^bind-address:/d' config.yaml
sed -i '/^external-controller:/d' config.yaml
sed -i '/^secret:/d' config.yaml

cat > config_header.yaml <<EOF
mixed-port: $PROXY_PORT
allow-lan: false
bind-address: "127.0.0.1"
mode: rule
log-level: info
external-controller: 127.0.0.1:$UI_PORT
secret: "$SECRET"
EOF

cat config_header.yaml config.yaml > config_final.yaml
mv config_final.yaml config.yaml
rm config_header.yaml

# 3. 下载 GeoIP 数据库
echo ">>> Downloading Geo Databases..."
wget -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb)
wget -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat)
wget -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat)

# 4. 配置环境变量别名
if ! grep -q "alias proxyon" "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<EOF

# === Proxy Aliases ===
export CLASH_PORT=$PROXY_PORT
alias proxyon='export https_proxy=[http://127.0.0.1](http://127.0.0.1):\$CLASH_PORT; export http_proxy=[http://127.0.0.1](http://127.0.0.1):\$CLASH_PORT; export all_proxy=socks5://127.0.0.1:\$CLASH_PORT; echo "🌐 Proxy ON"'
alias proxyoff='unset https_proxy; unset http_proxy; unset all_proxy; echo "⚪ Proxy OFF"'
# =====================
EOF
fi

# 5. 启动服务
pkill -f "clash -d" || true
nohup "$INSTALL_DIR/clash" -d "$CONFIG_DIR" > "$CONFIG_DIR/clash.log" 2>&1 &
echo ">>> Done! Please run: source ~/.bashrc"
