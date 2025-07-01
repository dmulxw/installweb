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
# 2. 带参数执行: sudo bash installweb.sh domain.com email@example.com [tag] [zipfile]
# 3. 下载后执行: wget https://raw.githubusercontent.com/dmulxw/installweb/main/installweb.sh && sudo bash installweb.sh
#
# 参数说明：
# - domain: 域名 (必需)
# - email: Let's Encrypt 邮箱 (必需) 
# - tag: GitHub Release 标签 (可选，默认: hah)
# - zipfile: 要下载的文件路径 (可选，默认: build.zip)
#   支持格式:
#   - "build.zip" -> 使用指定tag下的文件
#   - "v1.0/build.zip" -> 自动解析为 v1.0 标签下的 build.zip
#   - "https://..." -> 完整URL
# =========================================================
set -euo pipefail

# ---------- 颜色和函数 ----------
GRN='\033[1;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info(){ echo -e "${GRN}[INFO] $*${NC}"; }
warn(){ echo -e "${YEL}[WARN] $*${NC}"; }
die(){  echo -e "${RED}[ERR]  $*${NC}"; exit 1; }

# 检查URL是否可访问
check_url() {
  local url="$1"
  info "正在检查URL: $url"
  
  # 使用更宽松的检查，避免因为网络问题导致脚本停止
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 --connect-timeout 10 "$url" 2>/dev/null || echo "000")
  
  info "URL检查结果: HTTP $response"
  
  # 接受200和302状码（GitHub可能会重定向）
  [[ "$response" == "200" || "$response" == "302" ]]
}

