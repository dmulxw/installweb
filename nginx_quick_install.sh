#!/usr/bin/env bash
# =========================================================
# Nginx 快速安装脚本 (简化版)
# · 一键安装和配置 Nginx
# · 自动配置基本安全设置
# · 支持直接创建站点
# =========================================================
set -e

# 颜色
G='\033[1;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${G}[INFO] $*${NC}"; }
warn(){ echo -e "${Y}[WARN] $*${NC}"; }
die(){ echo -e "${R}[ERROR] $*${NC}"; exit 1; }

[[ $EUID -ne 0 ]] && die "需要 root 权限"

# 检测系统
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian) PKG="apt-get" ;;
    centos|rhel|rocky|almalinux) PKG="yum" ;;
    *) die "不支持的系统: $ID" ;;
  esac
else
  die "无法识别系统"
fi

# 安装
info "安装 Nginx..."
if [[ $PKG == "apt-get" ]]; then
  apt-get update -y >/dev/null 2>&1
  apt-get install -y nginx certbot python3-certbot-nginx
elif [[ $PKG == "yum" ]]; then
  yum install -y epel-release >/dev/null 2>&1
  yum install -y nginx certbot python3-certbot-nginx
fi

# 启动
info "启动 Nginx..."
systemctl enable --now nginx

# 基本配置
info "配置 Nginx..."
cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    server_tokens off;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# 创建默认页面
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>Nginx 运行中</title>
<style>body{font-family:Arial;text-align:center;margin:50px;background:#f5f5f5}
.box{background:white;padding:30px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1);display:inline-block}
h1{color:#27ae60}</style></head>
<body><div class="box"><h1>🎉 Nginx 安装成功!</h1><p>服务器正在运行</p></div></body></html>
EOF

# 测试配置
nginx -t && systemctl reload nginx

# 获取IP
IP=$(curl -s ifconfig.me 2>/dev/null || echo "SERVER_IP")

# 完成信息
echo
info "🎉 安装完成!"
echo -e "${G}访问地址: http://$IP${NC}"
echo -e "${G}配置文件: /etc/nginx/nginx.conf${NC}"
echo -e "${G}网站目录: /var/www/html${NC}"
echo
info "常用命令:"
echo "  systemctl restart nginx  # 重启"
echo "  systemctl reload nginx   # 重载配置"
echo "  nginx -t                 # 测试配置"

# 如果提供了域名参数
if [[ $# -gt 0 ]]; then
  DOMAIN="$1"
  WEBROOT="/var/www/$DOMAIN"
  
  info "创建站点: $DOMAIN"
  mkdir -p "$WEBROOT"
  
  cat > "/etc/nginx/conf.d/${DOMAIN}.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

  cat > "$WEBROOT/index.html" << EOF
<!DOCTYPE html>
<html><head><title>$DOMAIN</title>
<style>body{font-family:Arial;text-align:center;margin:50px;background:#f8f9fa}
.box{background:white;padding:40px;border-radius:10px;box-shadow:0 4px 20px rgba(0,0,0,0.1);display:inline-block}
h1{color:#2c3e50}.domain{color:#e74c3c}</style></head>
<body><div class="box"><h1>🌐 <span class="domain">$DOMAIN</span></h1><p>站点配置成功!</p></div></body></html>
EOF

  nginx -t && systemctl reload nginx
  
  echo
  info "站点 $DOMAIN 已创建"
  echo -e "${G}访问地址: http://$DOMAIN${NC}"
  echo -e "${G}网站目录: $WEBROOT${NC}"
  echo -e "${G}SSL配置: certbot --nginx -d $DOMAIN${NC}"
fi
