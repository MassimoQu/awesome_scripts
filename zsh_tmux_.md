# **Linux 深度学习/开发环境配置全指南**

**这份指南旨在记录如何快速在一台新的 Linux 服务器（Ubuntu/Debian）上配置一个现代化、高效率、风格统一的开发环境。
主要包含：权限管理、Zsh/Tmux 一键配置、Tmux 使用手册、监控与 Git 技巧。**

------

## **1. 用户权限与基础设置 (Root 操作)**

**在拿到新服务器的 root 权限后，首先给个人账号（如** `**qqxluca**`**）配置完整权限。**

### **1.1 赋予 Sudo 和 Docker 权限**

```bash
# 1. 加入 sudo 组 (管理员权限)
usermod -aG sudo qqxluca

# 2. 加入 docker 组 (免 sudo 跑容器)
usermod -aG docker qqxluca
```



**注意**：执行完后，用户必须退出重登 (Logout & Login) 才会生效。

### 1.2 配置 Sudo 免密码 (可选，推荐)

为了跑脚本方便，可以设置 sudo 不再询问密码。

1. 输入 `visudo`
2. 在文件末尾添加：

Plaintext

```plain
qqxluca ALL=(ALL) NOPASSWD: ALL
```

### 1.3 解决文件权限问题 (圈地运动)

如果需要使用公共盘（如 `/data`），建议创建个人目录并更改所有者：

Bash

```plain
mkdir -p /data/qqxluca_space
chown -R qqxluca:qqxluca /data/qqxluca_space
```

------

## 2. 一键环境配置脚本 (用户操作)

这是一个“全自动”脚本。它会自动安装 Zsh、Tmux，配置国内镜像源的 Oh My Zsh，安装插件，并写入现代化的 Tmux 配置。

### 使用方法

1. 在服务器上创建文件：`nano setup_env.sh`
2. 粘贴下方代码。
3. 赋予权限并运行：`chmod +x setup_env.sh && ./setup_env.sh`

### 脚本内容 (setup_env.sh)

Bash

```plain
#!/bin/bash
# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}>>> 开始配置专属开发环境...${NC}"

# 1. 安装依赖
echo -e "${YELLOW}>>> [1/7] 安装软件 (需sudo密码)...${NC}"
if command -v apt &> /dev/null; then
    sudo apt update && sudo apt install -y zsh tmux git curl
else
    echo "非Debian系系统，请手动安装 zsh tmux git curl"
    exit 1
fi

# 2. 备份
echo -e "${YELLOW}>>> [2/7] 备份旧配置...${NC}"
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak.$(date +%F-%T)
[ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.bak.$(date +%F-%T)
rm -rf ~/.oh-my-zsh

# 3. 安装 Oh My Zsh (Gitee镜像)
echo -e "${YELLOW}>>> [3/7] 安装 Oh My Zsh...${NC}"
git clone [https://gitee.com/mirrors/oh-my-zsh.git](https://gitee.com/mirrors/oh-my-zsh.git) ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# 4. 下载插件
echo -e "${YELLOW}>>> [4/7] 下载插件...${NC}"
git clone [https://gitee.com/phpxxo/zsh-autosuggestions.git](https://gitee.com/phpxxo/zsh-autosuggestions.git) ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone [https://gitee.com/phpxxo/zsh-syntax-highlighting.git](https://gitee.com/phpxxo/zsh-syntax-highlighting.git) ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 5. 配置 .zshrc
echo -e "${YELLOW}>>> [5/7] 配置 Zsh 主题与插件...${NC}"
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="ys"/' ~/.zshrc
sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z extract)/' ~/.zshrc

# 6. 配置 .tmux.conf
echo -e "${YELLOW}>>> [6/7] 写入 Tmux 配置...${NC}"
cat > ~/.tmux.conf << EOF
# === 强制使用 Zsh ===
set-option -g default-shell $(which zsh)

# === 基础设置 ===
set -g mouse on
set -g history-limit 50000
set -g default-terminal "screen-256color"

# === 快捷键优化 ===
# | 垂直分屏, - 水平分屏
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# 新窗口打开当前目录
bind c new-window -c "#{pane_current_path}"
# 刷新配置: Prefix + r
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# === 状态栏 ===
set -g status-bg black
set -g status-fg white
set -g status-interval 1
set -g status-left-length 30
set -g status-right "#[fg=green]%H:%M #[fg=yellow]%d-%b"
EOF

# 7. 切换 Shell
echo -e "${YELLOW}>>> [7/7] 切换默认 Shell...${NC}"
if [[ "$SHELL" != *"/zsh"* ]]; then
    chsh -s $(which zsh)
fi

echo -e "${GREEN}>>> 配置完成！请重新登录 SSH。${NC}"
```

