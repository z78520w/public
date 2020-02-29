#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

sh_ver='1.0.1'
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
[ $(id -u) != '0' ] && { echo -e "${Error}您必须以root用户运行此脚本！\n${Info}使用$(red_font 'sudo su')命令切换到root用户！"; exit 1; }

get_char(){
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}
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
ssh_port=$(hostname -f|awk -F '-' '{print $2}')
HOSTNAME="$(hostname -f|awk -F "${ssh_port}-" '{print $2}').cloudshell.dev"
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
echo -e "${Info}主机名：  $(red_font $HOSTNAME)"
echo -e "${Info}SSH端口： $(red_font $ssh_port)"
echo -e "${Info}用户名：  $(red_font root)"
echo -e "${Info}密码是：  $(red_font $pw)"
echo -e "\n${Tip}请务必记录您的密码！任意键退出..."
char=`get_char`