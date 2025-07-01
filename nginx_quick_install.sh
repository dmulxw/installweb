#!/usr/bin/env bash
# =========================================================
# Nginx 快速安装脚本 (极简版)
# · 支持 Ubuntu/Debian/CentOS/Rocky/Alma 系统
# · 一键安装 nginx + 基础配置 + 防火墙设置
# · 可选直接创建站点配置
#
# 使用方法：
# 1. 快速安装: sudo bash nginx_quick_install.sh
# 2. 带域名安装: sudo bash nginx_quick_install.sh example.com
# =========================================================

set -euo pipefail

# 颜色定义
GRN='\033[1;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${GRN}[INFO] $*${NC}"; }
warn(){ echo -e "${YEL}[WARN] $*${NC}"; }
die(){  echo -e "${RED}[ERR]  $*${NC}"; exit 1; }

# 检查权限
[[ $EUID -ne 0 ]] && die "需要 root 权限，请使用 sudo 运行"

# 获取域名参数
DOMAIN="${1:-}"

info "🚀 开始快速安装 Nginx..."

# 系统检测
if command -v apt-get >/dev/null 2>&1; then
    info "📦 检测到 Debian/Ubuntu 系统，开始安装..."
    apt-get update -q
    apt-get install -y nginx
    WEBUSER="www-data"
elif command -v dnf >/dev/null 2>&1; then
    info "📦 检测到 RHEL/Fedora 系统，开始安装..."
    dnf install -y epel-release
    dnf install -y nginx
    WEBUSER="nginx"
elif command -v yum >/dev/null 2>&1; then
    info "📦 检测到 CentOS 系统，开始安装..."
    yum install -y epel-release
    yum install -y nginx
    WEBUSER="nginx"
else
    die "不支持的系统，请手动安装 nginx"
fi

# 启动服务
info "🚀 启动 Nginx 服务..."
systemctl enable nginx
systemctl start nginx

# 防火墙配置
info "🔥 配置防火墙..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

# 创建站点配置（如果提供了域名）
if [[ -n "$DOMAIN" ]]; then
    info "🌐 创建站点配置: $DOMAIN"
    
    # 创建网站目录
    WEBROOT="/var/www/$DOMAIN"
    mkdir -p "$WEBROOT"
    
    # 创建简单的测试页面
    cat > "$WEBROOT/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$DOMAIN - Nginx Running</title>
    <style>
        body { font-family: Arial; text-align: center; margin: 50px; }
        h1 { color: #2E8B57; }
        .info { background: #f5f5f5; padding: 20px; margin: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🎉 Nginx 安装成功！</h1>
    <h2>域名: $DOMAIN</h2>
    <div class="info">
        <p>网站根目录: $WEBROOT</p>
        <p>安装时间: $(date)</p>
    </div>
</body>
</html>
EOF

    # 设置权限
    chown -R $WEBUSER:$WEBUSER "$WEBROOT"
    chmod -R 755 "$WEBROOT"
    
    # 创建虚拟主机配置
    cat > "/etc/nginx/conf.d/$DOMAIN.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $WEBROOT;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    # 重载配置
    nginx -t && systemctl reload nginx
fi

# 完成提示
echo
info "✅ Nginx 安装完成！"
NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '{print $2}' | awk '{print $1}')
info "版本: $NGINX_VERSION"
info "状态: $(systemctl is-active nginx)"

if [[ -n "$DOMAIN" ]]; then
    info "🌍 访问测试: http://$DOMAIN"
    info "📁 网站目录: $WEBROOT"
fi

echo
info "常用命令:"
echo "  systemctl restart nginx  # 重启服务"
echo "  systemctl reload nginx   # 重载配置"
echo "  nginx -t                 # 测试配置"
