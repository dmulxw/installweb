#!/usr/bin/env bash
# =========================================================
# Nginx 自动安装脚本
# · 支持 Ubuntu ≥20.04 / Debian ≥10 / CentOS 8 / Rocky / Alma
# · 自动检测系统版本并选择合适的安装方式
# · 支持自定义配置和 SSL 证书
# · 包含基本的安全配置和优化
# 
# 使用方法：
# 1. 基本安装: sudo bash nginx_install.sh
# 2. 带域名配置: sudo bash nginx_install.sh domain.com
# 3. 完整配置: sudo bash nginx_install.sh domain.com /var/www/domain.com
# =========================================================
set -euo pipefail

# ---------- 颜色和函数 ----------
GRN='\033[1;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; BLU='\033[1;34m'; NC='\033[0m'
info(){ echo -e "${GRN}[INFO] $*${NC}"; }
warn(){ echo -e "${YEL}[WARN] $*${NC}"; }
error(){ echo -e "${RED}[ERROR] $*${NC}"; }
title(){ echo -e "${BLU}[NGINX] $*${NC}"; }
die(){ echo -e "${RED}[FATAL] $*${NC}"; exit 1; }

# ---------- 检查权限 ----------
[[ $EUID -ne 0 ]] && die "必须以 root 权限运行此脚本"

# ---------- 系统检测 ----------
detect_system() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        OS_FAMILY="debian"
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        ;;
      centos|rhel|rocky|almalinux)
        OS_FAMILY="rhel"
        OS_NAME="$ID"
        OS_VERSION="$VERSION_ID"
        ;;
      *)
        die "暂不支持的操作系统: $ID"
        ;;
    esac
  else
    die "无法识别操作系统"
  fi
  
  info "检测到系统: $OS_NAME $OS_VERSION"
}

# ---------- 安装 Nginx ----------
install_nginx() {
  title "开始安装 Nginx..."
  
  if [[ $OS_FAMILY == "debian" ]]; then
    info "更新软件包列表..."
    apt-get update -y >/dev/null 2>&1
    
    info "安装 Nginx 和相关工具..."
    apt-get install -y nginx curl wget unzip certbot python3-certbot-nginx
    
  elif [[ $OS_FAMILY == "rhel" ]]; then
    info "安装 EPEL 仓库..."
    if command -v dnf >/dev/null 2>&1; then
      dnf install -y epel-release
      info "安装 Nginx 和相关工具..."
      dnf install -y nginx curl wget unzip certbot python3-certbot-nginx
    else
      yum install -y epel-release
      info "安装 Nginx 和相关工具..."
      yum install -y nginx curl wget unzip certbot python3-certbot-nginx
    fi
  fi
  
  info "✅ Nginx 安装完成"
}

