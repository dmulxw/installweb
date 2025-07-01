#!/usr/bin/env bash
# =========================================================
# HAH DApp 网站一键部署脚本
# · 部署预编译的前端静态站点
# · 支持 Ubuntu ≥20.04 / Debian ≥10 / CentOS 8 / Rocky / Alma
# · 自动安装 nginx + certbot，配置虚拟主机与 SSL
# · 从 GitHub Releases 下载预构建文件
# 
# 构建文件来源：https://github.com/dmulxw/installweb/releases/tag/hah
# 
# 使用方法：
# 1. 交互式执行: curl -fsSL https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh | sudo bash
# 2. 带参数执行: sudo bash installweb.sh domain.com email@example.com
# 3. 下载后执行: wget https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh && sudo bash installweb.sh
# =========================================================
set -euo pipefail

# ---------- 颜色 ----------
GRN='\033[1;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${GRN}[INFO] $*${NC}"; }
warn(){ echo -e "${YEL}[WARN] $*${NC}"; }
die(){  echo -e "${RED}[ERR]  $*${NC}"; exit 1; }

[[ $EUID -ne 0 ]] && die "必须以 root / sudo 运行脚本"

# ---------- 发行版检测 ----------
OS_FAMILY=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "$ID" in
    ubuntu|debian) OS_FAMILY="debian" ;;
    centos|rhel|rocky|almalinux) OS_FAMILY="rhel" ;;
    *) die "暂不支持的发行版: $ID" ;;
  esac
else
  die "无法识别系统发行版"
fi

# ---------- 用户输入 ----------
# 支持命令行参数：./installweb.sh domain email
if [[ $# -eq 2 ]]; then
  DOMAIN="$1"
  EMAIL="$2"
  info "使用命令行参数: 域名=$DOMAIN, 邮箱=$EMAIL"
else
  # 检查是否通过管道执行，如果是则需要重新打开标准输入
  if [ ! -t 0 ]; then
    exec < /dev/tty
  fi

  read -rp "请输入 DApp 域名(如: dapp.example.com): " DOMAIN || die "无法读取域名输入"
  read -rp "Let's Encrypt 证书邮箱: " EMAIL || die "无法读取邮箱输入"
fi

[[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" ]] && die "域名和邮箱不能为空"

# ---------- 回显 ----------
echo -e "${GRN}======== 您的配置 ========${NC}"
printf "%-10s %s\n" "Domain:" "$DOMAIN"
printf "%-10s %s\n" "Email:"  "$EMAIL"
echo -e "${GRN}=========================${NC}"

# ---------- 域名解析检查 ----------
PUB_IP=$(curl -s https://ifconfig.me)
DNS_IP=$(dig +short "$DOMAIN" | tail -n1)
[[ "${DNS_IP:-}" != "${PUB_IP:-}" ]] && die "域名未解析到本机 (${DNS_IP:-unknown} != ${PUB_IP:-unknown})"
info "域名解析正确 ($DNS_IP)"

# ---------- 安装依赖 ----------
info "安装 nginx 和 certbot..."
if [[ $OS_FAMILY == debian ]]; then
  apt-get update -y
  apt-get install -y curl unzip nginx certbot python3-certbot-nginx
elif [[ $OS_FAMILY == rhel ]]; then
  dnf install -y epel-release
  dnf install -y curl unzip nginx certbot python3-certbot-nginx
fi
systemctl enable --now nginx

# ---------- 下载并解压前端 build ----------
WORKDIR=/opt/hahdapp_web
BUILD_URL="https://github.com/dmulxw/installweb/releases/download/hah/build.zip"
mkdir -p "$WORKDIR"
info "从 GitHub Releases 下载前端构建文件..."

# 下载构建文件
cd "$WORKDIR"
curl -L "$BUILD_URL" -o build.zip || die "下载构建文件失败，请检查网络连接或文件是否存在"

# 解压到临时目录
info "解压前端文件..."
rm -rf build_temp && mkdir -p build_temp
unzip -q build.zip -d build_temp || die "解压文件失败"

# 部署到网站目录
WEBROOT="/var/www/$DOMAIN"
rm -rf "$WEBROOT" && mkdir -p "$WEBROOT"
cp -r build_temp/* "$WEBROOT" || die "复制文件到网站目录失败"

info "前端文件部署完成"

# ---------- nginx 配置 ----------
NGCONF="/etc/nginx/conf.d/${DOMAIN}.conf"
cat > "$NGCONF" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root ${WEBROOT};
    index index.html;

    location / {
        try_files \$uri /index.html;
    }
}
EOF
nginx -t && systemctl reload nginx

# ---------- SSL ----------
info "申请/续签 SSL 证书..."
certbot --nginx --non-interactive --agree-tos -m "$EMAIL" -d "$DOMAIN" --redirect || \
  warn "证书申请失败，请稍后手动执行 certbot 重试"

# ---------- 完成 ----------
echo -e "${GRN}======== 部署完成 ========${NC}"
echo "访问地址: https://${DOMAIN}"
