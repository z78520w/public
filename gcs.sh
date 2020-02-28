#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

sh_ver='1.0.0'
green_font(){
	echo -e "\033[32m\033[01m$1\033[0m\033[37m\033[01m$2\033[0m"
}
red_font(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
yello_font(){
	echo -e "\033[33m\033[01m$1\033[0m"
}
Info=`green_font [信息]` && Error=`red_font [错误]` && Tip=`yello_font [注意]`
[ $(id -u) != '0' ] && { echo -e "${Error}您必须以root用户运行此脚本"; exit 1; }

if [[ -f /etc/redhat-release ]]; then
	release="centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
	release="debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
elif cat /proc/version | grep -q -E -i "debian"; then
	release="debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
fi
if [[ -s /etc/redhat-release ]]; then
	version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
else
	version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
fi
if [[ ${release} == "centos" ]]; then
	PM='yum'
else
	PM='apt'
fi
$PM -y install curl
IP=$(curl -s ipinfo.io/ip)
[ -z ${IP} ] && IP=$(curl -s http://api.ipify.org)
[ -z ${IP} ] && IP=$(curl -s ipv4.icanhazip.com)
[ -z ${IP} ] && IP=$(curl -s ipv6.icanhazip.com)
ssh_port=$(cat /etc/ssh/sshd_config |grep 'Port ' |awk -F ' ' '{print $2}')
pw=$(tr -dc 'A-Za-z0-9!@#$%^&*()[]{}+=_,' </dev/urandom | head -c 17)
echo root:${pw} |chpasswd
sed -i '1,/PermitRootLogin/{s/.*PermitRootLogin.*/PermitRootLogin yes/}' /etc/ssh/sshd_config
sed -i '1,/PasswordAuthentication/{s/.*PasswordAuthentication.*/PasswordAuthentication yes/}' /etc/ssh/sshd_config
if [[ ${release} == "centos" ]]; then
	service sshd restart
else
	service ssh restart
fi

clear
green_font '免费撸谷歌云一键脚本' "版本号：${sh_ver}\n"
echo -e "${Info}服务器IP地址：$(red_font $IP)"
echo -e "${Info}SSH端口：     $(red_font $ssh_port)"
echo -e "${Info}用户名：      $(red_font root)"
echo -e "${Info}您的密码是：  $(red_font $pw)"
echo -e "\n${Tip}请务必记录您的密码！任意键退出..."
char=`get_char`