# ---------- 配置 Nginx ----------
configure_nginx() {
  title "配置 Nginx..."
  
  # 备份原配置
  if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    info "已备份原始配置文件"
  fi
  
  # 创建优化的主配置
  cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # 日志格式
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # 性能优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # 安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # 隐藏 Nginx 版本
    server_tokens off;

    # 默认服务器配置
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        root /var/www/html;
        index index.html index.htm;

        location / {
            try_files $uri $uri/ =404;
        }

        location = /favicon.ico {
            log_not_found off;
            access_log off;
        }

        location = /robots.txt {
            log_not_found off;
            access_log off;
        }

        location ~ /\. {
            deny all;
        }
    }

    # 包含其他配置文件
    include /etc/nginx/conf.d/*.conf;
}
EOF

  # 创建默认网页目录
  mkdir -p /var/www/html
  
  # 创建默认主页
  cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Nginx 安装成功</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .status { background: #27ae60; color: white; padding: 15px; border-radius: 5px; text-align: center; margin: 20px 0; }
        .info { background: #3498db; color: white; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; margin-top: 30px; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Nginx 安装成功！</h1>
        <div class="status">
            ✅ Web 服务器正在运行
        </div>
        <div class="info">
            📁 网站根目录: /var/www/html
        </div>
        <div class="info">
            ⚙️ 配置文件: /etc/nginx/nginx.conf
        </div>
        <div class="info">
            📋 虚拟主机: /etc/nginx/conf.d/
        </div>
        <div class="footer">
            <p>您可以开始配置您的网站了！</p>
        </div>
    </div>
</body>
</html>
EOF

  info "✅ Nginx 配置完成"
}

# ---------- 创建站点配置 ----------
create_site_config() {
  local domain="$1"
  local webroot="${2:-/var/www/$domain}"
  
  title "为域名 $domain 创建站点配置..."
  
  # 创建网站目录
  mkdir -p "$webroot"
  
  # 设置权限
  chown -R nginx:nginx "$webroot" 2>/dev/null || chown -R www-data:www-data "$webroot" 2>/dev/null || true
  chmod -R 755 "$webroot"
  
  # 创建站点配置文件
  cat > "/etc/nginx/conf.d/${domain}.conf" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain} www.${domain};
    root ${webroot};
    index index.html index.htm index.php;

    # 访问日志
    access_log /var/log/nginx/${domain}.access.log;
    error_log /var/log/nginx/${domain}.error.log;

    # 主要位置块
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # PHP 支持 (如果需要，取消注释)
    # location ~ \.php$ {
    #     fastcgi_pass unix:/var/run/php/php-fpm.sock;
    #     fastcgi_index index.php;
    #     fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    #     include fastcgi_params;
    # }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|txt)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # 安全配置
    location ~ /\. {
        deny all;
    }

    location ~ ~$ {
        deny all;
    }
}
EOF

  # 创建默认站点页面
  cat > "${webroot}/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${domain} - 站点配置成功</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f8f9fa; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; margin-bottom: 30px; }
        .domain { color: #e74c3c; font-weight: bold; }
        .success { background: #27ae60; color: white; padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 30px 0; }
        .info-card { background: #ecf0f1; padding: 20px; border-radius: 8px; }
        .info-title { font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
        .footer { text-align: center; margin-top: 40px; color: #7f8c8d; border-top: 1px solid #ecf0f1; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 <span class="domain">${domain}</span></h1>
        <div class="success">
            ✅ 站点配置成功！您的网站已准备就绪
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-title">📁 网站目录</div>
                ${webroot}
            </div>
            <div class="info-card">
                <div class="info-title">⚙️ 配置文件</div>
                /etc/nginx/conf.d/${domain}.conf
            </div>
            <div class="info-card">
                <div class="info-title">📊 访问日志</div>
                /var/log/nginx/${domain}.access.log
            </div>
            <div class="info-card">
                <div class="info-title">❌ 错误日志</div>
                /var/log/nginx/${domain}.error.log
            </div>
        </div>
        
        <div class="footer">
            <p>您可以将网站文件上传到 <strong>${webroot}</strong> 目录</p>
            <p>配置 SSL 证书: <code>certbot --nginx -d ${domain}</code></p>
        </div>
    </div>
</body>
</html>
EOF

  info "✅ 站点 $domain 配置完成"
  info "📁 网站目录: $webroot"
  info "⚙️ 配置文件: /etc/nginx/conf.d/${domain}.conf"
}

# ---------- 启动服务 ----------
start_services() {
  title "启动和配置服务..."
  
  # 测试配置
  info "检查 Nginx 配置..."
  if nginx -t; then
    info "✅ Nginx 配置检查通过"
  else
    error "❌ Nginx 配置有误"
    exit 1
  fi
  
  # 启动并设置开机自启
  info "启动 Nginx 服务..."
  systemctl enable nginx
  systemctl start nginx
  
  # 检查状态
  if systemctl is-active --quiet nginx; then
    info "✅ Nginx 服务运行正常"
  else
    error "❌ Nginx 服务启动失败"
    systemctl status nginx
    exit 1
  fi
  
  # 配置防火墙（如果存在）
  if command -v ufw >/dev/null 2>&1; then
    info "配置 UFW 防火墙..."
    ufw allow 'Nginx Full' >/dev/null 2>&1 || true
  elif command -v firewall-cmd >/dev/null 2>&1; then
    info "配置 Firewalld 防火墙..."
    firewall-cmd --permanent --add-service=http >/dev/null 2>&1 || true
    firewall-cmd --permanent --add-service=https >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi
}

# ---------- 显示信息 ----------
show_info() {
  local domain="${1:-}"
  local webroot="${2:-}"
  
  echo
  title "🎉 Nginx 安装完成！"
  echo -e "${GRN}=========================${NC}"
  
  if [[ -n "$domain" ]]; then
    echo -e "🌐 域名: ${BLU}$domain${NC}"
    echo -e "📁 网站目录: ${BLU}$webroot${NC}"
    echo -e "🔗 访问地址: ${BLU}http://$domain${NC}"
    echo -e "⚙️ 配置文件: ${BLU}/etc/nginx/conf.d/${domain}.conf${NC}"
  else
    echo -e "🔗 默认访问: ${BLU}http://$(curl -s ifconfig.me 2>/dev/null || echo 'SERVER_IP')${NC}"
    echo -e "📁 默认目录: ${BLU}/var/www/html${NC}"
  fi
  
  echo -e "⚙️ 主配置文件: ${BLU}/etc/nginx/nginx.conf${NC}"
  echo -e "📊 访问日志: ${BLU}/var/log/nginx/access.log${NC}"
  echo -e "❌ 错误日志: ${BLU}/var/log/nginx/error.log${NC}"
  echo -e "${GRN}=========================${NC}"
  
  echo
  info "常用命令:"
  echo "  重启服务: systemctl restart nginx"
  echo "  重载配置: systemctl reload nginx"
  echo "  查看状态: systemctl status nginx"
  echo "  测试配置: nginx -t"
  
  if [[ -n "$domain" ]]; then
    echo
    info "SSL 证书配置:"
    echo "  certbot --nginx -d $domain"
  fi
  
  echo
  warn "请确保防火墙已开放 80 和 443 端口"
}

# ---------- 主函数 ----------
main() {
  local domain="${1:-}"
  local webroot="${2:-}"
  
  title "Nginx 自动安装脚本启动"
  
  # 系统检测
  detect_system
  
  # 安装 Nginx
  install_nginx
  
  # 配置 Nginx
  configure_nginx
  
  # 如果提供了域名，创建站点配置
  if [[ -n "$domain" ]]; then
    webroot="${webroot:-/var/www/$domain}"
    create_site_config "$domain" "$webroot"
  fi
  
  # 启动服务
  start_services
  
  # 显示信息
  show_info "$domain" "$webroot"
}

# ---------- 参数处理 ----------
if [[ $# -eq 0 ]]; then
  # 无参数，交互式安装
  echo -e "${BLU}Nginx 自动安装脚本${NC}"
  echo "1. 仅安装 Nginx"
  echo "2. 安装并配置域名"
  echo
  read -rp "请选择安装模式 (1-2): " choice
  
  case $choice in
    1)
      main
      ;;
    2)
      read -rp "请输入域名: " domain
      read -rp "请输入网站根目录 (默认: /var/www/$domain): " webroot
      webroot="${webroot:-/var/www/$domain}"
      main "$domain" "$webroot"
      ;;
    *)
      echo "无效选择"
      exit 1
      ;;
  esac
else
  # 有参数，直接安装
  main "$@"
fi
