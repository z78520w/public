#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

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

[ $(id -u) != '0' ] && { echo -e "${Error}您必须先执行$(red_font 'sudo su')切换到root用户再运行此脚本"; exit 1; }

app_name="$(pwd)/sshcopy"
if [ ! -e $app_name ]; then
	echo -e "${Info}正在下载免密登录程序..."
	wget -qO $app_name https://github.com/Jrohy/sshcopy/releases/download/v1.4/sshcopy_linux_386 && chmod +x $app_name
fi

clear && echo
read -p "请输入远程服务器的IP(主机名2)：" IP
read -p "请输入 ${IP} 的SSH端口(默认:6000)：" ssh_port
[ -z $ssh_port ] && ssh_port='6000'
read -p "请输入 ${IP} 的登录用户(默认:root)：" user
[ -z $user ] && user='root'
read -p "请输入 ${IP} 的登录密码：" passward

$app_name -ip $IP -user $user -port $ssh_port -pass $passward

if [ -e /var/spool/cron/root ]; then
	corn_path='/var/spool/cron/root'
elif [ -e /var/spool/cron/crontabs/root ]; then
	corn_path='/var/spool/cron/crontabs/root'
else
	$corn_path="$(pwd)/temp"
	echo 'SHELL=/bin/bash' > $corn_path
fi

echo "*/10 * * * *  ssh -p ${ssh_port} ${user}@${IP}" >> $corn_path
if [[ $corn_path == "$(pwd)/temp" ]]; then
	crontab -u root $corn_path
	rm -f $corn_path
fi
echo -e "${Info}定时任务添加成功！"
/etc/init.d/cron restart
