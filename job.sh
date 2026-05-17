#!/bin/bash

# GitHubIP 自动更新脚本
# 使用说明：
# 1. 在 Armbian 系统上克隆项目到某个位置
# 2. 将此脚本复制到 /etc/cron.daily/ 目录下
# 3. 确保脚本有执行权限：chmod +x job.sh
# 4. 配置 git 使用 SSH 密钥认证，避免手动输入密码

# 项目目录路径（需要根据实际克隆位置修改）
PROJECT_DIR="/mnt/data/git/GitHubIP"

# 日志文件路径
LOG_FILE="/var/log/githubip_update.log"

# 函数：记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "开始执行 GitHubIP 自动更新脚本"

# 切换到项目目录
cd "$PROJECT_DIR" || {
    log "错误：无法切换到项目目录 $PROJECT_DIR"
    exit 1
}

# 1. 使用 git pull 更新项目
log "正在更新项目..."
if git pull origin main; then
    log "项目更新成功"
else
    log "警告：项目更新失败，可能网络问题或本地有未提交的修改"
fi

# 2. 运行 findGitHubIP.sh 脚本
log "正在运行 findGitHubIP.sh 脚本..."
if ./findGitHubIP.sh; then
    log "findGitHubIP.sh 执行成功"
else
    log "警告：findGitHubIP.sh 执行失败"
fi

# 3. 检查是否有变更
log "检查是否有变更..."
if git status | grep -q "modified:"; then
    log "发现变更，准备提交..."
    
    # 添加 index.md 文件
    git add index.md
    
    # 提交变更
    if git commit -m "自动脚本执行 - $(date '+%Y-%m-%d %H:%M:%S')"; then
        log "提交成功"
        
        # 推送到 GitHub
        if git push origin main; then
            log "推送成功"
        else
            log "错误：推送失败"
        fi
    else
        log "警告：提交失败，可能没有需要提交的内容"
    fi
else
    log "没有发现变更，跳过提交"
fi

log "脚本执行完成"
