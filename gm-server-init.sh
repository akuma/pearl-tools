#!/bin/sh
# A script for initing Guomi server (Aliyun ECS).

hostname=$1

# 挂载数据盘、分区
dd if=/dev/zero of=/root/swapfile bs=1M count=4096
mkswap /root/swapfile                   # 建立swap的文件系统
swapon /root/swapfile                   # 启用swap文件
fdisk /dev/xvdb                         # 对 xvdb 进行分区，e.g.: xvdb1 -> /home，xvdb2 -> /opt
mkfs.xfs /dev/xvdb1                     # 格式化分区
mkfs.xfs /dev/xvdb2                     # 格式化分区
vi /etc/fstab                           # 配置系统启动时自动加载
mount -a

# 服务器配置
hostnamectl set-hostname $hostname      # 修改机器名
vi /etc/ssh/sshd_config                 # 修改 ssh 服务端口号，例如：58622
systemctl restart sshd
visudo                                  # 开启 %wheel 有 NOPASSWD: ALL 的配置
useradd -G wheel dev
passwd dev
su - dev
ssh-keygen -C dev@$hostname
cd .ssh || return
vi authorized_keys                      # 添加 public key

# 安装常用软件
sudo yum install -y yum-axelget
sudo yum update -y
sudo yum install -y git zsh wget lftp dstat
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
vi ~/.zshrc                             # plugins=(git sudo autojump yum)
# sudo yum install -y epel-release      # aliyun 已经安装
sudo yum install -y autojump autojump-zsh

# 安装 nfs 客户端
sudo yum install -y nfs-utils rpcbind
sudo vi /etc/fstab
