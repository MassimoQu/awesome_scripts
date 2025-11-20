#!/bin/bash

# ================= 配置区域 =================
# 安装目录
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.codex"
# 假设的下载地址 (如果这是私有工具，下载失败后会提示你手动传)
DOWNLOAD_URL="https://github.com/tabcode/codex/releases/download/v0.60.1/codex-x86_64-unknown-linux-musl.tar.gz"
# ===========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}>>> 开始配置 Codex 环境...${NC}"

# 1. 检查代理状态
if [ -z "$https_proxy" ]; then
    echo -e "${YELLOW}⚠️  检测到当前未开启代理。${NC}"
    echo "为了确保下载成功，建议先运行 'proxyon'。"
    read -p "是否继续？(y/n) " choice
    if [[ "$choice" != "y" ]]; then exit 1; fi
fi

# 2. 交互式获取 API Key
echo "------------------------------------------------"
if [ -f "$CONFIG_DIR/auth.json" ]; then
    echo -e "${YELLOW}检测到已存在 auth.json，跳过 Key 输入。${NC}"
else
    echo -e "${GREEN}请输入你的 OpenAI API Key (sk-开头):${NC}"
    read -s API_KEY
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}Key 不能为空！${NC}"
        exit 1
    fi
fi
echo "------------------------------------------------"

# 3. 准备目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# 4. 下载或安装核心
cd "$INSTALL_DIR"

if [ -f "codex" ] && [ -x "codex" ]; then
    echo -e "${GREEN}✅ 检测到 Codex 核心已存在，跳过安装。${NC}"
else
    echo -e "${YELLOW}>>> 尝试下载 Codex 核心...${NC}"
    # 删除残留
    rm -f codex.tar.gz
    
    # 尝试下载
    wget -T 15 -t 2 -O codex.tar.gz "$DOWNLOAD_URL"
    
    # 检查下载是否有效
    if [ ! -s "codex.tar.gz" ] || grep -q "<html" "codex.tar.gz"; then
        echo -e "${RED}❌ 下载失败或链接无效（可能需要手动上传）。${NC}"
        echo -e "${YELLOW}>>> 请在【本地电脑】下载好 tar.gz 包，执行以下命令上传：${NC}"
        echo -e "${GREEN}   scp -P 22 codex-x86_64-unknown-linux-musl.tar.gz $(whoami)@$(hostname -I | awk '{print $1}'):~/.local/bin/codex.tar.gz${NC}"
        echo ">>> 上传完成后，重新运行本脚本即可。"
        rm -f codex.tar.gz
        exit 1
    fi

    echo -e "${GREEN}✅ 下载成功，正在解压...${NC}"
    tar -xzvf codex.tar.gz
    # 自动查找解压出的可执行文件并重命名（防止解压出带文件夹的结构）
    find . -type f -name "codex*" ! -name "*.tar.gz" -exec mv {} ./codex \; 2>/dev/null
    chmod +x codex
    rm -f codex.tar.gz
fi

# 5. 生成配置文件 (根据你提供的截图复刻)
echo -e "${GREEN}>>> 生成配置文件...${NC}"

# config.toml
cat > "$CONFIG_DIR/config.toml" <<EOF
model_provider = "tabcode"
model = "gpt-5-codex"
model_reasoning_effort = "medium"
disable_response_storage = true
preferred_auth_method = "apikey"

[model_providers.tabcode]
name = "openai"
base_url = "https://api.tabcode.cc/openai"
wire_api = "responses"
requires_openai_auth = true
EOF

# auth.json (仅当不存在时写入，防止覆盖)
if [ ! -f "$CONFIG_DIR/auth.json" ]; then
    cat > "$CONFIG_DIR/auth.json" <<EOF
{ "OPENAI_API_KEY": "$API_KEY" }
EOF
    echo -e "${GREEN}✅ API Key 已写入。${NC}"
fi

# 6. 验证
echo "------------------------------------------------"
if command -v codex >/dev/null 2>&1; then
    echo -e "${GREEN}🎉 Codex 配置完成！${NC}"
    echo "测试命令: codex --version"
else
    echo -e "${YELLOW}⚠️  安装完成，但 PATH 可能未刷新。${NC}"
    echo "请执行: export PATH=\$HOME/.local/bin:\$PATH"
fi
echo "------------------------------------------------"
