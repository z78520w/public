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
white_font(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
yello_font(){
	echo -e "\033[33m\033[01m$1\033[0m"
}
Info=`green_font [信息]` && Error=`red_font [错误]` && Tip=`yello_font [注意]`

[ $(id -u) != '0' ] && { echo -e "${Error}您必须以root用户运行此脚本！\n${Info}使用$(red_font 'sudo su')命令切换到root用户！"; exit 1; }

if [[ -f /etc/redhat-release ]]; then
	release='centos'
elif cat /etc/issue | grep -q -E -i "debian"; then
	release='debian'
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
	release='ubuntu'
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
	release='centos'
elif cat /proc/version | grep -q -E -i "debian"; then
	release='debian'
elif cat /proc/version | grep -q -E -i "ubuntu"; then
	release='ubuntu'
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
	release='centos'
fi
if [[ ${release} == 'centos' ]]; then
	PM='yum'
else
	PM='apt'
fi

$PM -y install sshpass

clear && echo
unset IP ssh_port passward
until [[ -n $IP ]]
do
	read -p "请输入Goorm服务器的IP：" IP
done
until [[ -n $ssh_port ]]
do
	read -p "请输入 ${IP} 的SSH端口：" ssh_port
done
until [[ -n $passward ]]
do
	read -p "请输入 ${IP} 的登录密码：" passward
done

if [ -e /var/spool/cron/root ]; then
	corn_path='/var/spool/cron/root'
elif [ -e /var/spool/cron/crontabs/root ]; then
	corn_path='/var/spool/cron/crontabs/root'
else
	corn_path="$(pwd)/temp"
	echo 'SHELL=/bin/bash' > $corn_path
fi

echo "*/2 * * * *  sshpass -p ${passward} ssh -p ${ssh_port} root@${IP}" >> $corn_path
if [[ $corn_path == "$(pwd)/temp" ]]; then
	crontab -u root $corn_path
	rm -f $corn_path
fi
/etc/init.d/cron restart
echo -e "${Info}定时任务添加成功！"

donation_developer(){
	github='https://raw.githubusercontent.com/AmuyangA/public/master'
	yello_font '您的支持是作者更新和完善脚本的动力！'
	yello_font '请访问以下网址扫码捐赠：'
	green_font "[支付宝] \c" && white_font "${github}/donation/alipay.jpg"
	green_font "[微信]   \c" && white_font "${github}/donation/wechat.png"
	green_font "[银联]   \c" && white_font "${github}/donation/unionpay.png"
	green_font "[QQ]     \c" && white_font "${github}/donation/qq.png"
}
echo && read -p "是否捐赠作者?[y:是 n:退出脚本](默认:n)：" num
[ -z $num ] && num='n'
if [[ $num != 'n' ]]; then
	donation_developer
fi