# 解析文件路径并构建下载URL
build_download_url() {
  local tag="$1"
  local zipfile="$2"
  
  # 如果是完整URL，直接返回
  if [[ "$zipfile" =~ ^https?:// ]]; then
    echo "$zipfile"
    return
  fi
  
  # 如果包含斜杠，解析为 tag/file 格式
  if [[ "$zipfile" == *"/"* ]]; then
    local parsed_tag="${zipfile%%/*}"    # 提取斜杠前的部分作为tag
    local parsed_file="${zipfile##*/}"   # 提取斜杠后的部分作为文件名
    echo "https://github.com/dmulxw/installweb/releases/download/${parsed_tag}/${parsed_file}"
  else
    # 普通文件名，使用指定的tag
    echo "https://github.com/dmulxw/installweb/releases/download/${tag}/${zipfile}"
  fi
}

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
# 支持命令行参数：./installweb.sh domain email [tag] [zipfile]
if [[ $# -ge 2 ]]; then
  DOMAIN="$1"
  EMAIL="$2"
  TAG="${3:-hah}"
  ZIPFILE="${4:-build.zip}"
  info "使用命令行参数: 域名=$DOMAIN, 邮箱=$EMAIL, 标签=$TAG, 文件=$ZIPFILE"
else
  # 检查是否通过管道执行，如果是则需要重新打开标准输入
  if [ ! -t 0 ]; then
    exec < /dev/tty
  fi

  read -rp "请输入 DApp 域名(如: dapp.example.com): " DOMAIN || die "无法读取域名输入"
  read -rp "Let's Encrypt 证书邮箱: " EMAIL || die "无法读取邮箱输入"
  
  echo
  info "📦 配置下载文件..."
  echo "支持的格式:"
  echo "  - build.zip (使用指定标签)"  
  echo "  - v1.0/build.zip (自动解析标签/文件)"
  echo "  - https://... (完整URL)"
  echo
  read -rp "请输入 GitHub Release 标签 (默认: hah): " TAG
  TAG="${TAG:-hah}"
  
  read -rp "请输入要下载的文件路径 (默认: build.zip): " ZIPFILE  
  ZIPFILE="${ZIPFILE:-build.zip}"
fi

[[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" ]] && die "域名和邮箱不能为空"

# ---------- 回显 ----------
echo -e "${GRN}======== 您的配置 ========${NC}"
printf "%-12s %s\n" "Domain:" "$DOMAIN"
printf "%-12s %s\n" "Email:" "$EMAIL"
printf "%-12s %s\n" "Tag:" "$TAG"
printf "%-12s %s\n" "File Path:" "$ZIPFILE"

# 解析并显示最终URL
PREVIEW_URL=$(build_download_url "$TAG" "$ZIPFILE")
printf "%-12s %s\n" "Download URL:" "$PREVIEW_URL"
echo -e "${GRN}=========================${NC}"
echo
info "🚀 开始自动部署流程..."
info "📋 部署步骤: [1]域名检查 → [2]安装依赖 → [3]下载文件 → [4]配置nginx → [5]申请SSL"
echo

# ---------- 域名解析检查 ----------
info "📍 [步骤 1/5] 检查域名解析..."
info "正在获取服务器公网IP..."
PUB_IP=$(curl -s https://ifconfig.me)
info "服务器公网IP: $PUB_IP"

info "正在查询域名 $DOMAIN 的DNS解析..."
# 先尝试使用简单的方法检查域名解析
DNS_IP=""
for cmd in "nslookup" "host" "getent"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    case "$cmd" in
      "nslookup")
        DNS_IP=$(nslookup "$DOMAIN" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -n1 || echo "")
        ;;
      "host")
        DNS_IP=$(host "$DOMAIN" 2>/dev/null | grep "has address" | awk '{print $4}' | head -n1 || echo "")
        ;;
      "getent")
        DNS_IP=$(getent hosts "$DOMAIN" 2>/dev/null | awk '{print $1}' | head -n1 || echo "")
        ;;
    esac
    [[ -n "$DNS_IP" ]] && break
  fi
done

if [[ -z "$DNS_IP" ]]; then
  warn "⚠️ 无法使用常规方法查询DNS，尝试ping检查..."
  # 使用ping作为最后的检查方法
  if ping -c 1 "$DOMAIN" >/dev/null 2>&1; then
    DNS_IP=$(ping -c 1 "$DOMAIN" 2>/dev/null | grep "PING" | sed -n 's/.*(\([^)]*\)).*/\1/p' || echo "")
    if [[ -n "$DNS_IP" ]]; then
      info "通过ping获取域名解析IP: $DNS_IP"
      [[ "$DNS_IP" != "$PUB_IP" ]] && die "域名未解析到本机 ($DNS_IP != $PUB_IP)"
      info "✅ 域名解析正确 ($DNS_IP)"
    else
      warn "⚠️ 无法通过ping获取IP，将在安装依赖后重试"
      DNS_CHECK_LATER=true
    fi
  else
    warn "⚠️ 域名无法访问，将在安装依赖后重试"
    DNS_CHECK_LATER=true
  fi
else
  info "域名解析IP: $DNS_IP"
  [[ "$DNS_IP" != "$PUB_IP" ]] && die "域名未解析到本机 ($DNS_IP != $PUB_IP)"
  info "✅ 域名解析正确 ($DNS_IP)"
fi
echo

# ---------- 安装依赖 ----------
info "🔧 [步骤 2/5] 安装系统依赖..."
info "正在更新软件包列表，请稍候..."
if [[ $OS_FAMILY == debian ]]; then
  apt-get update -y >/dev/null 2>&1
  info "正在安装 nginx, certbot, curl, unzip, dnsutils..."
  apt-get install -y curl unzip nginx certbot python3-certbot-nginx dnsutils
elif [[ $OS_FAMILY == rhel ]]; then
  info "正在安装 EPEL 仓库..."
  dnf install -y epel-release >/dev/null 2>&1
  info "正在安装 nginx, certbot, curl, unzip, bind-utils..."
  dnf install -y curl unzip nginx certbot python3-certbot-nginx bind-utils
fi
info "正在启动 nginx 服务..."
systemctl enable --now nginx
info "✅ 系统依赖安装完成"

# 如果之前DNS检查失败，现在重新检查
if [[ "${DNS_CHECK_LATER:-false}" == "true" ]]; then
  info "🔍 重新检查域名解析..."
  DNS_IP=""
  
  # 尝试使用dig命令
  if command -v dig >/dev/null 2>&1; then
    DNS_IP=$(dig +short "$DOMAIN" 2>/dev/null | tail -n1 || echo "")
  fi
  
  # 如果dig失败或不存在，尝试其他方法
  if [[ -z "$DNS_IP" ]] && command -v nslookup >/dev/null 2>&1; then
    DNS_IP=$(nslookup "$DOMAIN" 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}' | head -n1 || echo "")
  fi
  
  if [[ -z "$DNS_IP" ]] && command -v host >/dev/null 2>&1; then
    DNS_IP=$(host "$DOMAIN" 2>/dev/null | grep "has address" | awk '{print $4}' | head -n1 || echo "")
  fi
  
  if [[ -n "$DNS_IP" ]]; then
    info "域名解析IP: $DNS_IP"
    [[ "$DNS_IP" != "$PUB_IP" ]] && die "域名未解析到本机 ($DNS_IP != $PUB_IP)"
    info "✅ 域名解析正确 ($DNS_IP)"
  else
    die "无法查询域名解析，请确保域名 $DOMAIN 已正确解析到 $PUB_IP"
  fi
fi
echo

# ---------- 下载并解压前端 build ----------
info "📦 [步骤 3/5] 下载前端构建文件..."
WORKDIR=/opt/hahdapp_web
mkdir -p "$WORKDIR"

# 构建下载URL（带重试逻辑）
# 检测是否通过管道执行
IS_PIPED=false
if [ ! -t 0 ] || [ ! -t 1 ]; then
  IS_PIPED=true
  info "检测到管道执行模式，将跳过交互式确认"
fi

while true; do
  BUILD_URL=$(build_download_url "$TAG" "$ZIPFILE")
  
  info "📋 准备下载文件:"
  echo "   🔗 下载地址: $BUILD_URL"
  echo "   📁 目标目录: $WORKDIR"
  
  # 解析并显示详细信息
  if [[ "$ZIPFILE" == *"/"* ]]; then
    parsed_tag="${ZIPFILE%%/*}"
    parsed_file="${ZIPFILE##*/}"
    echo "   🏷️ 解析标签: $parsed_tag"
    echo "   📦 解析文件: $parsed_file"
  elif [[ ! "$ZIPFILE" =~ ^https?:// ]]; then
    echo "   🏷️ 使用标签: $TAG"
    echo "   📦 使用文件: $ZIPFILE"
  fi
  echo

  # 让用户确认或修改下载地址（仅在非管道模式下）
  if [ "$IS_PIPED" = false ]; then
    read -rp "按回车确认下载，或输入新的文件路径: " USER_INPUT < /dev/tty
    if [[ -n "$USER_INPUT" ]]; then
      ZIPFILE="$USER_INPUT"
      BUILD_URL=$(build_download_url "$TAG" "$ZIPFILE")
      info "✏️ 使用新路径: $ZIPFILE"
      info "✏️ 新下载地址: $BUILD_URL"
    fi
  fi

  # 检查文件是否存在
  info "🔍 检查文件是否存在..."
  if check_url "$BUILD_URL"; then
    info "✅ 文件存在，开始下载"
    break
  else
    warn "⚠️ 文件不存在或无法访问: $BUILD_URL"
    warn "   请检查:"
    warn "   - 网络连接是否正常"
    if [[ "$ZIPFILE" == *"/"* ]]; then
      parsed_tag="${ZIPFILE%%/*}"
      parsed_file="${ZIPFILE##*/}"
      warn "   - GitHub Release 标签 '$parsed_tag' 是否存在"
      warn "   - 文件 '$parsed_file' 是否已上传"
    else
      warn "   - GitHub Release 标签 '$TAG' 是否存在"
      warn "   - 文件 '$ZIPFILE' 是否已上传"
    fi
    
    if [ "$IS_PIPED" = false ]; then
      echo
      read -rp "请重新输入文件路径 (或输入 'exit' 退出): " NEW_ZIPFILE < /dev/tty
      if [[ "$NEW_ZIPFILE" == "exit" ]]; then
        die "用户退出"
      elif [[ -n "$NEW_ZIPFILE" ]]; then
        ZIPFILE="$NEW_ZIPFILE"
        continue
      else
        die "文件不存在，部署终止"
      fi
    else
      die "文件不存在，部署终止"
    fi
  fi
done

# 下载构建文件
cd "$WORKDIR"
info "正在下载构建文件，请稍候..."
echo -ne "${YEL}[下载进度] ${NC}"
curl -L --progress-bar "$BUILD_URL" -o build.zip || die "下载构建文件失败，请检查网络连接"
echo # 换行
info "✅ 构建文件下载完成"

# 解压到临时目录
info "正在解压前端文件..."
rm -rf build_temp && mkdir -p build_temp
unzip -q build.zip -d build_temp || die "解压文件失败"
info "✅ 文件解压完成"

# 部署到网站目录
info "正在部署文件到网站目录..."
WEBROOT="/var/www/$DOMAIN"
rm -rf "$WEBROOT" && mkdir -p "$WEBROOT"
cp -r build_temp/* "$WEBROOT" || die "复制文件到网站目录失败"

info "✅ 前端文件部署完成"
echo

# ---------- nginx 配置 ----------
info "⚙️ [步骤 4/5] 配置 nginx..."
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
info "正在测试 nginx 配置..."
nginx -t && systemctl reload nginx
info "✅ nginx 配置完成"
echo

# ---------- SSL ----------
info "🔒 [步骤 5/5] 申请 SSL 证书..."
info "正在向 Let's Encrypt 申请证书，这可能需要几分钟..."
info "域名: $DOMAIN | 邮箱: $EMAIL"
certbot --nginx --non-interactive --agree-tos -m "$EMAIL" -d "$DOMAIN" --redirect || \
  warn "证书申请失败，请稍后手动执行: certbot --nginx -d $DOMAIN"
info "✅ SSL 证书配置完成"
echo

# ---------- 完成 ----------
echo -e "${GRN}🎉======== 部署完成 ========${NC}"
echo -e "✅ 网站已成功部署"
echo -e "🌐 访问地址: ${GRN}https://${DOMAIN}${NC}"
echo -e "📧 SSL证书邮箱: $EMAIL"
echo -e "📁 网站根目录: $WEBROOT"
echo -e "🏷️ 使用标签: $TAG"
echo -e "📦 下载文件: $ZIPFILE"
echo -e "🔗 下载地址: $BUILD_URL"
echo -e "${GRN}=========================${NC}"
