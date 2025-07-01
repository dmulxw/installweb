#!/usr/bin/env bash
# =========================================================
# Nginx 自动安装配置脚本
# · 支持 Ubuntu ≥20.04 / Debian ≥10 / CentOS 8 / Rocky / Alma
# · 自动检测系统并安装最新版本 nginx
# · 可选安装 certbot SSL 证书工具
# · 自动优化配置和安全设置
# · 可选创建示例虚拟主机
#
# 使用方法：
# 1. 基础安装: sudo bash nginx_auto_install.sh
# 2. 带域名创建站点: sudo bash nginx_auto_install.sh --domain example.com
# 3. 完整安装(含SSL工具): sudo bash nginx_auto_install.sh --full
# 4. 交互模式: sudo bash nginx_auto_install.sh --interactive
# =========================================================

set -euo pipefail

# ---------- 颜色和函数 ----------
GRN='\033[1;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; BLU='\033[1;34m'; NC='\033[0m'
info(){ echo -e "${GRN}[INFO] $*${NC}"; }
warn(){ echo -e "${YEL}[WARN] $*${NC}"; }
die(){  echo -e "${RED}[ERR]  $*${NC}"; exit 1; }
note(){ echo -e "${BLU}[NOTE] $*${NC}"; }

# ---------- 默认配置 ----------
INSTALL_CERTBOT=false
CREATE_SAMPLE_SITE=false
INTERACTIVE_MODE=false
DOMAIN=""
EMAIL=""
OPTIMIZE_CONFIG=true

# ---------- 帮助信息 ----------
show_help() {
    cat << 'EOF'
Nginx 自动安装配置脚本

用法: nginx_auto_install.sh [选项]

选项:
  -h, --help              显示帮助信息
  -d, --domain DOMAIN     创建指定域名的虚拟主机
  -e, --email EMAIL       SSL证书邮箱地址
  -f, --full              完整安装(包含certbot等工具)
  -i, --interactive       交互模式
  -s, --sample            创建示例站点
  --no-optimize           跳过配置优化

示例:
  sudo bash nginx_auto_install.sh
  sudo bash nginx_auto_install.sh --domain example.com
  sudo bash nginx_auto_install.sh --full --domain example.com --email admin@example.com
  sudo bash nginx_auto_install.sh --interactive

EOF
}

# ---------- 参数解析 ----------
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--domain)
            DOMAIN="$2"
            CREATE_SAMPLE_SITE=true
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -f|--full)
            INSTALL_CERTBOT=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -s|--sample)
            CREATE_SAMPLE_SITE=true
            shift
            ;;
        --no-optimize)
            OPTIMIZE_CONFIG=false
            shift
            ;;
        *)
            warn "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# ---------- 权限检查 ----------
[[ $EUID -ne 0 ]] && die "必须以 root 或 sudo 权限运行此脚本"

# ---------- 系统检测 ----------
info "🔍 检测系统环境..."
OS_FAMILY=""
OS_VERSION=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            OS_FAMILY="debian"
            OS_VERSION="$VERSION_ID"
            info "检测到系统: Ubuntu $VERSION_ID"
            [[ "${VERSION_ID%%.*}" -lt 20 ]] && warn "建议使用 Ubuntu 20.04 或更新版本"
            ;;
        debian)
            OS_FAMILY="debian"
            OS_VERSION="$VERSION_ID"
            info "检测到系统: Debian $VERSION_ID"
            [[ "${VERSION_ID%%.*}" -lt 10 ]] && warn "建议使用 Debian 10 或更新版本"
            ;;
        centos|rhel)
            OS_FAMILY="rhel"
            OS_VERSION="$VERSION_ID"
            info "检测到系统: $PRETTY_NAME"
            [[ "${VERSION_ID%%.*}" -lt 8 ]] && warn "建议使用 CentOS/RHEL 8 或更新版本"
            ;;
        rocky|almalinux)
            OS_FAMILY="rhel"
            OS_VERSION="$VERSION_ID"
            info "检测到系统: $PRETTY_NAME"
            ;;
        *)
            warn "未完全测试的发行版: $ID，尝试按 $ID_LIKE 处理"
            case "$ID_LIKE" in
                *debian*) OS_FAMILY="debian" ;;
                *rhel*|*fedora*) OS_FAMILY="rhel" ;;
                *) die "不支持的操作系统: $ID" ;;
            esac
            ;;
    esac
