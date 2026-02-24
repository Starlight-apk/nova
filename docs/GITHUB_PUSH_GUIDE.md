# 推送到 GitHub 指南

## 📋 NovaScript 主仓库

### 1. 在 GitHub 创建仓库

访问 https://github.com/new
- 仓库名：`nova` 或 `NovaScript`
- 可见性：Public
- **不要** 初始化（已有代码）

### 2. 添加远程并推送

```bash
cd /storage/emulated/0/Kaifa/NovaScript

# 添加远程（替换为你的用户名）
git remote add origin https://github.com/YOUR_USERNAME/nova.git

# 推送
git push -u origin main
```

---

## 📦 NovaScript Packages 包仓库

### 1. 在 GitHub 创建仓库

访问 https://github.com/new
- 仓库名：`packages`
- 可见性：Public
- **不要** 初始化

### 2. 添加远程并推送

```bash
cd /storage/emulated/0/Kaifa/NovaScript-Packages

# 添加远程
git remote add origin https://github.com/YOUR_USERNAME/packages.git

# 推送
git push -u origin main
```

---

## 🔐 认证方式

### 使用 Personal Access Token

1. 访问 https://github.com/settings/tokens
2. 生成新 token（勾选 `repo` 权限）
3. 复制 token
4. 推送时使用：
   - 用户名：你的 GitHub 用户名
   - 密码：粘贴 token

### 使用 SSH（推荐）

```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your@email.com"

# 添加公钥到 GitHub
# https://github.com/settings/keys

# 使用 SSH 远程
git remote set-url origin git@github.com:YOUR_USERNAME/nova.git
```

---

## ✅ 推送后

### 主仓库

用户可以使用：
```bash
git clone https://github.com/YOUR_USERNAME/nova.git
cd nova
bash install.sh
```

### 包仓库

用户可以使用：
```bash
nova install YOUR_USERNAME/image-generator
nova install YOUR_USERNAME/code-editor
```

---

## 📝 检查清单

- [ ] 主仓库推送到 `nova`
- [ ] 包仓库推送到 `packages`
- [ ] 更新 README 中的链接
- [ ] 测试安装脚本
- [ ] 测试包下载

---

## 🔗 相关链接

- [GitHub 文档](https://docs.github.com/)
- [Git 入门](https://git-scm.com/book/)
- [SSH 密钥设置](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
