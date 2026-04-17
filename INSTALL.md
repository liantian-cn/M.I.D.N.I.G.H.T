# 安装 M.I.D.N.I.G.H.T

此文档介绍如何安装 M.I.D.N.I.G.H.T 项目，不仅要安装程序本身，还要安装完整开发环境。

## 先决条件

- Python 3.12.10
- uv
- Git
- vscode
- vscode插件
- nvm
- nodejs
- wow-api-mcp
- 定位《魔兽世界》正式服客户端

### Python 3.12.10

- 检测：如果`python -V`提示已安装3.12以上版本，本环节跳过。
- 下载：`https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe`
- 安装：`python-3.12.10-amd64.exe /passive InstallAllUsers=0 PrependPath=1`

### uv

- 执行

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
uv python pin 3.12.10
```

### Git

- 检测：如果`git --version`提示已安装任意版本，本环节跳过。
- 下载`https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.2/Git-2.53.0.2-64-bit.exe`
- 安装

### vscode

- 检测：如果`code --version`提示大于`1.116`版本，本环节跳过。
- 下载`https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user`并安装

### vscode插件

- 执行`code --install-extension ketho.wow-api`安装

### nvm

- 下载`https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-setup.exe`并安装
- 配置源：

```bash
export NVM_NODEJS_ORG_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
```

### node

执行：

```cmd
nvm install lts
nvm use lts
```

### wow-api-mcp

```cmd
npm -g install wow-api-mcp@latest

```

### 定位《魔兽世界》正式服客户端

- 检查注册表`HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Blizzard Entertainment\World of Warcraft` KEY为 InstallPath
- 路径应该是 `X:\Path_to_WOW\_retail_\`

## 安装 MIDNIGHT

### 从github克隆 M.I.D.N.I.G.H.T repo

- 最好clone到和魔兽世界相同的盘符，便于后续更新。
- `git clone https://github.com/liantian-cn/M.I.D.N.I.G.H.T.git X:\MIDNIGHT`

### 安装Terminal组件的依赖

- `cd X:\MIDNIGHT\Terminal`
- `uv sync`
- 验证，执行`python main.py`

### 复制DejaVu组件到游戏插件目录

- 安装：若《魔兽世界》正式服客户端的安装路径是`X:\Path_to_WOW\_retail_\`，则插件路径是`X:\Path_to_WOW\_retail_\Interface\AddOns\`。
- 如果魔兽世界目录和相同盘符，则创建`DejaVu`目录下每个`DejaVu_`开头的子目录，符号链接到``X:\Path_to_WOW\_retail_\Interface\AddOns\`，比如 `New-Item -ItemType SymbolicLink -Path "X:\World of Warcraft\_retail_\Interface\AddOns\DejaVu_DruidGuardian" -Target "X:\MIDNIGHT\DejaVu\DejaVu_DruidGuardian"`
- 验证：检测`X:\Path_to_WOW\_retail_\Interface\AddOns\DejaVu_Core\DejaVu_Core.toc`文件是否存在。

## 升级

- 通过git更新M.I.D.N.I.G.H.T repo
- 重新复制DejaVu到插件目录，并覆盖旧文件。
