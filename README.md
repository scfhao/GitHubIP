# GitHubIP

提供可用的 GitHub IP 地址列表，帮助解决访问 GitHub 网络问题。

## 访问网站

请访问项目主页查看最新的可用 IP 列表：[https://scfhao.github.io/GitHubIP/](https://scfhao.github.io/GitHubIP/)

## 项目说明

本项目通过 `findGitHubIP.sh` 脚本自动从 GitHub API 获取 GitHub 的官方 IP 列表，然后对每个 IP 进行测试验证，筛选出可用的 IP 并按延迟排序展示在网站上。

## 使用方法

### 1. 运行脚本

```bash
# 正常运行（可能需要较长时间）
./findGitHubIP.sh

# 测试模式（快速生成模拟数据）
./findGitHubIP.sh --test
# 或
./findGitHubIP.sh -t
```

### 2. 本地预览网站

```bash
# 安装依赖
bundle install

# 启动 Jekyll 本地服务器
bundle exec jekyll serve
```

然后在浏览器访问 `http://localhost:4000` 即可预览网站。

## 网站功能

- **首页**：展示最新的可用 GitHub IP 列表及延迟
- **文档页**：查看项目相关文档

## 工作流程

1. 定时运行 `findGitHubIP.sh` 脚本，生成 `index.md` 文件
2. 将变更提交到 GitHub 仓库
3. GitHub Pages 自动部署更新网站

## 技术栈

- Jekyll
- GitHub Pages
- Shell Script

## 许可证

MIT License
