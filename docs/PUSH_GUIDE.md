# 推送到 GitHub 指南

## ⚠️ 重要提示

**不要将 Git 密钥硬编码在代码中！**

## 📋 推送步骤

### 1. 在 GitHub 创建新仓库

访问 https://github.com/new 创建新仓库
- 仓库名：`nova` 或 `NovaScript`
- 可见性：Public 或 Private
- **不要** 初始化 README（我们已经有了）

### 2. 添加远程仓库

```bash
cd /storage/emulated/0/Kaifa/NovaScript

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/YOUR_USERNAME/nova.git

# 或者使用 SSH（如果你配置了 SSH 密钥）
git remote add origin git@github.com:YOUR_USERNAME/nova.git
```

### 3. 推送代码

```bash
# 推送到 main 分支
git push -u origin main

# 如果是第一次推送，可能需要验证
# GitHub 会提示你使用 Personal Access Token
```

### 4. 验证推送

访问你的 GitHub 仓库页面，确认文件已上传。

---

## 🔐 使用 Personal Access Token

GitHub 现在要求使用 Personal Access Token 而不是密码：

### 创建 Token

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 选择权限：
   - `repo` (完整仓库控制)
   - `workflow` (如果使用 GitHub Actions)
4. 生成并复制 Token
5. **妥善保存，不要提交到代码中！**

### 使用 Token 推送

```bash
# 推送时会提示输入用户名和密码
# 用户名：你的 GitHub 用户名
# 密码：粘贴 Personal Access Token
```

---

## 🚀 后续更新

```bash
# 日常提交
git add .
git commit -m "Description of changes"
git push

# 拉取他人更改
git pull origin main
```

---

## 📦 安装脚本会处理依赖

用户安装时会自动从 GitHub 下载依赖：

```bash
# 安装本地包
nova install package-name

# 从 GitHub 安装
nova install novascript/image-generator
nova install owner/repo@v1.0.0
```

搜索也会调用 GitHub API：

```bash
nova search image
```

---

## ⚙️ GitHub API 配置

编辑 `lib/api/github.sh` 修改默认仓库：

```bash
DEFAULT_OWNER="novascript"
DEFAULT_REPO="packages"
```

**无需硬编码密钥**，使用公开的 GitHub API（有速率限制但够用）。

如需更高限制，可以：
1. 创建 GitHub App
2. 在运行时通过环境变量提供 Token
3. **不要提交到代码中！**

```bash
# 使用时设置
export GITHUB_TOKEN="your_token_here"
nova install package
```

---

## 📝 检查清单

- [ ] 在 GitHub 创建仓库
- [ ] 添加远程仓库
- [ ] 推送代码
- [ ] 验证文件已上传
- [ ] 更新 README 中的链接
- [ ] 创建 GitHub Release（可选）
- [ ] 配置 GitHub Pages（用于 WebUI 演示）

---

**完成！** 🎉
