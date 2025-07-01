#!/usr/bin/env bash
# 简单测试脚本，验证语法
set -euo pipefail

echo "脚本开始运行..."

# 模拟用户输入参数
DOMAIN="$1"
EMAIL="$2"
TAG="${3:-hah}"
ZIPFILE="${4:-build.zip}"

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"
echo "Tag: $TAG"
echo "Zipfile: $ZIPFILE"

echo "脚本运行成功！"
