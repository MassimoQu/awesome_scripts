#!/bin/bash

# ================= 配置区域 =================
# 你的订阅地址 (请替换为真实Token)
SUB_URL="[https://dy11.baipiaoyes.com/api/v1/client/subscribe?token=](https://dy11.baipiaoyes.com/api/v1/client/subscribe?token=)******"

# 路径配置
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/mihomo"
PROXY_PORT=57890
SECRET="qu523"

# Clash 核心下载地址 (Mihomo v1.18.1)
CLASH_URL="[https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz](https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz)"
# ===========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}>>> 初始化目录...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# ---------------------------------------------------------
# 第一步：检查或下载 Clash 核心
# ---------------------------------------------------------
cd "$INSTALL_DIR"

# 检查是否已经手动上传或安装好
if [ -f "clash" ] && [ -x "clash" ]; then
    echo -e "${GREEN}✅ 检测到 Clash 核心已存在，跳过下载步骤。${NC}"
else
    echo -e "${YELLOW}>>> 正在尝试从 GitHub 下载 Clash 核心...${NC}"
    rm -f clash.gz
    
    # 尝试下载，超时时间 10秒
    wget -T 15 -t 2 -O clash.gz "$CLASH_URL"
    
    # 检查下载是否成功 (是否存在且大于 1MB)
    if [ ! -s "clash.gz" ] || [ $(stat -c%s "clash.gz") -lt 1000000 ]; then
        echo -e "${RED}❌ GitHub 下载失败！服务器网络可能已屏蔽 GitHub。${NC}"
        echo -e "${YELLOW}>>> 请在你的【本地电脑】下载核心并通过 SCP 上传，操作如下：${NC}"
        echo "1. 本地下载: $CLASH_URL"
        echo "2. 本地打开终端执行 SCP 上传:"
        echo -e "${GREEN}   scp -P 22 mihomo-linux-amd64-v1.18.1.gz $(whoami)@$(hostname -I | awk '{print $1}'):~/.local/bin/clash.gz${NC}"
        echo "3. 上传完成后，请重新运行本脚本，将会自动识别文件。"
        
        # 清理垃圾文件
        rm -f clash.gz
        exit 1
    fi

    echo -e "${GREEN}✅ 下载成功，正在解压...${NC}"
    gunzip -f clash.gz
    mv clash mihomo-core 2>/dev/null 
    mv mihomo-core clash
    chmod +x clash
fi

# ---------------------------------------------------------
# 第二步：下载订阅配置
# ---------------------------------------------------------
echo -e "${GREEN}>>> 正在处理订阅配置...${NC}"
cd "$CONFIG_DIR"

# 只有当配置文件不存在，或者强制更新时才下载
# 先尝试下载
wget --user-agent="ClashMeta" -T 10 -t 2 -O config_temp.yaml "$SUB_URL"

if [ ! -s "config_temp.yaml" ]; then
    echo -e "${RED}❌ 订阅下载失败！机场 API 可能被墙。${NC}"
    
    # 检查是否已有旧配置可用
    if [ -f "config.yaml" ]; then
        echo -e "${YELLOW}⚠️  检测到存在旧的 config.yaml，将尝试使用旧配置启动...${NC}"
        rm -f config_temp.yaml
    else
        echo -e "${YELLOW}>>> 请在你的【本地电脑】Clash Verge 导出 config.yaml，并通过 SCP 上传：${NC}"
        echo -e "${GREEN}   scp -P 22 config.yaml $(whoami)@$(hostname -I | awk '{print $1}'):~/.config/mihomo/config.yaml${NC}"
        echo ">>> 上传完成后，请重新运行本脚本。"
        exit 1
    fi
else
    mv config_temp.yaml config.yaml
    echo -e "${GREEN}✅ 订阅下载成功，正在注入服务器配置...${NC}"
    
    # 清理旧配置冲突
    sed -i '/^port:/d' config.yaml
    sed -i '/^socks-port:/d' config.yaml
    sed -i '/^mixed-port:/d' config.yaml
    sed -i '/^allow-lan:/d' config.yaml
    sed -i '/^bind-address:/d' config.yaml
    sed -i '/^external-controller:/d' config.yaml
    sed -i '/^secret:/d' config.yaml

    # 写入新头部
    cat > config_header.yaml <<EOF
mixed-port: $PROXY_PORT
allow-lan: false
bind-address: "127.0.0.1"
mode: rule
log-level: info
external-controller: 127.0.0.1:9090
secret: "$SECRET"
EOF
    cat config_header.yaml config.yaml > config_final.yaml
    mv config_final.yaml config.yaml
    rm config_header.yaml
fi

# ---------------------------------------------------------
# 第三步：补全 GeoIP 数据库 (缺失会导致无法启动)
# ---------------------------------------------------------
echo -e "${GREEN}>>> 检查 Geo 数据库...${NC}"
# 如果没有文件，才尝试下载
if [ ! -f "country.mmdb" ]; then
    wget -T 10 -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb)
    wget -T 10 -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat)
    wget -T 10 -N [https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat](https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat)
    
    if [ ! -f "country.mmdb" ]; then
         echo -e "${YELLOW}⚠️  Geo 数据库下载失败(GitHub被墙)。${NC}"
         echo "Clash 可能会启动失败。如果失败，请手动上传 country.mmdb 到 ~/.config/mihomo/"
    fi
fi

# ---------------------------------------------------------
# 第四步：配置环境变量
# ---------------------------------------------------------
if ! grep -q "alias proxyon" "$HOME/.bashrc"; then
    cat >> "$HOME/.bashrc" <<EOF

# === Proxy Aliases ===
export CLASH_PORT=$PROXY_PORT
alias proxyon='export https_proxy=[http://127.0.0.1](http://127.0.0.1):\$CLASH_PORT; export http_proxy=[http://127.0.0.1](http://127.0.0.1):\$CLASH_PORT; export all_proxy=socks5://127.0.0.1:\$CLASH_PORT; echo "🌐 Proxy ON"'
alias proxyoff='unset https_proxy; unset http_proxy; unset all_proxy; echo "⚪ Proxy OFF"'
# =====================
EOF
    echo -e "${GREEN}✅ 已将快捷命令写入 .bashrc${NC}"
fi

# ---------------------------------------------------------
# 第五步：启动服务
# ---------------------------------------------------------
echo -e "${GREEN}>>> 正在重启 Clash 服务...${NC}"
pkill -f "clash -d" || true
sleep 1

# 后台启动
nohup "$INSTALL_DIR/clash" -d "$CONFIG_DIR" > "$CONFIG_DIR/clash.log" 2>&1 &

# 检查进程是否存在
sleep 2
if pgrep -x "clash" > /dev/null; then
    echo -e "${GREEN}🎉 安装完成！服务运行中。${NC}"
    echo "------------------------------------------------"
    echo "1. 使命令生效:  source ~/.bashrc"
    echo "2. 开启代理:    proxyon"
    echo "3. 关闭代理:    proxyoff"
    echo "4. 测试连接:    proxyon; curl -I [https://www.google.com](https://www.google.com)"
    echo "------------------------------------------------"
else
    echo -e "${RED}❌ 启动失败！请查看日志：${NC}"
    echo "cat $CONFIG_DIR/clash.log"
fi
