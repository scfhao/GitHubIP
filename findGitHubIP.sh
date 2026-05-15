#!/bin/bash

# 检查是否为测试模式
TEST_MODE=0
if [[ "$1" == "--test" || "$1" == "-t" ]]; then
  TEST_MODE=1
fi

# 从 https://api.github.com/meta 获取web ip列表
if [[ $TEST_MODE -eq 1 ]]; then
  # 测试模式：使用模拟数据
  web_ips="140.82.112.0/24"
  echo "测试模式：使用模拟数据"
else
  web_ips=$(curl -s https://api.github.com/meta | jq -r '.web[]')
fi

server_name="github.com"
ip_ping_list=()

# 遍历IP列表
if [[ $TEST_MODE -eq 1 ]]; then
    # 测试模式：直接添加模拟数据
    ip_ping_list=("120.5 140.82.112.3" "180.3 140.82.112.4" "220.1 140.82.112.5" "250.7 140.82.112.6")
    echo "测试模式：使用模拟 IP 数据"
else
    for ip in $web_ips; do
        # 判断IP是否为ipv6格式，如果是则跳过本次循环
        if [[ $ip == *":"* ]]; then
            continue
        fi
        # 检查是否为CIDR格式（网段）
        if [[ $ip == *"/"* ]]; then
            # 记录该网段连续失败 IP 数量
            fail_count=0
            # 使用进程替换避免子shell问题
            while read -r single_ip; do
                # 使用 curl 和 https 协议访问此 IP，忽略证书错误，并打印响应的 location 响应头
                server_header=$(curl -sI -k -H "Host: $server_name" --max-time 2 "https://$single_ip" | grep -i '^Server:' | tr -d '\r' | cut -d' ' -f2-)
                # 判断 server_header 是否不为空且第一个元素是否等于 server_name
                if [[ -n "$server_header" && "$server_header" != "null" ]]; then
                    # 重置失败计数
                    fail_count=0
                    if [[ "$server_header" == "$server_name" ]]; then
                        # 对单个IP执行ping操作，发送4个ICMP包，获取平均延时(兼容Linux和macOS)
                        ping_output=$(ping -c 4 "$single_ip")
                        # macOS格式: round-trip min/avg/max/stddev = 240.410/255.502/280.308/16.219 ms
                        # Linux格式: rtt min/avg/max/mdev = 240.410/255.502/280.308/16.219 ms
                        ping_stats=$(echo "$ping_output" | grep -E 'round-trip|rtt' | cut -d '=' -f 2)
                        ping_result=$(echo "$ping_stats" | cut -d '/' -f 2)
                        # 判断 ping_result 是否为有效数值
                        if [[ -n "$ping_result" && "$ping_result" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                            echo "IP $single_ip 平均延时: $ping_result ms"
                            ip_ping_list+=("$ping_result $single_ip")
                        else
                            echo "ping $single_ip 平均延时不是数值 $ping_result"
                        fi
                    else
                        echo "IP $single_ip 返回的 server 响应头是$server_header"
                    fi
                else
                    echo "IP $single_ip 没有返回 server 响应头"
                    # 增加失败计数
                    ((fail_count++))
                    # 检查失败计数是否超过阈值
                    if [[ $fail_count -gt 3 ]]; then
                        echo "网段 $ip 内连续失败 IP 数量超过3个,跳过"
                        break
                    fi
                fi
            done < <(nmap -sL "$ip" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        fi
    done
fi

# 获取当前时间
current_time=$(date "+%Y-%m-%d %H:%M:%S")

# 生成index.md文件
cat > index.md <<EOF
---
layout: home
title: GitHub IP 列表
date: $current_time
---

## 可用 GitHub IP 列表

| IP 地址 | 平均延时 (ms) |
|---------|--------------|
EOF

if [[ ${#ip_ping_list[@]} -gt 0 ]]; then
    # 按延时从小到大排序并添加到表格
    printf "%s\n" "${ip_ping_list[@]}" | sort -n | while read -r delay addr; do
        echo "| $addr | $delay |" >> index.md
    done
else
    echo "| 暂无可用 IP | - |" >> index.md
fi

cat >> index.md <<EOF

---

*数据更新时间: $current_time*
EOF

echo "已生成 index.md 文件"
