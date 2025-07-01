# Nginx 安装脚本 - 快速选择指南

## 🚀 一键选择合适的安装方式

### 💡 30秒快速决策

**我需要什么？**
- 🔥 **5分钟快速搭建** → [极简版](#极简版)
- 🔧 **平衡功能和简易** → [标准版](#标准版)  
- 🏢 **生产环境全功能** → [全功能版](#全功能版)

---

## 极简版 (nginx_quick_install.sh)

### ⚡ 特点
- 一行命令安装
- 5分钟内完成
- 零配置
- 自动创建测试页面

### 🎯 使用场景
- 个人博客
- 测试环境
- 快速演示
- 静态网站托管

### 📝 安装命令
```bash
# 基础安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash

# 带域名安装
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash -s your-domain.com
```

---

## 标准版 (nginx_install.sh)

### ⚙️ 特点
- 支持自定义网站目录
- 基础性能优化
- 交互式配置
- 适度的功能平衡

### 🎯 使用场景
- 中小型网站
- 开发环境
- 需要自定义配置
- 企业内网站点

### 📝 安装命令
```bash
# 下载脚本
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_install.sh

# 基础安装
sudo bash nginx_install.sh

# 带域名和自定义目录
sudo bash nginx_install.sh your-domain.com /var/www/custom
```

---

## 全功能版 (nginx_auto_install.sh)

### 🏢 特点
- 企业级配置
- 自动SSL证书
- 性能调优
- 安全加固
- 交互式配置

### 🎯 使用场景
- 生产环境
- 企业网站
- 高流量站点
- 需要SSL的网站

### 📝 安装命令
```bash
# 下载脚本
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_auto_install.sh

# 完整安装
sudo bash nginx_auto_install.sh --full --domain your-domain.com --email admin@your-domain.com

# 交互模式
sudo bash nginx_auto_install.sh --interactive
```

---

## 🔄 升级路径

```
极简版 → 标准版 → 全功能版
 ⬇️      ⬇️        ⬇️
测试    开发     生产
```

### 从极简版升级到标准版
1. 备份现有配置: `sudo cp -r /etc/nginx /etc/nginx.backup`
2. 运行标准版脚本: `sudo bash nginx_install.sh`

### 从标准版升级到全功能版
1. 备份配置: `sudo cp -r /etc/nginx /etc/nginx.backup`
2. 运行全功能版: `sudo bash nginx_auto_install.sh --full`

---

## 📊 功能对比表

| 功能 | 极简版 | 标准版 | 全功能版 |
|------|:-----:|:-----:|:-------:|
| 安装速度 | ⚡⚡⚡ | ⚡⚡ | ⚡ |
| 配置复杂度 | 🟢 简单 | 🟡 中等 | 🔴 复杂 |
| SSL支持 | ❌ | ❌ | ✅ |
| 性能优化 | 基础 | 中等 | 高级 |
| 防火墙配置 | ✅ | ✅ | ✅ |
| 自定义目录 | ❌ | ✅ | ✅ |
| 交互配置 | ❌ | ✅ | ✅ |
| 证书自动申请 | ❌ | ❌ | ✅ |

---

## 🎯 推荐选择

### 👤 个人用户
```bash
# 个人博客/作品展示
curl -fsSL https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_quick_install.sh | sudo bash -s myblog.com
```

### 👥 小团队
```bash
# 下载并配置
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_install.sh
sudo bash nginx_install.sh team-project.com /home/projects/website
```

### 🏢 企业用户
```bash
# 完整企业级部署
wget https://raw.githubusercontent.com/dmulxw/hahdapp/main/nginx_auto_install.sh
sudo bash nginx_auto_install.sh --full --domain company.com --email admin@company.com
```

---

## ⚠️ 重要提醒

1. **生产环境** 建议使用全功能版
2. **测试环境** 可以使用极简版快速搭建
3. **开发环境** 推荐标准版，平衡功能和简易性
4. 所有脚本都支持 **Ubuntu/Debian/CentOS/Rocky/Alma** 系统
5. 运行前确保有 **sudo 权限**

---

## 📚 详细文档

查看完整安装指南: [nginx安装指南.md](./nginx安装指南.md)

## 🆘 需要帮助？

1. 查看错误日志: `sudo tail -f /var/log/nginx/error.log`
2. 测试配置: `sudo nginx -t`
3. 检查服务状态: `sudo systemctl status nginx`

**一键安装，轻松部署！选择适合你的Nginx安装方式。** 🚀