else
    die "无法识别系统发行版，请确保 /etc/os-release 文件存在"
fi

# ---------- 交互模式 ----------
if [[ "$INTERACTIVE_MODE" == true ]]; then
    echo
    info "🎛️ 交互配置模式"
    
    read -rp "是否安装 certbot SSL 工具? [y/N]: " install_ssl
    [[ "$install_ssl" =~ ^[Yy] ]] && INSTALL_CERTBOT=true
    
    read -rp "是否创建示例网站? [y/N]: " create_site
    if [[ "$create_site" =~ ^[Yy] ]]; then
        CREATE_SAMPLE_SITE=true
        read -rp "请输入域名 (如: example.com): " DOMAIN
        if [[ "$INSTALL_CERTBOT" == true && -n "$DOMAIN" ]]; then
            read -rp "请输入邮箱 (SSL证书用): " EMAIL
        fi
    fi
    
    read -rp "是否应用性能优化配置? [Y/n]: " optimize
    [[ "$optimize" =~ ^[Nn] ]] && OPTIMIZE_CONFIG=false
fi

# ---------- 安装前检查 ----------
info "🔧 开始安装 Nginx..."

# 检查是否已安装
if command -v nginx >/dev/null 2>&1; then
    CURRENT_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')
    warn "Nginx 已安装 (版本: $CURRENT_VERSION)"
    read -rp "是否继续重新配置? [y/N]: " continue_install
    [[ ! "$continue_install" =~ ^[Yy] ]] && exit 0
fi

# ---------- 安装 Nginx ----------
info "📦 更新软件包列表..."
if [[ $OS_FAMILY == "debian" ]]; then
    apt-get update -q
    
    info "📦 安装 Nginx..."
    apt-get install -y nginx
    
    if [[ "$INSTALL_CERTBOT" == true ]]; then
        info "📦 安装 Certbot..."
        apt-get install -y certbot python3-certbot-nginx
    fi
    
elif [[ $OS_FAMILY == "rhel" ]]; then
    # 安装 EPEL 仓库
    if ! rpm -q epel-release >/dev/null 2>&1; then
        info "📦 安装 EPEL 仓库..."
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y epel-release
        else
            yum install -y epel-release
        fi
    fi
    
    info "📦 安装 Nginx..."
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y nginx
        if [[ "$INSTALL_CERTBOT" == true ]]; then
            info "📦 安装 Certbot..."
            dnf install -y certbot python3-certbot-nginx
        fi
    else
        yum install -y nginx
        if [[ "$INSTALL_CERTBOT" == true ]]; then
            info "📦 安装 Certbot..."
            yum install -y certbot python3-certbot-nginx
        fi
    fi
fi

# ---------- 启动服务 ----------
info "🚀 启动并启用 Nginx 服务..."
systemctl enable nginx
systemctl start nginx

# 检查服务状态
if systemctl is-active --quiet nginx; then
    info "✅ Nginx 服务启动成功"
else
    die "❌ Nginx 服务启动失败，请检查配置"
fi

