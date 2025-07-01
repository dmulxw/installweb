# Nginx 自动安装脚本使用指南

## 📦 脚本介绍

提供了三个不同级别的 Nginx 安装脚本：

1. **`nginx_auto_install.sh`** - 全功能版，生产环境推荐
2. **`nginx_install.sh`** - 标准版，平衡功能与简易性
3. **`nginx_quick_install.sh`** - 极简版，快速部署

## 🚀 快速开始

### 方法一：极简安装（最简单）

```bash
# 一键快速安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash

# 带域名一键安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash -s your-domain.com
```

### 方法二：全功能安装（生产环境）

```bash
# 下载全功能脚本
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_auto_install.sh

# 基础安装
sudo bash nginx_auto_install.sh

# 带域名安装
sudo bash nginx_auto_install.sh --domain your-domain.com

# 完整安装（含SSL工具）
sudo bash nginx_auto_install.sh --full --domain your-domain.com --email admin@your-domain.com

# 交互模式
sudo bash nginx_auto_install.sh --interactive
```

### 方法三：标准安装

```bash
# 下载标准脚本
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_install.sh

# 基本安装
sudo bash nginx_install.sh

# 带域名和自定义目录
sudo bash nginx_install.sh your-domain.com /var/www/custom
```

## 📋 功能对比

| 功能 | 极简版 | 标准版 | 全功能版 |
|------|-------|-------|----------|
| 自动系统检测 | ✅ | ✅ | ✅ |
| 安装 Nginx | ✅ | ✅ | ✅ |
| 基本安全配置 | ✅ | ✅ | ✅ |
| 防火墙配置 | ✅ | ✅ | ✅ |
| 性能优化 | ❌ | ✅ | ✅ |
| Certbot SSL | ❌ | ❌ | ✅ |
| 交互式安装 | ❌ | ❌ | ✅ |
| 自动SSL申请 | ❌ | ❌ | ✅ |
| 命令行参数 | 域名 | 域名+目录 | 全参数 |
| 配置优化 | ❌ | ✅ | ✅ |
| 详细帮助 | ❌ | ❌ | ✅ |

## 🔧 脚本详细说明

### nginx_auto_install.sh (全功能版)

#### 支持的系统
- Ubuntu ≥ 20.04
- Debian ≥ 10
- CentOS 8+
- Rocky Linux
- AlmaLinux

#### 命令行参数
```bash
-h, --help              显示帮助信息
-d, --domain DOMAIN     创建指定域名的虚拟主机
-e, --email EMAIL       SSL证书邮箱地址
-f, --full              完整安装(包含certbot等工具)
-i, --interactive       交互模式
-s, --sample            创建示例站点
--no-optimize           跳过配置优化
```

#### 使用示例
```bash
# 基础安装
sudo bash nginx_auto_install.sh

# 完整安装带域名
sudo bash nginx_auto_install.sh --domain example.com --email admin@example.com --full

# 交互模式
sudo bash nginx_auto_install.sh --interactive
```

#### 自动配置功能
- ✅ CPU核心数优化
- ✅ Gzip 压缩优化
- ✅ 安全头配置
- ✅ 性能调优
- ✅ 防火墙自动配置
- ✅ SSL证书自动申请
- ✅ 域名解析检查

### nginx_install.sh (标准版)

#### 特点
- 平衡功能与简易性
- 支持自定义网站目录
- 基础性能优化
- 交互式选择

#### 使用示例
```bash
# 基本安装
sudo bash nginx_install.sh

# 带域名
sudo bash nginx_install.sh example.com

# 自定义目录
sudo bash nginx_install.sh example.com /var/www/custom
```

### nginx_quick_install.sh (极简版)

#### 特点
- 快速一键安装
- 最少的用户交互
- 自动检测系统
- 基础配置即用

#### 使用示例
```bash
# 快速安装
sudo bash nginx_quick_install.sh

# 带域名快速安装
sudo bash nginx_quick_install.sh example.com
```

## 🎯 脚本选择建议

### 什么时候选择极简版 (nginx_quick_install.sh)
✅ **适合以下情况**:
- 快速搭建测试环境
- 个人项目快速部署
- 只需要基础的 HTTP 服务
- 不需要复杂配置
- 追求最快的安装速度

❌ **不适合以下情况**:
- 生产环境部署
- 需要SSL证书的网站
- 需要性能调优的高流量网站

### 什么时候选择标准版 (nginx_install.sh)
✅ **适合以下情况**:
- 中小型网站部署
- 需要一定的自定义配置
- 开发环境搭建
- 需要指定网站目录

❌ **不适合以下情况**:
- 需要自动SSL证书申请
- 需要企业级安全配置
- 大型生产环境

### 什么时候选择全功能版 (nginx_auto_install.sh)
✅ **适合以下情况**:
- 🏢 生产环境部署
- 🔒 需要SSL证书的网站
- 📈 高性能要求的网站
- 🔧 需要详细配置控制
- 🛡️ 需要企业级安全设置
- 🤖 需要自动化证书管理

