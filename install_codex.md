# Codex 环境配置指南 (非 Root 权限)

这份文档用于说明如何在服务器上使用自动化脚本配置 Codex 命令行工具。

## 1. 准备工作

在开始之前，请确保你已经完成了以下步骤：

1.  **开启代理**：建议使用 `setup_clash.sh` 配置好的环境。
    ```bash
    source ~/.bashrc
    proxyon
    ```
    *注意：如果不开启代理，下载核心文件时极大概率会失败。*

2.  **准备 API Key**：你需要一个有效的 OpenAI 格式的 API Key (`sk-xxxxxxxx`)。

## 2. 安装步骤

### 2.1 运行自动化脚本
假设你已经创建好了 `install_codex.sh` 脚本文件。

1.  **赋予执行权限**：
    ```bash
    chmod +x install_codex.sh
    ```

2.  **执行脚本**：
    ```bash
    ./install_codex.sh
    ```
    * 脚本会自动检测代理状态。
    * 首次运行时，会提示你输入 API Key（输入过程不可见，粘贴后回车即可）。
    * 脚本会自动生成配置文件 `config.toml` 和 `auth.json`。

### 2.2 如果下载失败 (手动上传)
如果脚本提示 **Download Failed** (通常是因为 GitHub 连接被重置)，请按照脚本报错提示进行**离线安装**：

1.  **在本地电脑下载**：
    * 下载文件名：`codex-x86_64-unknown-linux-musl.tar.gz`
    * 下载地址：请参考脚本中提示的 Release 链接。

2.  **上传到服务器**：
    在**本地电脑**的终端执行 SCP 命令（将 `<用户名>` 和 `<IP>` 替换为实际值）：
    ```bash
    scp -P 22 codex-x86_64-unknown-linux-musl.tar.gz <用户名>@<服务器IP>:~/.local/bin/codex.tar.gz
    ```

3.  **重新运行脚本**：
    上传完成后，再次执行 `./install_codex.sh`，脚本会自动识别本地文件并完成解压和配置。

## 3. 配置文件管理

安装完成后，配置文件位于 `~/.codex/` 目录下：

* **核心配置** (`config.toml`):
    包含模型 (`gpt-5-codex`) 和 API Endpoint (`tabcode`) 的定义。
    *路径*: `~/.codex/config.toml`

* **密钥配置** (`auth.json`):
    存储你的 API Key。
    *路径*: `~/.codex/auth.json`
    
    **如何修改 Key**:
    ```bash
    nano ~/.codex/auth.json
    ```
    内容格式：
    ```json
    { "OPENAI_API_KEY": "你的新Key" }
    ```

## 4. 验证与使用

1.  **验证安装**：
    ```bash
    codex --version
    ```

2.  **初始化项目**：
    进入任意代码目录，运行：
    ```bash
    codex
    ```

## 5. 常见问题

* **Q: 提示 `codex: command not found`?**
    * A: 请确保 `~/.local/bin` 在你的 PATH 环境变量中。执行 `source ~/.bashrc` 刷新环境，或检查 `.bashrc` 中是否有 `export PATH=$HOME/.local/bin:$PATH`。

* **Q: 运行 codex 报错连接超时?**
    * A: 请检查是否开启了 `proxyon`，或者检查 `config.toml` 中的 `base_url` 是否正确。
