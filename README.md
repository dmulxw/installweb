# HAH DApp 网站部署指南

## 📦 部署架构

### 构建文件来源
- **主项目**：`dmulxw/hahdapp`（private）- 包含源代码和开发环境
- **部署项目**：`dmulxw/installweb`（public）- 包含部署脚本和预构建文件
- **构建文件**：从 GitHub Releases 下载 `https://github.com/dmulxw/installweb/releases/download/hah/build.zip`

### 优势
- ✅ 源代码保持私有
- ✅ 部署无需构建环境
- ✅ 下载速度更快
- ✅ 减少服务器资源消耗

## 快速部署命令

### ✅ 方法一：命令行参数（推荐，避免交互问题）
```bash
# 基本用法（使用默认 hah 标签和 build.zip）
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh
sudo bash installweb.sh your-domain.com your-email@example.com

# 指定标签和文件
sudo bash installweb.sh your-domain.com your-email@example.com v1.0 frontend.zip

# 使用完整URL
sudo bash installweb.sh your-domain.com your-email@example.com "" "https://example.com/files/app.zip"
```

### 方法二：交互式执行（支持自定义下载）
```bash
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh | sudo bash
```
交互模式中，您可以：
- 输入自定义的 GitHub Release 标签
- 指定要下载的文件名
- 在下载前确认或修改下载地址

### 方法三：分步执行
```bash
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh
chmod +x installweb.sh
sudo ./installweb.sh
```

## 📦 自定义下载文件

### 支持的文件来源
1. **GitHub Releases**（默认）
   - 标准格式：`https://github.com/dmulxw/installweb/releases/download/{TAG}/{FILE}`
   - 简化格式：`{TAG}/{FILE}` （如：`v1.0/build.zip`）
   - 文件名格式：`{FILE}` （使用指定的tag）

2. **自定义URL**
   - 任何可访问的 `.zip` 文件URL
   - 支持其他 CDN 或服务器

### 参数说明
- **tag**：GitHub Release 标签名（默认：`hah`）
- **zipfile**：文件路径，支持多种格式：
  - `build.zip` - 使用指定tag的文件
  - `v1.0/build.zip` - 自动解析tag和文件名
  - `https://...` - 完整URL

### 使用示例
```bash
# 使用默认设置 (hah 标签下的 build.zip)
sudo bash installweb.sh domain.com email@example.com

# 指定不同的标签和文件
sudo bash installweb.sh domain.com email@example.com v1.0 frontend.zip

# 使用 tag/file 格式（自动解析）
sudo bash installweb.sh domain.com email@example.com "" "v2.0/build.zip"
sudo bash installweb.sh domain.com email@example.com "" "latest/app.zip"

# 使用完整的自定义URL
sudo bash installweb.sh domain.com email@example.com "" "https://cdn.example.com/releases/app.zip"
```

### 路径解析规则
- **`build.zip`** → 使用指定tag下的文件：`https://github.com/dmulxw/installweb/releases/download/hah/build.zip`
- **`v1.0/build.zip`** → 自动解析为：`https://github.com/dmulxw/installweb/releases/download/v1.0/build.zip`
- **`latest/frontend.zip`** → 自动解析为：`https://github.com/dmulxw/installweb/releases/download/latest/frontend.zip`
- **`https://...`** → 直接使用完整URL

## 解决的问题

### ❌ 之前的错误
```bash
# 错误：语法不正确
https://raw.githubusercontent.com/dmulxw/hahdapp/installweb.sh | sudo bash

# 错误：变量未定义
bash: line 35: EMAIL: unbound variable
```

### ✅ 现在的解决方案
1. **支持命令行参数**：避免交互式输入问题
2. **修复管道执行**：正确处理标准输入重定向
3. **变量安全检查**：使用 `${VAR:-}` 语法避免 unbound variable 错误

## 部署要求

### 1. GitHub 仓库要求
- ✅ 部署仓库 `dmulxw/installweb` 必须是 **public**
- ✅ 包含 `installweb.sh` 部署脚本
- ✅ 在 Releases 中包含 `build.zip` 预构建文件
- ✅ 主项目可以保持 **private**

### 2. 服务器要求
- ✅ 支持的操作系统：
  - Ubuntu ≥ 20.04
  - Debian ≥ 10
  - CentOS 8 / Rocky Linux / AlmaLinux
