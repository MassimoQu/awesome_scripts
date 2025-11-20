# Server Proxy Setup Guide (Anti-GFW Edition)

这份文档记录了在 Linux 服务器（Ubuntu 18.04+）上，在**没有 sudo 权限**且**无法连接 GitHub** 的恶劣网络环境下，配置 Clash Meta (Mihomo) 代理服务的完整流程。

此方案包含一个**智能容错脚本**，当服务器无法下载文件时，会提示你如何从本地上传，并支持“断点续传”。

## 1. 环境信息
* **核心程序**: Clash Meta (Mihomo) v1.18.1
* **安装目录**: `~/.local/bin`
* **配置目录**: `~/.config/mihomo`
* **监听端口**: `57890`
* **密钥 (Secret)**: `qu523`

## 2. 智能安装脚本

在服务器上创建安装脚本：
```bash
nano setup_clash.sh
```

## 3. 使用流程
### 第一阶段：尝试一键运行
在服务器执行：

```bash
chmod +x setup_clash.sh
./setup_clash.sh
```

### 第二阶段：如果脚本报错（GitHub 被墙）
如果脚本提示红色错误，请按照脚本打印出的提示，在本地电脑执行 SCP 上传。

#### 场景 A：核心文件下载失败 脚本会提示你上传 clash.gz。

1. 本地下载：[Mihomo Release](https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-amd64-v1.18.1.gz)
2. 本地上传：
```bash
scp -P 22 mihomo-linux-amd64-v1.18.1.gz qqxluca@183.173.81.138:~/.local/bin/clash.gz
```
3. 重新运行脚本：./setup_clash.sh（脚本会自动识别文件并完成安装）。

## 场景 B：订阅下载失败 脚本会提示你上传 config.yaml。

1. 本地导出 Clash Verge 的配置为 `config.yaml`。
2. 本地上传：
```bash
scp -P 22 config.yaml qqxluca@183.173.81.138:~/.config/mihomo/config.yaml
```
3. 重新运行脚本。

4. 常用命令
安装成功后，务必先执行 `source ~/.bashrc`。
* `proxyon` : 开启代理（终端翻墙）
* `proxyoff`: 关闭代理
* `tail -f ~/.config/mihomo/clash.log`: 查看日志排错
