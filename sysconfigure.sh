#!/bin/bash
echo "=====系统环境初始化脚本====="
echo "1.关闭防火墙与SELinux"
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i '/SELINUX/{s/enforcing/disabled/}' /etc/selinux/config

echo "2.创建阿里仓库"
rm -rf /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum -y install wget
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

echo "3.设置时区并同步时间"
timedatectl set-timezone Asia/Shanghai
yum -y install chrony
systemctl start chronyd
systemctl enable chronyd

echo "4.设置系统最大打开文件数"
if ! grep "* soft nofile 65535" /etc/security/limits.conf &>/dev/null; then
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535   #软限制
* hard nofile 65535   #硬限制
EOF
fi

echo "5.系统内核优化"
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1             #防范SYN洪水攻击，0为关闭
net.ipv4.tcp_max_tw_buckets = 20480     #此项参数可以控制TIME_WAIT套接字的最大数量，避免Squid服务器被大量的TIME_WAIT套接字拖死
net.ipv4.tcp_max_syn_backlog = 20480    #表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数
net.core.netdev_max_backlog = 262144    #每个网络接口 接受数据包的速率比内核处理这些包的速率快时，允许发送到队列的数据包的最大数目
net.ipv4.tcp_fin_timeout = 20           #FIN-WAIT-2状态的超时时间，避免内核崩溃
EOF

echo "6.减少SWAP使用"
echo "0" > /proc/sys/vm/swappiness

echo "7.安装系统性能分析工具及其他"
yum install -y gcc make autoconf vim sysstat net-tools iostat  lrzsz