❌ **不适合以下情况**:
- 快速测试
- 简单的静态网站托管

### 📊 选择流程图

```
开始部署 Nginx
     │
     ▼
   是生产环境？
   ├─ 是 ──→ nginx_auto_install.sh (全功能版)
   │
   └─ 否 ──→ 需要自定义配置？
            ├─ 是 ──→ nginx_install.sh (标准版)
            │
            └─ 否 ──→ nginx_quick_install.sh (极简版)
```

### 💡 推荐搭配使用

1. **开发阶段**: 使用极简版快速搭建 → `nginx_quick_install.sh`
2. **测试阶段**: 使用标准版完善配置 → `nginx_install.sh`
3. **生产阶段**: 使用全功能版上线 → `nginx_auto_install.sh`

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

## 🔍 常见问题排查

### Q1: 脚本执行时提示权限不足
```bash
# 解决方案：使用 sudo 权限执行
sudo bash nginx_auto_install.sh
```

### Q2: 系统不被支持的错误
```bash
# 检查系统版本
cat /etc/os-release

# 手动安装依赖
# Ubuntu/Debian:
sudo apt-get update && sudo apt-get install -y nginx

# CentOS/RHEL:
sudo yum install -y epel-release nginx
```

### Q3: 防火墙阻止访问
```bash
# Ubuntu (UFW)
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# CentOS (Firewalld)
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 检查 SELinux (CentOS)
sudo setsebool -P httpd_can_network_connect 1
```

### Q4: SSL 证书申请失败
```bash
# 检查域名解析
dig +short your-domain.com

# 手动申请证书
sudo certbot --nginx -d your-domain.com

# 检查 certbot 服务
sudo systemctl status certbot.timer
```

### Q5: Nginx 启动失败
```bash
# 查看详细错误
sudo journalctl -u nginx -f

# 检查配置文件
sudo nginx -t

# 检查端口占用
sudo netstat -tlnp | grep :80
```

## 🚀 进阶配置示例

### 高性能站点配置
```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/example.com;
    
    # 启用 HTTP/2
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # 性能优化
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        access_log off;
    }
    
    # Gzip 压缩
    location ~* \.(js|css|html|xml)$ {
        gzip on;
        gzip_comp_level 6;
        gzip_vary on;
    }
    
    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
}
```

### 反向代理配置
```nginx
upstream backend {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name api.example.com;
    
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 负载均衡配置
```nginx
upstream web_servers {
    least_conn;
    server 192.168.1.100:80 weight=3;
    server 192.168.1.101:80 weight=2;
    server 192.168.1.102:80 backup;
}

server {
    listen 80;
    server_name load-balanced.example.com;
    
    location / {
        proxy_pass http://web_servers;
        health_check;
    }
}
```

## 📊 监控和维护

### 日志分析
```bash
# 实时监控访问日志
sudo tail -f /var/log/nginx/access.log

# 分析访问统计
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# 错误日志监控
sudo tail -f /var/log/nginx/error.log
```

### 性能监控
```bash
# 检查 Nginx 进程
ps aux | grep nginx

# 检查连接数
ss -tuln | grep :80

# 检查内存使用
free -h

# 检查磁盘空间
df -h
```

### 自动更新脚本
```bash
#!/bin/bash
# auto-update-nginx.sh

# 更新系统包
sudo apt-get update -y

# 检查 Nginx 更新
if [ "$(apt list --upgradable 2>/dev/null | grep nginx)" ]; then
    echo "发现 Nginx 更新，开始升级..."
    sudo apt-get upgrade nginx -y
    sudo systemctl reload nginx
    echo "Nginx 已更新并重载配置"
else
    echo "Nginx 已是最新版本"
fi

# 检查 SSL 证书
sudo certbot renew --dry-run
```

## 🎯 部署检查清单

### 安装后检查
- [ ] Nginx 服务正常运行 (`systemctl status nginx`)
- [ ] 配置文件语法正确 (`nginx -t`)
- [ ] 防火墙规则已配置
- [ ] 域名解析正确
- [ ] SSL 证书有效（如适用）
- [ ] 网站可正常访问
- [ ] 日志文件权限正确

### 安全检查
- [ ] 移除不必要的默认配置
- [ ] 配置安全头
- [ ] 禁用服务器版本显示
- [ ] 配置访问限制
- [ ] 设置适当的文件权限
- [ ] 启用 HTTPS 重定向

### 性能检查
- [ ] 启用 Gzip 压缩
- [ ] 配置静态文件缓存
- [ ] 优化 worker 进程数
- [ ] 设置合适的连接超时
- [ ] 配置日志轮转

---

**提示**: 这三个安装脚本可以满足从开发测试到生产部署的各种需求。选择合适的脚本，让 Nginx 部署变得简单高效！

📧 **技术支持**: 如有问题，请查看错误日志并参考上述排查步骤。