------

## 3. Tmux 使用速查表 (Cheat Sheet)

Tmux 是防掉线、多任务管理的神器。配置脚本已将其键位现代化。

前缀键 (Prefix): Ctrl + b (按住Ctrl按b，松开，再按后续键)

### 3.1 常用操作

| **场景**         | **命令/快捷键**                | **说明**                           |
| ---------------- | ------------------------------ | ---------------------------------- |
| **新建会话**     | `tmux new -s <名字>`           | 推荐！给任务起个名，方便以后找     |
| **暂时离开**     | `Prefix + d`                   | 最常用。任务后台继续跑，你下班走人 |
| **恢复会话**     | `tmux a` 或 `tmux a -t <名字>` | 回到之前的状态                     |
| **列出会话**     | `tmux ls`                      | 查看后台跑了哪些 Session           |
| **强制重载配置** | `Prefix + r`                   | 修改配置文件后热加载               |

### 3.2 窗口与分屏 (自定义键位)

| **功能**        | **快捷键 (Prefix + ...)** | **备注**                     |
| --------------- | ------------------------- | ---------------------------- |
| **垂直分屏**    | `|` (Shift + \)           |                              |
| **水平分屏**    | `-`                       | 上下切分                     |
| **切换焦点**    | 直接鼠标点击              | 已开启鼠标支持               |
| **调整大小**    | 鼠标拖拽分界线            | 已开启鼠标支持               |
| **最大化/还原** | `z`                       | 看日志、复制代码时很有用     |
| **关闭分屏**    | `x` 或输入 `exit`         | 关掉当前这一块               |
| **新建大窗口**  | `c`                       | 类似浏览器的标签页           |
| **切换大窗口**  | `0-9`                     | 切换标签页                   |
| **打断分屏**    | `!`                       | 把当前小分屏独立成一个大窗口 |

### 3.3 历史回滚

- 直接用 **鼠标滚轮** 向上滚动即可查看历史输出。
- 按 `q` 或滚到底部退出滚动模式。

------

## 4. 常见问题排查

### 4.1 网络/代理问题 (Clash)

如果 `curl` 或 `wget` 报错 `Connection refused`，通常是环境变量设置了代理但代理没运行。

**快速自救 (恢复直连):**

Bash

```plain
unset http_proxy
unset https_proxy
unset all_proxy
```

- **检查端口:**`sudo netstat -tulpn | grep clash`
- **后台运行 Clash:** 建议在 Tmux 里运行 `./clash -d .`，防止 SSH 断开导致代理挂掉。

### 4.2 Git 技巧

**场景：** 刚 commit 完，发现漏了一个文件，不想产生新的 commit 记录。

Bash

```plain
git add <漏掉的文件>
git commit --amend --no-edit

# 如果已经 push 过，需要强制推送:
git push -f origin <分支名>
```

### 4.3 资源监控

推荐始终在一个 Tmux 小窗格中运行监控：

- **看显卡 (GPU):**`nvtop` (强烈推荐，能看到是谁在用显卡)
- **看 CPU/内存:**`htop` (比 top 好看，支持鼠标)

------

## 5. 推荐工作流

1. SSH 登录服务器。
2. 输入 `tmux new -s work` (如果已有则 `tmux a`)。
3. 按 `Prefix + |` 分屏。
4. 左边写代码/跑训练，右边跑 `nvtop` 监控。
5. 下班直接关掉终端窗口 (或 `Prefix + d`)。
6. 下次登录，一键 `tmux a` 恢复所有进度。
