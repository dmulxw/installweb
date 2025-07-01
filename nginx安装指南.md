# Nginx 自动安装脚本使用指南

## 📦 脚本介绍

提供了两个 Nginx 安装脚本：

1. **`nginx_install.sh`** - 完整版，功能丰富
2. **`nginx_quick_install.sh`** - 快速版，简单易用

## 🚀 快速开始

### 方法一：快速安装（推荐）

```bash
# 下载并执行快速安装脚本
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash

# 或者带域名安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash -s your-domain.com
```

### 方法二：完整安装

```bash
# 下载脚本
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_install.sh

# 基本安装
sudo bash nginx_install.sh

# 带域名安装
sudo bash nginx_install.sh your-domain.com

# 自定义网站目录
sudo bash nginx_install.sh your-domain.com /var/www/custom
```

## 📋 功能对比

| 功能 | 快速版 | 完整版 |
|------|-------|-------|
| 自动系统检测 | ✅ | ✅ |
| 安装 Nginx | ✅ | ✅ |
| 基本安全配置 | ✅ | ✅ |
| 性能优化 | ❌ | ✅ |
| 详细配置 | ❌ | ✅ |
| 交互式安装 | ❌ | ✅ |
| 自定义网站目录 | ❌ | ✅ |
| 详细日志配置 | ❌ | ✅ |
| 美观的默认页面 | ✅ | ✅ |

## 🔧 完整版功能详解

### 1. 系统支持
- Ubuntu ≥ 20.04
- Debian ≥ 10
- CentOS 8
- Rocky Linux
- AlmaLinux

### 2. 自动配置
- ✅ 性能优化设置
- ✅ Gzip 压缩
- ✅ 安全头配置
- ✅ 缓存配置
- ✅ 防火墙配置

### 3. 站点管理
- 自动创建虚拟主机
- 独立的访问和错误日志
- SSL 证书支持准备
- 自定义网站目录

## 📝 使用示例

### 基本安装
```bash
# 仅安装 Nginx，使用默认配置
sudo bash nginx_install.sh
```

### 创建单个站点
```bash
# 为 example.com 创建站点
sudo bash nginx_install.sh example.com

# 自定义网站目录
sudo bash nginx_install.sh example.com /home/user/website
```

### 交互式安装
```bash
# 运行脚本后选择安装模式
sudo bash nginx_install.sh

# 会提示选择：
# 1. 仅安装 Nginx
# 2. 安装并配置域名
```

### 快速版安装
```bash
# 基本安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash

# 带域名
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash -s example.com
```

## 📁 安装后的目录结构

```
/etc/nginx/
├── nginx.conf              # 主配置文件
├── nginx.conf.backup.*     # 备份文件
└── conf.d/
    ├── default.conf        # 默认站点
    └── example.com.conf    # 域名站点配置

/var/www/
├── html/                   # 默认网站目录
│   └── index.html
└── example.com/            # 域名网站目录
    └── index.html

/var/log/nginx/
├── access.log              # 全局访问日志
├── error.log               # 全局错误日志
├── example.com.access.log  # 站点访问日志
└── example.com.error.log   # 站点错误日志
```

## ⚙️ 常用管理命令

### 服务管理
```bash
# 启动服务
systemctl start nginx

# 停止服务
systemctl stop nginx

# 重启服务
systemctl restart nginx

# 重载配置（无停机）
systemctl reload nginx

# 查看状态
systemctl status nginx

# 开机自启
systemctl enable nginx
```

### 配置管理
```bash
# 测试配置文件
nginx -t

# 查看配置文件路径
nginx -T

# 查看版本
nginx -v
```

### 日志管理
```bash
# 查看访问日志
tail -f /var/log/nginx/access.log

# 查看错误日志
tail -f /var/log/nginx/error.log

# 查看特定站点日志
tail -f /var/log/nginx/example.com.access.log
```

## 🔒 SSL 证书配置

### 使用 Let's Encrypt
```bash
# 为域名申请证书
certbot --nginx -d example.com

# 为多个域名申请证书
certbot --nginx -d example.com -d www.example.com

# 自动续期测试
certbot renew --dry-run
```

### 手动证书配置
如果您有自己的证书文件：
```bash
# 编辑站点配置
nano /etc/nginx/conf.d/example.com.conf

# 添加 SSL 配置
server {
    listen 443 ssl;
    server_name example.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # 其他配置...
}
```

## 🛠️ 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 检查端口占用
netstat -tlnp | grep :80

# 停止占用端口的服务
systemctl stop apache2  # 如果是 Apache
```

#### 2. 配置文件错误
```bash
# 检查配置语法
nginx -t

# 查看详细错误
nginx -t -c /etc/nginx/nginx.conf
```

#### 3. 权限问题
```bash
# 设置正确的文件权限
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html
```

#### 4. SELinux 问题（CentOS/RHEL）
```bash
# 临时禁用 SELinux
setenforce 0

# 永久禁用（重启后生效）
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
```

### 查看日志
```bash
# 系统日志
journalctl -u nginx -f

# Nginx 错误日志
tail -f /var/log/nginx/error.log

# 检查配置文件位置
nginx -t
```

## 🔧 自定义配置

### 添加新站点
```bash
# 创建配置文件
sudo nano /etc/nginx/conf.d/newsite.com.conf

# 基本站点配置模板
server {
    listen 80;
    server_name newsite.com www.newsite.com;
    root /var/www/newsite.com;
    index index.html index.php;

    location / {
        try_files $uri $uri/ =404;
    }
}

# 创建网站目录
sudo mkdir -p /var/www/newsite.com
sudo chown nginx:nginx /var/www/newsite.com

# 测试并重载配置
sudo nginx -t && sudo systemctl reload nginx
```

### 性能调优
```bash
# 编辑主配置文件
sudo nano /etc/nginx/nginx.conf

# 关键配置项
worker_processes auto;          # CPU 核心数
worker_connections 1024;       # 每个进程连接数
keepalive_timeout 65;          # 连接保持时间
client_max_body_size 100M;     # 最大上传文件大小
```

## 🎯 最佳实践

1. **定期备份配置文件**
2. **使用版本控制管理配置**
3. **定期更新 Nginx 版本**
4. **配置日志轮转**
5. **监控服务器性能**
6. **定期检查 SSL 证书有效期**

## 📞 技术支持

如果遇到问题：
1. 查看 `/var/log/nginx/error.log` 错误日志
2. 运行 `nginx -t` 检查配置
3. 检查防火墙和 SELinux 设置
4. 确认域名 DNS 解析正确

使用这些脚本可以快速部署生产就绪的 Nginx 服务器！