# ---------- 优化配置 ----------
if [[ "$OPTIMIZE_CONFIG" == true ]]; then
    info "⚙️ 应用性能优化配置..."
    
    # 备份原配置
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # 获取 CPU 核心数
    CPU_CORES=$(nproc)
    
    # 创建优化配置
    cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes $CPU_CORES;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # 日志格式
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                   '\$status \$body_bytes_sent "\$http_referer" '
                   '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # 性能优化
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip 压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_comp_level 6;
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

    # 包含虚拟主机配置
    include /etc/nginx/conf.d/*.conf;
}
EOF

    info "✅ 性能优化配置已应用"
fi

# ---------- 创建示例站点 ----------
if [[ "$CREATE_SAMPLE_SITE" == true && -n "$DOMAIN" ]]; then
    info "🌐 创建示例站点: $DOMAIN"
    
    # 创建网站目录
    WEBROOT="/var/www/$DOMAIN"
    mkdir -p "$WEBROOT"
    
    # 创建示例页面
    cat > "$WEBROOT/index.html" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>欢迎访问 $DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Nginx 安装成功！</h1>
        <p>欢迎访问 <strong>$DOMAIN</strong></p>
        <div class="info">
            <h3>站点信息</h3>
            <p><strong>域名:</strong> $DOMAIN</p>
            <p><strong>网站根目录:</strong> $WEBROOT</p>
            <p><strong>安装时间:</strong> $(date)</p>
        </div>
        <p>您可以将您的网站文件上传到网站根目录来替换此页面。</p>
    </div>
</body>
</html>
EOF

    # 设置权限
    chown -R nginx:nginx "$WEBROOT" 2>/dev/null || chown -R www-data:www-data "$WEBROOT" 2>/dev/null || true
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

    # 安全配置
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    info "✅ 示例站点已创建"
fi

# ---------- 测试配置 ----------
info "🧪 测试 Nginx 配置..."
if nginx -t; then
    info "✅ 配置测试通过"
    systemctl reload nginx
    info "✅ Nginx 配置已重载"
else
    warn "❌ 配置测试失败，请检查配置文件"
fi

# ---------- 防火墙配置 ----------
info "🔥 配置防火墙..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 'Nginx Full' 2>/dev/null || true
    info "✅ UFW 防火墙规则已添加"
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-service=http 2>/dev/null || true
    firewall-cmd --permanent --add-service=https 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    info "✅ Firewalld 防火墙规则已添加"
fi

# ---------- SSL 证书申请 ----------
if [[ "$INSTALL_CERTBOT" == true && -n "$DOMAIN" && -n "$EMAIL" ]]; then
    info "🔒 申请 SSL 证书..."
    
    # 检查域名解析
    info "检查域名解析..."
    if command -v dig >/dev/null 2>&1; then
        DNS_IP=$(dig +short "$DOMAIN" | tail -n1)
        PUB_IP=$(curl -s https://ifconfig.me || curl -s https://ipinfo.io/ip)
        
        if [[ "$DNS_IP" != "$PUB_IP" ]]; then
            warn "域名解析可能有问题: $DNS_IP != $PUB_IP"
            warn "建议先检查域名解析后再申请证书"
        else
            info "✅ 域名解析正确"
            certbot --nginx --non-interactive --agree-tos -m "$EMAIL" -d "$DOMAIN" --redirect || \
                warn "证书申请失败，请稍后手动执行: certbot --nginx -d $DOMAIN"
        fi
    else
        warn "无法检查域名解析，跳过自动证书申请"
        note "手动申请证书: certbot --nginx -d $DOMAIN"
    fi
fi

# ---------- 完成信息 ----------
echo
echo -e "${GRN}🎉======== Nginx 安装完成 ========${NC}"
NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')
echo -e "✅ Nginx 版本: ${GRN}$NGINX_VERSION${NC}"
echo -e "🌐 服务状态: ${GRN}$(systemctl is-active nginx)${NC}"
echo -e "📁 配置目录: /etc/nginx/"
echo -e "📁 网站根目录: /var/www/"
echo -e "📝 日志目录: /var/log/nginx/"

if [[ -n "$DOMAIN" ]]; then
    echo -e "🌍 测试网站: ${GRN}http://$DOMAIN${NC}"
    if [[ "$INSTALL_CERTBOT" == true ]]; then
        echo -e "🔒 SSL网站: ${GRN}https://$DOMAIN${NC}"
    fi
fi

echo
echo -e "${BLU}常用管理命令:${NC}"
echo -e "  重启服务: ${YEL}systemctl restart nginx${NC}"
echo -e "  重载配置: ${YEL}systemctl reload nginx${NC}"
echo -e "  查看状态: ${YEL}systemctl status nginx${NC}"
echo -e "  测试配置: ${YEL}nginx -t${NC}"

if [[ "$INSTALL_CERTBOT" == true ]]; then
    echo -e "  续期证书: ${YEL}certbot renew${NC}"
    echo -e "  查看证书: ${YEL}certbot certificates${NC}"
fi

echo -e "${GRN}================================${NC}"