- ✅ 需要 root 权限
- ✅ 服务器需要公网 IP

### 3. 域名要求
- ✅ 域名已解析到服务器公网 IP
- ✅ 准备好 Let's Encrypt 证书申请邮箱

## 部署过程

脚本将自动完成以下步骤：

1. **系统检查**：检测操作系统类型
2. **域名验证**：验证域名是否正确解析到服务器
3. **依赖安装**：安装 nginx, certbot（不再需要 git, nodejs）
4. **前端部署**：
   - 从 GitHub Releases 下载预构建的 build.zip 文件
   - 解压并部署到 nginx 网站目录
   - 无需本地构建，节省时间和资源
5. **SSL 配置**：自动申请和配置 Let's Encrypt 证书
6. **服务启动**：启动并配置 nginx 服务

## 故障排除

### 常见错误

### 常见错误

#### 1. "No such file or directory"
```bash
# ❌ 错误命令（缺少下载工具）
https://raw.githubusercontent.com/dmulxw/hahdapp/installweb.sh | sudo bash

# ✅ 正确命令
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh | sudo bash
```

#### 2. "EMAIL: unbound variable"
```bash
# ❌ 问题：通过管道执行时交互式输入失败
curl ... | sudo bash

# ✅ 解决方案1：使用命令行参数（推荐）
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh
sudo bash installweb.sh your-domain.com your-email@example.com

# ✅ 解决方案2：下载后交互式执行
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/installweb.sh
sudo bash installweb.sh
```

#### 2. "仓库是私有的"
确保 GitHub 仓库设置为 public：
- 进入仓库设置 → Settings
- 滚动到 Danger Zone
- 点击 "Change repository visibility" → "Make public"

#### 3. "下载构建文件失败"
检查网络连接和文件是否存在：
```bash
# 测试下载链接
curl -I https://github.com/dmulxw/installweb/releases/download/hah/build.zip

# 检查 GitHub Releases 页面
https://github.com/dmulxw/installweb/releases/tag/hah
```

#### 4. "域名解析错误"
检查域名 DNS 设置：
```bash
# 检查域名解析
dig +short your-domain.com

# 检查服务器公网 IP
curl ifconfig.me
```

#### 5. "前端构建失败"
由于现在使用预构建文件，此问题已不存在。如果需要重新构建：
```bash
# 在开发环境中构建
cd your-local-project/frontend
npm install && npm run build

# 将 build 目录打包上传到 GitHub Releases
zip -r build.zip build/*
```

### 手动部署（备选方案）

如果自动脚本失败，可以手动执行：

```bash
# 1. 安装依赖
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx curl unzip

# 2. 下载预构建文件
mkdir -p /opt/hahdapp_web
cd /opt/hahdapp_web
curl -L https://github.com/dmulxw/installweb/releases/download/hah/build.zip -o build.zip
unzip build.zip

# 3. 部署到 nginx
mkdir -p /var/www/your-domain.com
cp -r build/* /var/www/your-domain.com/

# 4. 配置 nginx 和 SSL
# 参考脚本中的 nginx 配置部分
```

## 验证部署

部署完成后，通过以下方式验证：

1. **访问网站**：`https://your-domain.com`
2. **检查服务状态**：
   ```bash
   systemctl status nginx
   certbot certificates
   ```
3. **查看日志**：
   ```bash
   tail -f /var/log/nginx/access.log
   tail -f /var/log/nginx/error.log
   ```

## 技术支持

如遇问题，请检查：
- 服务器防火墙设置（开放 80, 443 端口）
- 域名 DNS 解析是否正确
- GitHub 仓库是否为 public
- 服务器是否有足够的磁盘空间

联系信息：请在 GitHub 仓库提交 issue

## 🔄 更新构建文件

当前端代码有更新时，需要重新生成并上传 build.zip：

### 1. 本地构建
```bash
# 在主项目中构建前端
cd your-project/frontend
npm install
npm run build

# 打包构建文件
cd build
zip -r ../build.zip .
```

### 2. 上传到 GitHub Releases
1. 进入 `dmulxw/installweb` 仓库
2. 点击 "Releases" → "Edit" hah 标签
3. 删除旧的 `build.zip` 文件
4. 上传新的 `build.zip` 文件
5. 保存更新

### 3. 验证更新
```bash
# 测试新的下载链接
curl -I https://github.com/dmulxw/installweb/releases/download/hah/build.zip
```
