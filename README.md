# HAH DApp 网站一键部署脚本

自动部署预编译的前端静态站点，支持自动安装 nginx + certbot，配置虚拟主机与 SSL 证书。

## 一键执行

```bash
curl -fsSL https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh | sudo bash
```

## 支持系统

- Ubuntu ≥20.04
- Debian ≥10
- CentOS 8
- Rocky Linux
- AlmaLinux

## 功能特性

- 🚀 一键部署前端静态站点
- 🔧 自动安装并配置 nginx
- 🔒 自动申请 Let's Encrypt SSL 证书
- 📦 从 GitHub Releases 下载预构建文件
- ✅ 支持域名解析验证

## 使用方法

### 方法一：一键执行（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh | sudo bash
```

### 方法二：带参数执行
```bash
sudo bash installweb.sh domain.com email@example.com
```

### 方法三：下载后执行
```bash
wget https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh
sudo bash installweb.sh
```

## 注意事项

- 需要以 root 或 sudo 权限运行
- 确保域名已正确解析到服务器 IP
- 脚本会自动检测系统发行版并安装相应依赖
